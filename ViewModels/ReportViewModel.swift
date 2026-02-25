//
//  ReportViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Combine
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

class ReportViewModel: ObservableObject {

    // UI Binding
    @Published var locationName: String = ""
    @Published var waterLevelPercentage: Double = 30.0
    @Published var reportDescription: String = ""
    @Published var selectedImage: UIImage?

    // Trạng thái
    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false

    // Location (from shared service)
    let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()

    init(locationService: LocationService) {
        self.locationService = locationService

        // Subscribe to location updates from shared service
        locationService.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.locationName = String(
                    format: "Lat: %.4f, Long: %.4f",
                    coordinate.latitude, coordinate.longitude
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Location

    func requestCurrentLocation() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestPermission()
        case .restricted, .denied:
            locationName = "Permission Denied"
        case .authorizedAlways, .authorizedWhenInUse:
            locationService.requestCurrentLocation()
        @unknown default:
            break
        }
    }

    // MARK: - Submit Report

    func submitReport() {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "Bạn cần đăng nhập để gửi báo cáo."
            self.showErrorAlert = true
            return
        }
        guard let location = locationService.currentLocation else {
            self.errorMessage = "Vui lòng lấy vị trí hiện tại."
            self.showErrorAlert = true
            return
        }

        isSubmitting = true

        if let image = selectedImage {
            uploadImage(image) { [weak self] result in
                switch result {
                case .success(let url):
                    self?.saveDataToFirestore(photoURL: url, user: user, location: location)
                case .failure(let error):
                    self?.isSubmitting = false
                    self?.errorMessage = "Lỗi upload ảnh: \(error.localizedDescription)"
                    self?.showErrorAlert = true
                }
            }
        } else {
            saveDataToFirestore(photoURL: nil, user: user, location: location)
        }
    }

    // MARK: - Helpers

    private func uploadImage(
        _ image: UIImage, completion: @escaping (Result<String, Error>) -> Void
    ) {
        let filename = "report_images/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child(filename)

        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let url = url { completion(.success(url.absoluteString)) }
            }
        }
    }

    private func saveDataToFirestore(
        photoURL: String?, user: User, location: CLLocationCoordinate2D
    ) {
        let db = Firestore.firestore()

        let reportData: [String: Any] = [
            "user_id": user.uid,
            "user_name": user.displayName ?? "Anonymous",
            "location": GeoPoint(latitude: location.latitude, longitude: location.longitude),
            "location_name": self.locationName,
            "water_level": Float(self.waterLevelPercentage / 100.0 * 2.0),
            "description": self.reportDescription,
            "photo_url": photoURL ?? "",
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp(),
        ]

        db.collection("reports").addDocument(data: reportData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSubmitting = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                } else {
                    self?.showSuccessAlert = true
                    self?.resetForm()
                }
            }
        }
    }

    private func resetForm() {
        reportDescription = ""
        selectedImage = nil
    }
}

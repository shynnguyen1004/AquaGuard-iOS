//
//  ReportViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//
//  Community flood report submission — now uses the backend
//  REST API (POST /api/sos) instead of Firebase Firestore/Storage.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

class ReportViewModel: ObservableObject {

    // UI Binding
    @Published var locationName: String = ""
    @Published var waterLevelPercentage: Double = 30.0
    @Published var reportDescription: String = ""
    @Published var selectedImage: UIImage?

    // State
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

    // MARK: - Submit Report via Backend API

    func submitReport() {
        guard TokenManager.shared.isAuthenticated else {
            self.errorMessage = "You must be signed in to submit a report."
            self.showErrorAlert = true
            return
        }
        guard let location = locationService.currentLocation else {
            self.errorMessage = "Please get your current location first."
            self.showErrorAlert = true
            return
        }

        isSubmitting = true

        // Map water level percentage to urgency
        let urgency: String
        switch waterLevelPercentage {
        case 0..<25: urgency = "low"
        case 25..<50: urgency = "medium"
        case 50..<75: urgency = "high"
        default: urgency = "critical"
        }

        Task { @MainActor in
            do {
                // Build form fields
                var fields: [String: String] = [
                    "location": locationName,
                    "description": reportDescription.isEmpty
                        ? "Community flood report"
                        : reportDescription,
                    "urgency": urgency,
                    "latitude": String(location.latitude),
                    "longitude": String(location.longitude),
                ]

                // Build image data (if any)
                var images: [(fieldName: String, data: Data, filename: String)] = []
                if let image = selectedImage,
                   let imageData = image.jpegData(compressionQuality: 0.7) {
                    images.append((
                        fieldName: "images",
                        data: imageData,
                        filename: "report_\(UUID().uuidString).jpg"
                    ))
                }

                let _: APIRescueRequest = try await APIService.shared.uploadMultipart(
                    "/sos",
                    fields: fields,
                    images: images
                )

                self.isSubmitting = false
                self.showSuccessAlert = true
                self.resetForm()
            } catch {
                self.isSubmitting = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    // MARK: - Helpers

    private func resetForm() {
        reportDescription = ""
        selectedImage = nil
    }
}

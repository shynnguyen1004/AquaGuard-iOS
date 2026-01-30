//
//  ReportViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine
import FirebaseFirestore // 1. Import Firestore
import FirebaseStorage   // 2. Import Storage
import FirebaseAuth      // 3. Import Auth

class ReportViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
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
    
    // Vị trí
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? // Lưu toạ độ thật
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // --- XỬ LÝ VỊ TRÍ ---
    func requestCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied: locationName = "Permission Denied"
        case .authorizedAlways, .authorizedWhenInUse: locationManager.requestLocation()
        @unknown default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.userLocation = location.coordinate
            DispatchQueue.main.async {
                self.locationName = String(format: "Lat: %.4f, Long: %.4f", location.coordinate.latitude, location.coordinate.longitude)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Lỗi vị trí: \(error.localizedDescription)")
    }
    
    // --- GỬI BÁO CÁO (Logic Chính) ---
    func submitReport() {
        // 1. Kiểm tra đầu vào
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "Bạn cần đăng nhập để gửi báo cáo."; self.showErrorAlert = true; return
        }
        guard let location = userLocation else {
            self.errorMessage = "Vui lòng lấy vị trí hiện tại."; self.showErrorAlert = true; return
        }
        
        isSubmitting = true
        
        // 2. Nếu có ảnh -> Upload ảnh trước
        if let image = selectedImage {
            uploadImage(image) { [weak self] result in
                switch result {
                case .success(let url):
                    // Upload ảnh xong, có URL -> Gửi data
                    self?.saveDataToFirestore(photoURL: url, user: user, location: location)
                case .failure(let error):
                    self?.isSubmitting = false
                    self?.errorMessage = "Lỗi upload ảnh: \(error.localizedDescription)"
                    self?.showErrorAlert = true
                }
            }
        } else {
            // Không có ảnh -> Gửi data luôn (URL rỗng)
            saveDataToFirestore(photoURL: nil, user: user, location: location)
        }
    }
    
    // Helper: Upload ảnh lên Firebase Storage
    private func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Tạo tên file độc nhất
        let filename = "report_images/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child(filename)
        
        // Nén ảnh (0.5 chất lượng để upload nhanh)
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error { completion(.failure(error)); return }
            
            storageRef.downloadURL { url, error in
                if let error = error { completion(.failure(error)); return }
                if let url = url { completion(.success(url.absoluteString)) }
            }
        }
    }
    
    // Helper: Ghi data vào Firestore
    private func saveDataToFirestore(photoURL: String?, user: User, location: CLLocationCoordinate2D) {
        let db = Firestore.firestore()
        
        let reportData: [String: Any] = [
            "user_id": user.uid, // Reference ID người gửi
            "user_name": user.displayName ?? "Anonymous", // Lưu thêm tên để hiển thị cho nhanh
            "location": GeoPoint(latitude: location.latitude, longitude: location.longitude),
            "location_name": self.locationName,
            "water_level": Float(self.waterLevelPercentage / 100.0 * 2.0), // Giả sử max là 2m
            "description": self.reportDescription,
            "photo_url": photoURL ?? "",
            "status": "pending", // Mặc định là chờ duyệt
            "timestamp": FieldValue.serverTimestamp() // Lấy giờ server
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
        // Giữ lại vị trí để user đỡ phải lấy lại nếu gửi tiếp
    }
}

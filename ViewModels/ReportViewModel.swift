//
//  ReportViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import SwiftUI
import CoreLocation // BỔ SUNG QUAN TRỌNG
import Combine

class ReportViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // Các biến dữ liệu form
    @Published var locationName: String = ""
    @Published var waterLevelPercentage: Double = 30.0
    @Published var reportDescription: String = ""
    @Published var selectedImage: UIImage?
    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false


    
    // Quản lý định vị
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Hàm được gọi từ View để bắt đầu lấy toạ độ
    func requestCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.locationName = "Location Access Denied"
            print("Người dùng đã từ chối quyền vị trí.")
        case .authorizedAlways, .authorizedWhenInUse:
            // Lấy toạ độ 1 lần duy nhất (One-shot)
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    // 1. Khi lấy toạ độ thành công
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            // Cập nhật lên UI (phải chạy trên main thread)
            DispatchQueue.main.async {
                // Định dạng số đẹp (ví dụ: 10.7769, 106.7009)
                self.locationName = "Current Location: " + String(format: "%.5f, %.5f", lat, lon)
            }
        }
    }
    
    // 2. Khi có lỗi xảy ra (Bắt buộc phải có hàm này nếu dùng requestLocation)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Lỗi lấy vị trí: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.locationName = "Error fetching location"
        }
    }
    
    // 3. Khi quyền thay đổi (ví dụ user vừa bấm Allow)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func submitReport() {
        isSubmitting = true
        // Giả lập call API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSubmitting = false
            self.showSuccessAlert = true
            self.locationName = ""
            self.reportDescription = ""
        }
    }
}

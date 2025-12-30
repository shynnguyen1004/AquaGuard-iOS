//
//  MapViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import MapKit
import Combine
import SwiftUI
import CoreLocation // BỔ SUNG: Import CoreLocation

@MainActor
class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate { // BỔ SUNG: Kế thừa NSObject, CLLocationManagerDelegate
    
    // --- CODE CŨ (GIỮ NGUYÊN) ---
    @Published var zones: [FloodZone] = MockData.floodZones
    @Published var selectedZone: FloodZone?
    @Published var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10.778089, longitude: 106.681523),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    
    // --- PHẦN BỔ SUNG CHO TÍNH NĂNG LOCATE ---
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Hàm gọi khi bấm nút Locate
    func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access denied")
            // Ở đây có thể thêm logic hiển thị Alert hướng dẫn user bật lại trong Settings
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationManager.location {
                withAnimation {
                    // Zoom camera về vị trí người dùng
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        @unknown default:
            break
        }
    }
    
    // Tự động check khi quyền thay đổi (ví dụ user vừa bấm Allow)
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            // Logic xử lý khi quyền thay đổi
            // (Có thể gọi checkLocationPermission() nếu muốn tự động zoom ngay khi cấp quyền)
        }
    }
}

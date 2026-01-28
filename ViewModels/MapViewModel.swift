import Foundation
import MapKit
import Combine
import SwiftUI
import CoreLocation
import FirebaseFirestore // 1. Import Firebase

@MainActor
class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var zones: [FloodZone] = [] // 2. Xoá MockData, để mảng rỗng ban đầu
    @Published var selectedZone: FloodZone?
    @Published var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 16.352147, longitude: 107.016871),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    ))
    
    // --- 1. THÊM BIẾN NÀY ĐỂ LƯU ĐƯỜNG ĐI ---
    @Published var route: MKRoute?
    
    private let locationManager = CLLocationManager()
    private var db = Firestore.firestore() // 3. Khởi tạo Database
    private var listenerRegistration: ListenerRegistration? // Biến để quản lý việc lắng nghe
    
    override init() {
        super.init()
        setupLocationManager()
        fetchFloodZones() // 4. Gọi hàm lấy dữ liệu ngay khi khởi tạo
    }
    
    // --- 2. THÊM HÀM TÍNH TOÁN ĐƯỜNG ĐI ---
    func getDirections(to zone: FloodZone) {
        // Kiểm tra xem đã có vị trí người dùng chưa
        guard let userLocation = locationManager.location else {
            print("Chưa lấy được vị trí người dùng")
            return
        }
        
        // Tạo yêu cầu chỉ đường
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: zone.coordinate))
        request.transportType = .automobile // Hoặc .walking nếu muốn
        
        let directions = MKDirections(request: request)
        
        Task {
            do {
                let response = try await directions.calculate()
                // Lấy đường đi đầu tiên (ngắn nhất/tốt nhất)
                if let firstRoute = response.routes.first {
                    self.route = firstRoute
                    
                    // Tự động zoom bản đồ để thấy toàn bộ quãng đường
                    withAnimation {
                        self.cameraPosition = .item(MKMapItem(placemark: MKPlacemark(coordinate: zone.coordinate)))
                        // Hoặc dùng .rect(firstRoute.polyline.boundingMapRect) nếu muốn bao quát hơn
                    }
                }
            } catch {
                print("Lỗi tìm đường: \(error.localizedDescription)")
            }
        }
    }
    
    // --- 3. HÀM XÓA ĐƯỜNG ĐI (Khi user không muốn xem nữa) ---
    func clearRoute() {
        self.route = nil
    }
    
    // --- HÀM MỚI: Lắng ngh dữ liệu Realtime ---
    func fetchFloodZones() {
        listenerRegistration = db.collection("flood_zones").addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("LỖI: Không tìm thấy document nào hoặc lỗi mạng: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            print("TÌM THẤY: \(documents.count) địa điểm trên Firebase") // Xem nó in ra số mấy
            
            self?.zones = documents.compactMap { queryDocumentSnapshot -> FloodZone? in
                let zone = try? queryDocumentSnapshot.data(as: FloodZone.self)
                if zone == nil { print("LỖI GIẢI MÃ: Document ID \(queryDocumentSnapshot.documentID) bị sai dữ liệu") }
                return zone
            }
        }
    }
    
    // Hủy lắng nghe khi không dùng nữa (tốt cho hiệu năng)
    deinit {
        listenerRegistration?.remove()
    }
    
    // ... (Giữ nguyên các hàm setupLocationManager, checkLocationPermission cũ của bạn ở dưới) ...
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access denied")
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationManager.location {
                withAnimation {
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
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Logic xử lý khi quyền thay đổi
    }
}

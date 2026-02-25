import Combine
import CoreLocation
import FirebaseFirestore  // 1. Import Firebase
import Foundation
import MapKit
import SwiftUI

@MainActor
class MapViewModel: ObservableObject {

    @Published var zones: [FloodZone] = []
    @Published var selectedZone: FloodZone?
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 16.352147, longitude: 107.016871),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        ))

    @Published var route: MKRoute?

    let locationService: LocationService
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    init(locationService: LocationService) {
        self.locationService = locationService
        fetchFloodZones()
    }

    // MARK: - Directions

    func getDirections(to zone: FloodZone) {
        guard let userLocation = locationService.lastKnownLocation else {
            print("Chưa lấy được vị trí người dùng")
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: zone.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        Task {
            do {
                let response = try await directions.calculate()
                if let firstRoute = response.routes.first {
                    self.route = firstRoute
                    withAnimation {
                        self.cameraPosition = .item(
                            MKMapItem(placemark: MKPlacemark(coordinate: zone.coordinate)))
                    }
                }
            } catch {
                print("Lỗi tìm đường: \(error.localizedDescription)")
            }
        }
    }

    func clearRoute() {
        self.route = nil
    }

    // MARK: - Firestore

    func fetchFloodZones() {
        listenerRegistration = db.collection("flood_zones").addSnapshotListener {
            [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print(
                    "LỖI: Không tìm thấy document nào hoặc lỗi mạng: \(error?.localizedDescription ?? "Unknown")"
                )
                return
            }

            print("TÌM THẤY: \(documents.count) địa điểm trên Firebase")

            self?.zones = documents.compactMap { queryDocumentSnapshot -> FloodZone? in
                let zone = try? queryDocumentSnapshot.data(as: FloodZone.self)
                if zone == nil {
                    print(
                        "LỖI GIẢI MÃ: Document ID \(queryDocumentSnapshot.documentID) bị sai dữ liệu"
                    )
                }
                return zone
            }
        }
    }

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Location (delegates to LocationService)

    func checkLocationPermission() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestPermission()
        case .restricted, .denied:
            print("Location access denied")
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationService.lastKnownLocation {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                }
            }
        @unknown default:
            break
        }
    }
}

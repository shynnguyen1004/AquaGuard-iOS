import Combine
import CoreLocation
import FirebaseFirestore  // 1. Import Firebase
import Foundation
import MapKit
import SwiftUI

// MARK: - Map Mode

enum MapMode {
    case apple
    case windy
}

// MARK: - Weather Layer

enum WeatherLayer: String, CaseIterable {
    case rain
    case wind
    case clouds
    case temp
    case pressure
    case waves

    var displayName: String {
        switch self {
        case .rain: return "Rain"
        case .wind: return "Wind"
        case .clouds: return "Clouds"
        case .temp: return "Temperature"
        case .pressure: return "Pressure"
        case .waves: return "Waves"
        }
    }

    var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .clouds: return "cloud.fill"
        case .temp: return "thermometer.medium"
        case .pressure: return "gauge.with.dots.needle.bottom.50percent"
        case .waves: return "water.waves"
        }
    }

    /// The key used by Windy's store.set('overlay', key)
    var windyKey: String {
        return rawValue
    }
}

@MainActor
class MapViewModel: ObservableObject {

    // MARK: - Windy Map State

    @Published var mapMode: MapMode = .apple
    @Published var selectedWeatherLayer: WeatherLayer = .wind
    @Published var showWeatherPanel: Bool = false

    /// Windy API key — UPDATE THIS with your iOS-specific key
    /// See: https://api.windy.com/keys
    let windyAPIKey = "8IgvuJIwk3CicS5sVMk2CHI2Ar2FaUoF"

    // MARK: - Apple Map State

    @Published var showFloodZones: Bool = true
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
            print("User location not available")
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
                print("Directions error: \(error.localizedDescription)")
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
                    "ERROR: No documents found or network error: \(error?.localizedDescription ?? "Unknown")"
                )
                return
            }

            print("Found \(documents.count) flood zones on Firebase")

            self?.zones = documents.compactMap { queryDocumentSnapshot -> FloodZone? in
                let zone = try? queryDocumentSnapshot.data(as: FloodZone.self)
                if zone == nil {
                    print(
                        "DECODE ERROR: Document ID \(queryDocumentSnapshot.documentID) has invalid data"
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

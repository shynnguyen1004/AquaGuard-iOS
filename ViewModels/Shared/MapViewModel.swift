import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI
import FirebaseFirestore

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

    // MARK: - Family on Map State

    @Published var showFamilyOnMap: Bool = false
    @Published var familyMembers: [FamilyMember] = []
    @Published var selectedFamilyMember: FamilyMember?

    // MARK: - SOS Requests on Map

    @Published var sosRequests: [APIRescueRequest] = []

    let locationService: LocationService
    private nonisolated(unsafe) var firestoreListener: ListenerRegistration?

    init(locationService: LocationService) {
        self.locationService = locationService
        // Load mock data immediately so pins always appear
        zones = MockData.floodZones
        // Then try Firestore for real-time data
        fetchFloodZones()
        fetchFamilyMembers()
    }

    deinit {
        firestoreListener?.remove()
    }

    // MARK: - Fetch Family Members from Backend

    func fetchFamilyMembers() {
        guard TokenManager.shared.isAuthenticated else { return }

        Task { @MainActor in
            do {
                let response: APIResponse<[APIFamilyMember]> = try await APIService.shared.getRaw("/family/members")
                if let apiMembers = response.data {
                    self.familyMembers = apiMembers.map { m in
                        let safetyStatus: SafetyStatus = {
                            switch m.safetyStatus {
                            case "safe": return .safe
                            case "danger": return .danger
                            case "injured": return .sos
                            default: return .unknown
                            }
                        }()

                        let initial = String(m.displayName.prefix(1)).uppercased()
                        let colors: [Color] = [
                            Color(red: 0.9, green: 0.4, blue: 0.5),
                            Color(red: 0.3, green: 0.5, blue: 0.8),
                            Color(red: 0.6, green: 0.4, blue: 0.8),
                            Color(red: 0.2, green: 0.7, blue: 0.6),
                        ]
                        let hash = m.displayName.unicodeScalars.reduce(0) { $0 + Int($1.value) }

                        return FamilyMember(
                            name: m.relation.isEmpty ? m.displayName : "\(m.relation) - \(m.displayName)",
                            phone: m.phoneNumber,
                            avatarInitial: initial,
                            avatarColor: colors[hash % colors.count],
                            status: safetyStatus,
                            location: m.address.isEmpty ? "Chưa cập nhật" : m.address,
                            latitude: m.latitude ?? 0,
                            longitude: m.longitude ?? 0,
                            lastSeen: Date(),
                            relationship: m.relation.isEmpty ? "Gia đình" : m.relation
                        )
                    }
                }
            } catch {
                print("[MapVM] Failed to fetch family: \(error)")
            }
        }
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

    // MARK: - Fetch Flood Zones from Firestore (Real-time)
    // Tries "flood_zones" and "monitoring_points" collections.
    // Falls back to mock data if Firestore has no data.

    func fetchFloodZones() {
        let db = Firestore.firestore()

        // Remove any existing listener
        firestoreListener?.remove()

        // Try "flood_zones" collection first, then "monitoring_points"
        let collectionNames = ["flood_zones", "monitoring_points"]
        tryFirestoreCollection(db: db, names: collectionNames, index: 0)
    }

    private func tryFirestoreCollection(db: Firestore, names: [String], index: Int) {
        guard index < names.count else {
            print("[MapVM] ℹ️ No Firestore flood data found, keeping mock data")
            return
        }

        let collectionName = names[index]
        print("[MapVM] 🔍 Trying Firestore collection: \(collectionName)")

        firestoreListener = db.collection(collectionName)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if let error = error {
                        print("[MapVM] ❌ Firestore error (\(collectionName)): \(error.localizedDescription)")
                        // Try next collection name
                        self.firestoreListener?.remove()
                        self.tryFirestoreCollection(db: db, names: names, index: index + 1)
                        return
                    }

                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("[MapVM] ⚠️ Collection '\(collectionName)' empty, trying next...")
                        self.firestoreListener?.remove()
                        self.tryFirestoreCollection(db: db, names: names, index: index + 1)
                        return
                    }

                    let firestoreZones: [FloodZone] = documents.compactMap { doc in
                        let data = doc.data()
                        print("[MapVM] 📄 Doc \(doc.documentID): \(data)")

                        // Handle both flat fields and GeoPoint location
                        var lat: Double?
                        var lon: Double?

                        if let geoPoint = data["location"] as? GeoPoint {
                            lat = geoPoint.latitude
                            lon = geoPoint.longitude
                        } else {
                            lat = data["latitude"] as? Double
                            lon = data["longitude"] as? Double
                        }

                        guard let name = data["name"] as? String,
                              let latitude = lat,
                              let longitude = lon
                        else {
                            print("[MapVM] ⚠️ Skipping doc \(doc.documentID) - missing required fields")
                            return nil
                        }

                        let severityStr = data["severity"] as? String ?? data["status"] as? String ?? "moderate"
                        let severity = SeverityLevel(rawValue: severityStr) ?? .moderate
                        let waterLevel = data["water_level"] as? Double ?? data["waterLevel"] as? Double ?? 0.0

                        return FloodZone(
                            id: doc.documentID,
                            name: name,
                            latitude: latitude,
                            longitude: longitude,
                            severity: severity,
                            waterLevel: waterLevel
                        )
                    }

                    if !firestoreZones.isEmpty {
                        self.zones = firestoreZones
                        print("[MapVM] ✅ Loaded \(firestoreZones.count) flood zones from Firestore (\(collectionName))")
                    } else {
                        print("[MapVM] ⚠️ All docs in '\(collectionName)' invalid, keeping mock data")
                    }
                }
            }
    }

    // MARK: - Fetch SOS Requests for Map Markers

    func fetchSOSRequests() {
        Task {
            do {
                let requests: [APIRescueRequest] = try await APIService.shared.get("/sos/all")
                self.sosRequests = requests.filter { $0.latitude != nil && $0.longitude != nil }
            } catch {
                print("Failed to fetch SOS requests for map: \(error.localizedDescription)")
            }
        }
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

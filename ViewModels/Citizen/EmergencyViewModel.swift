//
//  EmergencyViewModel.swift
//  AquaGuard
//
//  Unified view model for the Emergency tab.
//  Handles both Quick SOS (camera capture → send) and
//  Detailed Rescue Request (form → send) flows.
//  Now uses backend REST API instead of in-memory dummy data.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
class EmergencyViewModel: ObservableObject {

    // MARK: - Request History

    /// All emergency requests (newest first) — fetched from backend
    @Published var requests: [EmergencyRequest] = []

    /// Currently selected request (for tracking sheet)
    @Published var activeRequest: EmergencyRequest?

    // MARK: - Quick SOS Mode

    /// Image captured from camera
    @Published var capturedImage: UIImage?

    /// Caption for quick SOS
    @Published var caption: String = ""

    /// Show preview sheet after capture
    @Published var showPreview: Bool = false

    // MARK: - Detailed Mode

    /// GPS coordinates as readable string (e.g. "10.7769, 106.7009")
    @Published var gpsString: String = ""

    /// Human-readable address from reverse geocoding
    @Published var resolvedAddress: String = ""

    /// Situation description
    @Published var reportDescription: String = ""

    /// Image selected via form
    @Published var selectedImage: UIImage?

    /// Show detailed form sheet
    @Published var showDetailedForm: Bool = false

    // MARK: - Shared State

    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var showTrackingSheet: Bool = false
    @Published var isLoadingHistory: Bool = false

    // MARK: - Dependencies

    let locationService: LocationService
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()

    init(locationService: LocationService) {
        self.locationService = locationService

        // Subscribe to location updates → update GPS string + reverse geocode
        locationService.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.gpsString = String(
                    format: "%.5f, %.5f",
                    coordinate.latitude, coordinate.longitude
                )
                self?.reverseGeocode(coordinate: coordinate)
            }
            .store(in: &cancellables)

        // Load real data from backend
        fetchMyRequests()
    }

    // MARK: - Fetch My Requests from Backend

    func fetchMyRequests() {
        guard TokenManager.shared.isAuthenticated else { return }

        isLoadingHistory = true

        Task {
            do {
                let response: APIResponse<[APIRescueRequest]> = try await APIService.shared.getRaw("/sos/my")

                if let apiRequests = response.data {
                    self.requests = apiRequests.map { r in
                        // Filter valid image URLs (non-empty, valid URL format)
                        let validImageURLs = (r.images ?? []).filter { urlStr in
                            guard !urlStr.isEmpty, URL(string: urlStr) != nil else {
                                print("[EmergencyVM] ⚠️ Invalid image URL skipped: '\(urlStr)'")
                                return false
                            }
                            return true
                        }

                        if !validImageURLs.isEmpty {
                            print("[EmergencyVM] 🖼️ Request #\(r.id) has \(validImageURLs.count) images: \(validImageURLs)")
                        }

                        return EmergencyRequest(
                            id: "\(r.id)",
                            userId: "\(r.userId ?? 0)",
                            localImage: nil,
                            photoURL: validImageURLs.first,
                            imageURLs: validImageURLs,
                            latitude: r.latitude ?? 0,
                            longitude: r.longitude ?? 0,
                            address: r.location ?? "",
                            description: r.description ?? "",
                            requestType: .quickSOS,
                            status: r.sosStatus,
                            timestamp: r.createdDate,
                            rescuerId: r.assignedTo != nil ? "\(r.assignedTo!)" : nil,
                            rescuerLatitude: r.rescuerLatitude,
                            rescuerLongitude: r.rescuerLongitude,
                            rescuerName: r.assignedName
                        )
                    }
                    print("[EmergencyVM] Loaded \(self.requests.count) requests from backend")
                } else {
                    print("[EmergencyVM] API returned success=\(response.success) but data is nil. message=\(response.message ?? "none")")
                }
                self.isLoadingHistory = false
            } catch {
                print("[EmergencyVM] ❌ Failed to fetch requests: \(error)")
                self.isLoadingHistory = false
            }
        }
    }

    // MARK: - Reverse Geocoding

    /// Convert GPS coordinates to human-readable address
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.cancelGeocode()

        // Use Vietnamese locale for best local address formatting
        geocoder.reverseGeocodeLocation(
            location,
            preferredLocale: Locale(identifier: "vi_VN")
        ) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let placemark = placemarks?.first {
                    var streetParts: [String] = []
                    if let number = placemark.subThoroughfare {
                        streetParts.append(number)
                    }
                    if let street = placemark.thoroughfare {
                        streetParts.append(street)
                    }

                    var fullParts: [String] = []
                    if !streetParts.isEmpty {
                        fullParts.append(streetParts.joined(separator: " "))
                    }
                    if let ward = placemark.subLocality {
                        fullParts.append(ward)
                    }
                    if let district = placemark.subAdministrativeArea {
                        fullParts.append(district)
                    }
                    if let city = placemark.locality {
                        fullParts.append(city)
                    }

                    if fullParts.count >= 2 {
                        self.resolvedAddress = fullParts.joined(separator: ", ")
                    } else if let name = placemark.name, !name.isEmpty {
                        self.resolvedAddress = name
                    } else {
                        self.resolvedAddress = fullParts.joined(separator: ", ")
                    }
                } else {
                    self.resolvedAddress = "Unable to resolve address"
                }
            }
        }
    }

    // MARK: - Quick SOS Actions

    /// Called after camera captures an image
    func onImageCaptured(_ image: UIImage) {
        capturedImage = image
        showPreview = true
    }

    /// Submit a Quick SOS request via backend POST /api/sos
    func submitQuickSOS() {
        guard let image = capturedImage else { return }
        guard TokenManager.shared.isAuthenticated else {
            errorMessage = "You must be signed in to send SOS."
            showErrorAlert = true
            return
        }

        let coordinate = locationService.currentLocation ?? CLLocationCoordinate2D(
            latitude: 10.7769, longitude: 106.7009
        )

        isSubmitting = true

        Task {
            do {
                let addressText = resolvedAddress.isEmpty ? gpsString : resolvedAddress
                let descText = caption.isEmpty ? "Quick SOS — Emergency" : caption

                let fields: [String: String] = [
                    "location": addressText,
                    "description": descText,
                    "urgency": "critical",
                    "latitude": String(coordinate.latitude),
                    "longitude": String(coordinate.longitude),
                ]

                var images: [(fieldName: String, data: Data, filename: String)] = []
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    images.append((
                        fieldName: "images",
                        data: imageData,
                        filename: "sos_\(UUID().uuidString).jpg"
                    ))
                }

                let _: APIRescueRequest = try await APIService.shared.uploadMultipart(
                    "/sos",
                    fields: fields,
                    images: images
                )

                self.isSubmitting = false
                self.showSuccessAlert = true
                self.resetForms()

                // Refresh history to include the new request
                self.fetchMyRequests()
            } catch {
                self.isSubmitting = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    /// Cancel quick SOS preview
    func cancelPreview() {
        capturedImage = nil
        caption = ""
        showPreview = false
    }

    // MARK: - Detailed Request Actions

    /// Request current GPS location
    func requestCurrentLocation() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestPermission()
        case .restricted, .denied:
            resolvedAddress = "Permission Denied"
        case .authorizedAlways, .authorizedWhenInUse:
            locationService.requestCurrentLocation()
        @unknown default:
            break
        }
    }

    /// Submit a detailed rescue request via backend POST /api/sos
    func submitDetailedRequest() {
        guard TokenManager.shared.isAuthenticated else {
            errorMessage = "You must be signed in to send a request."
            showErrorAlert = true
            return
        }

        let coordinate = locationService.currentLocation ?? CLLocationCoordinate2D(
            latitude: 10.7769, longitude: 106.7009
        )

        isSubmitting = true

        Task {
            do {
                let addressText = resolvedAddress.isEmpty ? gpsString : resolvedAddress

                var fields: [String: String] = [
                    "location": addressText,
                    "description": reportDescription.isEmpty ? "Flood rescue request" : reportDescription,
                    "urgency": "high",
                    "latitude": String(coordinate.latitude),
                    "longitude": String(coordinate.longitude),
                ]

                var images: [(fieldName: String, data: Data, filename: String)] = []
                if let image = selectedImage,
                   let imageData = image.jpegData(compressionQuality: 0.7) {
                    images.append((
                        fieldName: "images",
                        data: imageData,
                        filename: "rescue_\(UUID().uuidString).jpg"
                    ))
                }

                let _: APIRescueRequest = try await APIService.shared.uploadMultipart(
                    "/sos",
                    fields: fields,
                    images: images
                )

                self.isSubmitting = false
                self.showSuccessAlert = true
                self.resetForms()

                // Refresh history
                self.fetchMyRequests()
            } catch {
                self.isSubmitting = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    // MARK: - Tracking

    func openTracking(for request: EmergencyRequest) {
        activeRequest = request
        showTrackingSheet = true
    }

    // MARK: - Helpers

    private func resetForms() {
        // Quick SOS
        capturedImage = nil
        caption = ""
        showPreview = false

        // Detailed
        reportDescription = ""
        selectedImage = nil
        showDetailedForm = false
        // Note: gpsString and resolvedAddress are NOT reset
        // (they come from GPS and should persist)
    }

    var requestCount: Int {
        requests.count
    }
}

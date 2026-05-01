//
//  EmergencyViewModel.swift
//  AquaGuard
//
//  Unified view model for the Emergency tab.
//  Handles both Quick SOS (camera capture → send) and
//  Detailed Rescue Request (form → send) flows.
//  Currently uses in-memory dummy data for testing.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
class EmergencyViewModel: ObservableObject {

    // MARK: - Request History

    /// All emergency requests (newest first) — stored in memory
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

    /// Location name (auto-filled or typed)
    @Published var locationName: String = ""

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

    // MARK: - Dependencies

    let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()

    init(locationService: LocationService) {
        self.locationService = locationService

        // Subscribe to location updates for the detailed form
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

        // Load mock history
        loadMockData()
    }

    // MARK: - Quick SOS Actions

    /// Called after camera captures an image
    func onImageCaptured(_ image: UIImage) {
        capturedImage = image
        showPreview = true
    }

    /// Submit a Quick SOS request (camera capture flow)
    func submitQuickSOS() {
        guard let image = capturedImage else { return }

        let coordinate = locationService.currentLocation ?? CLLocationCoordinate2D(
            latitude: 10.7769, longitude: 106.7009
        )

        isSubmitting = true

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }

            let request = EmergencyRequest(
                id: UUID().uuidString,
                userId: "dummy_user",
                localImage: image,
                photoURL: nil,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: self.locationName.isEmpty
                    ? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    : self.locationName,
                description: self.caption,
                requestType: .quickSOS,
                status: .pending,
                timestamp: Date(),
                rescuerId: nil
            )

            self.requests.insert(request, at: 0)
            self.isSubmitting = false
            self.showSuccessAlert = true
            self.resetForms()
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
            locationName = "Permission Denied"
        case .authorizedAlways, .authorizedWhenInUse:
            locationService.requestCurrentLocation()
        @unknown default:
            break
        }
    }

    /// Submit a detailed rescue request (form flow)
    func submitDetailedRequest() {
        let coordinate = locationService.currentLocation ?? CLLocationCoordinate2D(
            latitude: 10.7769, longitude: 106.7009
        )

        isSubmitting = true

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }

            let request = EmergencyRequest(
                id: UUID().uuidString,
                userId: "dummy_user",
                localImage: self.selectedImage,
                photoURL: nil,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: self.locationName.isEmpty
                    ? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    : self.locationName,
                description: self.reportDescription,
                requestType: .detailed,
                status: .pending,
                timestamp: Date(),
                rescuerId: nil
            )

            self.requests.insert(request, at: 0)
            self.isSubmitting = false
            self.showSuccessAlert = true
            self.resetForms()
        }
    }

    // MARK: - Tracking

    func openTracking(for request: EmergencyRequest) {
        activeRequest = request
        showTrackingSheet = true
    }

    // MARK: - Mock Data

    private func loadMockData() {
        requests = [
            EmergencyRequest(
                id: "mock_1",
                userId: "dummy_user",
                localImage: nil,
                photoURL: nil,
                latitude: 10.7731,
                longitude: 106.6880,
                address: "12 Nguyen Hue, District 1",
                description: "Water flooding into first floor, family of 4 needs help",
                requestType: .quickSOS,
                status: .pending,
                timestamp: Date().addingTimeInterval(-420),
                rescuerId: nil
            ),
            EmergencyRequest(
                id: "mock_2",
                userId: "dummy_user",
                localImage: nil,
                photoURL: nil,
                latitude: 10.7540,
                longitude: 106.6633,
                address: "456 Le Loi, District 5",
                description: "Elderly person stranded on rooftop due to rising water",
                requestType: .detailed,
                status: .inProgress,
                timestamp: Date().addingTimeInterval(-1920),
                rescuerId: "rescuer_alpha"
            ),
            EmergencyRequest(
                id: "mock_3",
                userId: "dummy_user",
                localImage: nil,
                photoURL: nil,
                latitude: 10.7688,
                longitude: 106.6925,
                address: "78 Tran Hung Dao, District 1",
                description: "Road completely flooded, car stuck and cannot move",
                requestType: .quickSOS,
                status: .resolved,
                timestamp: Date().addingTimeInterval(-7200),
                rescuerId: "rescuer_bravo"
            ),
        ]
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
        locationName = ""
        showDetailedForm = false
    }

    var requestCount: Int {
        requests.count
    }
}

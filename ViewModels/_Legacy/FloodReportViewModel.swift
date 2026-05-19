//
//  FloodReportViewModel.swift
//  AquaGuard
//
//  Manages instant flood report capture and storage.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

class FloodReportViewModel: ObservableObject {

    // MARK: - Published

    /// All captured flood reports (newest first)
    @Published var reports: [FloodReport] = []

    /// Captured image from camera (before confirm)
    @Published var capturedImage: UIImage?

    /// Caption input
    @Published var caption: String = ""

    /// Camera sheet state
    @Published var showCamera = false

    /// Preview/confirm sheet state
    @Published var showPreview = false

    // MARK: - Dependencies

    let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    // MARK: - Actions

    /// Called when user taps the capture button — request location & open camera
    func startCapture() {
        locationService.requestCurrentLocation()
        showCamera = true
    }

    /// Called after camera returns an image
    func onImageCaptured(_ image: UIImage) {
        capturedImage = image
        showCamera = false
        showPreview = true
    }

    /// Confirm and save the report
    func confirmReport() {
        guard let image = capturedImage else { return }

        let coordinate = locationService.currentLocation ?? CLLocationCoordinate2D(
            latitude: 0, longitude: 0
        )

        let report = FloodReport(
            image: image,
            coordinate: coordinate,
            timestamp: Date(),
            caption: caption
        )

        // Insert at beginning (newest first)
        reports.insert(report, at: 0)

        // Reset state
        capturedImage = nil
        caption = ""
        showPreview = false
    }

    /// Cancel the preview
    func cancelPreview() {
        capturedImage = nil
        caption = ""
        showPreview = false
    }

    /// Delete a report
    func deleteReport(_ report: FloodReport) {
        reports.removeAll { $0.id == report.id }
    }

    var reportCount: Int {
        reports.count
    }
}

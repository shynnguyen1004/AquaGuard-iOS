//
//  RescueView.swift
//  AquaGuard
//
//  SOS tab — Locket-style instant flood reporting.
//  Live camera preview on entry. Tap to capture.
//  Photo feed below with GPS + timestamp overlay.
//
//  Created by Shyn Nguyễn on 16/12/25.
//

import Combine
import CoreLocation
import SwiftUI

struct RescueView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme

    // Camera
    @StateObject private var cameraService = CameraService()

    // Flood reports
    @StateObject private var reportVM: FloodReportViewModel

    // Gallery picker fallback
    @State private var showGalleryPicker = false

    // History sheet
    @State private var showHistory = false

    init(locationService: LocationService = LocationService()) {
        _reportVM = StateObject(wrappedValue: FloodReportViewModel(locationService: locationService))
    }

    var body: some View {
        ZStack {
            // Background
            Color.aquaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top bar
                HStack {
                    // GPS indicator
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.aquaPrimary)
                        if let coord = reportVM.locationService.currentLocation {
                            Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text(languageManager.localize("Getting GPS..."))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)

                    Spacer()

                    // Report count badge
                    if reportVM.reportCount > 0 {
                        Button {
                            showHistory = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 11))
                                Text("\(reportVM.reportCount)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.aquaPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // MARK: - Camera Preview (Locket-style rounded)
                ZStack {
                    if cameraService.isAuthorized {
                        CameraPreviewView(session: cameraService.session)
                            .cornerRadius(28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.aquaPrimary.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        // Permission denied state
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.aquaCard)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text(languageManager.localize("Camera access required"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(languageManager.localize("Go to Settings → AquaGuard → Camera"))
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                            )
                    }

                    // Flash toggle (top left)
                    VStack {
                        HStack {
                            Button {
                                cameraService.toggleFlash()
                            } label: {
                                Image(systemName: cameraService.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(.ultraThinMaterial.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(16)
                            Spacer()
                        }
                        Spacer()
                    }

                    // Timestamp overlay (bottom)
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                Text({
                                    let f = DateFormatter()
                                    f.dateFormat = "HH:mm · dd/MM/yyyy"
                                    return f.string(from: Date())
                                }())
                                .font(.system(size: 11, design: .monospaced))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .cornerRadius(16)
                            .padding(16)

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer(minLength: 16)

                // MARK: - Bottom controls
                HStack(alignment: .center, spacing: 0) {
                    // Gallery button
                    Button {
                        showGalleryPicker = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .frame(width: 48, height: 48)
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.aquaNavy)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Capture button (center, large)
                    Button {
                        reportVM.locationService.requestCurrentLocation()
                        cameraService.capturePhoto()
                    } label: {
                        ZStack {
                            // Outer ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .frame(width: 78, height: 78)

                            // Inner white circle
                            Circle()
                                .fill(Color.white)
                                .frame(width: 64, height: 64)
                                .shadow(color: .aquaPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Flip camera button
                    Button {
                        cameraService.flipCamera()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .frame(width: 48, height: 48)
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 18))
                                .foregroundColor(.aquaNavy)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 6)

                // History label
                if reportVM.reportCount > 0 {
                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12))
                            Text(languageManager.localize("History"))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                } else {
                    Text(languageManager.localize("Tap to capture flood report"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            cameraService.startSession()
            reportVM.locationService.requestCurrentLocation()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.capturedImage) { _, newImage in
            if let image = newImage {
                reportVM.onImageCaptured(image)
                cameraService.capturedImage = nil
            }
        }
        // Preview & confirm sheet
        .sheet(isPresented: $reportVM.showPreview) {
            InstantCapturePreview(viewModel: reportVM)
                .environmentObject(languageManager)
        }
        // Gallery picker
        .sheet(isPresented: $showGalleryPicker) {
            ImagePicker(
                selectedImage: Binding(
                    get: { nil },
                    set: { image in
                        if let image = image {
                            reportVM.onImageCaptured(image)
                        }
                    }
                ),
                sourceType: .photoLibrary
            )
        }
        // History sheet
        .sheet(isPresented: $showHistory) {
            FloodReportHistorySheet(reportVM: reportVM)
                .environmentObject(languageManager)
        }
    }
}

// MARK: - History Sheet

struct FloodReportHistorySheet: View {
    @ObservedObject var reportVM: FloodReportViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if reportVM.reports.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(languageManager.localize("No reports yet"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(reportVM.reports) { report in
                            FloodReportFullCard(report: report)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            reportVM.deleteReport(report)
                                        }
                                    } label: {
                                        Label(languageManager.localize("Delete"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Flood Reports"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localize("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.aquaPrimary)
                }
            }
        }
    }
}

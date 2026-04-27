//
//  SOSTabView.swift
//  AquaGuard
//
//  SOS tab content — Locket-style instant flood reporting.
//  Vertical paging: Camera (first page) → Community reports.
//  Uses ScrollView + scrollTargetBehavior for native vertical paging.
//
//  Created by Shyn Nguyễn on 16/12/25.
//

import Combine
import CoreLocation
import SwiftUI

struct SOSTabView: View {
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

    // Community reports
    let communityReports = CommunityReport.dummyReports

    init(locationService: LocationService = LocationService()) {
        _reportVM = StateObject(wrappedValue: FloodReportViewModel(locationService: locationService))
    }

    private var bgColor: Color {
        colorScheme == .dark
            ? Color(red: 0.063, green: 0.106, blue: 0.149)
            : Color(red: 0.96, green: 0.97, blue: 0.98)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // PAGE 0: Camera
                cameraPage
                    .containerRelativeFrame(.vertical)

                // PAGE 1+: Community reports
                ForEach(communityReports) { report in
                    communityPage(report: report)
                        .containerRelativeFrame(.vertical)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .background(bgColor.ignoresSafeArea())
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
        .sheet(isPresented: $reportVM.showPreview) {
            InstantCapturePreview(viewModel: reportVM)
                .environmentObject(languageManager)
        }
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
        .sheet(isPresented: $showHistory) {
            FloodReportHistorySheet(reportVM: reportVM)
                .environmentObject(languageManager)
        }
    }

    // MARK: - Camera Page

    private var cameraPage: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                // GPS
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )

                Spacer()

                // My reports
                if reportVM.reportCount > 0 {
                    Button { showHistory = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 11))
                            Text("\(reportVM.reportCount)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.aquaPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Camera preview
            ZStack {
                if cameraService.isAuthorized {
                    CameraPreviewView(session: cameraService.session)
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.aquaPrimary.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.16, blue: 0.22) : Color(red: 0.92, green: 0.93, blue: 0.95))
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text(languageManager.localize("Camera access required"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        )
                }

                // Flash (top left)
                VStack {
                    HStack {
                        Button { cameraService.toggleFlash() } label: {
                            Image(systemName: cameraService.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(14)
                        Spacer()
                    }
                    Spacer()
                }

                // Timestamp (bottom left)
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text({
                                let f = DateFormatter()
                                f.dateFormat = "HH:mm · dd/MM/yyyy"
                                return f.string(from: Date())
                            }())
                            .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(14)
                        .padding(14)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer(minLength: 12)

            // Bottom controls
            HStack(alignment: .center, spacing: 0) {
                Button { showGalleryPicker = true } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            .frame(width: 46, height: 46)
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    reportVM.locationService.requestCurrentLocation()
                    cameraService.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 74, height: 74)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .shadow(color: .aquaPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .frame(maxWidth: .infinity)

                Button { cameraService.flipCamera() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            .frame(width: 46, height: 46)
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 16))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 4)

            // Swipe hint
            VStack(spacing: 3) {
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.aquaPrimary.opacity(0.5))
                Text(languageManager.localize("Community Reports"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Community Report Page

    private func communityPage(report: CommunityReport) -> some View {
        VStack(spacing: 0) {
            // Top: user info
            HStack(spacing: 10) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.aquaPrimary, Color.aquaPrimary.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(report.userName.prefix(1)))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    Text(report.relativeTimeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Severity badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(report.severityColor)
                        .frame(width: 7, height: 7)
                    Text(report.severity.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Photo card
            ZStack {
                // Gradient placeholder
                communityGradient(for: report)
                    .overlay(
                        Image(systemName: communityFloodIcon(for: report))
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.15))
                    )
                    .cornerRadius(28)

                // Bottom gradient
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.65)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                    .cornerRadius(28)
                }

                // Location badge + caption at bottom
                VStack(alignment: .leading) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        // Location
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.aquaPrimary)
                            Text(report.locationName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(16)

                        // Caption
                        Text(report.caption)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(3)
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 12)

            // Bottom: reactions
            HStack(spacing: 16) {
                // Verified badge (admin-approved)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                    Text(languageManager.localize("Verified"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.aquaPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color.aquaPrimary.opacity(0.15) : Color.aquaPrimary.opacity(0.1))
                )

                // Report count
                HStack(spacing: 5) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                    Text("\(report.reactions)")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)

                Spacer()

                // Share
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Helpers

    private func communityGradient(for report: CommunityReport) -> LinearGradient {
        switch report.imageName {
        case "flood_street":
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.3, green: 0.5, blue: 0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case "flood_rain":
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.2, green: 0.35, blue: 0.55)],
                startPoint: .top, endPoint: .bottom
            )
        case "flood_market":
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.32, blue: 0.22), Color(red: 0.35, green: 0.5, blue: 0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case "flood_school":
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.25, blue: 0.15), Color(red: 0.55, green: 0.42, blue: 0.28)],
                startPoint: .top, endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.35, blue: 0.35), Color(red: 0.25, green: 0.55, blue: 0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private func communityFloodIcon(for report: CommunityReport) -> String {
        switch report.severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "severe": return "cloud.heavyrain.fill"
        case "moderate": return "cloud.rain.fill"
        default: return "checkmark.circle.fill"
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

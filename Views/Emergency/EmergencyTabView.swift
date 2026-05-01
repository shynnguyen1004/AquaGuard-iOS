//
//  EmergencyTabView.swift
//  AquaGuard
//
//  Unified Emergency tab — combines Quick SOS camera capture
//  with Detailed Rescue Request form, plus request history
//  and live tracking.
//

import Combine
import CoreLocation
import SwiftUI

struct EmergencyTabView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme

    // Camera
    @StateObject private var cameraService = CameraService()

    // Unified ViewModel
    @StateObject private var viewModel: EmergencyViewModel

    // Gallery picker
    @State private var showGalleryPicker = false

    // Segmented mode: camera vs history
    @State private var selectedMode: EmergencyMode = .camera

    enum EmergencyMode: String, CaseIterable {
        case camera = "Quick SOS"
        case history = "History"
    }

    init(locationService: LocationService) {
        _viewModel = StateObject(
            wrappedValue: EmergencyViewModel(locationService: locationService))
    }

    private var bgColor: Color {
        colorScheme == .dark
            ? Color(red: 0.063, green: 0.106, blue: 0.149)
            : Color(red: 0.96, green: 0.97, blue: 0.98)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Mode picker
                Picker("", selection: $selectedMode) {
                    ForEach(EmergencyMode.allCases, id: \.self) { mode in
                        Text(languageManager.localize(mode.rawValue))
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if selectedMode == .camera {
                    cameraSection
                } else {
                    historySection
                }
            }
            .background(bgColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                if selectedMode == .camera {
                    cameraService.startSession()
                }
                viewModel.locationService.requestCurrentLocation()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .onChange(of: selectedMode) { _, newMode in
                if newMode == .camera {
                    cameraService.startSession()
                } else {
                    cameraService.stopSession()
                }
            }
            .onChange(of: cameraService.capturedImage) { _, newImage in
                if let image = newImage {
                    viewModel.onImageCaptured(image)
                    cameraService.capturedImage = nil
                }
            }
            // Quick SOS preview
            .sheet(isPresented: $viewModel.showPreview) {
                QuickSOSPreview(viewModel: viewModel)
                    .environmentObject(languageManager)
            }
            // Gallery picker
            .sheet(isPresented: $showGalleryPicker) {
                ImagePicker(
                    selectedImage: Binding(
                        get: { nil },
                        set: { image in
                            if let image = image {
                                viewModel.onImageCaptured(image)
                            }
                        }
                    ),
                    sourceType: .photoLibrary
                )
            }
            // Detailed form sheet removed — Quick SOS captures the same data
            // Tracking
            .sheet(isPresented: $viewModel.showTrackingSheet) {
                if let request = viewModel.activeRequest {
                    LiveTrackingSheet(request: request)
                        .environmentObject(languageManager)
                }
            }
            // Success
            .alert(languageManager.localize("Success"), isPresented: $viewModel.showSuccessAlert) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(languageManager.localize("Your emergency request has been sent successfully."))
            }
            // Error
            .alert(languageManager.localize("Error"), isPresented: $viewModel.showErrorAlert) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // GPS badge
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.aquaPrimary)
                if let coord = viewModel.locationService.currentLocation {
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
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            )

            Spacer()

            // Request count badge
            if viewModel.requestCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 11))
                    Text("\(viewModel.requestCount)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.aquaPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
            }
        }
    }

    // MARK: - Camera Section

    private var cameraSection: some View {
        VStack(spacing: 0) {
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
                        .fill(
                            colorScheme == .dark
                                ? Color(red: 0.12, green: 0.16, blue: 0.22)
                                : Color(red: 0.92, green: 0.93, blue: 0.95)
                        )
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

                // Flash toggle (top-left)
                VStack {
                    HStack {
                        Button { cameraService.toggleFlash() } label: {
                            Image(
                                systemName: cameraService.isFlashOn
                                    ? "bolt.fill" : "bolt.slash.fill"
                            )
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

                // Timestamp (bottom-left)
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
            .padding(.top, 8)

            Spacer(minLength: 12)

            // Camera controls
            HStack(alignment: .center, spacing: 0) {
                // Gallery
                Button { showGalleryPicker = true } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            .frame(width: 46, height: 46)
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Capture
                Button {
                    viewModel.locationService.requestCurrentLocation()
                    cameraService.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.aquaDanger, Color(red: 0.96, green: 0.40, blue: 0.40),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 74, height: 74)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .shadow(color: .aquaDanger.opacity(0.3), radius: 8, x: 0, y: 4)
                        Text("SOS")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.aquaDanger)
                    }
                }
                .frame(maxWidth: .infinity)

                // Flip camera
                Button { cameraService.flipCamera() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            .frame(width: 46, height: 46)
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 16))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 16)
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.requests.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text(languageManager.localize("No emergency requests yet"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(
                            languageManager.localize(
                                "Use Quick SOS or send a detailed request to get help")
                        )
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    // Active requests first
                    let activeRequests = viewModel.requests.filter {
                        $0.status == .pending || $0.status == .inProgress
                    }
                    let resolvedRequests = viewModel.requests.filter { $0.status == .resolved }

                    if !activeRequests.isEmpty {
                        // Active section header
                        HStack {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundColor(.aquaDanger)
                            Text(languageManager.localize("Active"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                            Text(
                                "\(activeRequests.count) "
                                    + languageManager.localize("requests")
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)

                        LazyVStack(spacing: 12) {
                            ForEach(activeRequests) { request in
                                RequestHistoryCard(request: request)
                                    .onTapGesture {
                                        viewModel.openTracking(for: request)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if !resolvedRequests.isEmpty {
                        // Resolved section header
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.aquaSafe)
                            Text(languageManager.localize("Resolved"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                            Text(
                                "\(resolvedRequests.count) "
                                    + languageManager.localize("requests")
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, activeRequests.isEmpty ? 0 : 12)

                        LazyVStack(spacing: 12) {
                            ForEach(resolvedRequests) { request in
                                RequestHistoryCard(request: request)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
    }
}

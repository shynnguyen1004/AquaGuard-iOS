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
    @FocusState private var captionFocused: Bool

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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaBackground.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            LogoHeaderView()

                            topBar

                            Picker("", selection: $selectedMode) {
                                ForEach(EmergencyMode.allCases, id: \.self) { mode in
                                    Text(languageManager.localize(mode.rawValue))
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            if selectedMode == .camera {
                                cameraPreview
                                cameraControls
                                    .id("cameraControls")
                            } else {
                                historyContent
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                    .onChange(of: captionFocused) { _, isFocused in
                        guard isFocused else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("cameraControls", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if selectedMode == .camera, !viewModel.hasCapturedImage {
                    cameraService.startSession()
                }
                viewModel.locationService.requestCurrentLocation()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .onChange(of: selectedMode) { _, newMode in
                if newMode == .camera {
                    if !viewModel.hasCapturedImage {
                        cameraService.startSession()
                    }
                } else {
                    cameraService.stopSession()
                    // Refresh history from backend when switching to History tab
                    viewModel.fetchMyRequests()
                }
            }
            .onChange(of: cameraService.capturedImage) { _, newImage in
                if let image = newImage {
                    viewModel.onImageCaptured(image)
                    cameraService.capturedImage = nil
                    cameraService.stopSession()
                }
            }
            .onChange(of: viewModel.capturedImage) { _, image in
                if image == nil, selectedMode == .camera {
                    cameraService.startSession()
                }
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(languageManager.localize("Done")) {
                        captionFocused = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.aquaPrimary)
                }
            }
        }
    }

    private var hasCapture: Bool {
        viewModel.hasCapturedImage
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .top) {
            // Location info (address + GPS)
            VStack(alignment: .leading, spacing: 3) {
                // Resolved address
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.aquaPrimary)
                    if !viewModel.resolvedAddress.isEmpty {
                        Text(viewModel.resolvedAddress)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.aquaNavy)
                            .lineLimit(1)
                    } else {
                        Text(languageManager.localize("Resolving address..."))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                // GPS coordinates
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.aquaPrimary.opacity(0.6))
                    if !viewModel.gpsString.isEmpty {
                        Text(viewModel.gpsString)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        Text(languageManager.localize("Getting GPS..."))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
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

    // MARK: - Camera Preview (1:1)

    private var cameraPreview: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                GeometryReader { geo in
                    ZStack {
                        cameraPreviewContent(size: geo.size)

                        if hasCapture {
                            liveTimestampOverlay
                            captureCaptionOverlay
                        } else {
                            flashToggleOverlay
                            liveTimestampOverlay
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.aquaPrimary.opacity(0.15), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func cameraPreviewContent(size: CGSize) -> some View {
        if let image = viewModel.capturedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else if cameraService.isAuthorized {
            CameraPreviewView(
                session: cameraService.session,
                mirrored: cameraService.isFrontCamera
            )
            .frame(width: size.width, height: size.height)
        } else {
            Rectangle()
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
                .frame(width: size.width, height: size.height)
        }
    }

    // MARK: - Camera Frame Overlays (live)

    private var flashToggleOverlay: some View {
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
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var liveTimestampOverlay: some View {
        VStack {
            HStack {
                Spacer()
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
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    // MARK: - Camera Frame Overlays (captured)

    private var captureCaptionOverlay: some View {
        let placeholder = languageManager.localize("What's your emergency?")
        let sizerText = viewModel.caption.isEmpty ? placeholder : viewModel.caption

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack {
                // Invisible sizer — drives the capsule width based on text length
                Text(sizerText)
                    .font(.system(size: 15, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(1...3)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .opacity(0)
                    .accessibilityHidden(true)

                if viewModel.caption.isEmpty && !captionFocused {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(1...3)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }

                TextField("", text: $viewModel.caption, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($captionFocused)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .tint(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .frame(maxWidth: 240)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Camera Controls

    private var cameraControls: some View {
        HStack(alignment: .center, spacing: 0) {
            Group {
                if hasCapture {
                    retakeButton
                } else {
                    galleryButton
                }
            }
            .frame(maxWidth: .infinity)

            Group {
                if hasCapture {
                    sendButton
                } else {
                    captureButton
                }
            }
            .frame(maxWidth: .infinity)

            Group {
                flipCameraButton
                    .opacity(hasCapture ? 0 : 1)
                    .disabled(hasCapture)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
    }

    private var galleryButton: some View {
        Button { showGalleryPicker = true } label: {
            sideControlIcon("photo.on.rectangle", size: 18)
        }
    }

    private var retakeButton: some View {
        Button {
            viewModel.cancelPreview()
        } label: {
            sideControlIcon("arrow.counterclockwise", size: 18)
        }
    }

    private var flipCameraButton: some View {
        Button { cameraService.flipCamera() } label: {
            sideControlIcon("arrow.triangle.2.circlepath.camera", size: 16)
        }
    }

    private func sideControlIcon(_ systemName: String, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                .frame(width: 46, height: 46)
            Image(systemName: systemName)
                .font(.system(size: size))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
    }

    private var captureButton: some View {
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
    }

    private var sendButton: some View {
        Button {
            viewModel.submitQuickSOS()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.aquaDanger,
                                Color(red: 0.96, green: 0.40, blue: 0.40),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: .aquaDanger.opacity(0.35), radius: 8, x: 0, y: 4)

                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(viewModel.isSubmitting)
    }

    // MARK: - History Content

    private var historyContent: some View {
        VStack(spacing: 16) {
                if viewModel.isLoadingHistory {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(languageManager.localize("Loading requests..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else if viewModel.requests.isEmpty {
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

                        LazyVStack(spacing: 12) {
                            ForEach(activeRequests) { request in
                                RequestHistoryCard(request: request)
                                    .onTapGesture {
                                        viewModel.openTracking(for: request)
                                    }
                            }
                        }
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
                        .padding(.top, activeRequests.isEmpty ? 0 : 12)

                        LazyVStack(spacing: 12) {
                            ForEach(resolvedRequests) { request in
                                RequestHistoryCard(request: request)
                            }
                        }
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }
}

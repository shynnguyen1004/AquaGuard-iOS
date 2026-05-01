//
//  QuickSOSPreview.swift
//  AquaGuard
//
//  Preview sheet after Quick SOS camera capture.
//  Shows the captured image with GPS + timestamp overlay,
//  optional caption input, and sends directly to Firebase.
//

import CoreLocation
import SwiftUI

struct QuickSOSPreview: View {
    @ObservedObject var viewModel: EmergencyViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @FocusState private var captionFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaModalBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Captured image preview
                        if let image = viewModel.capturedImage {
                            ZStack(alignment: .bottom) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 360)
                                    .clipped()
                                    .cornerRadius(20)

                                // Gradient overlay
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                                .frame(height: 120)
                                .cornerRadius(20)

                                // Address + GPS + Time overlay
                                VStack(alignment: .leading, spacing: 6) {
                                    Spacer()

                                    HStack {
                                        // Address + GPS stacked
                                        VStack(alignment: .leading, spacing: 3) {
                                            if !viewModel.resolvedAddress.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 10))
                                                    Text(viewModel.resolvedAddress)
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .lineLimit(1)
                                                }
                                            }
                                            HStack(spacing: 4) {
                                                Image(systemName: "location.fill")
                                                    .font(.system(size: 9))
                                                if !viewModel.gpsString.isEmpty {
                                                    Text(viewModel.gpsString)
                                                        .font(.system(size: 10, design: .monospaced))
                                                } else {
                                                    Text(languageManager.localize("Locating..."))
                                                        .font(.system(size: 10))
                                                }
                                            }
                                            .opacity(0.8)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial.opacity(0.55))
                                        .cornerRadius(12)

                                        Spacer()

                                        // Timestamp
                                        HStack(spacing: 5) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 10))
                                            Text({
                                                let f = DateFormatter()
                                                f.dateFormat = "HH:mm · dd/MM"
                                                return f.string(from: Date())
                                            }())
                                            .font(.system(size: 11))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial.opacity(0.55))
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Caption input
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text(languageManager.localize("Caption"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.aquaNavy)
                            } icon: {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundColor(.aquaPrimary)
                            }

                            TextField(
                                languageManager.localize("Describe the emergency situation..."),
                                text: $viewModel.caption,
                                axis: .vertical
                            )
                            .lineLimit(3...5)
                            .focused($captionFocused)
                            .padding(14)
                            .background(Color.aquaInputBg)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.aquaInputBorder)
                            )
                        }
                        .padding(.horizontal)

                        // Action buttons
                        VStack(spacing: 12) {
                            // Send SOS
                            Button {
                                viewModel.submitQuickSOS()
                            } label: {
                                HStack(spacing: 10) {
                                    if viewModel.isSubmitting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.title3)
                                        Text(languageManager.localize("Send SOS"))
                                            .fontWeight(.bold)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.aquaDanger,
                                            Color(red: 0.96, green: 0.40, blue: 0.40),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .aquaDanger.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .disabled(viewModel.isSubmitting)

                            // Retake
                            Button {
                                viewModel.cancelPreview()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.rotate.fill")
                                    Text(languageManager.localize("Retake"))
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle(languageManager.localize("Quick SOS"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.localize("Cancel")) {
                        viewModel.cancelPreview()
                    }
                    .foregroundColor(.aquaPrimary)
                }
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
}

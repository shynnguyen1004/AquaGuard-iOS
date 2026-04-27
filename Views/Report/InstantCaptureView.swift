//
//  InstantCaptureView.swift
//  AquaGuard
//
//  Full-screen capture preview after taking a photo.
//  Shows captured image with GPS + timestamp overlay,
//  optional caption input, and confirm/retake actions.
//

import CoreLocation
import SwiftUI

struct InstantCapturePreview: View {
    @ObservedObject var viewModel: FloodReportViewModel
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

                                // GPS + Time badges
                                HStack {
                                    // GPS
                                    HStack(spacing: 5) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 11))
                                        if let coord = viewModel.locationService.currentLocation {
                                            Text(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                                                .font(.system(size: 12, design: .monospaced))
                                        } else {
                                            Text(languageManager.localize("Locating..."))
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial.opacity(0.7))
                                    .cornerRadius(20)

                                    Spacer()

                                    // Timestamp
                                    HStack(spacing: 5) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 11))
                                        Text({
                                            let f = DateFormatter()
                                            f.dateFormat = "HH:mm · dd/MM/yyyy"
                                            return f.string(from: Date())
                                        }())
                                        .font(.system(size: 12))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial.opacity(0.7))
                                    .cornerRadius(20)
                                }
                                .padding(16)
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
                                languageManager.localize("Describe the flood situation..."),
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
                            // Confirm
                            Button {
                                viewModel.confirmReport()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text(languageManager.localize("Post Report"))
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }

                            // Retake
                            Button {
                                viewModel.cancelPreview()
                                viewModel.showCamera = true
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
            .navigationTitle(languageManager.localize("New Flood Report"))
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

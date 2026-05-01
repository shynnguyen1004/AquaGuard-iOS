//
//  DetailedRequestSheet.swift
//  AquaGuard
//
//  Form sheet for sending a detailed rescue request.
//  Includes location, description, and photo upload fields.
//  Migrated from RescueRequestFormSheet.
//

import SwiftUI

struct DetailedRequestSheet: View {
    @ObservedObject var viewModel: EmergencyViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme

    @FocusState private var isInputActive: Bool

    // ImagePicker state
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showActionSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header icon
                    Image(systemName: "lifepreserver.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.aquaPrimary)
                        .padding(.top, 8)

                    Text(languageManager.localize("Detailed Rescue Request"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)

                    VStack(alignment: .leading, spacing: 20) {
                        // Location Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text(languageManager.localize("Current Location"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.aquaNavy)
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.aquaDanger)
                            }

                            HStack {
                                TextField(
                                    languageManager.localize("Enter location or pin on map"),
                                    text: $viewModel.locationName
                                )
                                .focused($isInputActive)

                                Button(action: {
                                    viewModel.requestCurrentLocation()
                                }) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.aquaPrimary)
                                        .padding(10)
                                        .background(Color.aquaPrimary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.aquaInputBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.aquaInputBorder)
                            )
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text(languageManager.localize("Situation Description"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.aquaNavy)
                            } icon: {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.aquaPrimary)
                            }

                            TextEditor(text: $viewModel.reportDescription)
                                .focused($isInputActive)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.aquaInputBg)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.aquaInputBorder)
                                )
                                .overlay(alignment: .topLeading) {
                                    if viewModel.reportDescription.isEmpty {
                                        Text(
                                            languageManager.localize(
                                                "Describe the current situation: water level, number of people needing rescue, health conditions..."
                                            )
                                        )
                                        .font(.body)
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                    }
                                }
                        }

                        // Photo Upload
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text(languageManager.localize("Add Photo (Optional)"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.aquaNavy)
                            } icon: {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.orange)
                            }

                            Button(action: { showActionSheet = true }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .foregroundColor(Color.aquaInputBorder)
                                        .background(Color.aquaInputBg.opacity(0.5))
                                        .frame(height: 150)

                                    if let image = viewModel.selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .cornerRadius(12)
                                            .clipped()
                                    } else {
                                        VStack {
                                            Image(systemName: "camera.fill")
                                                .font(.title)
                                                .foregroundColor(.secondary)
                                            Text(languageManager.localize("Tap to upload"))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Submit Button
                    Button(action: {
                        viewModel.submitDetailedRequest()
                        isPresented = false
                    }) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text(languageManager.localize("Send Request"))
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.aquaModalBg)
            .navigationTitle(languageManager.localize("Rescue Request"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.localize("Cancel")) {
                        isPresented = false
                    }
                    .foregroundColor(.aquaPrimary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(languageManager.localize("Done")) {
                        isInputActive = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.aquaPrimary)
                }
            }
            .confirmationDialog(
                languageManager.localize("Select Photo"), isPresented: $showActionSheet
            ) {
                Button(languageManager.localize("Camera")) {
                    sourceType = .camera
                    showImagePicker = true
                }
                Button(languageManager.localize("Photo Library")) {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button(languageManager.localize("Cancel"), role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: sourceType)
            }
        }
    }
}

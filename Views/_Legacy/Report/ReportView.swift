//
//  ReportView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct ReportView: View {
    @StateObject var viewModel: ReportViewModel
    @EnvironmentObject var languageManager: LanguageManager

    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(locationService: locationService))
    }

    // Keyboard focus management
    @FocusState private var isInputActive: Bool

    // ImagePicker state
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showActionSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    LogoHeaderView(topPadding: -3)
                    // Header Illustration
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.aquaPrimary)
                    //.padding(.top, 20)

                    VStack(alignment: .leading, spacing: 20) {
                        // Location Field
                        VStack(alignment: .leading) {
                            Text(languageManager.localize("Location"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)

                            // Location Input Row
                            HStack {
                                TextField(
                                    languageManager.localize("Enter location or pin on map"),
                                    text: $viewModel.locationName
                                )
                                //.textFieldStyle(RoundedBorderTextFieldStyle())
                                //.disabled(true)
                                .focused($isInputActive)
                                // Get current location button
                                Button(action: {
                                    // Request location from ViewModel
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
                            .background(Color.aquaCard)
                            .cornerRadius(12)
                            // Subtle border
                            .overlay(
                                RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        }

                        // Water Level Slider
                        VStack(alignment: .leading) {
                            HStack {
                                Text(languageManager.localize("Water Level"))
                                    .font(.headline)
                                    .foregroundColor(.aquaNavy)
                                Spacer()
                                Text("\(Int(viewModel.waterLevelPercentage))%")
                                    .fontWeight(.bold)
                                    .foregroundColor(.aquaPrimary)
                            }

                            Slider(value: $viewModel.waterLevelPercentage, in: 0...100)
                                .tint(.aquaPrimary)

                            HStack {
                                Text(languageManager.localize("Low")).font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(languageManager.localize("High")).font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        // Description
                        VStack(alignment: .leading) {
                            Text(languageManager.localize("Description"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)

                            TextEditor(text: $viewModel.reportDescription)
                                .focused($isInputActive)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.aquaCard)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12).stroke(
                                        Color.gray.opacity(0.3)))
                        }

                        // Photo Upload
                        VStack(alignment: .leading) {
                            Text(languageManager.localize("Add Photo (Optional)")).font(.headline)
                                .foregroundColor(.aquaNavy)

                            Button(action: { showActionSheet = true }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .background(Color.aquaCard.opacity(0.3))
                                        .frame(height: 150)

                                    if let image = viewModel.selectedImage {
                                        // Show selected image
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .cornerRadius(12)
                                            .clipped()
                                    } else {
                                        // Show placeholder icon
                                        VStack {
                                            Image(systemName: "camera.fill").font(.title)
                                                .foregroundColor(.gray)
                                            Text(languageManager.localize("Tap to upload")).font(
                                                .caption
                                            ).foregroundColor(
                                                .gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()

                    // Submit Button
                    Button(action: viewModel.submitReport) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(languageManager.localize("Submit Report")).bold()
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.aquaPrimary).foregroundColor(.white).cornerRadius(16)
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
            // Success alert
            .alert(languageManager.localize("Success"), isPresented: $viewModel.showSuccessAlert) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(languageManager.localize("Your report has been submitted successfully."))
            }
            // Error alert
            .alert(languageManager.localize("Error"), isPresented: $viewModel.showErrorAlert) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            // Camera/Library action sheet
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
            // Present ImagePicker
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: sourceType)
            }

            // Keyboard dismiss toolbar
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(languageManager.localize("Done")) {
                        isInputActive = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

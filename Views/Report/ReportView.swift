//
//  ReportView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct ReportView: View {
    @StateObject var viewModel: ReportViewModel

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
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.aquaNavy)

                            // Location Input Row
                            HStack {
                                TextField(
                                    "Enter location or pin on map", text: $viewModel.locationName
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
                                Text("Water Level")
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
                                Text("Low").font(.caption).foregroundColor(.gray)
                                Spacer()
                                Text("High").font(.caption).foregroundColor(.gray)
                            }
                        }

                        // Description
                        VStack(alignment: .leading) {
                            Text("Description")
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
                            Text("Add Photo (Optional)").font(.headline).foregroundColor(.aquaNavy)

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
                                            Text("Tap to upload").font(.caption).foregroundColor(
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
                                Text("Submit Report").bold()
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
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your report has been submitted successfully.")
            }
            // Error alert
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            // Camera/Library action sheet
            .confirmationDialog("Select Photo", isPresented: $showActionSheet) {
                Button("Camera") {
                    sourceType = .camera
                    showImagePicker = true
                }
                Button("Photo Library") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            // Present ImagePicker
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: sourceType)
            }

            // Keyboard dismiss toolbar
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputActive = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

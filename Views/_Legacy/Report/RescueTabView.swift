//
//  RescueTabView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

// Rescue tab content (send rescue request + request history).
struct RescueTabView: View {
    @StateObject var viewModel: RescueRequestViewModel
    @EnvironmentObject var languageManager: LanguageManager

    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: RescueRequestViewModel(locationService: locationService))
    }

    // Sheet state
    @State private var showRescueRequestForm = false

    // Dummy history data
    @State private var rescueRequestHistory: [SOSRequest] = MockData.sosRequests

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    LogoHeaderView(topPadding: -3)

                    // MARK: - Rescue Header
                    VStack(spacing: 12) {
                        Image(systemName: "lifepreserver.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                LinearGradient(
                                    colors: [Color.aquaPrimary, Color.aquaPrimary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .aquaPrimary.opacity(0.4), radius: 12, x: 0, y: 6)

                        Text(languageManager.localize("Rescue Request"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)

                        Text(languageManager.localize("Send a rescue request for flood assistance"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 4)

                    // MARK: - Send Rescue Request Button
                    Button(action: { showRescueRequestForm = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text(languageManager.localize("Send Rescue Request"))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .aquaPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 20)

                    // MARK: - History Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.aquaPrimary)
                            Text(languageManager.localize("Request History"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                            Text("\(rescueRequestHistory.count) " + languageManager.localize("requests"))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)

                        if rescueRequestHistory.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.4))
                                Text(languageManager.localize("No rescue requests yet"))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            // Request cards
                            LazyVStack(spacing: 12) {
                                ForEach(rescueRequestHistory) { request in
                                    RescueRequestHistoryCard(request: request)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
            // Rescue Form Sheet
            .sheet(isPresented: $showRescueRequestForm) {
                RescueRequestFormSheet(viewModel: viewModel, isPresented: $showRescueRequestForm)
                    .environmentObject(languageManager)
            }
            // Success alert
            .alert(languageManager.localize("Success"), isPresented: $viewModel.showSuccessAlert) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(languageManager.localize("Your rescue request has been sent successfully."))
            }
            // Error alert
            .alert(languageManager.localize("Error"), isPresented: $viewModel.showErrorAlert) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Rescue Request History Card
struct RescueRequestHistoryCard: View {
    let request: SOSRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Address + Status badge
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.aquaPrimary)
                        .font(.title3)
                    Text(request.address)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaNavy)
                        .lineLimit(1)
                }
                Spacer()
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: request.status.icon)
                        .font(.caption2)
                    Text(request.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(request.status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(request.status.color.opacity(0.12))
                .cornerRadius(20)
            }

            // Description
            Text(request.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)

            // Bottom: Timestamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
                Text(request.timeAgoString)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(16)
        .background(Color.aquaCard)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Rescue Request Form Sheet
struct RescueRequestFormSheet: View {
    @ObservedObject var viewModel: RescueRequestViewModel
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
                    // Rescue Icon
                    Image(systemName: "lifepreserver.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.aquaPrimary)
                        .padding(.top, 8)

                    Text(languageManager.localize("New Rescue Request"))
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
                                        Text(languageManager.localize("Describe the current situation: water level, number of people needing rescue, health conditions..."))
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
                        viewModel.submitReport()
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
                                colors: [Color.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68)],
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


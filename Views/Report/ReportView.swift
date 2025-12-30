//
//  ReportView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct ReportView: View {
    @StateObject var viewModel = ReportViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image("AquaLogoHeader")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding(.top, -3)
                        .frame(maxWidth: .infinity, alignment: .center)
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
                                        TextField("Enter location or pin on map", text: $viewModel.locationName)
                                            //.textFieldStyle(RoundedBorderTextFieldStyle())
                                        
                                        // Nút Lấy Vị Trí (Đã sửa logic)
                                        Button(action: {
                                            // Gọi hàm lấy toạ độ thật từ ViewModel
                                            viewModel.requestCurrentLocation()
                                        }) {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.aquaPrimary)
                                                .padding(10) // Tăng vùng bấm lên một chút cho dễ bấm
                                                .background(Color.aquaPrimary.opacity(0.1)) // Thêm nền mờ cho đẹp
                                                .cornerRadius(8)
                                        }
                                    }
                            .padding()
                            .background(Color.aquaCard) // FIX: Dùng màu nền thông minh
                            .cornerRadius(12)
                            // FIX: Viền mờ đi cho đẹp
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
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
                                .scrollContentBackground(.hidden) // FIX: Ẩn nền trắng mặc định của iOS
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.aquaCard) // FIX: Dùng màu nền thông minh
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        }
                        
                        // Photo Upload
                        VStack(alignment: .leading) {
                            Text("Add Photo (Optional)")
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            
                            Button(action: {}) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .background(Color.aquaCard.opacity(0.3)) // FIX: Thêm nền nhẹ để không bị "lủng"
                                        .frame(height: 150)
                                    
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                            .foregroundColor(.gray)
                                        Text("Tap to upload")
                                            .font(.caption)
                                            .foregroundColor(.gray)
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
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Submit Report")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.aquaPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
            .alert("Report Submitted", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Thank you for helping the community stay safe.")
            }
        }
    }
}

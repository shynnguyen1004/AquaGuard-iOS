//
//  LoginView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 28/1/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = AuthenticationViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isShowingRegister = false

    var body: some View {
        ZStack {
            Color.aquaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // ── Logo ────────────────────────────────────────
                    LogoHeaderView(height: 120, topPadding: 40)

                    // ── Welcome Text ────────────────────────────────
                    VStack(spacing: 8) {
                        Text(languageManager.localize("Welcome to AquaGuard"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)

                        Text(languageManager.localize("Sign in to access flood alerts and rescue features"))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // ── Login Card ───────────────────────────────────
                    VStack(spacing: 18) {

                        // Phone Number
                        VStack(alignment: .leading, spacing: 6) {
                            Text(languageManager.localize("Phone Number"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.aquaNavy)

                            HStack(spacing: 10) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.aquaPrimary)
                                    .frame(width: 20)

                                TextField(
                                    languageManager.localize("Enter your phone number"),
                                    text: $viewModel.phoneNumber
                                )
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text(languageManager.localize("Password"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.aquaNavy)

                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.aquaPrimary)
                                    .frame(width: 20)

                                if viewModel.isPasswordVisible {
                                    TextField(
                                        languageManager.localize("Enter your password"),
                                        text: $viewModel.password
                                    )
                                    .textContentType(.password)
                                } else {
                                    SecureField(
                                        languageManager.localize("Enter your password"),
                                        text: $viewModel.password
                                    )
                                    .textContentType(.password)
                                }

                                Button(action: { viewModel.isPasswordVisible.toggle() }) {
                                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }

                        // Sign In Button
                        Button(action: { viewModel.signInWithPhone() }) {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3)
                                    Text(languageManager.localize("Sign In"))
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.aquaPrimary)
                            .cornerRadius(15)
                            .shadow(color: Color.aquaPrimary.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(20)
                    .background(Color.aquaCard)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)

                    // ── OR Divider ───────────────────────────────────
                    HStack(spacing: 12) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.25))
                        Text(languageManager.localize("OR"))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.25))
                    }
                    .padding(.horizontal, 40)

                    // ── Register Button ──────────────────────────────
                    Button(action: { isShowingRegister = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus.fill")
                                .foregroundColor(.aquaPrimary)
                            Text(languageManager.localize("Create an account"))
                                .fontWeight(.semibold)
                                .foregroundColor(.aquaNavy)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.aquaCard)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.aquaPrimary.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)




                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $isShowingRegister) {
            RegisterView()
                .environmentObject(languageManager)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(languageManager.localize("Error")),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(languageManager.localize("OK")))
            )
        }
    }
}

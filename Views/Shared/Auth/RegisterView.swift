//
//  RegisterView.swift
//  AquaGuard
//

import SwiftUI

struct RegisterView: View {
    @StateObject var viewModel = AuthenticationViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.aquaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // ── Logo Header ─────────────────────────────────
                    LogoHeaderView(height: 100, topPadding: 30)

                    // ── Title ───────────────────────────────────────
                    VStack(spacing: 8) {
                        Text(languageManager.localize("Create Account"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)

                        Text(languageManager.localize("Join AquaGuard to stay safe during floods"))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // ── Form Card ───────────────────────────────────
                    VStack(spacing: 16) {

                        // Full Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text(languageManager.localize("Full Name"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.aquaNavy)

                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.aquaPrimary)
                                    .frame(width: 20)

                                TextField(
                                    languageManager.localize("Enter your full name"),
                                    text: $viewModel.displayName
                                )
                                .textContentType(.name)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }

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
                                        languageManager.localize("At least 6 characters"),
                                        text: $viewModel.password
                                    )
                                } else {
                                    SecureField(
                                        languageManager.localize("At least 6 characters"),
                                        text: $viewModel.password
                                    )
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

                        // Confirm Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text(languageManager.localize("Confirm Password"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.aquaNavy)

                            HStack(spacing: 10) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.aquaPrimary)
                                    .frame(width: 20)

                                if viewModel.isConfirmPasswordVisible {
                                    TextField(
                                        languageManager.localize("Re-enter password"),
                                        text: $viewModel.confirmPassword
                                    )
                                } else {
                                    SecureField(
                                        languageManager.localize("Re-enter password"),
                                        text: $viewModel.confirmPassword
                                    )
                                }

                                Button(action: { viewModel.isConfirmPasswordVisible.toggle() }) {
                                    Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        viewModel.passwordMismatch ? Color.aquaDanger.opacity(0.6) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )

                            if viewModel.passwordMismatch {
                                Text(languageManager.localize("Passwords do not match"))
                                    .font(.caption2)
                                    .foregroundColor(.aquaDanger)
                            }
                        }

                        // Create Account Button
                        Button(action: { viewModel.registerWithPhone() }) {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text(languageManager.localize("Create Account"))
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

                    // ── Back to Login ────────────────────────────────
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                            Text(languageManager.localize("Already have an account? Sign in"))
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.aquaPrimary)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertIsSuccess
                    ? languageManager.localize("Success")
                    : languageManager.localize("Error")),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(languageManager.localize("OK"))) {
                    if viewModel.alertIsSuccess { dismiss() }
                }
            )
        }
    }
}

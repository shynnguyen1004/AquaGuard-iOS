//
//  AuthenticationViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 28/1/26.
//
//  Handles login, registration, and password reset via the
//  AquaGuard backend REST API (JWT-based, no Firebase Auth).
//

import Foundation
import SwiftUI
import Combine

class AuthenticationViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertIsSuccess: Bool = false

    // MARK: - Login / Register Fields
    @Published var phoneNumber: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""

    // MARK: - Register Extra Fields
    @Published var selectedRole: String = "citizen"
    @Published var rolePassword: String = ""
    @Published var gender: String = ""
    @Published var dateOfBirth: Date? = nil

    // MARK: - Forgot Password Fields
    @Published var otpCode: String = ""
    @Published var newPassword: String = ""
    @Published var sessionToken: String = ""
    @Published var forgotPasswordStep: ForgotPasswordStep = .enterPhone

    enum ForgotPasswordStep {
        case enterPhone
        case enterOTP
        case enterNewPassword
    }

    // MARK: - UI State
    @Published var isPasswordVisible: Bool = false
    @Published var isConfirmPasswordVisible: Bool = false

    var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    // MARK: - Dependencies

    private let api = APIService.shared
    private let tokenManager = TokenManager.shared

    // MARK: - Login

    /// Sign in with phone number + password via POST /api/auth/login
    @MainActor
    func signInWithPhone() {
        let phone = normalizedPhone()
        guard !phone.isEmpty, !password.isEmpty else {
            showError("Please enter your phone number and password.")
            return
        }

        isLoading = true

        Task {
            do {
                let authData: AuthData = try await api.postNoAuth("/auth/login", body: [
                    "phone_number": phone,
                    "password": password,
                ])

                if authData.user.userRole == .admin {
                    isLoading = false
                    showError(
                        "Vui lòng đăng nhập với tài khoản Citizen hoặc Rescuer. Quản trị viên chỉ dùng trên web."
                    )
                    return
                }

                // Save session
                tokenManager.saveSession(token: authData.accessToken, user: authData.user)

                // Update AppState role
                AppState.shared.selectRole(authData.user.userRole)

                isLoading = false
                print("✅ Signed in: \(authData.user.displayName) (\(authData.user.role))")
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Register

    /// Register with phone + password via POST /api/auth/register
    /// After successful registration, auto-login and navigate to app.
    @MainActor
    func registerWithPhone() {
        guard !displayName.isEmpty else {
            showError("Please enter your full name.")
            return
        }

        let phone = normalizedPhone()
        guard !phone.isEmpty else {
            showError("Please enter your phone number.")
            return
        }
        guard password.count >= 6 else {
            showError("Password must be at least 6 characters.")
            return
        }
        guard password == confirmPassword else {
            showError("Passwords do not match.")
            return
        }

        isLoading = true

        Task {
            do {
                let body: [String: Any] = [
                    "phone_number": phone,
                    "password": password,
                    "display_name": displayName,
                    "role": "citizen",
                ]

                let authData: AuthData = try await api.postNoAuth("/auth/register", body: body)

                // Auto-login: save session and go straight to app
                tokenManager.saveSession(token: authData.accessToken, user: authData.user)
                AppState.shared.selectRole(.citizen)

                isLoading = false
                print("✅ Registered & auto-logged in: \(authData.user.displayName)")
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Forgot Password Flow

    /// Step 1: Send OTP to phone via POST /api/auth/forgot-password
    @MainActor
    func sendForgotPasswordOTP() {
        let phone = normalizedPhone()
        guard !phone.isEmpty else {
            showError("Please enter your phone number.")
            return
        }

        isLoading = true

        Task {
            do {
                let response: APIResponse<EmptyData> = try await api.postNoAuthRaw("/auth/forgot-password", body: [
                    "phone_number": phone,
                ])

                isLoading = false

                if response.success {
                    forgotPasswordStep = .enterOTP
                    alertMessage = response.message ?? "OTP sent to your phone."
                    alertIsSuccess = true
                    showAlert = true
                } else {
                    showError(response.message ?? "Failed to send OTP.")
                }
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    /// Step 2: Verify OTP via POST /api/auth/verify-otp
    @MainActor
    func verifyOTP() {
        let phone = normalizedPhone()
        guard !otpCode.isEmpty else {
            showError("Please enter the OTP code.")
            return
        }

        isLoading = true

        Task {
            do {
                let data: OTPVerifyData = try await api.postNoAuth("/auth/verify-otp", body: [
                    "phone_number": phone,
                    "otp": otpCode,
                ])

                sessionToken = data.sessionToken
                isLoading = false
                forgotPasswordStep = .enterNewPassword
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    /// Step 3: Reset password via POST /api/auth/reset-password
    @MainActor
    func resetPassword() {
        let phone = normalizedPhone()
        guard !newPassword.isEmpty, newPassword.count >= 6 else {
            showError("New password must be at least 6 characters.")
            return
        }

        isLoading = true

        Task {
            do {
                let response: APIResponse<EmptyData> = try await api.postNoAuthRaw("/auth/reset-password", body: [
                    "phone_number": phone,
                    "sessionToken": sessionToken,
                    "newPassword": newPassword,
                ])

                isLoading = false

                if response.success {
                    alertMessage = "Password reset successful. Please sign in again."
                    alertIsSuccess = true
                    showAlert = true
                    forgotPasswordStep = .enterPhone
                } else {
                    showError(response.message ?? "Failed to reset password.")
                }
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Logout

    @MainActor
    func signOut() {
        tokenManager.clearSession()
        AppState.shared.logout()
    }

    // MARK: - Helpers

    /// Normalize phone number to +84 format
    /// Accepts: "0901234567", "84901234567", "+84901234567"
    private func normalizedPhone() -> String {
        var phone = phoneNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        // Convert "0xx" → "+84xx"
        if phone.hasPrefix("0") {
            phone = "+84" + phone.dropFirst()
        }
        // Convert "84xx" → "+84xx"
        else if phone.hasPrefix("84") && !phone.hasPrefix("+") {
            phone = "+" + phone
        }
        // Ensure it starts with "+"
        else if !phone.hasPrefix("+") && !phone.isEmpty {
            phone = "+84" + phone
        }

        return phone
    }

    private func showError(_ message: String) {
        alertMessage = message
        alertIsSuccess = false
        showAlert = true
    }
}

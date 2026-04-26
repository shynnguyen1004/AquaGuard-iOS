//
//  AuthenticationViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 28/1/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import SwiftUI
import Combine

class AuthenticationViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertIsSuccess: Bool = false

    // MARK: - Form Fields
    @Published var phoneNumber: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""

    // MARK: - UI State
    @Published var isPasswordVisible: Bool = false
    @Published var isConfirmPasswordVisible: Bool = false

    var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    // MARK: - Phone/Password Login (via Firebase Email auth using phone as email)
    // Since Firebase phone auth requires SMS verification, we use email/password
    // with phone number formatted as email: phone@aquaguard.app
    @MainActor
    func signInWithPhone() {
        guard !phoneNumber.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter your phone number and password."
            showAlert = true
            return
        }

        isLoading = true
        let email = normalizedEmail(from: phoneNumber)

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                self.alertMessage = self.friendlyError(error)
                self.alertIsSuccess = false
                self.showAlert = true
            } else {
                print("Signed in: \(result?.user.uid ?? "")")
            }
        }
    }

    // MARK: - Register with Phone + Password
    @MainActor
    func registerWithPhone() {
        guard !displayName.isEmpty else {
            alertMessage = "Please enter your full name."
            showAlert = true
            return
        }
        guard !phoneNumber.isEmpty else {
            alertMessage = "Please enter your phone number."
            showAlert = true
            return
        }
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters."
            showAlert = true
            return
        }
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }

        isLoading = true
        let email = normalizedEmail(from: phoneNumber)

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.isLoading = false
                self.alertMessage = self.friendlyError(error)
                self.alertIsSuccess = false
                self.showAlert = true
                return
            }

            // Update display name
            let changeRequest = result?.user.createProfileChangeRequest()
            changeRequest?.displayName = self.displayName
            changeRequest?.commitChanges { _ in
                self.isLoading = false
                self.alertMessage = "Account created successfully! You can now sign in."
                self.alertIsSuccess = true
                self.showAlert = true
            }
        }
    }

    // MARK: - Guest Login (Dev)
    @MainActor
    func signInAsGuest() {
        isLoading = true
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                self.alertMessage = error.localizedDescription
                self.alertIsSuccess = false
                self.showAlert = true
            } else {
                print("Guest sign-in: \(result?.user.uid ?? "")")
            }
        }
    }

    // MARK: - Helpers
    private func normalizedEmail(from phone: String) -> String {
        let cleaned = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
        return "\(cleaned)@aquaguard.app"
    }

    private func friendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this phone number."
        case .emailAlreadyInUse:
            return "This phone number is already registered."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .networkError:
            return "Network error. Please check your connection."
        default:
            return error.localizedDescription
        }
    }
}

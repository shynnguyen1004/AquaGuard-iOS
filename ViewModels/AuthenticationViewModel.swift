//
//  AuthenticationViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 28/1/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import SwiftUI
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    // Google Sign-In handler
    @MainActor
    func signInWithGoogle() {
        // Get the presenting view controller for Google Sign-In
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        isLoading = true
        
        // Call Google Sign-In SDK
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.alertMessage = "Google error: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.isLoading = false
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            // Create Firebase credential from Google tokens
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            
            // Sign in to Firebase with credential
            Auth.auth().signIn(with: credential) { authResult, error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Firebase error: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                print("Google sign-in successful: \(authResult?.user.email ?? "")")
            }
        }
    }
}

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

    var body: some View {
        ZStack {
            Color.aquaBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                // Logo
                Image("AquaLogoHeader")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                VStack(spacing: 12) {
                    Text(languageManager.localize("Welcome to AquaGuard"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)

                    Text(
                        languageManager.localize(
                            "Sign in to access flood alerts and rescue features")
                    )
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }

                // Google Sign-In button
                Button(action: {
                    viewModel.signInWithGoogle()
                }) {
                    HStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            // Google icon from Assets

                            Image(systemName: "globe")
                                .font(.title3)

                            Text(languageManager.localize("Sign in with Google"))
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.black.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 40)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(languageManager.localize("Error")),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(languageManager.localize("OK"))))
        }
    }
}

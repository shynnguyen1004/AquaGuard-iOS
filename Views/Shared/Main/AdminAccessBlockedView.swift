//
//  AdminAccessBlockedView.swift
//  AquaGuard
//
//  Shown when an admin account is used on mobile.
//  Admin workflows are web-only.
//

import SwiftUI

struct AdminAccessBlockedView: View {
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        ZStack {
            Color.aquaBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "globe")
                    .font(.system(size: 56))
                    .foregroundColor(.aquaPrimary)

                Text(languageManager.localize("Admin Web Only Title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)
                    .multilineTextAlignment(.center)

                Text(languageManager.localize("Admin Web Only Message"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: { AppState.shared.logout() }) {
                    Text(languageManager.localize("Sign Out"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.aquaPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    AdminAccessBlockedView()
        .environmentObject(LanguageManager.shared)
}

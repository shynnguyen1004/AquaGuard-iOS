//
//  SettingsView.swift
//  AquaGuard
//

import FirebaseAuth
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var homeVM = HomeViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    // User info
    private var displayName: String {
        Auth.auth().currentUser?.displayName ?? "Responder Alpha"
    }
    private var email: String {
        Auth.auth().currentUser?.email ?? "guest@aquaguard.app"
    }
    private var photoURL: URL? {
        Auth.auth().currentUser?.photoURL
    }

    // Glass card style
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.aquaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Profile Card ────────────────────────────
                        HStack(spacing: 16) {
                            // Avatar
                            if let photoURL = photoURL {
                                AsyncImage(url: photoURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 64, height: 64)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(
                                                    LinearGradient(
                                                        colors: [.aquaPrimary, .aquaPrimary.opacity(0.4)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2.5
                                                )
                                            )
                                    default:
                                        defaultAvatar
                                    }
                                }
                            } else {
                                defaultAvatar
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(displayName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(glassBackground)
                        .padding(.horizontal)

                        // ── General ─────────────────────────────────
                        sectionHeader(languageManager.localize("General"))

                        VStack(spacing: 0) {
                            // Language
                            Button {
                                languageManager.toggle()
                            } label: {
                                settingsRow(
                                    icon: "globe",
                                    iconBg: Color.blue.opacity(0.15),
                                    iconColor: .blue,
                                    title: languageManager.localize("Language"),
                                    trailing: AnyView(
                                        HStack(spacing: 4) {
                                            Text(languageManager.current == .english ? "English" : "Tiếng Việt")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                                )
                            }

                            Divider().padding(.leading, 56)

                            // Theme
                            VStack(spacing: 12) {
                                settingsRow(
                                    icon: themeManager.current.icon,
                                    iconBg: Color.purple.opacity(0.15),
                                    iconColor: .purple,
                                    title: languageManager.localize("Theme"),
                                    trailing: AnyView(EmptyView())
                                )

                                // Theme picker
                                HStack(spacing: 0) {
                                    ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                themeManager.current = theme
                                            }
                                        } label: {
                                            VStack(spacing: 5) {
                                                Image(systemName: theme.icon)
                                                    .font(.system(size: 18, weight: .medium))
                                                Text(languageManager.localize(theme.displayName))
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                themeManager.current == theme
                                                    ? Color.aquaPrimary.opacity(0.2)
                                                    : Color.clear
                                            )
                                            .foregroundColor(
                                                themeManager.current == theme
                                                    ? .aquaPrimary
                                                    : .secondary
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(4)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }

                            Divider().padding(.leading, 56)

                            // Notifications
                            settingsRow(
                                icon: "bell.badge.fill",
                                iconBg: Color.red.opacity(0.12),
                                iconColor: .red,
                                title: languageManager.localize("Notifications"),
                                trailing: AnyView(
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                )
                            )

                            Divider().padding(.leading, 56)

                            // Location
                            settingsRow(
                                icon: "location.fill",
                                iconBg: Color.aquaPrimary.opacity(0.15),
                                iconColor: .aquaPrimary,
                                title: languageManager.localize("Location Services"),
                                trailing: AnyView(
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                )
                            )
                        }
                        .background(glassBackground)
                        .padding(.horizontal)

                        // ── Support ──────────────────────────────────
                        sectionHeader(languageManager.localize("Support"))

                        VStack(spacing: 0) {
                            settingsRow(
                                icon: "questionmark.circle.fill",
                                iconBg: Color.orange.opacity(0.12),
                                iconColor: .orange,
                                title: languageManager.localize("Help & FAQ"),
                                trailing: AnyView(
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                )
                            )

                            Divider().padding(.leading, 56)

                            settingsRow(
                                icon: "info.circle.fill",
                                iconBg: Color.aquaPrimary.opacity(0.15),
                                iconColor: .aquaPrimary,
                                title: languageManager.localize("About AquaGuard"),
                                trailing: AnyView(
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                )
                            )

                            Divider().padding(.leading, 56)

                            settingsRow(
                                icon: "checkmark.seal.fill",
                                iconBg: Color.green.opacity(0.12),
                                iconColor: .green,
                                title: languageManager.localize("Version"),
                                trailing: AnyView(
                                    Text("1.0.0 (Beta)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                )
                            )
                        }
                        .background(glassBackground)
                        .padding(.horizontal)

                        // ── Sign Out ────────────────────────────────
                        Button {
                            homeVM.signOut()
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.body)
                                Text(languageManager.localize("Sign Out"))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.red.opacity(0.15), lineWidth: 1)
                                    )
                                    .shadow(color: Color.red.opacity(0.06), radius: 8, x: 0, y: 4)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle(languageManager.localize("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localize("Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaPrimary)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    // MARK: - Components

    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.aquaPrimary.opacity(0.3), .aquaPrimary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Image(systemName: "person.fill")
                .font(.system(size: 28))
                .foregroundColor(.aquaPrimary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private func settingsRow(
        icon: String,
        iconBg: Color,
        iconColor: Color,
        title: String,
        trailing: AnyView
    ) -> some View {
        HStack(spacing: 14) {
            // Icon badge
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconBg)
                .cornerRadius(8)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

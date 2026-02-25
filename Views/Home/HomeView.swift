//
//  HomeView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import FirebaseAuth
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showLogoutAlert = false

    // Binding to control TabView from parent
    @Binding var selectedTab: Int

    // SOS alert state
    @State private var showSOSAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    LogoHeaderView()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(Auth.auth().currentUser?.displayName ?? "Responder Alpha")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.aquaNavy)
                        }
                        Spacer()
                        /*Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                         */
                        // Avatar with settings menu
                        Menu {
                            // Language toggle
                            Button {
                                languageManager.toggle()
                            } label: {
                                Label(
                                    languageManager.current == .english
                                        ? "🇻🇳 Tiếng Việt"
                                        : "🇺🇸 English",
                                    systemImage: "globe"
                                )
                            }

                            Divider()

                            // Sign out
                            Button(role: .destructive) {
                                viewModel.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            if let photoURL = Auth.auth().currentUser?.photoURL {
                                AsyncImage(url: photoURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(Color.aquaPrimary, lineWidth: 2)
                                            )
                                            .shadow(radius: 3)
                                    default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Risk Status Card
                    StatusCard(
                        location: viewModel.currentRiskLocation, level: viewModel.currentRiskLevel
                    )
                    .padding(.horizontal)

                    // --- QUICK ACTIONS (PHẦN CHỈNH SỬA CHÍNH) ---
                    VStack(alignment: .leading) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.aquaNavy)
                            .padding(.horizontal)

                        HStack(spacing: 15) {
                            // Shelter button -> navigate to Rescue tab
                            QuickActionButton(
                                icon: "house.fill", label: "Shelter", color: .aquaPrimary
                            ) {
                                selectedTab = 4
                            }

                            // SOS button -> show alert
                            Button(action: {
                                showSOSAlert = true
                            }) {
                                VStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "phone.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        )

                                    Text("SOS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.94, green: 0.27, blue: 0.27))
                                .cornerRadius(15)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                            }

                            // Family button -> navigate to Rescue tab
                            QuickActionButton(
                                icon: "person.2.fill", label: "Family", color: .orange
                            ) {
                                selectedTab = 4
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Active Alerts
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Active Alerts")
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                            Text("\(viewModel.activeAlerts.count) Active")
                                .font(.caption)
                                .padding(6)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)

                        ForEach(viewModel.activeAlerts) { alert in
                            AlertRow(alert: alert)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color.aquaBackground)
            .navigationTitle("AquaGuard")
            .navigationBarHidden(true)
            .alert("SOS Sent", isPresented: $showSOSAlert) {
                Button("OK") {
                    // Navigate to Safety tab on dismiss
                    selectedTab = 3
                }
            } message: {
                Text("Your information is sent! Stay at your current position and wait for help")
            }
        }
    }
}

// MARK: - QuickActionButton
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: icon).foregroundColor(color))

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.aquaNavy)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.aquaCard)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Subcomponents
struct StatusCard: View {
    let location: String
    let level: SeverityLevel

    // Status title based on severity level
    private var statusTitle: String {
        switch level {
        case .low: return "Safe"
        case .moderate: return "Caution"
        case .severe: return "Danger"
        case .critical: return "Critical"
        }
    }

    // Background color — delegates to SeverityLevel.color (single source of truth)
    private var backgroundColor: Color { level.color }

    // Icon based on severity level
    private var iconName: String {
        switch level {
        case .low: return "checkmark.shield.fill"
        case .moderate: return "cloud.sun.fill"
        case .severe: return "cloud.heavyrain.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Current Status")
                }
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)

                // Use computed statusTitle
                Text(statusTitle)
                    .font(.largeTitle)
                    .fontWeight(.heavy)

                Text("Location: \(location)")
                    .font(.subheadline)
                    .opacity(0.9)

                Text("Take action immediately")
                    .font(.caption)
                    .padding(.top, 4)
            }
            Spacer()
            // Use computed iconName
            Image(systemName: iconName)
                .font(.system(size: 60))
                .opacity(0.8)
        }
        .foregroundColor(.white)
        .padding(20)
        // Use computed backgroundColor
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: backgroundColor.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

struct AlertRow: View {
    let alert: FloodAlert

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        alert.severity == .severe
                            ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)
                    )
                    .frame(width: 50, height: 50)
                Image(systemName: alert.iconName)
                    .foregroundColor(alert.severity == .severe ? .red : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaNavy)
                Text(alert.location)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(alert.timeAgo)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.aquaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(alert.severity == .severe ? Color.red : Color.orange, lineWidth: 1)
                .opacity(0.3)
        )
    }
}

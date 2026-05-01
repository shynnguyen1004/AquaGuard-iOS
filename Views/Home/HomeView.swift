//
//  HomeView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import FirebaseAuth
import SwiftUI

struct HomeView: View {
    private enum TabIndex {
        static let emergency = 2
    }

    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showLogoutAlert = false

    // Binding to control TabView from parent
    @Binding var selectedTab: Int

    // Settings sheet
    @State private var showSettings = false

    // Family page
    @State private var showFamily = false
    @State private var expandedAlertID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    LogoHeaderView()

                    HStack {
                        VStack(alignment: .leading) {
                            Text(languageManager.localize("Welcome back,"))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(
                                Auth.auth().currentUser?.displayName
                                    ?? languageManager.localize("Responder Alpha")
                            )
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
                        // Avatar → opens Settings
                        Button(action: { showSettings = true }) {
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
                        Text(languageManager.localize("Quick Actions"))
                            .font(.headline)
                            .foregroundColor(.aquaNavy)
                            .padding(.horizontal)

                        HStack(spacing: 15) {
                            // Shelter button -> navigate to Rescue tab
                            QuickActionButton(
                                icon: "house.fill", label: languageManager.localize("Shelter"),
                                color: .aquaPrimary
                            ) {
                                selectedTab = TabIndex.emergency
                            }

                            // SOS button -> navigate directly to SOS tab
                            Button(action: {
                                selectedTab = TabIndex.emergency
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

                            // Family button -> navigate to Family page
                            QuickActionButton(
                                icon: "person.2.fill", label: languageManager.localize("Family"),
                                color: .orange
                            ) {
                                showFamily = true
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Active Alerts
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(languageManager.localize("Active Alerts"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                            Text(
                                "\(viewModel.activeAlerts.count) \(languageManager.localize("Active"))"
                            )
                            .font(.caption)
                            .padding(6)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)

                        ForEach(viewModel.activeAlerts) { alert in
                            VStack(spacing: 10) {
                                CommunityAlertRow(
                                    alert: alert,
                                    isExpanded: expandedAlertID == alert.id
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                        expandedAlertID = expandedAlertID == alert.id ? nil : alert.id
                                    }
                                }

                                if expandedAlertID == alert.id {
                                    CommunityAlertExpandedCard(alert: alert)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .move(edge: .top)),
                                            removal: .opacity
                                        ))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color.aquaBackground)
            .navigationTitle("AquaGuard")
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(languageManager)
            }
            .fullScreenCover(isPresented: $showFamily) {
                FamilyView(selectedTab: $selectedTab)
                    .environmentObject(languageManager)
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
        case .low: return "Safe".localized
        case .moderate: return "Caution".localized
        case .severe: return "Danger".localized
        case .critical: return "Critical".localized
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
                    Text("Current Risk Level".localized)
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

struct CommunityAlertRow: View {
    let alert: CommunityReport
    let isExpanded: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(alert.severityColor.opacity(0.14))
                        .frame(width: 50, height: 50)
                    Image(systemName: communityFloodIcon(for: alert))
                        .foregroundColor(alert.severityColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.locationName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaNavy)
                        .lineLimit(1)
                    Text(alert.caption)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(alert.relativeTimeString)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.aquaCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(alert.severityColor, lineWidth: 1)
                    .opacity(0.25)
            )
        }
        .buttonStyle(.plain)
    }

    private func communityFloodIcon(for report: CommunityReport) -> String {
        switch report.severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "severe": return "cloud.heavyrain.fill"
        case "moderate": return "cloud.rain.fill"
        default: return "checkmark.circle.fill"
        }
    }
}

struct CommunityAlertExpandedCard: View {
    let alert: CommunityReport

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                communityGradient(for: alert)
                    .overlay(
                        Image(systemName: communityFloodIcon(for: alert))
                            .font(.system(size: 54, weight: .thin))
                            .foregroundColor(.white.opacity(0.2))
                    )
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)

                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                        Text(alert.locationName)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.55))
                    .cornerRadius(18)

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(alert.timeString)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.55))
                    .cornerRadius(18)
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(alert.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaNavy)
                    Spacer()
                    Text(alert.severity.capitalized)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(alert.severityColor.opacity(0.16))
                        .foregroundColor(alert.severityColor)
                        .cornerRadius(10)
                }

                Text(alert.caption)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color.aquaCard)
        }
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private func communityFloodIcon(for report: CommunityReport) -> String {
        switch report.severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "severe": return "cloud.heavyrain.fill"
        case "moderate": return "cloud.rain.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private func communityGradient(for report: CommunityReport) -> LinearGradient {
        switch report.imageName {
        case "flood_street":
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.3, green: 0.5, blue: 0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case "flood_rain":
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.2, green: 0.35, blue: 0.55)],
                startPoint: .top, endPoint: .bottom
            )
        case "flood_market":
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.32, blue: 0.22), Color(red: 0.35, green: 0.5, blue: 0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case "flood_school":
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.25, blue: 0.15), Color(red: 0.55, green: 0.42, blue: 0.28)],
                startPoint: .top, endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.35, blue: 0.35), Color(red: 0.25, green: 0.55, blue: 0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

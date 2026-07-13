//
//  HomeView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//


import SwiftUI

struct HomeView: View {
    private enum TabIndex {
        static let emergency = 2
    }

    let locationService: LocationService
    @StateObject var viewModel: HomeViewModel
    @StateObject var notificationsVM = NotificationsViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showLogoutAlert = false

    // Binding to control TabView from parent
    @Binding var selectedTab: Int

    // Settings sheet
    @State private var showSettings = false

    // Family page
    @State private var showFamily = false

    // Notifications: show a capped list until the user expands it
    @State private var showAllNotifications = false
    private let notificationPreviewLimit = 10

    init(selectedTab: Binding<Int>, locationService: LocationService) {
        _selectedTab = selectedTab
        self.locationService = locationService
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(locationService: locationService)
        )
    }

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
                                TokenManager.shared.currentUser?.displayName
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
                            if let avatarUrl = TokenManager.shared.currentUser?.avatarUrl,
                               !avatarUrl.isEmpty,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { phase in
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
                        location: viewModel.currentRiskLocation,
                        level: viewModel.currentRiskLevel,
                        summary: viewModel.weatherSummary,
                        metrics: viewModel.weatherMetrics,
                        actionLine: viewModel.statusActionLine,
                        isLoading: viewModel.isLoadingWeather,
                        hasError: viewModel.weatherError != nil
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

                    // --- NOTIFICATIONS ---
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(languageManager.localize("Notifications"))
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            if notificationsVM.unreadCount > 0 {
                                Text("\(notificationsVM.unreadCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.94, green: 0.27, blue: 0.27))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            if notificationsVM.unreadCount > 0 {
                                Button(action: { notificationsVM.markAllRead() }) {
                                    Text(languageManager.localize("Mark all as read"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.aquaPrimary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        let visibleNotifications = showAllNotifications
                            ? notificationsVM.notifications
                            : Array(notificationsVM.notifications.prefix(notificationPreviewLimit))

                        ForEach(visibleNotifications) { notification in
                            NotificationRow(notification: notification)
                                .onTapGesture {
                                    notificationsVM.markRead(id: notification.id)
                                }
                        }
                        .padding(.horizontal)

                        // See more / less toggle
                        if notificationsVM.notifications.count > notificationPreviewLimit {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAllNotifications.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(
                                        showAllNotifications
                                            ? languageManager.localize("Show less")
                                            : languageManager.localize("See more")
                                    )
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    Image(systemName: showAllNotifications ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.aquaPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.aquaCard)
                                .cornerRadius(14)
                            }
                            .padding(.horizontal)
                        }

                        if notificationsVM.notifications.isEmpty && !notificationsVM.isLoading {
                            VStack(spacing: 8) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(0.4))
                                Text(languageManager.localize("No notifications yet"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(languageManager.localize("You're all caught up"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                }
                .padding(.top)
            }
            .refreshable {
                notificationsVM.fetch()
                await viewModel.refreshWeatherRisk(forceRefresh: true)
            }
            .background(Color.aquaBackground)
            .navigationTitle("AquaGuard")
            .navigationBarHidden(true)
            .onAppear {
                notificationsVM.fetch()
                viewModel.onAppear()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(locationService: locationService)
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
    var summary: String = ""
    var metrics: WeatherCardMetrics?
    var actionLine: String = ""
    var isLoading: Bool = false
    var hasError: Bool = false

    private var accentColor: Color {
        hasError ? Color.gray : level.color
    }

    private var statusTitle: String {
        if hasError {
            return "Weather unavailable".localized
        }
        switch level {
        case .low: return "Safe".localized
        case .moderate: return "Caution".localized
        case .severe: return "Danger".localized
        case .critical: return "Critical".localized
        }
    }

    private var backgroundColor: Color {
        hasError ? Color.gray.opacity(0.55) : level.color
    }

    private var iconName: String {
        if hasError { return "icloud.slash" }
        switch level {
        case .low: return "checkmark.shield.fill"
        case .moderate: return "cloud.sun.fill"
        case .severe: return "cloud.heavyrain.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private var locationText: String {
        if location.isEmpty {
            return "Location unavailable".localized
        }
        return "\("Location:".localized) \(location)"
    }

    private var showMetricPills: Bool {
        !isLoading && !hasError && metrics != nil
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Current Risk Level".localized)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.1)
                            .padding(.vertical, 8)
                        Text("Updating weather...".localized)
                            .font(.subheadline)
                            .opacity(0.9)
                    } else {
                        Text(statusTitle)
                            .font(.largeTitle)
                            .fontWeight(.heavy)

                        if !summary.isEmpty {
                            Text(summary)
                                .font(.subheadline)
                                .opacity(0.95)
                                .lineLimit(2)
                        }

                        Text(locationText)
                            .font(.caption)
                            .opacity(0.85)
                            .lineLimit(2)

                        if !actionLine.isEmpty {
                            Text(actionLine)
                                .font(.caption)
                                .padding(.top, 2)
                                .opacity(hasError ? 1 : 0.9)
                        }
                    }
                }
                Spacer(minLength: 8)
                if !isLoading {
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(20)
            .shadow(color: backgroundColor.opacity(0.4), radius: 10, x: 0, y: 5)

            if showMetricPills, let metrics {
                HStack(spacing: 8) {
                    WeatherMetricPill(
                        label: "Rain".localized,
                        value: metrics.precipitationDisplay(),
                        accent: accentColor
                    )
                    WeatherMetricPill(
                        label: "Wind".localized,
                        value: metrics.windDisplay(),
                        accent: accentColor
                    )
                    WeatherMetricPill(
                        label: "Humidity".localized,
                        value: metrics.humidityDisplay() ?? "Humidity unavailable".localized,
                        accent: accentColor
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .animation(.easeInOut(duration: 0.25), value: level)
    }
}

// MARK: - Weather metric pill

private struct WeatherMetricPill: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(accent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: APINotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(notification.iconColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaNavy)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    // Unread dot
                    if !notification.isRead {
                        Circle()
                            .fill(Color.aquaPrimary)
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)
                    }
                }

                if let body = notification.body, !body.isEmpty {
                    Text(body)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Text(notification.relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .padding(14)
        .background(notification.isRead ? Color.aquaCard : notification.iconColor.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(notification.iconColor.opacity(notification.isRead ? 0.12 : 0.25), lineWidth: 1)
        )
    }
}

// MARK: - Family Safety Row
struct FamilySafetyRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(member.avatarColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                Text(member.avatarInitial)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(member.avatarColor)

                // Status dot (bottom-right)
                Circle()
                    .fill(member.status.color)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color.aquaCard, lineWidth: 2)
                    )
                    .offset(x: 16, y: 16)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaNavy)
                        .lineLimit(1)
                    Spacer()
                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: member.status.icon)
                            .font(.system(size: 9))
                        Text(member.status.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(member.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(member.status.color.opacity(0.12))
                    .cornerRadius(10)
                }

                HStack(spacing: 12) {
                    // Location
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.aquaPrimary)
                        Text(member.location)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Last seen
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(member.lastSeenString)
                            .font(.caption2)
                    }
                    .foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(Color.aquaCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(member.status.color.opacity(0.2), lineWidth: 1)
        )
    }
}

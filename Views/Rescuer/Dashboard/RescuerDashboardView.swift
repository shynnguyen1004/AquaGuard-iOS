//
//  RescuerDashboardView.swift
//  AquaGuard
//
//  Rescuer "Nhiệm vụ" tab — Team Missions.
//  Unlike RescuerRequestsView ("Yêu cầu", system-wide via /sos/all), this view
//  is scoped to the rescuer's own team via /sos/team and mirrors the web
//  Team Missions layout: To Start (admin-assigned, not yet started) →
//  In Progress (team actively working) → Completed (team's own resolved work).
//  Compact list + tap-to-open detail sheet; actions live in the sheet only.
//

import SwiftUI

// MARK: - Shared SOS Data Model

struct SosRequest: Identifiable {
    let id: Int
    let userName: String
    let description: String?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let urgency: String    // "critical" | "high" | "medium" | "low"
    var status: String     // "pending" | "assigned" | "in_progress" | "resolved"
    let assignedName: String?
    let assignedGroupName: String?
    let createdAt: String
    let images: [String]
    let userAge: Int?
    let userGender: String?    // "male" | "female" | "other"

    /// Short relative time string (e.g. "2h ago") from `createdAt`.
    var relativeTimeString: String {
        guard let date = Self.parseDate(createdAt) else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    // Urgency display
    var urgencyLabel: String {
        switch urgency {
        case "critical": return "Nguy cấp"
        case "high": return "Cao"
        case "medium": return "Trung bình"
        default: return "Thấp"
        }
    }

    var urgencyColor: Color {
        switch urgency {
        case "critical": return .purple
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }

    var urgencyIcon: String {
        switch urgency {
        case "critical": return "bolt.fill"
        case "high": return "exclamationmark.2"
        case "medium": return "exclamationmark.triangle.fill"
        default: return "exclamationmark.circle"
        }
    }

    // Status display
    var statusLabel: String {
        switch status {
        case "pending": return "Chờ xử lý"
        case "assigned": return "Đã nhận"
        case "in_progress": return "Đang cứu"
        default: return "Hoàn thành"
        }
    }

    var statusColor: Color {
        switch status {
        case "pending": return .orange
        case "assigned": return .blue
        case "in_progress": return .aquaPrimary
        default: return .green
        }
    }
}

// MARK: - Rescuer Dashboard View (Team Missions)

struct RescuerDashboardView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var viewModel = RescuerViewModel()
    @State private var selectedTab = 0  // 0=To Start, 1=In Progress, 2=Completed
    @State private var activeSheet: MissionSheet?
    @State private var toastMessage: String?

    // Sort & filter
    @State private var sortKey: SosSortKey = .priority
    @State private var selectedAgeGroups: Set<String> = []
    @State private var selectedGenders: Set<String> = []
    @State private var selectedCities: Set<String> = []
    @State private var showSortFilterSheet = false

    private enum MissionSheet: Identifiable {
        case detail(SosRequest)
        case tracking(SosRequest)

        var id: String {
            switch self {
            case .detail(let r): return "mission-detail-\(r.id)"
            case .tracking(let r): return "mission-tracking-\(r.id)"
            }
        }
    }

    // Team-scoped status buckets — pulled straight from viewModel.requests,
    // which /sos/team already restricts to this rescuer's group.
    private var toStartMissions: [SosRequest] { viewModel.requests.filter { $0.status == "assigned" } }
    private var inProgressMissions: [SosRequest] { viewModel.requests.filter { $0.status == "in_progress" } }
    private var completedMissions: [SosRequest] { viewModel.requests.filter { $0.status == "resolved" } }

    private var tabFilteredList: [SosRequest] {
        switch selectedTab {
        case 1: return inProgressMissions
        case 2: return completedMissions
        default: return toStartMissions
        }
    }

    private var currentList: [SosRequest] {
        sosFilterAndSort(
            tabFilteredList,
            sortKey: sortKey,
            ageGroups: selectedAgeGroups,
            genders: selectedGenders,
            cities: selectedCities
        )
    }

    private var hasActiveFilters: Bool {
        !selectedAgeGroups.isEmpty || !selectedGenders.isEmpty || !selectedCities.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        LogoHeaderView()

                        headerRow

                        tabFilter

                        // Sort & filter trigger
                        HStack {
                            SosSortFilterTrigger(sortKey: sortKey, hasActiveFilters: hasActiveFilters) {
                                showSortFilterSheet = true
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 30)
                        } else if currentList.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(currentList) { mission in
                                    missionCard(mission)
                                        .onTapGesture { activeSheet = .detail(mission) }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .detail(let mission):
                    missionDetailSheet(mission)
                case .tracking(let mission):
                    RescuerLiveTrackingSheet(request: mission)
                        .environmentObject(languageManager)
                }
            }
            .sheet(isPresented: $showSortFilterSheet) {
                SosSortFilterSheet(
                    sortKey: $sortKey,
                    selectedAgeGroups: $selectedAgeGroups,
                    selectedGenders: $selectedGenders,
                    selectedCities: $selectedCities,
                    cityOptions: sosCityOptions(for: tabFilteredList)
                )
            }
            .overlay(alignment: .bottom) {
                if let msg = toastMessage {
                    toastView(msg)
                }
            }
            .onAppear {
                viewModel.fetchTeamRequests()
            }
            .refreshable {
                viewModel.fetchTeamRequests()
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.aquaPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nhiệm vụ đội")
                        .font(.headline)
                        .foregroundColor(.aquaNavy)
                    if let teamName = viewModel.teamName {
                        Text("Team: \(teamName)")
                            .font(.caption2)
                            .foregroundColor(.aquaSubtitle)
                    } else {
                        Text("Chưa có nhiệm vụ nào được giao")
                            .font(.caption2)
                            .foregroundColor(.aquaSubtitle)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab Filter (counts included, no separate stats row)

    private var tabFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "Chờ bắt đầu", count: toStartMissions.count, tag: 0, color: .orange)
                filterPill(label: "Đang thực hiện", count: inProgressMissions.count, tag: 1, color: .aquaPrimary)
                filterPill(label: "Hoàn thành", count: completedMissions.count, tag: 2, color: .green)
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterPill(label: String, count: Int, tag: Int, color: Color) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag } }) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 12, weight: selectedTab == tag ? .bold : .medium))

                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(selectedTab == tag ? color : .aquaSubtitle)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(selectedTab == tag ? Color.white.opacity(0.3) : Color.secondary.opacity(0.1))
                    )
            }
            .foregroundColor(selectedTab == tag ? .white : .aquaSubtitle)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(selectedTab == tag ? color : Color.aquaCard)
                    .shadow(color: selectedTab == tag ? color.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            )
        }
    }

    // MARK: - Mission Card (compact — tap opens detail, no inline actions)

    private func missionCard(_ mission: SosRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mission.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)
                    .lineLimit(1)

                Spacer()

                SosUrgencyBadge(request: mission)

                if selectedTab == 0 {
                    // "To Start" hint — nudges the rescuer to open & begin it
                    HStack(spacing: 3) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 9))
                        Text("Chờ bắt đầu")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                } else {
                    SosStatusBadge(request: mission)
                }
            }

            HStack(spacing: 5) {
                if let loc = mission.location {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.aquaSubtitle.opacity(0.7))
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if !mission.relativeTimeString.isEmpty {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                        .foregroundColor(.aquaSubtitle.opacity(0.6))
                    Text(mission.relativeTimeString)
                        .font(.caption2)
                        .foregroundColor(.aquaSubtitle.opacity(0.7))
                        .lineLimit(1)
                }
            }

            if let desc = mission.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }

    // MARK: - Mission Detail Sheet

    private func missionDetailSheet(_ mission: SosRequest) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(mission.userName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)
                        Spacer()
                        SosUrgencyBadge(request: mission)
                        SosStatusBadge(request: mission)
                    }

                    Text(mission.createdAt)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)

                    Divider()

                    if let loc = mission.location {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            Text(loc)
                                .font(.subheadline)
                                .foregroundColor(.aquaNavy)
                        }
                    }

                    if let groupName = mission.assignedGroupName {
                        HStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.aquaPrimary)
                            Text("Đội phụ trách: \(groupName)")
                                .font(.subheadline)
                                .foregroundColor(.aquaNavy)
                        }
                    }

                    if let desc = mission.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.aquaNavy)
                    }

                    SosPhotoCarousel(imageURLs: mission.images)

                    if let lat = mission.latitude, let lng = mission.longitude {
                        HStack(spacing: 10) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            Text("GPS: \(String(format: "%.5f", lat)), \(String(format: "%.5f", lng))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.aquaPrimary)
                        }
                    }

                    Divider()

                    missionActions(mission)
                }
                .padding(20)
            }
            .background(Color.aquaBackground)
            .navigationTitle("Chi tiết nhiệm vụ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { activeSheet = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func missionActions(_ mission: SosRequest) -> some View {
        switch mission.status {
        case "assigned":
            // To Start: single primary CTA — hands off to the existing
            // /accept endpoint, which already transitions assigned → in_progress.
            Button(action: {
                viewModel.acceptRequest(mission)
                activeSheet = nil
                showToast("Đã bắt đầu nhiệm vụ ✓")
            }) {
                HStack(spacing: 8) {
                    if viewModel.isActioning {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Bắt đầu nhiệm vụ")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.aquaPrimary)
                .cornerRadius(12)
            }
            .disabled(viewModel.isActioning)

        case "in_progress":
            VStack(spacing: 10) {
                Button(action: {
                    activeSheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        activeSheet = .tracking(mission)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 13))
                        Text("Tracking")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.aquaPrimary)
                    .cornerRadius(12)
                }

                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.completeRequest(mission)
                        activeSheet = nil
                        showToast("Hoàn thành nhiệm vụ ✓")
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Complete")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.85))
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isActioning)

                    Button(action: {
                        viewModel.cancelRequest(mission)
                        activeSheet = nil
                        showToast("Đã huỷ nhiệm vụ")
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Cancel")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.aquaSubtitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.aquaInputBg)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.aquaInputBorder, lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.isActioning)
                }
            }

        default:
            // Completed — read-only
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Nhiệm vụ đã hoàn thành")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.green.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.aquaSubtitle.opacity(0.4))
            Text("Không có nhiệm vụ nào")
                .font(.subheadline)
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.aquaPrimary)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

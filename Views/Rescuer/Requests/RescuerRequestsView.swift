//
//  RescuerRequestsView.swift
//  AquaGuard
//
//  Rescuer "Yêu cầu" tab — Full rescue request management, system-wide
//  (all requests, not just this rescuer's team — see RescuerDashboardView
//  for the team-scoped "Nhiệm vụ" view).
//  Compact list + tap-to-open detail sheet; photos only ever show inside
//  the detail sheet, never on the list card.
//  Flow: Pending → Accept → In Progress (Complete/Cancel) → Resolved.
//  Connected to backend via RescuerViewModel.
//

import SwiftUI

// Sheet type enum to prevent multiple .sheet() conflicts
enum RescuerSheetType: Identifiable {
    case detail(SosRequest)
    case tracking(SosRequest)

    var id: String {
        switch self {
        case .detail(let r): return "detail-\(r.id)"
        case .tracking(let r): return "tracking-\(r.id)"
        }
    }
}

struct RescuerRequestsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var viewModel = RescuerViewModel()
    @State private var selectedTab = 0  // 0=All, 1=Pending, 2=InProgress, 3=Resolved
    @State private var activeSheet: RescuerSheetType?
    @State private var toastMessage: String?

    // Sort & filter
    @State private var sortKey: SosSortKey = .priority
    @State private var selectedAgeGroups: Set<String> = []
    @State private var selectedGenders: Set<String> = []
    @State private var selectedCities: Set<String> = []
    @State private var showSortFilterSheet = false

    // Computed filters
    private var allRequests: [SosRequest] { viewModel.allRequests }
    private var pendingRequests: [SosRequest] { viewModel.pendingRequests }
    private var inProgressRequests: [SosRequest] { viewModel.inProgressRequests }
    private var resolvedRequests: [SosRequest] { viewModel.resolvedRequests }

    private var tabFilteredList: [SosRequest] {
        switch selectedTab {
        case 1: return pendingRequests
        case 2: return inProgressRequests
        case 3: return resolvedRequests
        default: return allRequests
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

                        headerSection

                        // Tab filter (counts live here — no separate stats row)
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
                                ForEach(currentList) { req in
                                    requestCard(req)
                                        .onTapGesture { activeSheet = .detail(req) }
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
                case .detail(let req):
                    requestDetailSheet(req)
                case .tracking(let req):
                    RescuerLiveTrackingSheet(request: req)
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
                    toastBanner(msg)
                }
            }
            .onAppear {
                viewModel.fetchAllRequests()
            }
            .refreshable {
                viewModel.fetchAllRequests()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "light.beacon.max.fill")
                .font(.system(size: 18))
                .foregroundColor(.aquaPrimary)

            VStack(alignment: .leading, spacing: 1) {
                Text("Rescue Requests")
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                if let teamName = viewModel.teamName {
                    Text("Team: \(teamName)")
                        .font(.caption2)
                        .foregroundColor(.aquaSubtitle)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab Filter (pill buttons, counts included)

    private var tabFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "Pending", count: pendingRequests.count, tag: 1, color: .orange)
                filterPill(label: "In Progress", count: inProgressRequests.count, tag: 2, color: .aquaPrimary)
                filterPill(label: "Resolved", count: resolvedRequests.count, tag: 3, color: .green)
                filterPill(label: "All", count: allRequests.count, tag: 0, color: .aquaNavy)
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

    // MARK: - Request Card (compact — no photos, no assignment line)

    private func requestCard(_ request: SosRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)
                    .lineLimit(1)

                Spacer()

                SosUrgencyBadge(request: request)
                SosStatusBadge(request: request)
            }

            HStack(spacing: 5) {
                if let loc = request.location {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if !request.relativeTimeString.isEmpty {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                        .foregroundColor(.aquaSubtitle.opacity(0.6))
                    Text(request.relativeTimeString)
                        .font(.caption2)
                        .foregroundColor(.aquaSubtitle.opacity(0.7))
                        .lineLimit(1)
                }
            }

            if let desc = request.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                    .lineLimit(1)
            }

            // Action buttons based on status
            if request.status == "pending" {
                Button(action: {
                    viewModel.acceptRequest(request)
                    showToast("Đã nhận nhiệm vụ ✓")
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isActioning {
                            ProgressView().scaleEffect(0.7).tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Accept")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.aquaPrimary)
                    .cornerRadius(9)
                }
                .disabled(viewModel.isActioning)
            }

            if request.status == "in_progress" || request.status == "assigned" {
                HStack(spacing: 8) {
                    compactActionButton(icon: "location.fill", label: "Tracking", color: .white, bg: Color.aquaPrimary) {
                        activeSheet = .tracking(request)
                    }
                    compactActionButton(icon: "checkmark.circle.fill", label: "Complete", color: .white, bg: Color.green.opacity(0.85)) {
                        viewModel.completeRequest(request)
                        showToast("Hoàn thành ✓")
                    }
                    compactActionButton(icon: "xmark", label: "Cancel", color: .aquaSubtitle, bg: Color.aquaInputBg, bordered: true) {
                        viewModel.cancelRequest(request)
                        showToast("Đã huỷ nhiệm vụ")
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }

    private func compactActionButton(icon: String, label: String, color: Color, bg: Color, bordered: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(bg)
            .cornerRadius(9)
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: 9).stroke(Color.aquaInputBorder, lineWidth: 1)
                }
            }
        }
        .disabled(viewModel.isActioning)
    }

    // MARK: - Detail Sheet

    private func requestDetailSheet(_ request: SosRequest) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(request.userName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)
                        Spacer()
                        SosUrgencyBadge(request: request)
                        SosStatusBadge(request: request)
                    }

                    Text(request.createdAt)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)

                    Divider()

                    if let loc = request.location {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            Text(loc)
                                .font(.subheadline)
                                .foregroundColor(.aquaNavy)
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Assigned to: \(request.assignedName ?? "Unassigned")")
                            .font(.subheadline)
                            .foregroundColor(request.assignedName != nil ? .aquaNavy : .aquaSubtitle)
                    }

                    if let desc = request.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.aquaNavy)
                    }

                    SosPhotoCarousel(imageURLs: request.images)

                    if let lat = request.latitude, let lng = request.longitude {
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

                    if request.status == "pending" {
                        Button(action: {
                            viewModel.acceptRequest(request)
                            activeSheet = nil
                            showToast("Đã nhận nhiệm vụ ✓")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Accept")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.aquaPrimary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isActioning)
                    }

                    if request.status == "in_progress" || request.status == "assigned" {
                        VStack(spacing: 10) {
                            Button(action: {
                                activeSheet = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    activeSheet = .tracking(request)
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
                                    viewModel.completeRequest(request)
                                    activeSheet = nil
                                    showToast("Hoàn thành ✓")
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
                                    viewModel.cancelRequest(request)
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
                    }
                }
                .padding(20)
            }
            .background(Color.aquaBackground)
            .navigationTitle("Request Detail")
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundColor(.aquaSubtitle.opacity(0.3))
            Text("Không có yêu cầu nào")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.4)) { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut) { toastMessage = nil }
        }
    }

    private func toastBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: message.contains("✓") ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 16))
            Text(message)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(
            Capsule()
                .fill(Color.aquaPrimary)
                .shadow(color: .aquaPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.bottom, 30)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

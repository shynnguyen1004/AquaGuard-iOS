//
//  RescuerRequestsView.swift
//  AquaGuard
//
//  Rescuer "Yêu cầu" tab — Full rescue request management.
//  Stats row, 4-tab filter, request cards, detail sheet.
//  Flow: Pending → Accept → In Progress (Complete/Cancel) → Resolved.
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
    @State private var requests = SosRequest.dummyRequests
    @State private var selectedTab = 0  // 0=All, 1=Pending, 2=InProgress, 3=Resolved
    @State private var activeSheet: RescuerSheetType?
    @State private var toastMessage: String?

    // Computed filters
    private var allRequests: [SosRequest] { requests }
    private var pendingRequests: [SosRequest] { requests.filter { $0.status == "pending" } }
    private var inProgressRequests: [SosRequest] { requests.filter { $0.status == "in_progress" || $0.status == "assigned" } }
    private var resolvedRequests: [SosRequest] { requests.filter { $0.status == "resolved" } }

    private var currentList: [SosRequest] {
        switch selectedTab {
        case 1: return pendingRequests
        case 2: return inProgressRequests
        case 3: return resolvedRequests
        default: return allRequests
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Header
                        headerSection

                        // Stats row (4 cards)
                        statsRow

                        // Tab filter
                        tabFilter

                        // Sort hint
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 12))
                                .foregroundColor(.aquaSubtitle)
                            Text("Sắp xếp theo: ")
                                .font(.caption)
                                .foregroundColor(.aquaSubtitle)
                            Text("Ưu tiên")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        // Request list
                        if currentList.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(currentList.sorted(by: { urgencyPriority($0.urgency) > urgencyPriority($1.urgency) }).enumerated()), id: \.element.id) { index, req in
                                    requestCard(req)
                                        .onTapGesture {
                                            activeSheet = .detail(req)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .animation(.easeOut(duration: 0.25).delay(Double(index) * 0.06), value: selectedTab)
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
            .overlay(alignment: .bottom) {
                if let msg = toastMessage {
                    toastBanner(msg)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "light.beacon.max.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.aquaPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rescue Requests")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    Text("Manage and track rescue requests")
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                }
                Spacer()
            }

            // Team name
            HStack(spacing: 5) {
                Text("Team:")
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                Text("Đội Cứu Hộ Alpha")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaPrimary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Stats Row (4 cards matching web)

    private var statsRow: some View {
        HStack(spacing: 8) {
            statsCard(icon: "list.bullet.clipboard", label: "Total", value: "\(allRequests.count)", color: .aquaNavy, bgColor: .clear)
            statsCard(icon: "clock.fill", label: "Pending", value: "\(pendingRequests.count)", color: .orange, bgColor: .orange)
            statsCard(icon: "arrow.triangle.2.circlepath", label: "In Progress", value: "\(inProgressRequests.count)", color: .aquaPrimary, bgColor: .aquaPrimary)
            statsCard(icon: "checkmark.circle.fill", label: "Resolved", value: "\(resolvedRequests.count)", color: .green, bgColor: .green)
        }
        .padding(.horizontal, 16)
    }

    private func statsCard(icon: String, label: String, value: String, color: Color, bgColor: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(bgColor == .clear ? .aquaNavy : bgColor)
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.aquaNavy)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.aquaSubtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bgColor == .clear ? Color.aquaCard : bgColor.opacity(0.08))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Tab Filter (pill buttons)

    private var tabFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "Pending", count: pendingRequests.count, tag: 1, color: .orange)
                filterPill(label: "In Progress", count: inProgressRequests.count, tag: 2, color: .aquaPrimary)
                filterPill(label: "Resolved", count: resolvedRequests.count, tag: 3, color: .green)
                filterPill(label: "All Requests", count: allRequests.count, tag: 0, color: .aquaPrimary)
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterPill(label: String, count: Int, tag: Int, color: Color) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag } }) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 12, weight: selectedTab == tag ? .bold : .medium))

                if count > 0 {
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

    // MARK: - Request Card

    private func requestCard(_ request: SosRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Name + Urgency + Status badges
            HStack {
                Text(request.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)

                Spacer()

                // Urgency badge
                Text(request.urgencyLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(request.urgencyColor)
                    .cornerRadius(6)

                // Status badge
                Text(request.statusLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(request.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(request.statusColor.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(request.statusColor.opacity(0.2), lineWidth: 1)
                    )
            }

            // Row 2: Location
            if let loc = request.location {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                        .lineLimit(1)
                }
            }

            // Row 3: Description
            if let desc = request.description {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                    .lineLimit(2)
            }

            // Row 4: Assigned info
            if let assigned = request.assignedName {
                HStack(spacing: 5) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text("Assigned to: \(assigned)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.aquaSubtitle.opacity(0.6))
                    Text("Assigned to: Unassigned")
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle.opacity(0.7))
                }
            }

            // Action buttons based on status
            if request.status == "pending" {
                Button(action: { acceptRequest(request) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Accept")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.aquaPrimary)
                    .cornerRadius(10)
                }
            }

            // In-progress: 3 buttons (Tracking, Complete, Cancel)
            if request.status == "in_progress" || request.status == "assigned" {
                HStack(spacing: 8) {
                    Button(action: {
                        activeSheet = .tracking(request)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text("Tracking")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.aquaPrimary)
                        .cornerRadius(9)
                    }

                    Button(action: { completeRequest(request) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Complete")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.85))
                        .cornerRadius(9)
                    }

                    Button(action: { cancelRequest(request) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.aquaSubtitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.aquaInputBg)
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.aquaInputBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Detail Sheet

    private func requestDetailSheet(_ request: SosRequest) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header: Name + badges
                    HStack {
                        Text(request.userName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)

                        Spacer()

                        Text(request.urgencyLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(request.urgencyColor)
                            .cornerRadius(8)

                        Text(request.statusLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(request.statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(request.statusColor.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Date
                    Text(request.createdAt)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)

                    Divider()

                    // Location
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

                    // Assigned
                    HStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Assigned to: \(request.assignedName ?? "Unassigned")")
                            .font(.subheadline)
                            .foregroundColor(request.assignedName != nil ? .aquaNavy : .aquaSubtitle)
                    }

                    // Description
                    if let desc = request.description {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(.aquaNavy)
                        }
                    }

                    // GPS
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

                    // Actions based on status
                    if request.status == "pending" {
                        Button(action: {
                            acceptRequest(request)
                            activeSheet = nil
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
                    }

                    if request.status == "in_progress" || request.status == "assigned" {
                        // Full-width button row
                        VStack(spacing: 10) {
                            // Tracking — full width primary
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
                                // Complete
                                Button(action: {
                                    completeRequest(request)
                                    activeSheet = nil
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

                                // Cancel
                                Button(action: {
                                    cancelRequest(request)
                                    activeSheet = nil
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

    // MARK: - Actions

    private func acceptRequest(_ req: SosRequest) {
        if let idx = requests.firstIndex(where: { $0.id == req.id }) {
            withAnimation { requests[idx].status = "in_progress" }
            showToast("Đã nhận nhiệm vụ ✓")
        }
    }

    private func completeRequest(_ req: SosRequest) {
        if let idx = requests.firstIndex(where: { $0.id == req.id }) {
            withAnimation { requests[idx].status = "resolved" }
            showToast("Hoàn thành ✓")
        }
    }

    private func cancelRequest(_ req: SosRequest) {
        if let idx = requests.firstIndex(where: { $0.id == req.id }) {
            withAnimation { requests[idx].status = "pending" }
            showToast("Đã huỷ nhiệm vụ")
        }
    }

    // MARK: - Helpers

    private func urgencyPriority(_ urgency: String) -> Int {
        switch urgency {
        case "critical": return 4
        case "high": return 3
        case "medium": return 2
        default: return 1
        }
    }

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

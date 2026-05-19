//
//  AdminSOSView.swift
//  AquaGuard
//
//  Admin SOS management — 4-tab filter,
//  assign SOS to rescue groups, complete actions.
//  Matching guide.md spec exactly.
//

import SwiftUI

// MARK: - Admin Rescue Group

struct AdminRescueGroup: Identifiable {
    let id: Int
    let name: String
    let memberCount: Int
    let leaderName: String

    static let rescueGroups: [AdminRescueGroup] = [
        AdminRescueGroup(id: 1, name: "Đội Alpha", memberCount: 3, leaderName: "Nguyễn Văn A"),
        AdminRescueGroup(id: 2, name: "Đội Beta", memberCount: 5, leaderName: "Trần Văn X"),
        AdminRescueGroup(id: 3, name: "Đội Gamma", memberCount: 4, leaderName: "Lê Minh Y"),
    ]
}

// MARK: - View

struct AdminSOSView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var viewModel = RescuerViewModel()
    @State private var selectedTab = 0  // 0=Tất cả, 1=Đang chờ, 2=Đang xử lý, 3=Hoàn thành
    @State private var toastMessage: String?

    private var requests: [SosRequest] { viewModel.allRequests }
    private var allRequests: [SosRequest] { viewModel.allRequests }
    private var pendingRequests: [SosRequest] { viewModel.pendingRequests }
    private var activeRequests: [SosRequest] { viewModel.inProgressRequests }
    private var resolvedRequests: [SosRequest] { viewModel.resolvedRequests }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Stats row
                statsRow

                // 4 Tabs
                Picker("", selection: $selectedTab) {
                    Text("Tất cả (\(allRequests.count))").tag(0)
                    Text("Đang chờ (\(pendingRequests.count))").tag(1)
                    Text("Đang xử lý (\(activeRequests.count))").tag(2)
                    Text("Hoàn thành (\(resolvedRequests.count))").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // List
                ScrollView {
                    let currentList: [SosRequest] = {
                        switch selectedTab {
                        case 1: return pendingRequests
                        case 2: return activeRequests
                        case 3: return resolvedRequests
                        default: return allRequests
                        }
                    }()

                    if currentList.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.aquaSubtitle.opacity(0.3))
                            Text("Không có yêu cầu nào")
                                .font(.subheadline)
                                .foregroundColor(.aquaSubtitle)
                        }
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(currentList) { req in
                                adminSOSCard(req)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchAllRequests()
            }
            .overlay(alignment: .bottom) {
                if let msg = toastMessage {
                    Text(msg)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.aquaPrimary)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.15), radius: 10)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.aquaPrimary)
                Text("Quản lý SOS")
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
            }
            Text("Quản lý tất cả yêu cầu cứu hộ trong hệ thống")
                .font(.caption)
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            sosPill(label: "Chờ xử lý", count: pendingRequests.count, color: .orange)
            sosPill(label: "Đang xử lý", count: activeRequests.count, color: .aquaPrimary)
            sosPill(label: "Hoàn thành", count: resolvedRequests.count, color: .green)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func sosPill(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - SOS Card

    private func adminSOSCard(_ request: SosRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Name + urgency + status
            HStack {
                Text(request.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: request.urgencyIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(request.urgencyLabel)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(request.urgencyColor)
                .cornerRadius(6)

                Text(request.statusLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(request.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(request.statusColor.opacity(0.1))
                    .cornerRadius(6)
            }

            // Description
            if let desc = request.description {
                Text(desc).font(.caption).foregroundColor(.aquaSubtitle).lineLimit(2)
            }

            // Location
            if let loc = request.location {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(.aquaSubtitle.opacity(0.6))
                    Text(loc).font(.caption).foregroundColor(.aquaSubtitle.opacity(0.7)).lineLimit(1)
                }
            }

            // Assignment info
            if let assigned = request.assignedName {
                HStack(spacing: 5) {
                    Image(systemName: "person.fill").font(.system(size: 10)).foregroundColor(.aquaPrimary)
                    Text("Phân công: \(assigned)").font(.caption).foregroundColor(.aquaPrimary)
                }
            } else if request.status == "pending" {
                Text("Chưa phân công")
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle.opacity(0.6))
            }

            // Admin actions
            if request.status == "pending" {
                // Assign picker
                VStack(spacing: 8) {
                    ForEach(AdminRescueGroup.rescueGroups) { group in
                        Button(action: {
                            assignToGroup(request, group: group)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lifepreserver.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.aquaPrimary)
                                Text(group.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.aquaNavy)
                                Spacer()
                                Text("\(group.memberCount) người")
                                    .font(.caption2)
                                    .foregroundColor(.aquaSubtitle)
                                Image(systemName: "arrow.right.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.aquaPrimary.opacity(0.5))
                            }
                            .padding(10)
                            .background(Color.aquaBackground)
                            .cornerRadius(10)
                        }
                    }
                }
            }

            if request.status == "in_progress" || request.status == "assigned" {
                Button(action: { adminComplete(request) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 12))
                        Text("Hoàn thành (Admin)")
                            .font(.caption).fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(10)
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

    // MARK: - Actions

    private func assignToGroup(_ request: SosRequest, group: AdminRescueGroup) {
        // TODO: Call admin assign API when available
        viewModel.acceptRequest(request)
        showToast("Đã phân công cho \(group.name)")
    }

    private func adminComplete(_ request: SosRequest) {
        viewModel.completeRequest(request)
        showToast("Đã hoàn thành")
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}

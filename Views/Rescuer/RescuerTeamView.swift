//
//  RescuerTeamView.swift
//  AquaGuard
//
//  Rescuer team management with 3 internal tabs:
//  Tab 0: "Đội của tôi" — group hero, stats, invite, members
//  Tab 1: "Danh bạ" — all rescuers directory
//  Tab 2: "Lời mời" — received invitations
//  Connected to backend via RescuerTeamViewModel.
//

import SwiftUI

struct RescuerTeamView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var viewModel = RescuerTeamViewModel()
    @State private var selectedTab = 0
    @State private var toastMessage: String?

    // Create team form
    @State private var newTeamName = ""
    @State private var newTeamDesc = ""

    // Invite
    @State private var invitePhone = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 3 tabs
                Picker("", selection: $selectedTab) {
                    Text("Đội của tôi").tag(0)
                    Text("Danh bạ").tag(1)
                    HStack {
                        Text("Lời mời")
                        if !viewModel.receivedInvites.isEmpty {
                            Text("(\(viewModel.receivedInvites.count))")
                        }
                    }.tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        switch selectedTab {
                        case 0: myTeamTab
                        case 1: directoryTab
                        case 2: invitesTab
                        default: EmptyView()
                        }
                    }
                }
            }
            .background(Color.aquaBackground)
            .navigationTitle("Đội cứu hộ")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                viewModel.fetchMyGroup()
            }
            .refreshable {
                viewModel.fetchMyGroup()
            }
            .onChange(of: viewModel.successMessage) { msg in
                if let msg = msg {
                    showToast(msg)
                    viewModel.successMessage = nil
                }
            }
            .onChange(of: viewModel.errorMessage) { msg in
                if let msg = msg {
                    showToast("❌ \(msg)")
                    viewModel.errorMessage = nil
                }
            }
        }
    }

    // MARK: - Tab 0: Đội của tôi

    private var myTeamTab: some View {
        VStack(spacing: 16) {
            if !viewModel.hasTeam {
                createTeamForm
            } else {
                // A. Group Hero Card
                groupHeroCard

                // B. Stats
                teamStatsRow

                // C. Invite (leader/co_leader only)
                if viewModel.isLeaderOrCoLeader {
                    inviteSection
                }

                // D. Pending outgoing invites
                if !viewModel.pendingOutgoingInvites.isEmpty {
                    pendingInvitesSection
                }

                // E. Member list
                memberListSection
            }

            Spacer(minLength: 30)
        }
        .padding(.top, 8)
    }

    private var createTeamForm: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)

            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundColor(.aquaSubtitle.opacity(0.4))

            Text("Bạn chưa có đội cứu hộ")
                .font(.headline)
                .foregroundColor(.aquaNavy)

            VStack(spacing: 12) {
                TextField("Tên đội cứu hộ", text: $newTeamName)
                    .padding(14)
                    .background(Color.aquaInputBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aquaInputBorder, lineWidth: 1))

                TextField("Mô tả (tùy chọn)", text: $newTeamDesc)
                    .padding(14)
                    .background(Color.aquaInputBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aquaInputBorder, lineWidth: 1))

                Button(action: {
                    guard !newTeamName.isEmpty else { return }
                    viewModel.createTeam(name: newTeamName, description: newTeamDesc)
                    newTeamName = ""
                    newTeamDesc = ""
                }) {
                    if viewModel.isActioning {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Tạo đội")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(Color.aquaPrimary)
                .cornerRadius(14)
                .disabled(viewModel.isActioning || newTeamName.isEmpty)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var groupHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.group?.name ?? "")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)

                    Text(viewModel.group?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                }

                Spacer()

                // My role badge
                Text({
                    switch viewModel.myRole {
                    case "leader": return "Đội trưởng"
                    case "co_leader": return "Phó đội"
                    default: return "Thành viên"
                    }
                }())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor({
                    switch viewModel.myRole {
                    case "leader": return Color.orange
                    case "co_leader": return Color.aquaPrimary
                    default: return Color.green
                    }
                }())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background({
                    switch viewModel.myRole {
                    case "leader": return Color.orange.opacity(0.1)
                    case "co_leader": return Color.aquaPrimary.opacity(0.1)
                    default: return Color.green.opacity(0.1)
                    }
                }())
                .cornerRadius(8)
            }

            // Menu
            if viewModel.myRole == "leader" {
                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.disbandGroup()
                    }) {
                        Text("Giải tán")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.isActioning)
                }
            } else {
                Button(action: {
                    viewModel.leaveGroup()
                }) {
                    Text("Rời nhóm")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .disabled(viewModel.isActioning)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }

    private var teamStatsRow: some View {
        HStack(spacing: 10) {
            miniStat(label: "Thành viên", value: "\(viewModel.members.count)", color: .aquaPrimary)
            miniStat(label: "Lời mời chờ", value: "\(viewModel.pendingOutgoingInvites.count)", color: .orange)
            miniStat(label: "Vai trò", value: viewModel.myRole == "leader" ? "Trưởng" : viewModel.myRole == "co_leader" ? "Phó" : "TV", color: .green)
        }
        .padding(.horizontal, 16)
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.aquaSubtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }

    private var inviteSection: some View {
        HStack(spacing: 10) {
            TextField("+84...", text: $invitePhone)
                .keyboardType(.phonePad)
                .padding(12)
                .background(Color.aquaInputBg)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.aquaInputBorder, lineWidth: 1))

            Button(action: {
                guard !invitePhone.isEmpty else { return }
                viewModel.inviteByPhone(invitePhone)
                invitePhone = ""
            }) {
                if viewModel.isActioning {
                    ProgressView().scaleEffect(0.8).tint(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                } else {
                    Text("Mời")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                }
            }
            .background(Color.aquaPrimary)
            .cornerRadius(10)
            .disabled(viewModel.isActioning || invitePhone.isEmpty)
        }
        .padding(.horizontal, 16)
    }

    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lời mời đã gửi")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.aquaSubtitle)
                .padding(.horizontal, 20)

            ForEach(viewModel.pendingOutgoingInvites) { invite in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(invite.displayName.prefix(1)))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.5))
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(invite.displayName.isEmpty ? invite.phoneNumber : invite.displayName)
                            .font(.caption).fontWeight(.medium).foregroundColor(.aquaNavy)
                        Text(invite.phoneNumber)
                            .font(.caption2).foregroundColor(.aquaSubtitle)
                    }
                    Spacer()
                    Text("Đang chờ")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.aquaCard))
            .padding(.horizontal, 16)
        }
    }

    private var memberListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thành viên")
                .font(.headline)
                .foregroundColor(.aquaNavy)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(roleColor(member.memberRole).opacity(0.15))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(String(member.displayName.prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(roleColor(member.memberRole))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.displayName).font(.subheadline).fontWeight(.medium).foregroundColor(.aquaNavy)
                            Text(member.phoneNumber).font(.caption).foregroundColor(.aquaSubtitle)
                        }

                        Spacer()

                        Text(roleLabel(member.memberRole))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(roleColor(member.memberRole))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(roleColor(member.memberRole).opacity(0.1))
                            .cornerRadius(6)

                        // Leader menu actions
                        if viewModel.myRole == "leader" && member.memberRole != "leader" {
                            Menu {
                                if member.memberRole == "member" {
                                    Button("Thăng cấp") { viewModel.promoteMember(member) }
                                }
                                if member.memberRole == "co_leader" {
                                    Button("Giáng cấp") { viewModel.demoteMember(member) }
                                }
                                Button("Xóa khỏi nhóm", role: .destructive) { viewModel.removeMember(member) }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < viewModel.members.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.aquaCard)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab 1: Danh bạ

    private var directoryTab: some View {
        VStack(spacing: 12) {
            if viewModel.allRescuers.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Đang tải danh sách...")
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                }
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.allRescuers) { rescuer in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.aquaPrimary.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(rescuer.displayName.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.aquaPrimary)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rescuer.displayName).font(.subheadline).fontWeight(.medium).foregroundColor(.aquaNavy)
                            Text(rescuer.phoneNumber).font(.caption).foregroundColor(.aquaSubtitle)
                        }

                        Spacer()

                        if rescuer.hasActiveGroup {
                            Text("Đã có đội")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        } else if rescuer.hasPendingInviteFromMe {
                            Text("Đã mời")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        } else if viewModel.isLeaderOrCoLeader {
                            Button(action: {
                                viewModel.inviteByPhone(rescuer.phoneNumber)
                            }) {
                                Text("Mời")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 5)
                                    .background(Color.aquaPrimary)
                                    .cornerRadius(6)
                            }
                            .disabled(viewModel.isActioning)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.aquaCard)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    )
                }
                .padding(.horizontal, 16)
            }

            Spacer(minLength: 30)
        }
        .padding(.top, 8)
        .onAppear {
            viewModel.fetchRescuers()
        }
    }

    // MARK: - Tab 2: Lời mời

    private var invitesTab: some View {
        VStack(spacing: 12) {
            if viewModel.receivedInvites.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.aquaSubtitle.opacity(0.4))
                    Text("Không có lời mời nào")
                        .font(.subheadline)
                        .foregroundColor(.aquaSubtitle)
                }
                .padding(.vertical, 80)
            } else {
                ForEach(viewModel.receivedInvites) { invite in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.aquaPrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(invite.group.name).font(.subheadline).fontWeight(.bold).foregroundColor(.aquaNavy)
                                Text("Người mời: \(invite.inviter.displayName)").font(.caption).foregroundColor(.aquaSubtitle)
                            }
                            Spacer()
                        }

                        HStack(spacing: 10) {
                            Button(action: {
                                viewModel.acceptInvite(invite)
                            }) {
                                Text("Chấp nhận")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .disabled(viewModel.isActioning)

                            Button(action: {
                                viewModel.declineInvite(invite)
                            }) {
                                Text("Từ chối")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                            .disabled(viewModel.isActioning)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.aquaCard)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    )
                    .padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 30)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func roleLabel(_ role: String) -> String {
        switch role {
        case "leader": return "Đội trưởng"
        case "co_leader": return "Phó đội"
        default: return "Thành viên"
        }
    }

    private func roleColor(_ role: String) -> Color {
        switch role {
        case "leader": return .orange
        case "co_leader": return .aquaPrimary
        default: return .green
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}

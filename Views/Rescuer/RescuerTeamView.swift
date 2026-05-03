//
//  RescuerTeamView.swift
//  AquaGuard
//
//  Rescuer team management with 3 internal tabs:
//  Tab 0: "Đội của tôi" — group hero, stats, invite, members
//  Tab 1: "Danh bạ" — all rescuers directory
//  Tab 2: "Lời mời" — received invitations
//  Uses dummy data matching guide.md spec.
//

import SwiftUI

// MARK: - Data Models (guide spec)

struct GuideTeamMember: Identifiable {
    let id: Int
    let displayName: String
    let phoneNumber: String
    var memberRole: String  // "leader" | "co_leader" | "member"

    var roleLabel: String {
        switch memberRole {
        case "leader": return "Đội trưởng"
        case "co_leader": return "Phó đội"
        default: return "Thành viên"
        }
    }

    var roleColor: Color {
        switch memberRole {
        case "leader": return .orange
        case "co_leader": return .aquaPrimary
        default: return .green
        }
    }
}

struct RescueGroup {
    let id: Int
    var name: String
    var description: String
    var myRole: String
    var members: [GuideTeamMember]
    var pendingInvites: [PendingInvite]
}

struct PendingInvite: Identifiable {
    let id: Int
    let displayName: String
    let phoneNumber: String
}

struct ReceivedInvite: Identifiable {
    let id: Int
    let groupName: String
    let inviterName: String
    let createdAt: String
}

struct DirectoryRescuer: Identifiable {
    let id: Int
    let displayName: String
    let phoneNumber: String
    var hasActiveGroup: Bool
    var hasPendingInviteFromMe: Bool
}

// MARK: - View

struct RescuerTeamView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTab = 0
    @State private var toastMessage: String?

    // State: has team or not
    @State private var hasTeam = true

    // Create team form
    @State private var newTeamName = ""
    @State private var newTeamDesc = ""

    // Invite
    @State private var invitePhone = ""

    // Dummy data
    @State private var group = RescueGroup(
        id: 1,
        name: "Đội Cứu Hộ Alpha",
        description: "Đội cứu hộ chính khu vực Quận 1 - Quận 3",
        myRole: "leader",
        members: [
            GuideTeamMember(id: 1, displayName: "Nguyễn Văn A", phoneNumber: "+84901234567", memberRole: "leader"),
            GuideTeamMember(id: 2, displayName: "Trần Thị B", phoneNumber: "+84901234568", memberRole: "co_leader"),
            GuideTeamMember(id: 3, displayName: "Lê Văn C", phoneNumber: "+84901234569", memberRole: "member"),
        ],
        pendingInvites: [
            PendingInvite(id: 10, displayName: "Phạm Văn D", phoneNumber: "+84901234570"),
        ]
    )

    @State private var allRescuers: [DirectoryRescuer] = [
        DirectoryRescuer(id: 4, displayName: "Hoàng Văn E", phoneNumber: "+84901234571", hasActiveGroup: false, hasPendingInviteFromMe: false),
        DirectoryRescuer(id: 5, displayName: "Vũ Thị F", phoneNumber: "+84901234572", hasActiveGroup: false, hasPendingInviteFromMe: true),
        DirectoryRescuer(id: 6, displayName: "Đặng Minh G", phoneNumber: "+84901234573", hasActiveGroup: true, hasPendingInviteFromMe: false),
        DirectoryRescuer(id: 7, displayName: "Bùi Thanh H", phoneNumber: "+84901234574", hasActiveGroup: false, hasPendingInviteFromMe: false),
    ]

    @State private var receivedInvites: [ReceivedInvite] = [
        ReceivedInvite(id: 100, groupName: "Đội Beta", inviterName: "Nguyễn Minh K", createdAt: "2025-05-03T06:00:00Z"),
    ]

    private var isLeaderOrCoLeader: Bool {
        group.myRole == "leader" || group.myRole == "co_leader"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 3 tabs
                Picker("", selection: $selectedTab) {
                    Text("Đội của tôi").tag(0)
                    Text("Danh bạ").tag(1)
                    HStack {
                        Text("Lời mời")
                        if !receivedInvites.isEmpty {
                            Text("(\(receivedInvites.count))")
                        }
                    }.tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                ScrollView {
                    switch selectedTab {
                    case 0: myTeamTab
                    case 1: directoryTab
                    case 2: invitesTab
                    default: EmptyView()
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
        }
    }

    // MARK: - Tab 0: Đội của tôi

    private var myTeamTab: some View {
        VStack(spacing: 16) {
            if !hasTeam {
                createTeamForm
            } else {
                // A. Group Hero Card
                groupHeroCard

                // B. Stats
                teamStatsRow

                // C. Invite (leader/co_leader only)
                if isLeaderOrCoLeader {
                    inviteSection
                }

                // D. Pending outgoing invites
                if !group.pendingInvites.isEmpty {
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
                .foregroundColor(.secondary.opacity(0.3))

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
                    hasTeam = true
                    showToast("Đã tạo đội")
                }) {
                    Text("Tạo đội")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.aquaPrimary)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var groupHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)

                    Text(group.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // My role badge
                Text({
                    switch group.myRole {
                    case "leader": return "Đội trưởng"
                    case "co_leader": return "Phó đội"
                    default: return "Thành viên"
                    }
                }())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor({
                    switch group.myRole {
                    case "leader": return Color.orange
                    case "co_leader": return Color.aquaPrimary
                    default: return Color.green
                    }
                }())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background({
                    switch group.myRole {
                    case "leader": return Color.orange.opacity(0.1)
                    case "co_leader": return Color.aquaPrimary.opacity(0.1)
                    default: return Color.green.opacity(0.1)
                    }
                }())
                .cornerRadius(8)
            }

            // Menu
            if group.myRole == "leader" {
                HStack(spacing: 10) {
                    Button(action: {
                        hasTeam = false
                        showToast("Đã giải tán đội")
                    }) {
                        Text("Giải tán")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            } else {
                Button(action: {
                    hasTeam = false
                    showToast("Đã rời nhóm")
                }) {
                    Text("Rời nhóm")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }

    private var teamStatsRow: some View {
        HStack(spacing: 10) {
            miniStat(label: "Nhiệm vụ đang làm", value: "2", color: .orange)
            miniStat(label: "Đã hoàn thành", value: "15", color: .green)
            miniStat(label: "Thành viên", value: "\(group.members.count)", color: .aquaPrimary)
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
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
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
                group.pendingInvites.append(
                    PendingInvite(id: Int.random(in: 100...999), displayName: "Người dùng", phoneNumber: invitePhone)
                )
                invitePhone = ""
                showToast("Đã gửi lời mời")
            }) {
                Text("Mời")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .background(Color.aquaPrimary)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 16)
    }

    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lời mời đã gửi")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            ForEach(group.pendingInvites) { invite in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(invite.displayName.prefix(1)))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(invite.displayName).font(.caption).fontWeight(.medium).foregroundColor(.aquaNavy)
                        Text(invite.phoneNumber).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        group.pendingInvites.removeAll { $0.id == invite.id }
                        showToast("Đã huỷ lời mời")
                    }) {
                        Text("Huỷ")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    }
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
                ForEach(Array(group.members.enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(member.roleColor.opacity(0.15))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(String(member.displayName.prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(member.roleColor)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.displayName).font(.subheadline).fontWeight(.medium).foregroundColor(.aquaNavy)
                            Text(member.phoneNumber).font(.caption).foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(member.roleLabel)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(member.roleColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(member.roleColor.opacity(0.1))
                            .cornerRadius(6)

                        // Leader menu actions
                        if group.myRole == "leader" && member.memberRole != "leader" {
                            Menu {
                                if member.memberRole == "member" {
                                    Button("Thăng cấp") { promoteMember(member) }
                                }
                                if member.memberRole == "co_leader" {
                                    Button("Giáng cấp") { demoteMember(member) }
                                }
                                Button("Xóa khỏi nhóm", role: .destructive) { removeMember(member) }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < group.members.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.aquaCard)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab 1: Danh bạ

    private var directoryTab: some View {
        VStack(spacing: 12) {
            ForEach(allRescuers) { rescuer in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(rescuer.displayName.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(rescuer.displayName).font(.subheadline).fontWeight(.medium).foregroundColor(.aquaNavy)
                        Text(rescuer.phoneNumber).font(.caption).foregroundColor(.secondary)
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
                    } else {
                        Button(action: {
                            if let idx = allRescuers.firstIndex(where: { $0.id == rescuer.id }) {
                                allRescuers[idx].hasPendingInviteFromMe = true
                            }
                            showToast("Đã gửi lời mời")
                        }) {
                            Text("Mời")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background(Color.aquaPrimary)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.aquaCard)
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                )
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 30)
        }
        .padding(.top, 8)
    }

    // MARK: - Tab 2: Lời mời

    private var invitesTab: some View {
        VStack(spacing: 12) {
            if receivedInvites.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("Không có lời mời nào")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 80)
            } else {
                ForEach(receivedInvites) { invite in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(invite.groupName).font(.subheadline).fontWeight(.bold).foregroundColor(.aquaNavy)
                                Text("Người mời: \(invite.inviterName)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        HStack(spacing: 10) {
                            Button(action: {
                                receivedInvites.removeAll { $0.id == invite.id }
                                showToast("Đã chấp nhận")
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

                            Button(action: {
                                receivedInvites.removeAll { $0.id == invite.id }
                                showToast("Đã từ chối")
                            }) {
                                Text("Từ chối")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.aquaCard)
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 30)
        }
        .padding(.top, 8)
    }

    // MARK: - Member Actions

    private func promoteMember(_ member: GuideTeamMember) {
        if let idx = group.members.firstIndex(where: { $0.id == member.id }) {
            group.members[idx].memberRole = "co_leader"
            showToast("Đã thăng cấp")
        }
    }

    private func demoteMember(_ member: GuideTeamMember) {
        if let idx = group.members.firstIndex(where: { $0.id == member.id }) {
            group.members[idx].memberRole = "member"
            showToast("Đã giáng cấp")
        }
    }

    private func removeMember(_ member: GuideTeamMember) {
        group.members.removeAll { $0.id == member.id }
        showToast("Đã xóa")
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}

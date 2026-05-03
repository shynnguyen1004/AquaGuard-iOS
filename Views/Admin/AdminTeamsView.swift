//
//  AdminTeamsView.swift
//  AquaGuard
//
//  Admin view to see all rescue teams,
//  their members and stats.
//  Uses dummy data.
//

import SwiftUI

struct AdminTeamsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTeam: AdminTeamInfo?
    @State private var showDetail = false

    private let teams = AdminTeamInfo.dummyTeams

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary header
                    HStack(spacing: 12) {
                        teamSummaryPill(value: "\(teams.count)", label: "Teams", color: .purple)
                        teamSummaryPill(
                            value: "\(teams.reduce(0) { $0 + $1.memberCount })",
                            label: "Rescuers", color: .orange)
                        teamSummaryPill(
                            value: "\(teams.reduce(0) { $0 + $1.activeMissions })",
                            label: "Active", color: .blue)
                    }
                    .padding(.horizontal, 16)

                    // Team cards
                    ForEach(teams) { team in
                        teamCard(team)
                            .onTapGesture {
                                selectedTeam = team
                                showDetail = true
                            }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 10)
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Rescue Teams"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDetail) {
                if let team = selectedTeam {
                    teamDetailSheet(team)
                }
            }
        }
    }

    // MARK: - Summary Pill

    private func teamSummaryPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(languageManager.localize(label))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Team Card

    private func teamCard(_ team: AdminTeamInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Team icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "lifepreserver.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(team.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    Text(team.leaderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(team.activeMissions > 0 ? Color.blue : Color.green)
                            .frame(width: 6, height: 6)
                        Text(
                            team.activeMissions > 0
                                ? "\(team.activeMissions) active" : "Idle"
                        )
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
            }

            // Description
            Text(team.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Stats row
            HStack(spacing: 16) {
                miniStat(icon: "person.2.fill", value: "\(team.memberCount)", label: "Members")
                miniStat(
                    icon: "checkmark.seal.fill", value: "\(team.completedMissions)",
                    label: "Completed")
                miniStat(icon: "bolt.fill", value: "\(team.activeMissions)", label: "Active")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.aquaNavy)
            Text(languageManager.localize(label))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Detail Sheet

    private func teamDetailSheet(_ team: AdminTeamInfo) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Team header
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "lifepreserver.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }

                        Text(team.name)
                            .font(.headline)
                            .foregroundColor(.aquaNavy)

                        Text(team.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)

                    // Stats
                    HStack(spacing: 12) {
                        detailStatCard(value: "\(team.memberCount)", label: "Members", color: .blue)
                        detailStatCard(
                            value: "\(team.completedMissions)", label: "Completed", color: .green)
                        detailStatCard(value: "\(team.activeMissions)", label: "Active", color: .orange)
                    }
                    .padding(.horizontal, 16)

                    // Members list
                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.localize("Members"))
                            .font(.headline)
                            .foregroundColor(.aquaNavy)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(Array(team.members.enumerated()), id: \.offset) {
                                index, memberName in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.orange.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(String(memberName.prefix(1)))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.orange)
                                        )

                                    Text(memberName)
                                        .font(.subheadline)
                                        .foregroundColor(.aquaNavy)

                                    Spacer()

                                    if index == 0 {
                                        Text("Leader")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                                if index < team.members.count - 1 {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.aquaCard)
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Team Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDetail = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func detailStatCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(languageManager.localize(label))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Dummy Team Data

struct AdminTeamInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let leaderName: String
    let memberCount: Int
    let completedMissions: Int
    let activeMissions: Int
    let members: [String]

    static let dummyTeams: [AdminTeamInfo] = [
        AdminTeamInfo(
            id: "T1",
            name: "Đội Cứu Hộ Quận 1",
            description: "Đội cứu hộ chuyên trách khu vực Quận 1, TP.HCM. Hoạt động 24/7 trong mùa lũ.",
            leaderName: "Lê Hoàng Phúc",
            memberCount: 5,
            completedMissions: 12,
            activeMissions: 2,
            members: ["Lê Hoàng Phúc", "Trần Minh Tuấn", "Nguyễn Văn Hải", "Phạm Thị Hoa", "Võ Văn Đức"]
        ),
        AdminTeamInfo(
            id: "T2",
            name: "Đội Cứu Hộ Quận 3",
            description: "Phụ trách cứu hộ Quận 3, Quận 10 và khu vực lân cận.",
            leaderName: "Võ Thanh Hà",
            memberCount: 4,
            completedMissions: 8,
            activeMissions: 1,
            members: ["Võ Thanh Hà", "Đặng Quốc Bảo", "Ngô Minh Long", "Bùi Thị Lan"]
        ),
        AdminTeamInfo(
            id: "T3",
            name: "Đội Cứu Hộ Quận 5",
            description: "Chuyên xử lý tình huống ngập lụt khu Chợ Lớn và khu vực Quận 5.",
            leaderName: "Hoàng Văn Tùng",
            memberCount: 3,
            completedMissions: 5,
            activeMissions: 0,
            members: ["Hoàng Văn Tùng", "Lý Minh Trí", "Trương Thành Đạt"]
        ),
        AdminTeamInfo(
            id: "T4",
            name: "Đội Phản Ứng Nhanh TPHCM",
            description: "Đội phản ứng nhanh cấp thành phố, hỗ trợ các đội quận khi cần thiết.",
            leaderName: "Nguyễn Thanh Sơn",
            memberCount: 8,
            completedMissions: 25,
            activeMissions: 3,
            members: [
                "Nguyễn Thanh Sơn", "Phạm Đức Anh", "Lê Thị Ngọc", "Trần Văn Phong",
                "Đỗ Minh Quân", "Vũ Thị Mai", "Hoàng Đình Trung", "Ngô Thanh Tùng",
            ]
        ),
    ]
}

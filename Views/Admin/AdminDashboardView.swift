//
//  AdminDashboardView.swift
//  AquaGuard
//
//  Admin dashboard: Header, Stats Grid (2x2),
//  System Status Card, Rescuer Overview.
//  Matching guide.md spec exactly.
//

import SwiftUI

// MARK: - Admin User Model (guide spec)

struct GuideAdminUser: Identifiable {
    let id: Int
    let displayName: String
    let phoneNumber: String
    let email: String?
    var role: String  // "citizen" | "rescuer" | "admin"
    let avatarUrl: String?
    let createdAt: String
}

extension GuideAdminUser {
    static let dummyUsers: [GuideAdminUser] = [
        GuideAdminUser(id: 1, displayName: "Admin Chính", phoneNumber: "+84900000001", email: "admin@aquaguard.vn", role: "admin", avatarUrl: nil, createdAt: "2025-01-15T08:00:00Z"),
        GuideAdminUser(id: 2, displayName: "Nguyễn Văn A", phoneNumber: "+84901234567", email: nil, role: "rescuer", avatarUrl: nil, createdAt: "2025-02-20T10:30:00Z"),
        GuideAdminUser(id: 3, displayName: "Trần Thị B", phoneNumber: "+84901234568", email: nil, role: "rescuer", avatarUrl: nil, createdAt: "2025-03-10T14:00:00Z"),
        GuideAdminUser(id: 4, displayName: "Lê Văn C", phoneNumber: "+84901234569", email: "levanc@gmail.com", role: "citizen", avatarUrl: nil, createdAt: "2025-03-15T09:00:00Z"),
        GuideAdminUser(id: 5, displayName: "Phạm Thị D", phoneNumber: "+84901234570", email: nil, role: "citizen", avatarUrl: nil, createdAt: "2025-04-01T11:00:00Z"),
        GuideAdminUser(id: 6, displayName: "Hoàng Văn E", phoneNumber: "+84901234571", email: nil, role: "citizen", avatarUrl: nil, createdAt: "2025-04-05T16:00:00Z"),
        GuideAdminUser(id: 7, displayName: "Võ Thị F", phoneNumber: "+84901234572", email: "vothif@gmail.com", role: "rescuer", avatarUrl: nil, createdAt: "2025-04-10T08:30:00Z"),
        GuideAdminUser(id: 8, displayName: "Đặng Minh G", phoneNumber: "+84901234573", email: nil, role: "citizen", avatarUrl: nil, createdAt: "2025-04-12T13:00:00Z"),
    ]
}

// MARK: - View

struct AdminDashboardView: View {
    @EnvironmentObject var languageManager: LanguageManager

    private let users = GuideAdminUser.dummyUsers
    private let requests = SosRequest.dummyRequests

    private var totalUsers: Int { users.count }
    private var citizenCount: Int { users.filter { $0.role == "citizen" }.count }
    private var rescuerCount: Int { users.filter { $0.role == "rescuer" }.count }
    private var adminCount: Int { users.filter { $0.role == "admin" }.count }
    private var pendingCount: Int { requests.filter { $0.status == "pending" }.count }
    private var activeCount: Int { requests.filter { $0.status == "in_progress" || $0.status == "assigned" }.count }
    private var resolvedCount: Int { requests.filter { $0.status == "resolved" }.count }
    private var rescuers: [GuideAdminUser] { users.filter { $0.role == "rescuer" } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Header
                    headerSection

                    // 2. Stats Grid (2x2)
                    statsGrid

                    // 3. System Status Card
                    systemStatusCard

                    // 4. Rescuer Overview
                    rescuerOverview

                    Spacer(minLength: 30)
                }
                .padding(.top, 8)
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quản trị viên ⚙️")
                        .font(.headline)
                        .foregroundColor(.aquaNavy)
                    Text("Admin Chính")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("ADMIN")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            adminStat(icon: "person.2.fill", label: "Tổng người dùng", value: "\(totalUsers)", color: .aquaPrimary)
            adminStat(icon: "person.fill", label: "Công dân", value: "\(citizenCount)", color: .green)
            adminStat(icon: "flame.fill", label: "Cứu hộ", value: "\(rescuerCount)", color: .orange)
            adminStat(icon: "exclamationmark.triangle.fill", label: "SOS đang chờ", value: "\(pendingCount)", color: .red)
        }
        .padding(.horizontal, 16)
    }

    private func adminStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .cornerRadius(8)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.aquaNavy)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - System Status

    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trạng thái hệ thống")
                .font(.headline)
                .foregroundColor(.aquaNavy)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                statusRow(icon: "flame.fill", label: "Rescuers tích cực", value: "\(rescuerCount)", color: .orange)
                Divider().padding(.leading, 52)
                statusRow(icon: "bolt.fill", label: "SOS đang xử lý", value: "\(activeCount)", color: .aquaPrimary)
                Divider().padding(.leading, 52)
                statusRow(icon: "checkmark.circle.fill", label: "Đã giải quyết", value: "\(resolvedCount)", color: .green)
                Divider().padding(.leading, 52)
                statusRow(icon: "shield.checkered", label: "System Admins", value: "\(adminCount)", color: .red)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.aquaCard)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }

    private func statusRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .cornerRadius(8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.aquaNavy)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Rescuer Overview

    private var rescuerOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Đội cứu hộ")
                    .font(.headline)
                    .foregroundColor(.aquaNavy)

                Text("(\(rescuers.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(rescuers.prefix(5).enumerated()), id: \.element.id) { index, rescuer in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(String(rescuer.displayName.prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.orange)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rescuer.displayName).font(.subheadline).fontWeight(.medium).foregroundColor(.aquaNavy)
                            Text(rescuer.phoneNumber).font(.caption).foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("Cứu hộ")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if index < min(rescuers.count, 5) - 1 {
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
}

//
//  AdminUsersView.swift
//  AquaGuard
//
//  Admin user management — list all users,
//  filter by role, change roles.
//  Uses dummy data.
//

import SwiftUI

// MARK: - Dummy User Model

struct AdminUser: Identifiable {
    let id: String
    let name: String
    let phone: String
    var role: UserRole
    let createdAt: Date
    let isActive: Bool
    let gender: String
}

// MARK: - View

struct AdminUsersView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedRoleTab = 0  // 0=All, 1=Citizens, 2=Rescuers, 3=Admins
    @State private var searchText = ""
    @State private var users = AdminUser.dummyUsers
    @State private var selectedUser: AdminUser?
    @State private var showDetail = false

    private var filteredUsers: [AdminUser] {
        var result = users

        // Role filter
        switch selectedRoleTab {
        case 1: result = result.filter { $0.role == .citizen }
        case 2: result = result.filter { $0.role == .rescuer }
        case 3: result = result.filter { $0.role == .admin }
        default: break
        }

        // Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.phone.contains(searchText)
            }
        }

        return result
    }

    private var roleCounts: (all: Int, citizens: Int, rescuers: Int, admins: Int) {
        (
            users.count,
            users.filter { $0.role == .citizen }.count,
            users.filter { $0.role == .rescuer }.count,
            users.filter { $0.role == .admin }.count
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(languageManager.localize("Search users..."), text: $searchText)
                        .font(.subheadline)
                }
                .padding(12)
                .background(Color.aquaInputBg)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Role tabs
                Picker("", selection: $selectedRoleTab) {
                    Text(languageManager.localize("All") + " (\(roleCounts.all))").tag(0)
                    Text(languageManager.localize("Citizens") + " (\(roleCounts.citizens))").tag(1)
                    Text(languageManager.localize("Rescuers") + " (\(roleCounts.rescuers))").tag(2)
                    Text(languageManager.localize("Admins") + " (\(roleCounts.admins))").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // User list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredUsers.enumerated()), id: \.element.id) { index, user in
                            userRow(user)
                                .onTapGesture {
                                    selectedUser = user
                                    showDetail = true
                                }
                            if index < filteredUsers.count - 1 {
                                Divider().padding(.leading, 66)
                            }
                        }

                        if filteredUsers.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "person.slash.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text(languageManager.localize("No users found"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 60)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.aquaCard)
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("User Management"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDetail) {
                if let user = selectedUser {
                    AdminUserDetailSheet(user: user, onRoleChange: { newRole in
                        changeUserRole(user, to: newRole)
                    })
                    .environmentObject(languageManager)
                }
            }
        }
    }

    // MARK: - User Row

    private func userRow(_ user: AdminUser) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(user.role.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(user.role.color)
                    )

                Circle()
                    .fill(user.isActive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.aquaCard, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.aquaNavy)
                Text(user.phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Role badge
            Text(user.role.displayName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(user.role.color)
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func changeUserRole(_ user: AdminUser, to newRole: UserRole) {
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = AdminUser(
                id: user.id, name: user.name, phone: user.phone,
                role: newRole, createdAt: user.createdAt,
                isActive: user.isActive, gender: user.gender
            )
        }
    }
}

// MARK: - User Detail Sheet

struct AdminUserDetailSheet: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    let user: AdminUser
    var onRoleChange: (UserRole) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar + name
                    VStack(spacing: 12) {
                        Circle()
                            .fill(user.role.color.opacity(0.15))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text(String(user.name.prefix(1)))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(user.role.color)
                            )

                        Text(user.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)

                        Text(user.role.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(user.role.color)
                            .cornerRadius(10)
                    }

                    // Info rows
                    VStack(spacing: 0) {
                        detailRow(icon: "phone.fill", label: "Phone", value: user.phone)
                        Divider().padding(.leading, 50)
                        detailRow(icon: "person.fill", label: "Gender", value: user.gender)
                        Divider().padding(.leading, 50)
                        detailRow(
                            icon: "calendar", label: "Joined",
                            value: user.createdAt.formatted(date: .abbreviated, time: .omitted))
                        Divider().padding(.leading, 50)
                        detailRow(
                            icon: "circle.fill", label: "Status",
                            value: user.isActive ? "Active" : "Inactive")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.aquaCard)
                    )
                    .padding(.horizontal, 16)

                    // Change Role
                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.localize("Change Role"))
                            .font(.headline)
                            .foregroundColor(.aquaNavy)
                            .padding(.horizontal, 20)

                        ForEach(UserRole.allCases) { role in
                            Button(action: {
                                onRoleChange(role)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: role.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(role.color)
                                        .cornerRadius(8)

                                    Text(role.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.aquaNavy)

                                    Spacer()

                                    if user.role == role {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(role.color)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            user.role == role
                                                ? role.color.opacity(0.08) : Color.clear)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("User Detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.purple)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(languageManager.localize(label))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.aquaNavy)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Dummy Data

extension AdminUser {
    static let dummyUsers: [AdminUser] = [
        AdminUser(id: "U1", name: "Nguyễn Bảo Khang", phone: "+84 901 234 567", role: .admin,
                  createdAt: Date().addingTimeInterval(-86400 * 365), isActive: true, gender: "Nam"),
        AdminUser(id: "U2", name: "Trần Thị Mai", phone: "+84 912 345 678", role: .citizen,
                  createdAt: Date().addingTimeInterval(-86400 * 200), isActive: true, gender: "Nữ"),
        AdminUser(id: "U3", name: "Lê Hoàng Phúc", phone: "+84 923 456 789", role: .rescuer,
                  createdAt: Date().addingTimeInterval(-86400 * 150), isActive: true, gender: "Nam"),
        AdminUser(id: "U4", name: "Phạm Minh Đức", phone: "+84 934 567 890", role: .citizen,
                  createdAt: Date().addingTimeInterval(-86400 * 120), isActive: false, gender: "Nam"),
        AdminUser(id: "U5", name: "Võ Thanh Hà", phone: "+84 945 678 901", role: .rescuer,
                  createdAt: Date().addingTimeInterval(-86400 * 90), isActive: true, gender: "Nữ"),
        AdminUser(id: "U6", name: "Đặng Quốc Bảo", phone: "+84 956 789 012", role: .citizen,
                  createdAt: Date().addingTimeInterval(-86400 * 60), isActive: true, gender: "Nam"),
        AdminUser(id: "U7", name: "Ngô Thị Hồng", phone: "+84 967 890 123", role: .citizen,
                  createdAt: Date().addingTimeInterval(-86400 * 30), isActive: true, gender: "Nữ"),
        AdminUser(id: "U8", name: "Hoàng Văn Tùng", phone: "+84 978 901 234", role: .rescuer,
                  createdAt: Date().addingTimeInterval(-86400 * 20), isActive: false, gender: "Nam"),
        AdminUser(id: "U9", name: "Bùi Thị Lan", phone: "+84 989 012 345", role: .admin,
                  createdAt: Date().addingTimeInterval(-86400 * 10), isActive: true, gender: "Nữ"),
        AdminUser(id: "U10", name: "Lý Minh Trí", phone: "+84 990 123 456", role: .citizen,
                  createdAt: Date().addingTimeInterval(-86400 * 5), isActive: true, gender: "Nam"),
    ]
}

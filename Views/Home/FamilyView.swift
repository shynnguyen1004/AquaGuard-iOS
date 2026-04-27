//
//  FamilyView.swift
//  AquaGuard
//
//  Family safety network — view connected members' safety status,
//  send friend requests by phone number, accept incoming requests.
//
//  Created by Shyn Nguyễn on 27/04/26.
//

import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var familyMembers = FamilyMember.dummyMembers
    @State private var pendingRequests = FriendRequest.dummyRequests
    @State private var searchPhone = ""
    @State private var showAddSheet = false
    @State private var showRequestSent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Safety Summary
                    safetySummaryCard

                    // MARK: - Pending Requests
                    if !pendingRequests.isEmpty {
                        pendingRequestsSection
                    }

                    // MARK: - Family Members
                    familyMembersSection
                }
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Family Safety"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(languageManager.localize("Back"))
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.aquaPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.aquaPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddFamilySheet(
                    searchPhone: $searchPhone,
                    showRequestSent: $showRequestSent
                )
                .environmentObject(languageManager)
            }
            .alert(languageManager.localize("Request Sent!"), isPresented: $showRequestSent) {
                Button("OK") {}
            } message: {
                Text(languageManager.localize("Your friend request has been sent. They will appear here once they accept."))
            }
        }
    }

    // MARK: - Safety Summary Card

    private var safetySummaryCard: some View {
        let safeCount = familyMembers.filter { $0.status == .safe }.count
        let warningCount = familyMembers.filter { $0.status == .warning || $0.status == .danger }.count

        return VStack(spacing: 12) {
            HStack(spacing: 20) {
                // Safe
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    }
                    Text("\(safeCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    Text(languageManager.localize("Safe"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 60)

                // At Risk
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                    }
                    Text("\(warningCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    Text(languageManager.localize("At Risk"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 60)

                // Total
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.aquaPrimary.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.aquaPrimary)
                    }
                    Text("\(familyMembers.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    Text(languageManager.localize("Total"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.aquaCard)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Pending Requests

    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text(languageManager.localize("Pending Requests"))
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                Spacer()
                Text("\(pendingRequests.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            ForEach(pendingRequests) { request in
                HStack(spacing: 12) {
                    // Avatar
                    Circle()
                        .fill(request.avatarColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(request.avatarInitial)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )

                    // Info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(request.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.aquaNavy)
                        Text(request.phone + " · " + request.timeString)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Accept
                    Button {
                        withAnimation {
                            // Move to family
                            let newMember = FamilyMember(
                                name: request.name,
                                phone: request.phone,
                                avatarInitial: request.avatarInitial,
                                avatarColor: request.avatarColor,
                                status: .safe,
                                location: "Đang cập nhật...",
                                lastSeen: Date(),
                                relationship: "Bạn"
                            )
                            familyMembers.append(newMember)
                            pendingRequests.removeAll { $0.id == request.id }
                        }
                    } label: {
                        Text(languageManager.localize("Accept"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.aquaPrimary)
                            .cornerRadius(16)
                    }

                    // Decline
                    Button {
                        withAnimation {
                            pendingRequests.removeAll { $0.id == request.id }
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(14)
                .background(Color.aquaCard)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Family Members

    private var familyMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.aquaPrimary)
                Text(languageManager.localize("Family Members"))
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                Spacer()
            }
            .padding(.horizontal, 20)

            ForEach(familyMembers) { member in
                FamilyMemberRow(member: member)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Family Member Row

struct FamilyMemberRow: View {
    let member: FamilyMember
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with status ring
            ZStack {
                Circle()
                    .stroke(member.status.color, lineWidth: 3)
                    .frame(width: 52, height: 52)
                Circle()
                    .fill(member.avatarColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(member.avatarInitial)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                // Status dot
                Circle()
                    .fill(member.status.color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.aquaCard, lineWidth: 2))
                    .offset(x: 18, y: 18)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.aquaNavy)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: member.status.icon)
                        .font(.system(size: 10))
                        .foregroundColor(member.status.color)
                    Text(member.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(member.status.color)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 9))
                    Text(member.location)
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Right side
            VStack(alignment: .trailing, spacing: 6) {
                Text(member.lastSeenString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                // Relationship badge
                Text(member.relationship)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.aquaPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.aquaPrimary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.aquaCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Add Family Sheet

struct AddFamilySheet: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var searchPhone: String
    @Binding var showRequestSent: Bool

    // Dummy search result
    @State private var searchResult: (name: String, phone: String)? = nil
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Illustration
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.aquaPrimary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.aquaPrimary)
                    }
                    Text(languageManager.localize("Add Family Member"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    Text(languageManager.localize("Enter their phone number to send a safety connection request"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 20)

                // Phone search
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.aquaPrimary)
                        TextField(languageManager.localize("Phone number"), text: $searchPhone)
                            .keyboardType(.phonePad)
                            .font(.system(size: 16))
                    }
                    .padding(14)
                    .background(Color.aquaCard)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.aquaPrimary.opacity(0.3), lineWidth: 1)
                    )

                    Button {
                        // Simulate search
                        isSearching = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if searchPhone.count >= 9 {
                                searchResult = (name: "Nguyễn Văn Tùng", phone: searchPhone)
                            } else {
                                searchResult = nil
                            }
                            isSearching = false
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Color.aquaPrimary)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)

                // Search result
                if isSearching {
                    ProgressView()
                        .padding(.top, 20)
                } else if let result = searchResult {
                    // Found user
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.aquaPrimary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("T")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(result.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.aquaNavy)
                            Text(result.phone)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            showRequestSent = true
                            searchPhone = ""
                            searchResult = nil
                            dismiss()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 12))
                                Text(languageManager.localize("Send Request"))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.aquaPrimary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(16)
                    .background(Color.aquaCard)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.aquaPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                } else if !searchPhone.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.slash.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(languageManager.localize("No user found"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }

                Spacer()
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Add Member"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localize("Close")) {
                        dismiss()
                    }
                    .foregroundColor(.aquaPrimary)
                }
            }
        }
    }
}

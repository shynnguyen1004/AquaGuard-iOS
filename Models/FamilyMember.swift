//
//  FamilyMember.swift
//  AquaGuard
//
//  Model for family/friends safety network.
//  Users connect via phone number and track each other's safety status.
//

import Foundation
import SwiftUI

// MARK: - Safety Status

enum SafetyStatus: String, CaseIterable {
    case safe = "Safe"
    case warning = "In Warning Zone"
    case danger = "In Danger Zone"
    case unknown = "Unknown"
    case sos = "SOS Sent"

    var color: Color {
        switch self {
        case .safe: return .green
        case .warning: return .orange
        case .danger: return .red
        case .unknown: return .gray
        case .sos: return .red
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "exclamationmark.octagon.fill"
        case .unknown: return "questionmark.circle.fill"
        case .sos: return "sos.circle.fill"
        }
    }
}

// MARK: - Family Member

struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let avatarInitial: String
    let avatarColor: Color
    let status: SafetyStatus
    let location: String
    let lastSeen: Date
    let relationship: String

    var lastSeenString: String {
        let interval = Date().timeIntervalSince(lastSeen)
        if interval < 60 { return "Vừa xong" }
        if interval < 3600 { return "\(Int(interval / 60)) phút trước" }
        if interval < 86400 { return "\(Int(interval / 3600)) giờ trước" }
        return "\(Int(interval / 86400)) ngày trước"
    }
}

// MARK: - Friend Request

struct FriendRequest: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let avatarInitial: String
    let avatarColor: Color
    let sentAt: Date

    var timeString: String {
        let interval = Date().timeIntervalSince(sentAt)
        if interval < 3600 { return "\(Int(interval / 60)) phút trước" }
        if interval < 86400 { return "\(Int(interval / 3600)) giờ trước" }
        return "\(Int(interval / 86400)) ngày trước"
    }
}

// MARK: - Dummy Data

extension FamilyMember {
    static let dummyMembers: [FamilyMember] = [
        FamilyMember(
            name: "Mẹ - Nguyễn Thị Hoa",
            phone: "0901 234 567",
            avatarInitial: "M",
            avatarColor: Color(red: 0.9, green: 0.4, blue: 0.5),
            status: .safe,
            location: "Quận 1, TP.HCM",
            lastSeen: Date().addingTimeInterval(-300),
            relationship: "Mẹ"
        ),
        FamilyMember(
            name: "Ba - Nguyễn Văn Nam",
            phone: "0912 345 678",
            avatarInitial: "B",
            avatarColor: Color(red: 0.3, green: 0.5, blue: 0.8),
            status: .warning,
            location: "Quận Bình Thạnh, TP.HCM",
            lastSeen: Date().addingTimeInterval(-1800),
            relationship: "Ba"
        ),
        FamilyMember(
            name: "Em gái - Nguyễn Thị Lan",
            phone: "0923 456 789",
            avatarInitial: "L",
            avatarColor: Color(red: 0.6, green: 0.4, blue: 0.8),
            status: .safe,
            location: "ĐHBK TP.HCM, Quận 10",
            lastSeen: Date().addingTimeInterval(-600),
            relationship: "Em gái"
        ),
        FamilyMember(
            name: "Bạn - Trần Minh Đức",
            phone: "0934 567 890",
            avatarInitial: "Đ",
            avatarColor: Color(red: 0.2, green: 0.7, blue: 0.6),
            status: .danger,
            location: "Quận 7, TP.HCM",
            lastSeen: Date().addingTimeInterval(-120),
            relationship: "Bạn thân"
        ),
    ]
}

extension FriendRequest {
    static let dummyRequests: [FriendRequest] = [
        FriendRequest(
            name: "Phạm Thu Hà",
            phone: "0945 678 901",
            avatarInitial: "H",
            avatarColor: Color(red: 0.95, green: 0.6, blue: 0.3),
            sentAt: Date().addingTimeInterval(-7200)
        ),
        FriendRequest(
            name: "Lê Hoàng Anh",
            phone: "0956 789 012",
            avatarInitial: "A",
            avatarColor: Color(red: 0.4, green: 0.6, blue: 0.9),
            sentAt: Date().addingTimeInterval(-18000)
        ),
    ]
}

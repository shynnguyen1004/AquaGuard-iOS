//
//  APIModels.swift
//  AquaGuard
//
//  Decodable models matching the backend's JSON response format.
//  All backend responses follow: { success: Bool, message: String?, data: T? }
//

import Foundation

// MARK: - Generic API Response

/// Wraps every backend response.  Usage:
///   let response: APIResponse<User> = try await api.get("/auth/profile")
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?
}

/// For endpoints that return no meaningful data (e.g. DELETE)
struct EmptyData: Decodable {}

// MARK: - Live Location

/// One user's live position from GET /api/locations/live/:userId.
/// Redis (online) and Postgres fallback (last known) both return lat/lng;
/// `data` is null when the user has no stored position at all.
struct APILiveLocation: Decodable {
    let userId: Int?
    let lat: Double
    let lng: Double
    let online: Bool?
}

// MARK: - Auth Models

struct AuthData: Decodable {
    let user: APIUser
    let accessToken: String
}

/// User object as returned by the backend
struct APIUser: Codable {
    let id: Int
    let phoneNumber: String
    let displayName: String
    let role: String
    let avatarUrl: String

    // Optional fields (from /profile endpoint)
    var email: String?
    var gender: String?
    var dateOfBirth: String?
    var emergencyContact: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var locationUpdatedAt: String?
    var isActive: Bool?
    var createdAt: String?
    var updatedAt: String?

    /// Convenience — maps role string to UserRole enum
    var userRole: UserRole {
        UserRole(rawValue: role) ?? .citizen
    }
}

// MARK: - SOS / Rescue Request Models

/// Rescue request as returned by GET /api/sos/*
struct APIRescueRequest: Decodable, Identifiable {
    let id: Int
    let userId: Int?
    let location: String?
    let description: String?
    let latitude: Double?
    let longitude: Double?
    let images: [String]?
    let urgency: String?
    let status: String
    let assignedTo: Int?
    let assignedGroupId: Int?
    let acceptedMode: String?
    let rescuerLatitude: Double?
    let rescuerLongitude: Double?
    let createdAt: String?
    let updatedAt: String?
    let assignedAt: String?
    let resolvedAt: String?
    let lastCancelledBy: Int?
    let lastCancelledAt: String?

    // Joined fields — all optional (not all endpoints return these)
    let userName: String?
    let userPhone: String?
    let userGender: String?
    let userDateOfBirth: String?
    let userAge: Int?
    let userAddress: String?
    let assignedName: String?
    let assignedGroupName: String?
    let lastCancelledByName: String?

    enum CodingKeys: String, CodingKey {
        case id, location, description, latitude, longitude, images, urgency, status
        case userId, assignedTo, assignedGroupId, acceptedMode
        case rescuerLatitude, rescuerLongitude
        case createdAt, updatedAt, assignedAt, resolvedAt
        case lastCancelledBy, lastCancelledAt
        case userName, userPhone, userGender, userDateOfBirth, userAge, userAddress
        case assignedName, assignedGroupName, lastCancelledByName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        userId = try c.decodeIfPresent(Int.self, forKey: .userId)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        urgency = try c.decodeIfPresent(String.self, forKey: .urgency)
        status = try c.decode(String.self, forKey: .status)
        assignedTo = try c.decodeIfPresent(Int.self, forKey: .assignedTo)
        assignedGroupId = try c.decodeIfPresent(Int.self, forKey: .assignedGroupId)
        acceptedMode = try c.decodeIfPresent(String.self, forKey: .acceptedMode)
        rescuerLatitude = try c.decodeIfPresent(Double.self, forKey: .rescuerLatitude)
        rescuerLongitude = try c.decodeIfPresent(Double.self, forKey: .rescuerLongitude)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        assignedAt = try c.decodeIfPresent(String.self, forKey: .assignedAt)
        resolvedAt = try c.decodeIfPresent(String.self, forKey: .resolvedAt)
        lastCancelledBy = try c.decodeIfPresent(Int.self, forKey: .lastCancelledBy)
        lastCancelledAt = try c.decodeIfPresent(String.self, forKey: .lastCancelledAt)
        userName = try c.decodeIfPresent(String.self, forKey: .userName)
        userPhone = try c.decodeIfPresent(String.self, forKey: .userPhone)
        userGender = try c.decodeIfPresent(String.self, forKey: .userGender)
        userDateOfBirth = try c.decodeIfPresent(String.self, forKey: .userDateOfBirth)
        userAge = try c.decodeIfPresent(Int.self, forKey: .userAge)
        userAddress = try c.decodeIfPresent(String.self, forKey: .userAddress)
        assignedName = try c.decodeIfPresent(String.self, forKey: .assignedName)
        assignedGroupName = try c.decodeIfPresent(String.self, forKey: .assignedGroupName)
        lastCancelledByName = try c.decodeIfPresent(String.self, forKey: .lastCancelledByName)

        // ── Flexible images parsing ──
        // Backend may return images as:
        //   1. JSON array:   ["url1","url2"]
        //   2. JSON string:  "[\"url1\",\"url2\"]"
        //   3. Postgres literal: "{url1,url2}"
        //   4. Single string: "url1"
        //   5. null
        if let arr = try? c.decodeIfPresent([String].self, forKey: .images) {
            images = arr
        } else if let str = try? c.decodeIfPresent(String.self, forKey: .images) {
            // Try JSON-encoded string: "[\"url1\",\"url2\"]"
            if str.hasPrefix("["),
               let data = str.data(using: .utf8),
               let parsed = try? JSONDecoder().decode([String].self, from: data) {
                images = parsed
            }
            // Try Postgres array literal: "{url1,url2}"
            else if str.hasPrefix("{") && str.hasSuffix("}") {
                let inner = String(str.dropFirst().dropLast())
                images = inner.isEmpty ? [] : inner.components(separatedBy: ",").map {
                    $0.trimmingCharacters(in: .init(charactersIn: "\" "))
                }
            }
            // Single URL string
            else if !str.isEmpty {
                images = [str]
            } else {
                images = nil
            }
        } else {
            images = nil
        }

        if let imgs = images, !imgs.isEmpty {
            print("[APIRescueRequest] 🖼️ #\(id) decoded images: \(imgs)")
        }
    }

    // MARK: Computed

    var sosStatus: SOSStatus {
        switch status {
        case "pending": return .pending
        case "assigned": return .pending   // treat assigned as pending for citizen view
        case "in_progress": return .inProgress
        case "resolved": return .resolved
        case "cancelled": return .cancelled
        default: return .pending
        }
    }

    var createdDate: Date {
        guard let dateStr = createdAt else { return Date() }
        // Try ISO8601 first, then fallback to common Postgres format
        if let date = ISO8601DateFormatter().date(from: dateStr) { return date }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateStr) { return date }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateStr) ?? Date()
    }

    /// Backend uses snake_case, but our Codable pipeline handles camelCase via decoder
}

/// Stats returned by GET /api/sos/stats
struct SOSStats: Decodable {
    let pending: Int
    let inProgress: Int
    let resolved: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case pending
        case inProgress = "in_progress"
        case resolved
        case total
    }
}

// MARK: - Family Models

struct APIFamilyMember: Decodable, Identifiable {
    let connectionId: Int
    let id: Int
    let phoneNumber: String
    let displayName: String
    let avatarUrl: String
    let relation: String
    let safetyStatus: String
    let healthNote: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let locationUpdatedAt: String?
}

struct APIFamilyRequest: Decodable, Identifiable {
    let id: Int
    let relation: String
    let createdAt: String
    let from: APIFamilyRequestUser
}

// MARK: - Notifications

/// One in-app notification from GET /api/notifications.
/// `type` drives the icon/color; `metadata` is free-form JSON we don't decode.
struct APINotification: Decodable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let body: String?
    let isRead: Bool
    let createdAt: String
}

struct APIFamilyRequestUser: Decodable {
    let id: Int
    let phoneNumber: String
    let displayName: String
    let avatarUrl: String
}

struct APIFamilySearchResult: Decodable {
    let id: Int
    let phoneNumber: String
    let displayName: String
    let avatarUrl: String
    let safetyStatus: String
}

// MARK: - Rescue Group Models

struct APIRescueGroupData: Decodable {
    let group: APIRescueGroup?
    let canAcceptMission: Bool
    let pendingInvites: [APIGroupInvite]
}

struct APIRescueGroup: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let createdBy: Int?
    let leaderId: Int?
    let memberRole: String?
    let joinedAt: String?
    let status: String
    let createdAt: String?
    let updatedAt: String?
    let members: [APIGroupMember]?
    let pendingInvites: [APIGroupPendingInvite]?
}

struct APIGroupMember: Decodable, Identifiable {
    let id: Int
    let displayName: String
    let phoneNumber: String
    let avatarUrl: String
    let isActive: Bool
    let memberRole: String
    let joinStatus: String
    let joinedAt: String?
}

struct APIGroupPendingInvite: Decodable, Identifiable {
    let id: Int
    let phoneNumber: String
    let status: String
    let createdAt: String?
    let userId: Int?
    let displayName: String
    let avatarUrl: String
}

struct APIGroupInvite: Decodable, Identifiable {
    let id: Int
    let status: String
    let createdAt: String?
    let group: APIGroupInviteGroup
    let inviter: APIGroupInviter
}

struct APIGroupInviteGroup: Decodable {
    let id: Int
    let name: String
    let description: String
}

struct APIGroupInviter: Decodable {
    let id: Int
    let displayName: String
    let phoneNumber: String
}

struct APIGroupStats: Decodable {
    let activeMissions: Int
    let completedMissions: Int
    let pendingMissions: Int
    let teamSize: Int
}

// MARK: - Analytics Models (Admin)

struct APIAnalyticsOverview: Decodable {
    let totalUsers: Int
    let newUsers7d: Int
    let totalRequests: Int
    let pendingRequests: Int
    let activeRequests: Int
    let resolvedRequests: Int
    let avgResponseMinutes: Int
    let resolutionRate: Int
}

struct APIUserAnalytics: Decodable {
    let growth: [APIGrowthPoint]
    let roles: [APIRoleCount]
}

struct APIGrowthPoint: Decodable {
    let date: String
    let count: Int
}

struct APIRoleCount: Decodable {
    let role: String
    let count: Int
}

struct APIRescueAnalytics: Decodable {
    let trend: [APIGrowthPoint]
    let urgency: [APIUrgencyCount]
    let status: [APIStatusCount]
    let performance: APIPerformance
}

struct APIUrgencyCount: Decodable {
    let urgency: String
    let count: Int
}

struct APIStatusCount: Decodable {
    let status: String
    let count: Int
}

struct APIPerformance: Decodable {
    let fastest: Int
    let slowest: Int
    let average: Int
}

// MARK: - OTP / Password Reset

struct OTPVerifyData: Decodable {
    let sessionToken: String
}

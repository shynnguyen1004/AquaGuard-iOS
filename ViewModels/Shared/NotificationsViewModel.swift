//
//  NotificationsViewModel.swift
//  AquaGuard
//
//  ViewModel for in-app notifications.
//  Fetches the current user's notifications, tracks unread count,
//  and marks them read (single / all) via /api/notifications.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {

    @Published var notifications: [APINotification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Number of unread notifications (derived from the fetched list).
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    // MARK: - Fetch

    func fetch() {
        guard TokenManager.shared.isAuthenticated else { return }
        isLoading = true

        Task {
            do {
                let response: APIResponse<[APINotification]> =
                    try await APIService.shared.getRaw("/notifications")
                if let items = response.data {
                    self.notifications = items
                    print("[NotificationsVM] Loaded \(items.count) notifications")
                }
                self.isLoading = false
            } catch {
                print("[NotificationsVM] ❌ Failed to fetch: \(error)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Mark read

    func markRead(id: Int) {
        // Optimistic update
        replaceRead(id: id)

        Task {
            do {
                let _: APIResponse<EmptyData> =
                    try await APIService.shared.putRaw("/notifications/\(id)/read")
            } catch {
                print("[NotificationsVM] ❌ Mark read failed: \(error)")
            }
        }
    }

    func markAllRead() {
        guard unreadCount > 0 else { return }
        // Optimistic update
        notifications = notifications.map { replacingRead($0) }

        Task {
            do {
                let _: APIResponse<EmptyData> =
                    try await APIService.shared.putRaw("/notifications/read-all")
            } catch {
                print("[NotificationsVM] ❌ Mark all read failed: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func replaceRead(id: Int) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }),
              !notifications[idx].isRead else { return }
        notifications[idx] = replacingRead(notifications[idx])
    }

    private func replacingRead(_ n: APINotification) -> APINotification {
        guard !n.isRead else { return n }
        return APINotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt
        )
    }
}

// MARK: - Presentation helpers

extension APINotification {
    /// SF Symbol chosen from the notification `type`.
    var iconName: String {
        switch type {
        case "sos_accepted", "tracking_started":
            return "figure.wave"
        case "sos_resolved", "family_sos_resolved":
            return "checkmark.circle.fill"
        case "tracking_cancelled", "tracking_ended":
            return "xmark.circle.fill"
        case "flood_alert":
            return "exclamationmark.triangle.fill"
        case "admin_announcement":
            return "megaphone.fill"
        default:
            return "bell.fill"
        }
    }

    /// Accent color chosen from the notification `type`.
    var iconColor: Color {
        switch type {
        case "sos_accepted", "tracking_started":
            return .orange
        case "sos_resolved", "family_sos_resolved":
            return .green
        case "tracking_cancelled", "tracking_ended":
            return .red
        case "flood_alert":
            return Color(red: 0.94, green: 0.27, blue: 0.27)
        case "admin_announcement":
            return .aquaPrimary
        default:
            return .aquaPrimary
        }
    }

    /// Short relative time string (e.g. "2d ago") from `createdAt`.
    var relativeTimeString: String {
        guard let date = Self.parseDate(createdAt) else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}

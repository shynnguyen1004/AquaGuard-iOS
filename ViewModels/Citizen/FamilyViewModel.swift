//
//  FamilyViewModel.swift
//  AquaGuard
//
//  ViewModel for family safety features.
//  Fetches members, pending requests from backend API.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class FamilyViewModel: ObservableObject {

    @Published var familyMembers: [FamilyMember] = []
    @Published var pendingRequests: [APIFamilyRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Search
    @Published var searchResult: APIFamilySearchResult?
    @Published var isSearching: Bool = false
    @Published var searchError: String?

    // MARK: - Fetch Family Members

    func fetchMembers() {
        guard TokenManager.shared.isAuthenticated else { return }
        isLoading = true

        Task {
            do {
                let response: APIResponse<[APIFamilyMember]> = try await APIService.shared.getRaw("/family/members")
                if let apiMembers = response.data {
                    self.familyMembers = apiMembers.map { m in
                        let safetyStatus: SafetyStatus = {
                            switch m.safetyStatus {
                            case "safe": return .safe
                            case "danger": return .danger
                            case "injured": return .sos
                            default: return .unknown
                            }
                        }()

                        let initial = String(m.displayName.prefix(1)).uppercased()
                        let color = Self.colorForName(m.displayName)

                        return FamilyMember(
                            name: m.relation.isEmpty ? m.displayName : "\(m.relation) - \(m.displayName)",
                            phone: m.phoneNumber,
                            avatarInitial: initial,
                            avatarColor: color,
                            status: safetyStatus,
                            location: m.address.isEmpty ? "Chưa cập nhật" : m.address,
                            latitude: m.latitude ?? 0,
                            longitude: m.longitude ?? 0,
                            lastSeen: Self.parseDate(m.locationUpdatedAt) ?? Date(),
                            relationship: m.relation.isEmpty ? "Gia đình" : m.relation
                        )
                    }
                    print("[FamilyVM] Loaded \(self.familyMembers.count) members")
                }
                self.isLoading = false
            } catch {
                print("[FamilyVM] ❌ Failed to fetch members: \(error)")
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch Pending Requests

    func fetchPendingRequests() {
        guard TokenManager.shared.isAuthenticated else { return }

        Task {
            do {
                let response: APIResponse<[APIFamilyRequest]> = try await APIService.shared.getRaw("/family/requests")
                if let requests = response.data {
                    self.pendingRequests = requests
                    print("[FamilyVM] Loaded \(requests.count) pending requests")
                }
            } catch {
                print("[FamilyVM] ❌ Failed to fetch requests: \(error)")
            }
        }
    }

    // MARK: - Search by Phone

    func searchByPhone(_ phone: String) {
        guard TokenManager.shared.isAuthenticated else { return }
        guard phone.count >= 9 else {
            searchResult = nil
            searchError = "Số điện thoại quá ngắn"
            return
        }

        isSearching = true
        searchError = nil
        searchResult = nil

        Task {
            do {
                let response: APIResponse<APIFamilySearchResult> = try await APIService.shared.getRaw("/family/search?phone=\(phone)")
                if response.success, let result = response.data {
                    self.searchResult = result
                } else {
                    self.searchResult = nil
                    self.searchError = response.message ?? "Không tìm thấy người dùng"
                }
                self.isSearching = false
            } catch {
                self.searchError = error.localizedDescription
                self.isSearching = false
            }
        }
    }

    // MARK: - Send Request

    func sendRequest(receiverId: Int, relation: String) {
        guard TokenManager.shared.isAuthenticated else { return }

        Task {
            do {
                let body: [String: Any] = [
                    "receiver_id": receiverId,
                    "relation": relation,
                ]
                let _: APIResponse<EmptyData> = try await APIService.shared.postRaw("/family/request", body: body)
                self.searchResult = nil
            } catch {
                print("[FamilyVM] ❌ Send request failed: \(error)")
            }
        }
    }

    // MARK: - Accept / Reject

    func acceptRequest(id: Int) {
        Task {
            do {
                let _: APIResponse<EmptyData> = try await APIService.shared.putRaw("/family/requests/\(id)/accept")
                // Refresh both lists
                fetchMembers()
                fetchPendingRequests()
            } catch {
                print("[FamilyVM] ❌ Accept failed: \(error)")
            }
        }
    }

    func rejectRequest(id: Int) {
        Task {
            do {
                let _: APIResponse<EmptyData> = try await APIService.shared.putRaw("/family/requests/\(id)/reject")
                fetchPendingRequests()
            } catch {
                print("[FamilyVM] ❌ Reject failed: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private static func colorForName(_ name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.9, green: 0.4, blue: 0.5),
            Color(red: 0.3, green: 0.5, blue: 0.8),
            Color(red: 0.6, green: 0.4, blue: 0.8),
            Color(red: 0.2, green: 0.7, blue: 0.6),
            Color(red: 0.95, green: 0.6, blue: 0.3),
            Color(red: 0.4, green: 0.6, blue: 0.9),
        ]
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }

    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateStr = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateStr)
    }
}

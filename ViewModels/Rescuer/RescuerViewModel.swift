//
//  RescuerViewModel.swift
//  AquaGuard
//
//  ViewModel for Rescuer role — fetches SOS requests from backend,
//  handles accept/complete/cancel actions via API.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RescuerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var requests: [SosRequest] = []
    @Published var teamName: String? = nil
    @Published var isLoading = false
    @Published var isActioning = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let api = APIService.shared

    /// Which endpoint last populated `requests` — accept/complete/cancel refresh
    /// through this so a team-scoped list doesn't get silently replaced by the
    /// system-wide one (or vice versa).
    private enum FetchSource { case all, team }
    private var lastFetchSource: FetchSource = .all

    private func refreshCurrentSource() {
        switch lastFetchSource {
        case .all: fetchAllRequests()
        case .team: fetchTeamRequests()
        }
    }

    // MARK: - Computed

    var allRequests: [SosRequest] { requests }
    var pendingRequests: [SosRequest] { requests.filter { $0.status == "pending" } }
    var assignedRequests: [SosRequest] { requests.filter { $0.status == "assigned" } }
    var inProgressRequests: [SosRequest] { requests.filter { $0.status == "in_progress" || $0.status == "assigned" } }
    var resolvedRequests: [SosRequest] { requests.filter { $0.status == "resolved" } }

    var rescuerDisplayName: String {
        TokenManager.shared.currentUser?.displayName ?? "Rescuer"
    }

    // MARK: - Fetch All Requests

    /// Fetch all SOS requests (for the "Yêu cầu" tab)
    func fetchAllRequests() {
        guard TokenManager.shared.isAuthenticated else { return }
        isLoading = true
        lastFetchSource = .all

        Task {
            do {
                let response: APIResponse<[APIRescueRequest]> = try await api.getRaw("/sos/all")
                if let apiRequests = response.data {
                    self.requests = apiRequests.map { Self.mapToSosRequest($0) }
                    print("[RescuerVM] Loaded \(self.requests.count) requests from /sos/all")
                }
                self.isLoading = false
            } catch {
                print("[RescuerVM] ❌ fetchAllRequests: \(error)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Fetch team-assigned requests (for the "Nhiệm vụ" tab).
    /// Only requests with `assigned_group_id` = the rescuer's team show up here —
    /// unlike `/sos/all`, this never includes other teams' or unassigned work.
    func fetchTeamRequests() {
        guard TokenManager.shared.isAuthenticated else { return }
        isLoading = true
        lastFetchSource = .team

        Task {
            do {
                let response: APIResponse<[APIRescueRequest]> = try await api.getRaw("/sos/team")
                if let apiRequests = response.data {
                    self.requests = apiRequests.map { Self.mapToSosRequest($0) }
                    // The top-level `group` field isn't decoded by our generic APIResponse envelope,
                    // but every row already carries assigned_group_name — reuse it instead.
                    self.teamName = apiRequests.first?.assignedGroupName
                    print("[RescuerVM] Loaded \(self.requests.count) team requests")
                }
                self.isLoading = false
            } catch {
                print("[RescuerVM] ❌ fetchTeamRequests: \(error)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Actions

    /// Accept a pending request → in_progress
    func acceptRequest(_ request: SosRequest, latitude: Double? = nil, longitude: Double? = nil) {
        isActioning = true

        Task {
            do {
                var body: [String: Any] = [:]
                if let lat = latitude { body["latitude"] = lat }
                if let lng = longitude { body["longitude"] = lng }

                let _: APIRescueRequest = try await api.put("/sos/\(request.id)/accept", body: body)

                // Refresh list after action
                self.refreshCurrentSource()
                self.isActioning = false
                print("[RescuerVM] ✅ Accepted request #\(request.id)")
            } catch {
                print("[RescuerVM] ❌ acceptRequest: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    /// Complete an in_progress request → resolved
    func completeRequest(_ request: SosRequest) {
        isActioning = true

        Task {
            do {
                let _: APIRescueRequest = try await api.put("/sos/\(request.id)/complete", body: [:])

                self.refreshCurrentSource()
                self.isActioning = false
                print("[RescuerVM] ✅ Completed request #\(request.id)")
            } catch {
                print("[RescuerVM] ❌ completeRequest: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    /// Cancel an in_progress request → back to pending
    func cancelRequest(_ request: SosRequest) {
        isActioning = true

        Task {
            do {
                let _: APIRescueRequest = try await api.put("/sos/\(request.id)/cancel", body: [:])

                self.refreshCurrentSource()
                self.isActioning = false
                print("[RescuerVM] ✅ Cancelled request #\(request.id)")
            } catch {
                print("[RescuerVM] ❌ cancelRequest: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Mapping

    /// Map backend APIRescueRequest → local SosRequest for UI
    static func mapToSosRequest(_ r: APIRescueRequest) -> SosRequest {
        let validImageURLs = (r.images ?? []).filter { !$0.isEmpty && URL(string: $0) != nil }
        return SosRequest(
            id: r.id,
            userName: r.userName ?? "Unknown",
            description: r.description,
            location: r.location,
            latitude: r.latitude,
            longitude: r.longitude,
            urgency: r.urgency ?? "medium",
            status: r.status,
            assignedName: r.assignedName ?? r.assignedGroupName,
            assignedGroupName: r.assignedGroupName,
            createdAt: r.createdAt ?? "",
            images: validImageURLs,
            userAge: r.userAge,
            userGender: r.userGender
        )
    }
}

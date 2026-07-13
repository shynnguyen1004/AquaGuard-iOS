//
//  RescuerTeamViewModel.swift
//  AquaGuard
//
//  ViewModel for Rescuer Team management — fetches group data,
//  handles invite/accept/decline/promote/demote/remove/leave/disband actions.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RescuerTeamViewModel: ObservableObject {

    // MARK: - Published State

    @Published var groupData: APIRescueGroupData?
    @Published var allRescuers: [APIRescuerDirectory] = []
    @Published var isLoading = false
    @Published var isActioning = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Dependencies

    private let api = APIService.shared

    // MARK: - Computed

    var hasTeam: Bool {
        groupData?.group != nil
    }

    var group: APIRescueGroup? {
        groupData?.group
    }

    var members: [APIGroupMember] {
        groupData?.group?.members ?? []
    }

    var pendingOutgoingInvites: [APIGroupPendingInvite] {
        groupData?.group?.pendingInvites ?? []
    }

    var receivedInvites: [APIGroupInvite] {
        groupData?.pendingInvites ?? []
    }

    var myRole: String {
        groupData?.group?.memberRole ?? "member"
    }

    var isLeaderOrCoLeader: Bool {
        myRole == "leader" || myRole == "co_leader"
    }

    // MARK: - Fetch My Group

    func fetchMyGroup() {
        guard TokenManager.shared.isAuthenticated else { return }
        isLoading = true

        Task {
            do {
                let response: APIResponse<APIRescueGroupData> = try await api.getRaw("/auth/rescue-groups/my")
                if let data = response.data {
                    self.groupData = data
                    print("[TeamVM] Group: \(data.group?.name ?? "none"), members: \(data.group?.members?.count ?? 0), invites: \(data.pendingInvites.count)")
                }
                self.isLoading = false
            } catch {
                print("[TeamVM] ❌ fetchMyGroup: \(error)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch Rescuers Directory

    func fetchRescuers() {
        guard TokenManager.shared.isAuthenticated else { return }

        Task {
            do {
                let response: APIResponse<[APIRescuerDirectory]> = try await api.getRaw("/auth/rescuers")
                if let data = response.data {
                    self.allRescuers = data
                    print("[TeamVM] Loaded \(data.count) rescuers in directory")
                }
            } catch {
                print("[TeamVM] ❌ fetchRescuers: \(error)")
            }
        }
    }

    // MARK: - Create Team

    func createTeam(name: String, description: String) {
        isActioning = true

        Task {
            do {
                let body: [String: Any] = [
                    "name": name,
                    "description": description
                ]
                let response: APIResponse<APIRescueGroupData> = try await api.postRaw("/auth/rescue-groups", body: body)
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã tạo đội thành công"
            } catch {
                print("[TeamVM] ❌ createTeam: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Update Team Info

    /// Edit the group's name/description. Backend restricts this to the leader
    /// (PUT /auth/rescue-groups/:id — 403s for anyone else, including co_leader).
    func updateGroup(name: String, description: String) {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let body: [String: Any] = [
                    "name": name,
                    "description": description
                ]
                let response: APIResponse<APIRescueGroupData> = try await api.putRaw("/auth/rescue-groups/\(groupId)", body: body)
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã cập nhật thông tin đội"
            } catch {
                print("[TeamVM] ❌ updateGroup: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Invite by Phone

    func inviteByPhone(_ phone: String) {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let body: [String: Any] = ["phone_number": phone]
                let response: APIResponse<APIRescueGroupData> = try await api.postRaw("/auth/rescue-groups/\(groupId)/invite", body: body)
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã gửi lời mời"
            } catch {
                print("[TeamVM] ❌ invite: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Accept Invite

    func acceptInvite(_ invite: APIGroupInvite) {
        isActioning = true

        Task {
            do {
                let response: APIResponse<APIRescueGroupData> = try await api.postRaw("/auth/rescue-group-invites/\(invite.id)/accept")
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã chấp nhận lời mời"
            } catch {
                print("[TeamVM] ❌ acceptInvite: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Decline Invite

    func declineInvite(_ invite: APIGroupInvite) {
        isActioning = true

        Task {
            do {
                let response: APIResponse<APIRescueGroupData> = try await api.postRaw("/auth/rescue-group-invites/\(invite.id)/decline")
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã từ chối lời mời"
            } catch {
                print("[TeamVM] ❌ declineInvite: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Promote Member

    func promoteMember(_ member: APIGroupMember) {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let body: [String: Any] = ["role": "co_leader"]
                let response: APIResponse<APIRescueGroupData> = try await api.putRaw("/auth/rescue-groups/\(groupId)/members/\(member.id)/role", body: body)
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã thăng cấp"
            } catch {
                print("[TeamVM] ❌ promote: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Demote Member

    func demoteMember(_ member: APIGroupMember) {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let body: [String: Any] = ["role": "member"]
                let response: APIResponse<APIRescueGroupData> = try await api.putRaw("/auth/rescue-groups/\(groupId)/members/\(member.id)/role", body: body)
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã giáng cấp"
            } catch {
                print("[TeamVM] ❌ demote: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Remove Member

    func removeMember(_ member: APIGroupMember) {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let response: APIResponse<APIRescueGroupData> = try await api.deleteRaw("/auth/rescue-groups/\(groupId)/members/\(member.id)") as APIResponse<APIRescueGroupData>
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã xóa thành viên"
            } catch {
                print("[TeamVM] ❌ remove: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Leave Group

    func leaveGroup() {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let response: APIResponse<APIRescueGroupData> = try await api.postRaw("/auth/rescue-groups/\(groupId)/leave")
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã rời nhóm"
            } catch {
                print("[TeamVM] ❌ leave: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }

    // MARK: - Disband Group

    func disbandGroup() {
        guard let groupId = group?.id else { return }
        isActioning = true

        Task {
            do {
                let response: APIResponse<APIRescueGroupData> = try await api.deleteRaw("/auth/rescue-groups/\(groupId)") as APIResponse<APIRescueGroupData>
                if let data = response.data {
                    self.groupData = data
                }
                self.isActioning = false
                self.successMessage = "Đã giải tán đội"
            } catch {
                print("[TeamVM] ❌ disband: \(error)")
                self.errorMessage = error.localizedDescription
                self.isActioning = false
            }
        }
    }
}

// MARK: - Rescuer Directory Model

struct APIRescuerDirectory: Decodable, Identifiable {
    let id: Int
    let phoneNumber: String
    let displayName: String
    let role: String
    let avatarUrl: String
    let isActive: Bool
    let hasActiveGroup: Bool
    let hasPendingInviteFromMe: Bool
    let createdAt: String?
    let updatedAt: String?
}

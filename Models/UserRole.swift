//
//  UserRole.swift
//  AquaGuard
//
//  Defines user roles (Citizen, Rescuer, Admin) and
//  a shared AppState to manage current role selection
//  for navigation routing throughout the app.
//

import Combine
import SwiftUI

// MARK: - User Role Enum

enum UserRole: String, CaseIterable, Identifiable {
    case citizen = "citizen"
    case rescuer = "rescuer"
    case admin = "admin"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .citizen: return "Citizen"
        case .rescuer: return "Rescuer"
        case .admin: return "Admin"
        }
    }

    var icon: String {
        switch self {
        case .citizen: return "person.fill"
        case .rescuer: return "lifepreserver.fill"
        case .admin: return "shield.checkered"
        }
    }

    var color: Color {
        switch self {
        case .citizen: return .aquaPrimary
        case .rescuer: return .orange
        case .admin: return .purple
        }
    }

    var description: String {
        switch self {
        case .citizen: return "Report floods, track family safety"
        case .rescuer: return "Accept & manage rescue missions"
        case .admin: return "Manage users, teams & system"
        }
    }
}

// MARK: - App State (shared across app)

class AppState: ObservableObject {
    static let shared = AppState()

    /// Current active role (persisted for dev testing)
    @Published var currentRole: UserRole

    /// Whether user has explicitly selected a role
    @Published var hasSelectedRole: Bool

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedRole") ?? "citizen"
        self.currentRole = UserRole(rawValue: saved) ?? .citizen
        self.hasSelectedRole = UserDefaults.standard.bool(forKey: "hasSelectedRole")
    }

    func selectRole(_ role: UserRole) {
        currentRole = role
        hasSelectedRole = true
        UserDefaults.standard.set(role.rawValue, forKey: "selectedRole")
        UserDefaults.standard.set(true, forKey: "hasSelectedRole")
    }

    func logout() {
        hasSelectedRole = false
        UserDefaults.standard.set(false, forKey: "hasSelectedRole")
    }
}

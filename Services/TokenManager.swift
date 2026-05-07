//
//  TokenManager.swift
//  AquaGuard
//
//  Manages JWT authentication tokens and user session data.
//  Stores tokens securely in the iOS Keychain, user info in UserDefaults.
//  Provides reactive auth state via @Published properties.
//

import Foundation
import Security
import Combine

class TokenManager: ObservableObject {

    static let shared = TokenManager()

    // MARK: - Published State

    /// Whether a valid token exists — drives auth-gated navigation
    @Published var isAuthenticated: Bool = false

    /// Current user info (loaded from disk on init)
    @Published var currentUser: APIUser?

    // MARK: - Keychain Keys

    private let tokenKeychainKey = "com.aquaguard.jwt_token"
    private let userDefaultsKey = "com.aquaguard.current_user"

    // MARK: - Init

    private init() {
        // Restore session on app launch
        if let token = getToken(), !token.isEmpty {
            isAuthenticated = true
        }
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(APIUser.self, from: data) {
            currentUser = user
        }
    }

    // MARK: - Token Management

    /// Save JWT token to Keychain and user info to UserDefaults.
    /// Called after successful login/register.
    func saveSession(token: String, user: APIUser) {
        saveTokenToKeychain(token)
        saveUserToDefaults(user)

        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    /// Retrieve the stored JWT token (nil if not logged in)
    func getToken() -> String? {
        return loadTokenFromKeychain()
    }

    /// Update only the user info (e.g. after profile edit)
    func updateUser(_ user: APIUser) {
        saveUserToDefaults(user)
        DispatchQueue.main.async {
            self.currentUser = user
        }
    }

    /// Clear all session data — called on logout or 401
    func clearSession() {
        deleteTokenFromKeychain()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)

        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    // MARK: - Convenience

    /// Current user's role (defaults to citizen if not logged in)
    var currentRole: UserRole {
        currentUser?.userRole ?? .citizen
    }

    /// Current user's ID (nil if not logged in)
    var userId: Int? {
        currentUser?.id
    }

    // MARK: - Keychain Helpers

    private func saveTokenToKeychain(_ token: String) {
        let data = Data(token.utf8)

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKeychainKey,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKeychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKeychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKeychainKey,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - UserDefaults Helpers

    private func saveUserToDefaults(_ user: APIUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

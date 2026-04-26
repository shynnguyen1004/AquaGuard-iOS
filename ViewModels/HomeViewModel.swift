//
//  HomeViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Combine
import FirebaseAuth
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeAlerts: [FloodAlert] = MockData.alerts
    @Published var currentRiskLocation: String =
        "Ho Chi Minh city University of Technology, Dien Hong Ward"
    @Published var currentRiskLevel: SeverityLevel = .severe
    @Published var signOutError: String?

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            signOutError = error.localizedDescription
        }
        // Also reset dev skip flag
        UserDefaults.standard.set(false, forKey: "devSkipLogin")
    }
}

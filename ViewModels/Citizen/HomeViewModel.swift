//
//  HomeViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Combine
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeAlerts: [CommunityReport] = CommunityReport.dummyReports
    @Published var currentRiskLocation: String =
        "Ho Chi Minh city University of Technology, Dien Hong Ward"
    @Published var currentRiskLevel: SeverityLevel = .severe
    @Published var signOutError: String?

    func signOut() {
        AppState.shared.logout()
    }
}

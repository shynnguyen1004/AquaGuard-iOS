//
//  RescueViewModel.swift
//  AquaGuard
//
//  Created for P1 refactor: extract hardcoded data from RescueView.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Models

struct RescueResource: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let current: Int
    let total: Int
    let color: Color
}

struct RescueRequest: Identifiable {
    let id = UUID()
    let address: String
    let people: Int
    let time: String
    let status: String
    let team: String?
    let severityColor: Color
}

// MARK: - ViewModel

@MainActor
class RescueViewModel: ObservableObject {

    @Published var resources: [RescueResource] = MockData.rescueResources
    @Published var requests: [RescueRequest] = MockData.rescueRequests

    var pendingCount: Int {
        requests.filter { $0.status == "Pending" }.count
    }
}

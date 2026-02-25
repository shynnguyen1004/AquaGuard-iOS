//
//  RescueViewModel.swift
//  AquaGuard
//
//  Created for P1 refactor: extract hardcoded data from RescueView.
//

import Foundation

@MainActor
class RescueViewModel: ObservableObject {

    @Published var resources: [RescueResource] = MockData.rescueResources
    @Published var requests: [RescueRequest] = MockData.rescueRequests

    var pendingCount: Int {
        requests.filter { $0.status == "Pending" }.count
    }
}

//
//  RescueDashboardViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 25/2/26.
//

import Combine
import Foundation

@MainActor
class RescueDashboardViewModel: ObservableObject {

    @Published var resources: [RescueResource] = MockData.rescueResources
    @Published var requests: [RescueRequest] = MockData.rescueRequests

    var pendingCount: Int {
        requests.filter { $0.status == "Pending" }.count
    }
}

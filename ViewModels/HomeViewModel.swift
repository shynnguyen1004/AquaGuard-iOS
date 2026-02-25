//
//  HomeViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Combine  // FIX: Import thư viện này để sửa lỗi ObservableObject
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeAlerts: [FloodAlert] = MockData.alerts
    @Published var currentRiskLocation: String =
        "Ho Chi Minh city University of Technology, Dien Hong Ward"
    @Published var currentRiskLevel: SeverityLevel = .severe
}

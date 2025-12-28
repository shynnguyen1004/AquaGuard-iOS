//
//  HomeViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import Combine // FIX: Import thư viện này để sửa lỗi ObservableObject

@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeAlerts: [Alert] = MockData.alerts
    @Published var currentRiskLocation: String = "Ho Chi Minh city University of Technology, Dien Hong Ward"
    @Published var currentRiskLevel: SeverityLevel = .low
}

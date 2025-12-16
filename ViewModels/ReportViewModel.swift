//
//  ReportViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import Combine // FIX: Import Combine

@MainActor
class ReportViewModel: ObservableObject {
    @Published var locationName: String = ""
    @Published var waterLevelPercentage: Double = 30.0
    @Published var description: String = ""
    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false
    
    func submitReport() {
        isSubmitting = true
        // Giả lập call API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSubmitting = false
            self.showSuccessAlert = true
            self.locationName = ""
            self.description = ""
        }
    }
}

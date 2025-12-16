//
//  Models.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import CoreLocation
import SwiftUI

enum SeverityLevel: String, Codable {
    case low, moderate, severe, critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .aquaWarning
        case .severe: return .aquaDanger
        case .critical: return .red
        }
    }
}

// FIX: Thêm Hashable và Equatable thủ công vì CLLocationCoordinate2D không tự hỗ trợ
struct FloodZone: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let severity: SeverityLevel
    let waterLevel: Double
    
    // Hàm so sánh để tuân thủ Equatable/Hashable
    static func == (lhs: FloodZone, rhs: FloodZone) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Alert: Identifiable {
    let id = UUID()
    let title: String
    let location: String
    let timeAgo: String
    let severity: SeverityLevel
    let iconName: String
}

// MARK: - Mock Data
class MockData {
    static let floodZones = [
        FloodZone(name: "Downtown District", coordinate: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009), severity: .severe, waterLevel: 1.2),
        FloodZone(name: "Riverside Park", coordinate: CLLocationCoordinate2D(latitude: 10.7800, longitude: 106.7050), severity: .moderate, waterLevel: 0.5),
        FloodZone(name: "Harbor View", coordinate: CLLocationCoordinate2D(latitude: 10.7700, longitude: 106.6900), severity: .low, waterLevel: 0.1)
    ]
    
    static let alerts = [
        Alert(title: "Heavy Rainfall Expected", location: "Downtown District", timeAgo: "15 min ago", severity: .moderate, iconName: "cloud.heavyrain.fill"),
        Alert(title: "River Water Level Rising", location: "Riverside Area", timeAgo: "1 hour ago", severity: .severe, iconName: "waveform.path.ecg")
    ]
}

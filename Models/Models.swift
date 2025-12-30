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
        case .low: return .aquaSafe
        case .moderate: return .aquaWarning
        case .severe: return .aquaDanger
        case .critical: return .aquaCritical
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
        FloodZone(name: "Phu Nhuan", coordinate: CLLocationCoordinate2D(latitude: 10.794211, longitude: 106.677869), severity: .moderate, waterLevel: 0.5),
        FloodZone(name: "Bui Vien Walking Street", coordinate: CLLocationCoordinate2D(latitude: 10.767308, longitude: 106.693755), severity: .critical, waterLevel: 1.4),
        FloodZone(name: "An Dong Market", coordinate: CLLocationCoordinate2D(latitude: 10.757304, longitude: 106.672451), severity: .severe, waterLevel: 0.9),
        FloodZone(name: "HCMUT Football Field", coordinate: CLLocationCoordinate2D(latitude: 10.772741, longitude: 106.659507), severity: .low, waterLevel: 0.1),
        FloodZone(name: "Nam Ky Khoi Nghia x Dien Bien Phu", coordinate: CLLocationCoordinate2D(latitude: 10.783487, longitude: 106.690790), severity: .low, waterLevel: 0.1)
    ]
    
    static let alerts = [
        Alert(title: "Heavy Rainfall Expected", location: "Bui Vien Walking Street", timeAgo: "15 min ago", severity: .moderate, iconName: "cloud.heavyrain.fill"),
        Alert(title: "River Water Level Rising", location: "Phu Nhuan", timeAgo: "1 hour ago", severity: .severe, iconName: "waveform.path.ecg")
    ]
}

struct DataPackage {
    let carrier: String
    let name: String
    let number: String
    let syntax: String
}

// Danh sách các gói cứu hộ nhanh
let emergencyPackages = [
    DataPackage(carrier: "Viettel", name: "ST5K (5k/500MB)", number: "191", syntax: "ST5K"),
    DataPackage(carrier: "Vinaphone", name: "D5 (5k/1GB)", number: "888", syntax: "DK D5"),
    DataPackage(carrier: "Mobifone", name: "D5 (5k/1GB)", number: "999", syntax: "DK D5"),
    DataPackage(carrier: "Vietnamobile", name: "N3 (3k/3GB)", number: "345", syntax: "DK N3")
]

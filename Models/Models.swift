//
//  Models.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import CoreLocation
import FirebaseFirestore  // Nhớ import cái này
import Foundation
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

// CẬP NHẬT STRUCT NÀY (Thêm Hashable và hàm so sánh)
struct FloodZone: Identifiable, Codable, Hashable {
    @DocumentID var id: String?

    var name: String
    var location: GeoPoint
    var severity: SeverityLevel
    var waterLevel: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case severity
        case waterLevel = "water_level"
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }

    // --- PHẦN BỔ SUNG QUAN TRỌNG ĐỂ SỬA LỖI ---

    // 1. Hàm so sánh bằng (Equatable): Chỉ cần ID giống nhau là coi như giống nhau
    static func == (lhs: FloodZone, rhs: FloodZone) -> Bool {
        return lhs.id == rhs.id
    }

    // 2. Hàm băm (Hashable): Dùng ID để tạo mã băm
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FloodAlert: Identifiable {
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
        FloodZone(
            name: "Phu Nhuan",
            location: GeoPoint(latitude: 10.794211, longitude: 106.677869),
            severity: .moderate,
            waterLevel: 0.5),

        FloodZone(
            name: "Bui Vien Walking Street",
            location: GeoPoint(latitude: 10.767308, longitude: 106.693755),
            severity: .critical,
            waterLevel: 1.4),

        FloodZone(
            name: "An Dong Market",
            location: GeoPoint(latitude: 10.757304, longitude: 106.672451),
            severity: .severe,
            waterLevel: 0.9),

        FloodZone(
            name: "HCMUT Football Field",
            location: GeoPoint(latitude: 10.772741, longitude: 106.659507),
            severity: .low,
            waterLevel: 0.1),

        FloodZone(
            name: "Nam Ky Khoi Nghia x Dien Bien Phu",
            location: GeoPoint(latitude: 10.783487, longitude: 106.690790),
            severity: .low,
            waterLevel: 0.1),
    ]

    static let alerts = [
        FloodAlert(
            title: "Heavy Rainfall Expected", location: "Bui Vien Walking Street",
            timeAgo: "15 min ago", severity: .moderate, iconName: "cloud.heavyrain.fill"),
        FloodAlert(
            title: "River Water Level Rising", location: "Phu Nhuan", timeAgo: "1 hour ago",
            severity: .severe, iconName: "waveform.path.ecg"),
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
    DataPackage(carrier: "Vietnamobile", name: "N3 (3k/3GB)", number: "345", syntax: "DK N3"),
]

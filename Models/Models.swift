//
//  Models.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import CoreLocation
import FirebaseFirestore
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

// FloodZone model with Hashable conformance
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

    // MARK: Equatable & Hashable

    // Equatable: compare by document ID
    static func == (lhs: FloodZone, rhs: FloodZone) -> Bool {
        return lhs.id == rhs.id
    }

    // Hashable: hash by document ID
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

    static let emergencyPackages = [
        DataPackage(carrier: "Viettel", name: "ST5K (5k/500MB)", number: "191", syntax: "ST5K"),
        DataPackage(carrier: "Vinaphone", name: "D5 (5k/1GB)", number: "888", syntax: "DK D5"),
        DataPackage(carrier: "Mobifone", name: "D5 (5k/1GB)", number: "999", syntax: "DK D5"),
        DataPackage(carrier: "Vietnamobile", name: "N3 (3k/3GB)", number: "345", syntax: "DK N3"),
    ]

    static let rescueResources = [
        RescueResource(icon: "ferry", title: "Rescue Boats", current: 8, total: 12, color: .teal),
        RescueResource(icon: "house", title: "Shelters Open", current: 5, total: 8, color: .blue),
        RescueResource(
            icon: "heart", title: "Medical Teams", current: 6, total: 10, color: .orange),
        RescueResource(
            icon: "person.3", title: "Active Rescues", current: 3, total: 3, color: .gray),
    ]

    static let rescueRequests = [
        RescueRequest(
            address: "123 Ly Thuong Kiet", people: 4, time: "10 min ago",
            status: "In Progress", team: "Team Alpha", severityColor: .orange),
        RescueRequest(
            address: "456 To Hien Thanh", people: 2, time: "5 min ago",
            status: "Pending", team: nil, severityColor: .red),
        RescueRequest(
            address: "789 Nguyen Tri Phuong", people: 6, time: "45 min ago",
            status: "Completed", team: "Team Bravo", severityColor: .orange),
    ]

    static let sosRequests = [
        SOSRequest(
            address: "12 Nguyen Hue, District 1",
            description: "Water flooding into first floor, family of 4 needs help",
            photoURL: nil,
            status: .pending,
            timestamp: Date().addingTimeInterval(-300)  // 5 min ago
        ),
        SOSRequest(
            address: "456 Le Loi, District 5",
            description: "Elderly person stranded on rooftop due to rising water",
            photoURL: nil,
            status: .inProgress,
            timestamp: Date().addingTimeInterval(-1800)  // 30 min ago
        ),
        SOSRequest(
            address: "78 Tran Hung Dao, District 1",
            description: "Road completely flooded, car stuck and cannot move",
            photoURL: nil,
            status: .resolved,
            timestamp: Date().addingTimeInterval(-7200)  // 2 hours ago
        ),
    ]
}

// MARK: - SOS Request Status
enum SOSStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case resolved = "Resolved"

    var color: Color {
        switch self {
        case .pending: return .aquaWarning
        case .inProgress: return .aquaPrimary
        case .resolved: return .aquaSafe
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .resolved: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Emergency Request Type
enum RequestType: String, Codable {
    case quickSOS = "quick_sos"
    case detailed = "detailed"
}

// MARK: - Unified Emergency Request
/// Unified model for both Quick SOS and Detailed Rescue requests.
/// Replaces the old separate SOSRequest and FloodReport models.
struct EmergencyRequest: Identifiable {
    let id: String
    let userId: String
    let localImage: UIImage?     // Local only (not persisted to Firestore)
    let photoURL: String?
    let latitude: Double
    let longitude: Double
    let address: String
    let description: String
    let requestType: RequestType
    let status: SOSStatus
    let timestamp: Date
    let rescuerId: String?       // Assigned rescuer (for tracking)

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var locationString: String {
        String(format: "%.5f, %.5f", latitude, longitude)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm · dd/MM/yyyy"
        return formatter.string(from: timestamp)
    }

    var timeAgoString: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60)) min ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// Legacy model — kept for backward compat with RescueRequestHistoryCard mock data
struct SOSRequest: Identifiable {
    let id = UUID()
    let address: String
    let description: String
    let photoURL: String?
    let status: SOSStatus
    let timestamp: Date

    var timeAgoString: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60)) min ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct DataPackage {
    let carrier: String
    let name: String
    let number: String
    let syntax: String
}

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

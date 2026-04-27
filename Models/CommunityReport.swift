//
//  CommunityReport.swift
//  AquaGuard
//
//  Community flood report posted by other users.
//  Displayed in the Locket-style feed below the camera.
//

import CoreLocation
import Foundation
import SwiftUI
import UIKit

struct CommunityReport: Identifiable {
    let id = UUID()
    let userName: String
    let userAvatar: String  // SF Symbol for avatar
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let caption: String
    let imageName: String  // placeholder gradient color key
    let severity: String   // low, moderate, severe, critical
    let reactions: Int

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    var relativeTimeString: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Vừa xong" }
        if interval < 3600 { return "\(Int(interval / 60)) phút trước" }
        if interval < 86400 { return "\(Int(interval / 3600)) giờ trước" }
        return "\(Int(interval / 86400)) ngày trước"
    }

    var severityColor: Color {
        switch severity {
        case "critical": return .red
        case "severe": return .orange
        case "moderate": return .yellow
        default: return .green
        }
    }
}

// MARK: - Dummy Data

extension CommunityReport {
    static let dummyReports: [CommunityReport] = [
        CommunityReport(
            userName: "Minh Trần",
            userAvatar: "person.circle.fill",
            locationName: "Phố Đi Bộ Nguyễn Huệ",
            coordinate: CLLocationCoordinate2D(latitude: 10.7740, longitude: 106.7030),
            timestamp: Date().addingTimeInterval(-900),  // 15 min ago
            caption: "Nước ngập ngang đầu gối, giao thông tê liệt hoàn toàn khu vực trung tâm Q.1",
            imageName: "flood_street",
            severity: "severe",
            reactions: 24
        ),
        CommunityReport(
            userName: "Lan Nguyễn",
            userAvatar: "person.circle.fill",
            locationName: "Bùi Viện Walking Street",
            coordinate: CLLocationCoordinate2D(latitude: 10.7673, longitude: 106.6938),
            timestamp: Date().addingTimeInterval(-2700),  // 45 min ago
            caption: "Nước dâng nhanh sau cơn mưa lớn, nhiều xe máy bị ngập. Mọi người cẩn thận!",
            imageName: "flood_rain",
            severity: "critical",
            reactions: 56
        ),
        CommunityReport(
            userName: "Hùng Phạm",
            userAvatar: "person.circle.fill",
            locationName: "Chợ An Đông, Q.5",
            coordinate: CLLocationCoordinate2D(latitude: 10.7573, longitude: 106.6725),
            timestamp: Date().addingTimeInterval(-5400),  // 1.5h ago
            caption: "Khu vực chợ bị ngập nhẹ, nước đang rút dần. Vẫn có thể đi lại được.",
            imageName: "flood_market",
            severity: "moderate",
            reactions: 12
        ),
        CommunityReport(
            userName: "Thu Hà",
            userAvatar: "person.circle.fill",
            locationName: "ĐHBK HCMUT Cơ sở 2",
            coordinate: CLLocationCoordinate2D(latitude: 10.7727, longitude: 106.6595),
            timestamp: Date().addingTimeInterval(-10800),  // 3h ago
            caption: "Sân trường ngập sau mưa lớn. Sinh viên được thông báo nghỉ học chiều nay.",
            imageName: "flood_school",
            severity: "moderate",
            reactions: 38
        ),
        CommunityReport(
            userName: "Đức Lê",
            userAvatar: "person.circle.fill",
            locationName: "NK Khởi Nghĩa × Điện Biên Phủ",
            coordinate: CLLocationCoordinate2D(latitude: 10.7835, longitude: 106.6908),
            timestamp: Date().addingTimeInterval(-18000),  // 5h ago
            caption: "Nước đã rút hết, giao thông trở lại bình thường. Cảm ơn đội cứu hộ!",
            imageName: "flood_clear",
            severity: "low",
            reactions: 8
        ),
    ]
}

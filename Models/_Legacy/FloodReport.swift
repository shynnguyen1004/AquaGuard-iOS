//
//  FloodReport.swift
//  AquaGuard
//
//  Instant flood report model — each report captures
//  a photo with GPS coordinates and timestamp.
//

import CoreLocation
import Foundation
import SwiftUI

struct FloodReport: Identifiable {
    let id = UUID()
    let image: UIImage
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let caption: String

    var locationString: String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm · dd/MM/yyyy"
        return formatter.string(from: timestamp)
    }

    var relativeTimeString: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60)) min ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

//
//  WMOWeatherCode.swift
//  AquaGuard
//
//  WMO weather interpretation codes (Open-Meteo).
//  https://open-meteo.com/en/docs
//

import Foundation

struct WMOWeatherCode: Equatable, Sendable {
    let code: Int

    var shortDescription: String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly cloudy"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }

    var systemImageName: String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    var isRainy: Bool {
        switch code {
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99:
            return true
        default:
            return false
        }
    }

    var isStorm: Bool {
        (95...99).contains(code)
    }
}

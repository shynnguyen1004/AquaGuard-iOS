//
//  DevWeatherSettings.swift
//  AquaGuard
//
//  Dev-only weather status simulation for previewing Status Card states.
//

import Combine
import CoreLocation
import Foundation

enum WeatherStatusSimulation: String, CaseIterable, Identifiable {
    case real
    case safe
    case caution
    case danger
    case critical

    var id: String { rawValue }

    var isSimulating: Bool {
        self != .real
    }

    var severityLevel: SeverityLevel? {
        switch self {
        case .real: return nil
        case .safe: return .low
        case .caution: return .moderate
        case .danger: return .severe
        case .critical: return .critical
        }
    }

    /// Localization keys for Settings picker labels.
    var settingsTitleKey: String {
        switch self {
        case .real: return "Real (current location)"
        case .safe: return "Preview: Safe"
        case .caution: return "Preview: Caution"
        case .danger: return "Preview: Danger"
        case .critical: return "Preview: Critical"
        }
    }
}

struct WeatherSimulationPreset {
    let locationLabel: String
    let coordinate: CLLocationCoordinate2D
    let level: SeverityLevel
    let summary: String
    let metrics: WeatherCardMetrics
}

enum WeatherSimulationPresets {
    static func preset(for mode: WeatherStatusSimulation) -> WeatherSimulationPreset? {
        switch mode {
        case .real:
            return nil
        case .safe:
            return WeatherSimulationPreset(
                locationLabel: "Đà Lạt, Lâm Đồng",
                coordinate: CLLocationCoordinate2D(latitude: 11.9404, longitude: 108.4583),
                level: .low,
                summary: "Partly cloudy · 22°C",
                metrics: WeatherCardMetrics(
                    precipitationMm: 0,
                    windSpeedKmh: 8,
                    relativeHumidityPercent: 55
                )
            )
        case .caution:
            return WeatherSimulationPreset(
                locationLabel: "Quận 1, TP. Hồ Chí Minh",
                coordinate: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009),
                level: .moderate,
                summary: "Light rain · 27°C",
                metrics: WeatherCardMetrics(
                    precipitationMm: 1.2,
                    windSpeedKmh: 22,
                    relativeHumidityPercent: 78
                )
            )
        case .danger:
            return WeatherSimulationPreset(
                locationLabel: "Thủ Đức, TP. Hồ Chí Minh",
                coordinate: CLLocationCoordinate2D(latitude: 10.8500, longitude: 106.7537),
                level: .severe,
                summary: "Heavy rain · 26°C",
                metrics: WeatherCardMetrics(
                    precipitationMm: 5.0,
                    windSpeedKmh: 45,
                    relativeHumidityPercent: 88
                )
            )
        case .critical:
            return WeatherSimulationPreset(
                locationLabel: "Cần Giờ, TP. Hồ Chí Minh",
                coordinate: CLLocationCoordinate2D(latitude: 10.4111, longitude: 106.9547),
                level: .critical,
                summary: "Thunderstorm · 25°C",
                metrics: WeatherCardMetrics(
                    precipitationMm: 12,
                    windSpeedKmh: 55,
                    relativeHumidityPercent: 95
                )
            )
        }
    }
}

@MainActor
final class DevWeatherSettings: ObservableObject {
    static let shared = DevWeatherSettings()

    private static let storageKey = "dev.weather.statusSimulation"

    @Published var statusSimulation: WeatherStatusSimulation {
        didSet {
            guard oldValue != statusSimulation else { return }
            UserDefaults.standard.set(statusSimulation.rawValue, forKey: Self.storageKey)
        }
    }

    var isSimulating: Bool { statusSimulation.isSimulating }

    var activePreset: WeatherSimulationPreset? {
        WeatherSimulationPresets.preset(for: statusSimulation)
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? WeatherStatusSimulation.real.rawValue
        statusSimulation = WeatherStatusSimulation(rawValue: raw) ?? .real
    }
}

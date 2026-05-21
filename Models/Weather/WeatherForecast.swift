//
//  WeatherForecast.swift
//  AquaGuard
//
//  Domain models for Open-Meteo data (Status Card + Forecast UI).
//

import Foundation

// MARK: - Aggregated forecast

struct WeatherForecast: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather
    let hourly: [HourlyForecastItem]
    let daily: [DailyForecastItem]
    let fetchedAt: Date

    /// Compact view for Status Card and summaries.
    var snapshot: WeatherSnapshot {
        WeatherSnapshot(
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            current: current,
            nextHours: Self.upcomingHours(from: hourly, after: current.time, count: 6),
            fetchedAt: fetchedAt
        )
    }

    /// Hourly rows from the current moment onward (not midnight of the forecast day).
    static func upcomingHours(
        from hourly: [HourlyForecastItem],
        after currentTime: Date,
        count: Int
    ) -> [HourlyForecastItem] {
        let upcoming = hourly.filter { $0.time >= currentTime }
        return Array(upcoming.prefix(count))
    }
}

// MARK: - Current conditions

struct CurrentWeather: Equatable, Sendable {
    let time: Date
    let temperatureCelsius: Double
    let precipitationMm: Double
    let weatherCode: Int
    let windSpeedKmh: Double
    let relativeHumidityPercent: Int?

    var wmo: WMOWeatherCode { WMOWeatherCode(code: weatherCode) }
}

// MARK: - Hourly row

struct HourlyForecastItem: Equatable, Sendable, Identifiable {
    let time: Date
    let temperatureCelsius: Double
    let precipitationProbabilityPercent: Int?
    let precipitationMm: Double
    let weatherCode: Int
    let windSpeedKmh: Double

    var id: Date { time }
    var wmo: WMOWeatherCode { WMOWeatherCode(code: weatherCode) }
}

// MARK: - Daily row

struct DailyForecastItem: Equatable, Sendable, Identifiable {
    let date: Date
    let weatherCode: Int
    let temperatureMaxCelsius: Double
    let temperatureMinCelsius: Double
    let precipitationSumMm: Double
    let precipitationProbabilityMaxPercent: Int?
    let windSpeedMaxKmh: Double

    var id: Date { date }
    var wmo: WMOWeatherCode { WMOWeatherCode(code: weatherCode) }
}

// MARK: - Status Card snapshot

struct WeatherSnapshot: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather
    let nextHours: [HourlyForecastItem]
    let fetchedAt: Date

    /// Human-readable one-liner, e.g. "Thunderstorm · 28°C"
    var summaryLine: String {
        let temp = Int(current.temperatureCelsius.rounded())
        return "\(current.wmo.shortDescription) · \(temp)°C"
    }
}

// MARK: - Status Card metric pills

struct WeatherCardMetrics: Equatable, Sendable {
    let precipitationMm: Double
    let windSpeedKmh: Double
    let relativeHumidityPercent: Int?

    static func from(current: CurrentWeather) -> WeatherCardMetrics {
        WeatherCardMetrics(
            precipitationMm: current.precipitationMm,
            windSpeedKmh: current.windSpeedKmh,
            relativeHumidityPercent: current.relativeHumidityPercent
        )
    }

    func precipitationDisplay() -> String {
        if precipitationMm < 0.05 {
            return "0 mm"
        }
        if precipitationMm < 10 {
            return String(format: "%.1f mm", precipitationMm)
        }
        return String(format: "%.0f mm", precipitationMm)
    }

    func windDisplay() -> String {
        "\(Int(windSpeedKmh.rounded())) km/h"
    }

    func humidityDisplay() -> String? {
        relativeHumidityPercent.map { "\($0)%" }
    }
}

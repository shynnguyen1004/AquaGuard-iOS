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
            nextHours: Array(hourly.prefix(6)),
            fetchedAt: fetchedAt
        )
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

    /// Human-readable one-liner, e.g. "Thunderstorm · 28°C · Wind 5 km/h"
    var summaryLine: String {
        let temp = Int(current.temperatureCelsius.rounded())
        let wind = Int(current.windSpeedKmh.rounded())
        return "\(current.wmo.shortDescription) · \(temp)°C · Wind \(wind) km/h"
    }
}

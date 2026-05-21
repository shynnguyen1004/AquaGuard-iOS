//
//  WeatherRiskCalculator.swift
//  AquaGuard
//
//  Maps Open-Meteo snapshot to SeverityLevel for Status Card.
//

import Foundation

enum WeatherRiskCalculator {

    static func evaluate(snapshot: WeatherSnapshot) -> SeverityLevel {
        let current = snapshot.current
        let nextHours = snapshot.nextHours

        let precipNow = current.precipitationMm
        let windNow = current.windSpeedKmh
        let next3hPrecip = nextHours.prefix(3).map(\.precipitationMm).reduce(0, +)
        let maxPrecipProb = nextHours.prefix(6).compactMap(\.precipitationProbabilityPercent).max() ?? 0
        let maxWindNext6h = max(
            windNow,
            nextHours.prefix(6).map(\.windSpeedKmh).max() ?? windNow
        )

        if precipNow >= 10 || next3hPrecip >= 30 {
            return .critical
        }
        if current.wmo.isStorm && (precipNow >= 2 || maxPrecipProb >= 70) {
            return .critical
        }

        if precipNow >= 4 || next3hPrecip >= 15 || maxPrecipProb >= 80 || maxWindNext6h >= 50 {
            return .severe
        }

        if precipNow > 0.5
            || next3hPrecip >= 4
            || maxPrecipProb >= 50
            || maxWindNext6h >= 30
            || current.wmo.isRainy
        {
            return .moderate
        }

        return .low
    }
}

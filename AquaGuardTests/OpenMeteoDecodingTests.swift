//
//  OpenMeteoDecodingTests.swift
//  AquaGuardTests
//

import Foundation
import Testing
@testable import AquaGuard

struct OpenMeteoDecodingTests {

    @Test func decodesFixtureIntoDomainForecast() throws {
        let data = try loadFixture(named: "open_meteo_forecast_sample")
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let forecast = try response.toDomain(fetchedAt: Date(timeIntervalSince1970: 0))

        #expect(forecast.latitude == 10.790861)
        #expect(forecast.longitude == 106.71088)
        #expect(forecast.timezone == "Asia/Ho_Chi_Minh")
        #expect(forecast.current.weatherCode == 95)
        #expect(forecast.current.temperatureCelsius == 28.2)
        #expect(forecast.hourly.count == 3)
        #expect(forecast.daily.count == 2)
    }

    @Test func snapshotSummaryIncludesTemperature() throws {
        let data = try loadFixture(named: "open_meteo_forecast_sample")
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let forecast = try response.toDomain()
        let summary = forecast.snapshot.summaryLine

        #expect(summary.contains("28"))
        #expect(summary.contains("Thunderstorm"))
    }

    @Test func weatherCacheReturnsFreshEntry() throws {
        let cache = WeatherCache()
        let data = try loadFixture(named: "open_meteo_forecast_sample")
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let forecast = try response.toDomain()

        cache.store(forecast, ttl: 60)
        let cached = cache.cachedForecast(latitude: forecast.latitude, longitude: forecast.longitude)

        #expect(cached == forecast)
    }

    @Test func weatherCacheKeyRoundsCoordinates() {
        let key1 = WeatherCache.cacheKey(latitude: 10.77691, longitude: 106.70089)
        let key2 = WeatherCache.cacheKey(latitude: 10.77694, longitude: 106.70092)
        #expect(key1 == key2)
    }

    @Test func parsesOpenMeteoLocalTimeWithoutOffset() {
        let parsed = OpenMeteoDateParser.parse(
            "2026-05-21T23:00",
            timeZoneIdentifier: "Asia/Ho_Chi_Minh"
        )
        #expect(parsed != nil)
    }

    @Test func snapshotUsesUpcomingHoursNotMidnightPrefix() throws {
        let data = try loadFixture(named: "open_meteo_forecast_sample")
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let forecast = try response.toDomain()
        let snapshot = forecast.snapshot

        #expect(snapshot.nextHours.allSatisfy { $0.time >= snapshot.current.time })
        #expect(snapshot.nextHours.count <= 6)
    }

    @Test func riskCalculatorMarksThunderstormAsElevated() throws {
        let data = try loadFixture(named: "open_meteo_forecast_sample")
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let snapshot = try response.toDomain().snapshot
        let level = WeatherRiskCalculator.evaluate(snapshot: snapshot)
        #expect(level == .severe || level == .critical)
    }

    // MARK: - Helpers

    private func loadFixture(named name: String) throws -> Data {
        let bundle = Bundle(for: OpenMeteoBundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            // Fallback when Xcode runs tests from project directory layout
            let projectURL = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Fixtures/\(name).json")
            return try Data(contentsOf: projectURL)
        }
        return try Data(contentsOf: url)
    }
}

/// Anchor type for `Bundle(for:)` in test target.
private final class OpenMeteoBundleToken {}

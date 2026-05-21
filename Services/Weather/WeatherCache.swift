//
//  WeatherCache.swift
//  AquaGuard
//
//  In-memory cache for Open-Meteo responses keyed by rounded coordinates.
//

import Foundation

final class WeatherCache: @unchecked Sendable {
    private struct Entry {
        let forecast: WeatherForecast
        let expiresAt: Date
    }

    private let lock = NSLock()
    private var storage: [String: Entry] = [:]

    func cachedForecast(
        latitude: Double,
        longitude: Double,
        now: Date = Date()
    ) -> WeatherForecast? {
        let key = Self.cacheKey(latitude: latitude, longitude: longitude)
        lock.lock()
        defer { lock.unlock() }
        guard let entry = storage[key], entry.expiresAt > now else {
            if storage[key] != nil { storage.removeValue(forKey: key) }
            return nil
        }
        return entry.forecast
    }

    func store(_ forecast: WeatherForecast, ttl: TimeInterval = NetworkConfig.weatherCacheTTL) {
        let key = Self.cacheKey(latitude: forecast.latitude, longitude: forecast.longitude)
        let entry = Entry(forecast: forecast, expiresAt: Date().addingTimeInterval(ttl))
        lock.lock()
        storage[key] = entry
        lock.unlock()
    }

    func clear() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }

    static func cacheKey(latitude: Double, longitude: Double) -> String {
        let lat = (latitude * 100).rounded() / 100
        let lon = (longitude * 100).rounded() / 100
        return "\(lat),\(lon)"
    }
}

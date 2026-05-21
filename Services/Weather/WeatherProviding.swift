//
//  WeatherProviding.swift
//  AquaGuard
//

import Foundation

protocol WeatherProviding: Sendable {
    func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> WeatherForecast
}

//
//  OpenMeteoService.swift
//  AquaGuard
//
//  Fetches forecast data from Open-Meteo (no API key required on free tier).
//

import Foundation

final class OpenMeteoService: WeatherProviding, @unchecked Sendable {

    static let shared = OpenMeteoService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let cache: WeatherCache

    init(session: URLSession? = nil, cache: WeatherCache = WeatherCache()) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = NetworkConfig.requestTimeout
            self.session = URLSession(configuration: config)
        }
        self.decoder = JSONDecoder()
        self.cache = cache
    }

    func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool = false
    ) async throws -> WeatherForecast {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw WeatherError.invalidCoordinates
        }

        if !forceRefresh,
           let cached = cache.cachedForecast(latitude: latitude, longitude: longitude) {
            return cached
        }

        let url = try buildForecastURL(latitude: latitude, longitude: longitude)
        let fetchedAt = Date()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw WeatherError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WeatherError.httpStatus(http.statusCode)
        }

        let apiResponse: OpenMeteoResponse
        do {
            apiResponse = try decoder.decode(OpenMeteoResponse.self, from: data)
        } catch {
            throw WeatherError.decodingFailed
        }

        let forecast = try apiResponse.toDomain(fetchedAt: fetchedAt)
        cache.store(forecast)
        return forecast
    }

    // MARK: - URL

    private func buildForecastURL(latitude: Double, longitude: Double) throws -> URL {
        guard var components = URLComponents(string: NetworkConfig.openMeteoForecastURL) else {
            throw WeatherError.invalidURL
        }

        let lat = String(format: "%.4f", latitude)
        let lon = String(format: "%.4f", longitude)

        components.queryItems = [
            URLQueryItem(name: "latitude", value: lat),
            URLQueryItem(name: "longitude", value: lon),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation,rain"
            ),
            URLQueryItem(
                name: "hourly",
                value: [
                    "temperature_2m",
                    "precipitation_probability",
                    "precipitation",
                    "weather_code",
                    "wind_speed_10m",
                ].joined(separator: ",")
            ),
            URLQueryItem(
                name: "daily",
                value: [
                    "weather_code",
                    "temperature_2m_max",
                    "temperature_2m_min",
                    "precipitation_sum",
                    "precipitation_probability_max",
                    "wind_speed_10m_max",
                ].joined(separator: ",")
            ),
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL
        }
        return url
    }
}

//
//  WeatherError.swift
//  AquaGuard
//

import Foundation

enum WeatherError: LocalizedError, Equatable {
    case invalidURL
    case invalidCoordinates
    case missingData(String)
    case httpStatus(Int)
    case decodingFailed
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid weather service URL"
        case .invalidCoordinates:
            return "Invalid location coordinates"
        case .missingData(let field):
            return "Weather data incomplete (\(field))"
        case .httpStatus(let code):
            return "Weather service returned status \(code)"
        case .decodingFailed:
            return "Could not read weather data"
        case .network(let message):
            return "Weather network error: \(message)"
        }
    }
}

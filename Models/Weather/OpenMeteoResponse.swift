//
//  OpenMeteoResponse.swift
//  AquaGuard
//
//  Codable types matching Open-Meteo Forecast API JSON.
//  https://open-meteo.com/en/docs
//

import Foundation

// MARK: - API response root

struct OpenMeteoResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: OpenMeteoCurrent?
    let hourly: OpenMeteoHourly?
    let daily: OpenMeteoDaily?

    func toDomain(fetchedAt: Date = Date()) throws -> WeatherForecast {
        guard let currentPayload = current else {
            throw WeatherError.missingData("current")
        }
        guard let hourlyPayload = hourly else {
            throw WeatherError.missingData("hourly")
        }
        guard let dailyPayload = daily else {
            throw WeatherError.missingData("daily")
        }

        let currentWeather = try currentPayload.toDomain()
        let hourlyItems = try hourlyPayload.toDomainItems()
        let dailyItems = try dailyPayload.toDomainItems()

        return WeatherForecast(
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            current: currentWeather,
            hourly: hourlyItems,
            daily: dailyItems,
            fetchedAt: fetchedAt
        )
    }
}

// MARK: - Current

struct OpenMeteoCurrent: Decodable {
    let time: String
    let temperature2m: Double
    let precipitation: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let relativeHumidity2m: Int?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case relativeHumidity2m = "relative_humidity_2m"
    }

    func toDomain() throws -> CurrentWeather {
        guard let parsedTime = OpenMeteoDateParser.parse(time) else {
            throw WeatherError.missingData("current.time")
        }
        return CurrentWeather(
            time: parsedTime,
            temperatureCelsius: temperature2m,
            precipitationMm: precipitation,
            weatherCode: weatherCode,
            windSpeedKmh: windSpeed10m,
            relativeHumidityPercent: relativeHumidity2m
        )
    }
}

// MARK: - Hourly (parallel arrays)

struct OpenMeteoHourly: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let precipitationProbability: [Int]?
    let precipitation: [Double]
    let weatherCode: [Int]
    let windSpeed10m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }

    func toDomainItems() throws -> [HourlyForecastItem] {
        let count = time.count
        guard count > 0,
              temperature2m.count == count,
              precipitation.count == count,
              weatherCode.count == count,
              windSpeed10m.count == count
        else {
            throw WeatherError.missingData("hourly arrays length mismatch")
        }

        var items: [HourlyForecastItem] = []
        items.reserveCapacity(count)

        for index in 0..<count {
            guard let parsedTime = OpenMeteoDateParser.parse(time[index]) else { continue }
            let precipProb: Int? = precipitationProbability.flatMap { probs in
                index < probs.count ? probs[index] : nil
            }
            items.append(
                HourlyForecastItem(
                    time: parsedTime,
                    temperatureCelsius: temperature2m[index],
                    precipitationProbabilityPercent: precipProb,
                    precipitationMm: precipitation[index],
                    weatherCode: weatherCode[index],
                    windSpeedKmh: windSpeed10m[index]
                )
            )
        }
        return items
    }
}

// MARK: - Daily (parallel arrays)

struct OpenMeteoDaily: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationSum: [Double]
    let precipitationProbabilityMax: [Int]?
    let windSpeed10mMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case windSpeed10mMax = "wind_speed_10m_max"
    }

    func toDomainItems() throws -> [DailyForecastItem] {
        let count = time.count
        guard count > 0,
              weatherCode.count == count,
              temperature2mMax.count == count,
              temperature2mMin.count == count,
              precipitationSum.count == count,
              windSpeed10mMax.count == count
        else {
            throw WeatherError.missingData("daily arrays length mismatch")
        }

        var items: [DailyForecastItem] = []
        items.reserveCapacity(count)

        for index in 0..<count {
            guard let parsedDate = OpenMeteoDateParser.parseDaily(time[index]) else { continue }
            let precipProbMax: Int? = precipitationProbabilityMax.flatMap { probs in
                index < probs.count ? probs[index] : nil
            }
            items.append(
                DailyForecastItem(
                    date: parsedDate,
                    weatherCode: weatherCode[index],
                    temperatureMaxCelsius: temperature2mMax[index],
                    temperatureMinCelsius: temperature2mMin[index],
                    precipitationSumMm: precipitationSum[index],
                    precipitationProbabilityMaxPercent: precipProbMax,
                    windSpeedMaxKmh: windSpeed10mMax[index]
                )
            )
        }
        return items
    }
}

// MARK: - Date parsing

enum OpenMeteoDateParser {
    private static let hourlyFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let hourlyFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dailyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func parse(_ isoString: String) -> Date? {
        if let date = hourlyFormatter.date(from: isoString) { return date }
        return hourlyFormatterNoFraction.date(from: isoString)
    }

    static func parseDaily(_ dateString: String) -> Date? {
        dailyFormatter.date(from: dateString)
    }
}

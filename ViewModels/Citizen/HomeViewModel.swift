//
//  HomeViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Combine
import CoreLocation
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeAlerts: [CommunityReport] = CommunityReport.dummyReports
    @Published var currentRiskLocation: String = ""
    @Published var currentRiskLevel: SeverityLevel = .moderate
    @Published var weatherSummary: String = ""
    @Published var statusActionLine: String = ""
    @Published var isLoadingWeather: Bool = false
    @Published var weatherError: String?
    @Published var lastWeatherUpdate: Date?
    @Published var signOutError: String?

    private let locationService: LocationService
    private let weatherService: WeatherProviding
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    private let enablesWeatherUpdates: Bool
    private var weatherTask: Task<Void, Never>?

    init(
        locationService: LocationService,
        weatherService: WeatherProviding = OpenMeteoService.shared,
        enablesWeatherUpdates: Bool = true
    ) {
        self.locationService = locationService
        self.weatherService = weatherService
        self.enablesWeatherUpdates = enablesWeatherUpdates

        guard enablesWeatherUpdates else { return }

        locationService.$currentLocation
            .compactMap { $0 }
            .removeDuplicates { lhs, rhs in
                abs(lhs.latitude - rhs.latitude) < 0.005
                    && abs(lhs.longitude - rhs.longitude) < 0.005
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.reverseGeocode(coordinate: coordinate)
                self?.scheduleWeatherRefresh(for: coordinate, forceRefresh: false)
            }
            .store(in: &cancellables)
    }

    /// Settings sign-out only — does not subscribe to location or weather.
    convenience init() {
        self.init(
            locationService: LocationService(),
            enablesWeatherUpdates: false
        )
    }

    func onAppear() {
        guard enablesWeatherUpdates else { return }
        locationService.requestPermission()
        locationService.requestCurrentLocation()

        if let coordinate = locationService.currentLocation {
            if currentRiskLocation.isEmpty {
                reverseGeocode(coordinate: coordinate)
            }
            scheduleWeatherRefresh(for: coordinate, forceRefresh: false)
        } else {
            currentRiskLocation = ""
            statusActionLine = localized("Enable location to see your local risk")
        }
    }

    func refreshWeatherRisk(forceRefresh: Bool = true) async {
        guard enablesWeatherUpdates else { return }

        guard let coordinate = locationService.currentLocation else {
            weatherError = nil
            statusActionLine = localized("Enable location to see your local risk")
            return
        }

        weatherTask?.cancel()
        weatherTask = Task {
            await loadWeather(for: coordinate, forceRefresh: forceRefresh)
        }
        await weatherTask?.value
    }

    func signOut() {
        AppState.shared.logout()
    }

    // MARK: - Weather

    private func scheduleWeatherRefresh(
        for coordinate: CLLocationCoordinate2D,
        forceRefresh: Bool
    ) {
        weatherTask?.cancel()
        weatherTask = Task {
            await loadWeather(for: coordinate, forceRefresh: forceRefresh)
        }
    }

    private func loadWeather(
        for coordinate: CLLocationCoordinate2D,
        forceRefresh: Bool
    ) async {
        guard !Task.isCancelled else { return }

        isLoadingWeather = true
        weatherError = nil

        do {
            let forecast = try await weatherService.fetchForecast(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                forceRefresh: forceRefresh
            )
            guard !Task.isCancelled else { return }

            let snapshot = forecast.snapshot
            currentRiskLevel = WeatherRiskCalculator.evaluate(snapshot: snapshot)
            weatherSummary = snapshot.summaryLine
            lastWeatherUpdate = forecast.fetchedAt
            statusActionLine = actionLine(for: currentRiskLevel)
            weatherError = nil
        } catch {
            guard !Task.isCancelled else { return }
            if let weatherError = error as? WeatherError {
                self.weatherError = weatherError.localizedDescription
            } else {
                self.weatherError = error.localizedDescription
            }
            statusActionLine = localized("Could not load weather data")
            if weatherSummary.isEmpty {
                weatherSummary = ""
            }
        }

        isLoadingWeather = false
    }

    private func actionLine(for level: SeverityLevel) -> String {
        switch level {
        case .low:
            return localized("Conditions look stable near you")
        case .moderate:
            return localized("Stay alert for changing weather")
        case .severe:
            return localized("Limit travel and prepare for flooding")
        case .critical:
            return localized("Take immediate precautions")
        }
    }

    // MARK: - Geocoding

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(
            location,
            preferredLocale: Locale(identifier: "vi_VN")
        ) { [weak self] placemarks, _ in
            Task { @MainActor in
                guard let self else { return }
                if let placemark = placemarks?.first {
                    self.currentRiskLocation = Self.formatPlacemark(placemark)
                } else {
                    self.currentRiskLocation = Self.formatCoordinate(coordinate)
                }
            }
        }
    }

    private static func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var streetParts: [String] = []
        if let number = placemark.subThoroughfare { streetParts.append(number) }
        if let street = placemark.thoroughfare { streetParts.append(street) }

        var fullParts: [String] = []
        if !streetParts.isEmpty {
            fullParts.append(streetParts.joined(separator: " "))
        }
        if let ward = placemark.subLocality { fullParts.append(ward) }
        if let district = placemark.subAdministrativeArea { fullParts.append(district) }
        if let city = placemark.locality { fullParts.append(city) }

        if fullParts.count >= 2 {
            return fullParts.joined(separator: ", ")
        }
        return placemark.name ?? placemark.locality ?? formatCoordinate(
            CLLocationCoordinate2D(
                latitude: placemark.location?.coordinate.latitude ?? 0,
                longitude: placemark.location?.coordinate.longitude ?? 0
            )
        )
    }

    private static func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    private func localized(_ key: String) -> String {
        LanguageManager.shared.localize(key)
    }
}

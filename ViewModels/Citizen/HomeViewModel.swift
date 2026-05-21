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
    @Published var weatherMetrics: WeatherCardMetrics?
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
    private var locationDebounceTask: Task<Void, Never>?
    private var pendingCoordinate: CLLocationCoordinate2D?
    private var weatherLoadGeneration = 0

    init(
        locationService: LocationService,
        weatherService: WeatherProviding = OpenMeteoService.shared,
        enablesWeatherUpdates: Bool = true
    ) {
        self.locationService = locationService
        self.weatherService = weatherService
        self.enablesWeatherUpdates = enablesWeatherUpdates

        guard enablesWeatherUpdates else { return }

        DevWeatherSettings.shared.$statusSimulation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleDevSimulationModeChange()
            }
            .store(in: &cancellables)

        locationService.$currentLocation
            .compactMap { $0 }
            .removeDuplicates { lhs, rhs in
                abs(lhs.latitude - rhs.latitude) < 0.005
                    && abs(lhs.longitude - rhs.longitude) < 0.005
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                guard let self else { return }
                if DevWeatherSettings.shared.isSimulating {
                    self.applyWeatherSimulation()
                    return
                }
                self.reverseGeocode(coordinate: coordinate)
                self.scheduleWeatherRefresh(for: coordinate, forceRefresh: false)
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

        if DevWeatherSettings.shared.isSimulating {
            applyWeatherSimulation()
            return
        }

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

    /// Pull-to-refresh — runs outside SwiftUI's refreshable cancellation hierarchy.
    func refreshWeatherRisk(forceRefresh: Bool = true) async {
        guard enablesWeatherUpdates else { return }

        if DevWeatherSettings.shared.isSimulating {
            applyWeatherSimulation()
            return
        }

        locationDebounceTask?.cancel()
        locationDebounceTask = nil
        locationService.requestCurrentLocation()

        let coordinate = locationService.currentLocation
        guard let coordinate else {
            weatherError = nil
            weatherMetrics = nil
            statusActionLine = localized("Enable location to see your local risk")
            return
        }

        await Task.detached(priority: .userInitiated) { @MainActor in
            await self.executeWeatherLoad(
                for: coordinate,
                forceRefresh: forceRefresh
            )
        }.value
    }

    func signOut() {
        AppState.shared.logout()
    }

    // MARK: - Weather

    private func scheduleWeatherRefresh(
        for coordinate: CLLocationCoordinate2D,
        forceRefresh: Bool
    ) {
        if DevWeatherSettings.shared.isSimulating {
            applyWeatherSimulation()
            return
        }

        pendingCoordinate = coordinate
        locationDebounceTask?.cancel()
        locationDebounceTask = Task {
            // Debounce rapid GPS updates so in-flight Open-Meteo calls are not cancelled.
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let coordinate = pendingCoordinate else { return }
            await executeWeatherLoad(for: coordinate, forceRefresh: forceRefresh)
        }
    }

    private func executeWeatherLoad(
        for coordinate: CLLocationCoordinate2D,
        forceRefresh: Bool
    ) async {
        weatherLoadGeneration += 1
        let generation = weatherLoadGeneration
        await performWeatherLoad(
            for: coordinate,
            forceRefresh: forceRefresh,
            generation: generation
        )
    }

    private func performWeatherLoad(
        for coordinate: CLLocationCoordinate2D,
        forceRefresh: Bool,
        generation: Int
    ) async {
        if DevWeatherSettings.shared.isSimulating {
            applyWeatherSimulation()
            return
        }

        isLoadingWeather = true
        weatherError = nil

        defer {
            if generation == weatherLoadGeneration {
                isLoadingWeather = false
            }
        }

        do {
            let forecast = try await weatherService.fetchForecast(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                forceRefresh: forceRefresh
            )
            guard generation == weatherLoadGeneration else { return }

            let snapshot = forecast.snapshot
            currentRiskLevel = WeatherRiskCalculator.evaluate(snapshot: snapshot)
            weatherSummary = snapshot.summaryLine
            weatherMetrics = WeatherCardMetrics.from(current: snapshot.current)
            lastWeatherUpdate = forecast.fetchedAt
            statusActionLine = actionLine(for: currentRiskLevel)
            weatherError = nil
        } catch {
            if Self.isBenignCancellation(error) {
                return
            }
            guard generation == weatherLoadGeneration else { return }

            #if DEBUG
            print("HomeViewModel: weather load failed — \(error)")
            #endif

            weatherSummary = ""
            weatherMetrics = nil
            weatherError = Self.userFacingWeatherMessage(for: error)
            statusActionLine = localized("Could not load weather data")
        }
    }

    private static func isBenignCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let urlError = error as? URLError
        return urlError?.code == .cancelled
    }

    private static func userFacingWeatherMessage(for error: Error) -> String {
        if let weatherError = error as? WeatherError {
            return weatherError.localizedDescription
        }
        return error.localizedDescription
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

    private func handleDevSimulationModeChange() {
        guard enablesWeatherUpdates else { return }

        if DevWeatherSettings.shared.isSimulating {
            locationDebounceTask?.cancel()
            locationDebounceTask = nil
            applyWeatherSimulation()
            return
        }

        if let coordinate = locationService.currentLocation {
            reverseGeocode(coordinate: coordinate)
            scheduleWeatherRefresh(for: coordinate, forceRefresh: true)
        }
    }

    private func applyWeatherSimulation() {
        guard let preset = DevWeatherSettings.shared.activePreset else { return }

        weatherLoadGeneration += 1
        locationDebounceTask?.cancel()
        locationDebounceTask = nil

        isLoadingWeather = false
        weatherError = nil
        currentRiskLocation = preset.locationLabel
        currentRiskLevel = preset.level
        weatherSummary = preset.summary
        weatherMetrics = preset.metrics
        statusActionLine = actionLine(for: preset.level)
        lastWeatherUpdate = Date()
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        if DevWeatherSettings.shared.isSimulating {
            if let label = DevWeatherSettings.shared.activePreset?.locationLabel {
                currentRiskLocation = label
            }
            return
        }

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

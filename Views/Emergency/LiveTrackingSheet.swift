//
//  LiveTrackingSheet.swift
//  AquaGuard
//
//  Map sheet showing real-time tracking between
//  the victim and assigned rescuer.
//  Includes MKDirections route polyline drawing.
//

import MapKit
import SwiftUI

struct LiveTrackingSheet: View {
    let request: EmergencyRequest
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    // Map state
    @State private var cameraPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var isLoadingRoute = true

    // Simulated rescuer position (nearby)
    private var rescuerCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: request.latitude + 0.004,
            longitude: request.longitude + 0.003
        )
    }

    // Computed from real route data
    private var distanceText: String {
        guard let route = route else { return "" }
        let km = route.distance / 1000
        if km < 1 {
            return String(format: "%.0f m", route.distance)
        }
        return String(format: "%.1f km", km)
    }

    private var etaText: String {
        guard let route = route else { return "" }
        let minutes = Int(route.expectedTravelTime / 60)
        if minutes < 1 { return "<1 min" }
        return "~\(minutes) min"
    }

    init(request: EmergencyRequest) {
        self.request = request
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: request.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status header
                statusHeader

                // Map with route + pins
                ZStack(alignment: .topTrailing) {
                    Map(position: $cameraPosition) {
                        // Route polyline
                        if let route = route {
                            MapPolyline(route)
                                .stroke(Color.aquaPrimary, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        }

                        // Victim pin
                        Annotation(
                            languageManager.localize("Your Location"),
                            coordinate: request.coordinate
                        ) {
                            VStack(spacing: 0) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.aquaDanger)
                                    .background(Circle().fill(.white).padding(-3))
                                    .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
                            }
                        }

                        // Rescuer pin (if assigned)
                        if request.rescuerId != nil {
                            Annotation(
                                languageManager.localize("Rescuer"),
                                coordinate: rescuerCoord
                            ) {
                                VStack(spacing: 0) {
                                    Image(systemName: "figure.wave")
                                        .font(.system(size: 28))
                                        .foregroundColor(.aquaPrimary)
                                        .background(Circle().fill(.white).padding(-3))
                                        .shadow(color: .aquaPrimary.opacity(0.3), radius: 4, y: 2)
                                }
                            }
                        }
                    }
                    .mapStyle(.standard)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }

                    // Loading indicator
                    if isLoadingRoute && request.rescuerId != nil {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Đang tải lộ trình...")
                                .font(.caption2)
                                .foregroundColor(.aquaSubtitle)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(12)
                    }
                }

                // Request info bar
                requestInfoBar
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Live Tracking"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localize("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.aquaPrimary)
                }
            }
            .task {
                if request.rescuerId != nil {
                    await calculateRoute()
                }
            }
        }
    }

    // MARK: - Route Calculation

    private func calculateRoute() async {
        let dirRequest = MKDirections.Request()
        dirRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: rescuerCoord))
        dirRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: request.coordinate))
        dirRequest.transportType = .automobile

        let directions = MKDirections(request: dirRequest)

        do {
            let response = try await directions.calculate()
            if let firstRoute = response.routes.first {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.route = firstRoute
                    self.isLoadingRoute = false

                    // Fit camera to show the entire route
                    let routeRect = firstRoute.polyline.boundingMapRect
                    let padding = routeRect.size.width * 0.3
                    let paddedRect = routeRect.insetBy(dx: -padding, dy: -padding)
                    self.cameraPosition = .rect(paddedRect)
                }
            }
        } catch {
            print("Route calculation error: \(error.localizedDescription)")
            self.isLoadingRoute = false
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack(spacing: 12) {
            // Status icon with pulse animation
            ZStack {
                if request.status == .inProgress {
                    Circle()
                        .fill(request.status.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                Image(systemName: request.status.icon)
                    .font(.title2)
                    .foregroundColor(request.status.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(request.status.rawValue)
                    .font(.headline)
                    .foregroundColor(.aquaNavy)

                if request.status == .pending {
                    Text(languageManager.localize("Waiting for a rescuer to accept..."))
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                } else if request.status == .inProgress {
                    Text(languageManager.localize("Rescuer is on the way"))
                        .font(.caption)
                        .foregroundColor(.aquaPrimary)
                } else {
                    Text(languageManager.localize("This request has been resolved"))
                        .font(.caption)
                        .foregroundColor(.aquaSafe)
                }
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: request.status.icon)
                    .font(.caption2)
                Text(request.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(request.status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(request.status.color.opacity(0.12))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.aquaCard)
    }

    // MARK: - Request Info Bar

    private var requestInfoBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Route info (show when rescuer assigned and route loaded)
            if request.rescuerId != nil, route != nil {
                HStack(spacing: 12) {
                    VStack(spacing: 3) {
                        Image(systemName: "figure.wave")
                            .font(.system(size: 14))
                            .foregroundColor(.aquaPrimary)
                        Text("Rescuer")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.aquaSubtitle)
                    }

                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            ForEach(0..<6, id: \.self) { _ in
                                Circle()
                                    .fill(Color.aquaPrimary.opacity(0.4))
                                    .frame(width: 4, height: 4)
                            }
                        }
                        Text(distanceText)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.aquaPrimary)
                    }

                    VStack(spacing: 3) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Text("You")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.aquaSubtitle)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ETA")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.aquaSubtitle)
                        Text(etaText)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.aquaPrimary)
                    }
                }

                Divider()
            }

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.aquaPrimary)
                Text(request.address)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaNavy)
                    .lineLimit(1)
            }

            if !request.description.isEmpty {
                Text(request.description)
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                    .lineLimit(2)
            }

            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.aquaSubtitle)
                Text(request.timeAgoString)
                    .font(.caption2)
                    .foregroundColor(.aquaSubtitle)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aquaCard)
    }
}

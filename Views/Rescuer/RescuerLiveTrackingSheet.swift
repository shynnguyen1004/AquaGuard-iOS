//
//  RescuerLiveTrackingSheet.swift
//  AquaGuard
//
//  Map sheet showing real-time tracking between
//  the rescuer and the citizen (victim).
//  Includes MKDirections route polyline drawing.
//

import MapKit
import SwiftUI

struct RescuerLiveTrackingSheet: View {
    let request: SosRequest
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    // Map state
    @State private var cameraPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var isLoadingRoute = true

    // Citizen coordinate (victim location)
    private var citizenCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: request.latitude ?? 10.7769,
            longitude: request.longitude ?? 106.7009
        )
    }

    // Simulated rescuer coordinate (offset from citizen)
    private var rescuerCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (request.latitude ?? 10.7769) + 0.004,
            longitude: (request.longitude ?? 106.7009) + 0.003
        )
    }

    // Computed from real route data
    private var distanceText: String {
        guard let route = route else { return "~1.2 km" }
        let km = route.distance / 1000
        if km < 1 {
            return String(format: "%.0f m", route.distance)
        }
        return String(format: "%.1f km", km)
    }

    private var etaText: String {
        guard let route = route else { return "~8 min" }
        let minutes = Int(route.expectedTravelTime / 60)
        if minutes < 1 { return "<1 min" }
        return "~\(minutes) min"
    }

    init(request: SosRequest) {
        self.request = request
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (request.latitude ?? 10.7769) + 0.002,
                        longitude: (request.longitude ?? 106.7009) + 0.0015
                    ),
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

                        // Citizen (victim) pin — red
                        Annotation(
                            "Nạn nhân",
                            coordinate: citizenCoord
                        ) {
                            VStack(spacing: 0) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.red)
                                    .background(Circle().fill(.white).padding(-3))
                                    .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
                            }
                        }

                        // Rescuer pin — teal
                        Annotation(
                            "Bạn (Rescuer)",
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
                    .mapStyle(.standard)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }

                    // Loading indicator
                    if isLoadingRoute {
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

                // Request info bar at bottom
                requestInfoBar
            }
            .background(Color.aquaBackground)
            .navigationTitle("Live Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.aquaPrimary)
                }
            }
            .task {
                await calculateRoute()
            }
        }
    }

    // MARK: - Route Calculation

    private func calculateRoute() async {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: rescuerCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: citizenCoord))
        request.transportType = .automobile

        let directions = MKDirections(request: request)

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
            // Pulse icon
            ZStack {
                Circle()
                    .fill(Color.aquaPrimary.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "location.fill.viewfinder")
                    .font(.title2)
                    .foregroundColor(.aquaPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Đang theo dõi")
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                Text("Đang trên đường đến vị trí nạn nhân")
                    .font(.caption)
                    .foregroundColor(.aquaPrimary)
            }

            Spacer()

            // LIVE badge
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.12))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.aquaCard)
    }

    // MARK: - Request Info Bar

    private var requestInfoBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Route indicator with real data
            HStack(spacing: 12) {
                // Rescuer icon
                VStack(spacing: 3) {
                    Image(systemName: "figure.wave")
                        .font(.system(size: 14))
                        .foregroundColor(.aquaPrimary)
                    Text("Rescuer")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.aquaSubtitle)
                }

                // Dotted route line + distance
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

                // Citizen icon
                VStack(spacing: 3) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    Text("Citizen")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.aquaSubtitle)
                }

                Spacer()

                // ETA from real route
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

            // Location info
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaNavy)
                    Text(request.location ?? "Unknown location")
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                        .lineLimit(1)
                }

                Spacer()

                // Urgency
                Text(request.urgencyLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(request.urgencyColor)
                    .cornerRadius(6)
            }

            // Description
            if let desc = request.description {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                    .lineLimit(2)
            }

            // GPS coordinates
            if let lat = request.latitude, let lng = request.longitude {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("GPS: \(String(format: "%.5f", lat)), \(String(format: "%.5f", lng))")
                        .font(.caption2)
                        .foregroundColor(.aquaPrimary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aquaCard)
    }
}

//
//  FloodMapView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import MapKit
import SwiftUI

struct FloodMapView: View {
    @StateObject var viewModel: MapViewModel

    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: MapViewModel(locationService: locationService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Map Content (Apple or Windy)
            Group {
                if viewModel.mapMode == .apple {
                    appleMapView
                        .transition(.opacity)
                } else {
                    WindyMapView(
                        apiKey: viewModel.windyAPIKey,
                        overlay: viewModel.selectedWeatherLayer.windyKey,
                        centerLat: 16.352147,
                        centerLon: 107.016871,
                        zoom: 6,
                        currentOverlay: Binding(
                            get: { viewModel.selectedWeatherLayer.windyKey },
                            set: { _ in }
                        )
                    )
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea(edges: .all)
            .animation(.easeInOut(duration: 0.3), value: viewModel.mapMode)

            // Clear route button (visible when navigating on Apple Maps)
            if viewModel.route != nil && viewModel.mapMode == .apple {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation { viewModel.clearRoute() }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                        .padding(.top, 70)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // MARK: - Right Side Floating Buttons
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // Location button
                        Button(action: {
                            viewModel.checkLocationPermission()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.aquaPrimary)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3, x: 0, y: 2)
                        }

                        // Layer toggle button (Apple ↔ Windy)
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if viewModel.mapMode == .apple {
                                    viewModel.mapMode = .windy
                                    viewModel.showWeatherPanel = true
                                } else {
                                    viewModel.mapMode = .apple
                                    viewModel.showWeatherPanel = false
                                }
                            }
                        }) {
                            Image(
                                systemName: viewModel.mapMode == .apple
                                    ? "globe.americas.fill" : "map.fill"
                            )
                            .font(.title2)
                            .foregroundColor(
                                viewModel.mapMode == .windy ? .white : .aquaPrimary
                            )
                            .padding(12)
                            .background(
                                viewModel.mapMode == .windy
                                    ? Color.aquaPrimary : Color.white
                            )
                            .clipShape(Circle())
                            .shadow(radius: 3, x: 0, y: 2)
                        }

                        // Weather panel toggle (only in Windy mode)
                        if viewModel.mapMode == .windy {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.showWeatherPanel.toggle()
                                }
                            }) {
                                Image(systemName: "cloud.sun.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3, x: 0, y: 2)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 100)
                }
                Spacer()
            }

            // MARK: - Weather Layer Panel (Windy mode only)
            if viewModel.mapMode == .windy && viewModel.showWeatherPanel {
                VStack {
                    HStack(spacing: 0) {
                        Spacer()
                        WeatherLayerPanel(
                            selectedLayer: $viewModel.selectedWeatherLayer,
                            isVisible: $viewModel.showWeatherPanel,
                            onHideWeatherMap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.mapMode = .apple
                                    viewModel.showWeatherPanel = false
                                }
                            }
                        )
                        // 16 (button trailing) + 48 (button size) + 8 (gap) = 72
                        .padding(.trailing, 72)
                        .padding(.top, 100)
                    }
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity),
                    removal: .scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity)
                ))
            }

            // MARK: - Map Legend (Apple Maps only)
            if viewModel.mapMode == .apple {
                VStack {
                    HStack(spacing: 12) {
                        Label("Safe", systemImage: "circle.fill")
                            .foregroundColor(.aquaSafe)
                            .font(.caption)
                        Label("Moderate", systemImage: "circle.fill")
                            .foregroundColor(.aquaWarning)
                            .font(.caption)
                        Label("Severe", systemImage: "circle.fill")
                            .foregroundColor(.aquaDanger)
                            .font(.caption)
                        Label("Critical", systemImage: "circle.fill")
                            .foregroundColor(.aquaCritical)
                            .font(.caption)
                    }
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    Spacer()
                }
                .padding(.top, 65)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(edges: .all)
        .sheet(item: $viewModel.selectedZone) { zone in
            ZoneDetailSheet(zone: zone, viewModel: viewModel)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Apple Map View (extracted)

    private var appleMapView: some View {
        Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedZone) {
            // User Location
            UserAnnotation()

            // Flood Zones Pins
            ForEach(viewModel.zones) { zone in
                Marker(zone.name, coordinate: zone.coordinate)
                    .tint(zone.severity.color)
                    .tag(zone)
            }

            // Draw route polyline if available
            if let route = viewModel.route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            // Use custom locate button instead of default MapUserLocationButton
            MapCompass()
            MapScaleView()
        }
    }
}

// --- CẬP NHẬT SHEET CHI TIẾT ---
struct ZoneDetailSheet: View {
    let zone: FloodZone
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(zone.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.aquaNavy)
                .padding(.top)

            HStack(spacing: 40) {
                VStack {
                    Text("Severity").font(.caption).foregroundColor(.gray)
                    Text(zone.severity.rawValue.capitalized).font(.headline).foregroundColor(
                        zone.severity.color)
                }
                Divider().frame(height: 40)
                VStack {
                    Text("Water Level").font(.caption).foregroundColor(.gray)
                    Text("\(String(format: "%.1f", zone.waterLevel))m").font(.headline)
                        .foregroundColor(.aquaNavy)
                }
            }

            // --- NÚT NAVIGATE MỚI ---
            Button(action: {
                // Request directions
                viewModel.getDirections(to: zone)
                // Dismiss sheet
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Show Route")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.aquaPrimary)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

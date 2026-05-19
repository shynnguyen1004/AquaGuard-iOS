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

                        // Flood zone pins toggle (only in Apple Maps mode)
                        if viewModel.mapMode == .apple {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.showFloodZones.toggle()
                                }
                            }) {
                                Image(systemName: viewModel.showFloodZones ? "mappin.circle.fill" : "mappin.slash")
                                    .font(.title2)
                                    .foregroundColor(viewModel.showFloodZones ? .aquaPrimary : .gray)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3, x: 0, y: 2)
                            }
                            .transition(.scale.combined(with: .opacity))

                            // Family members toggle
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.showFamilyOnMap.toggle()
                                }
                            }) {
                                Image(systemName: viewModel.showFamilyOnMap ? "person.2.fill" : "person.2.slash")
                                    .font(.title3)
                                    .foregroundColor(viewModel.showFamilyOnMap ? .orange : .gray)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3, x: 0, y: 2)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 120)
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
                        .padding(.top, 120)
                    }
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity),
                    removal: .scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity)
                ))
            }

            // MARK: - Map Legend (Apple Maps only, when pins visible)
            if viewModel.mapMode == .apple && viewModel.showFloodZones {
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
                .padding(.top, 80)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(edges: .all)
        .sheet(item: $viewModel.selectedZone) { zone in
            ZoneDetailSheet(zone: zone, viewModel: viewModel)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.selectedFamilyMember) { member in
            FamilyMemberMapSheet(member: member)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Apple Map View (extracted)

    private var appleMapView: some View {
        Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedZone) {
            // User Location
            UserAnnotation()

            // Flood Zones Pins (conditionally shown)
            if viewModel.showFloodZones {
                ForEach(viewModel.zones) { zone in
                    Marker(zone.name, coordinate: zone.coordinate)
                        .tint(zone.severity.color)
                        .tag(zone)
                }
            }

            // Family Members (conditionally shown)
            if viewModel.showFamilyOnMap {
                ForEach(viewModel.familyMembers) { member in
                    Annotation(
                        member.shortName,
                        coordinate: member.coordinate,
                        anchor: .bottom
                    ) {
                        FamilyMapPin(member: member) {
                            viewModel.selectedFamilyMember = member
                        }
                    }
                }
            }

            // Draw route polyline if available
            if let route = viewModel.route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

// MARK: - Family Map Pin

struct FamilyMapPin: View {
    let member: FamilyMember
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    // Status ring
                    Circle()
                        .stroke(member.status.color, lineWidth: 3)
                        .frame(width: 40, height: 40)
                    // Avatar
                    Circle()
                        .fill(member.avatarColor)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(member.avatarInitial)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                    // Status dot
                    Circle()
                        .fill(member.status.color)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 14, y: 14)
                }
                // Triangle pointer
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(member.avatarColor)
                    .rotationEffect(.degrees(180))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Family Member Map Sheet

struct FamilyMemberMapSheet: View {
    let member: FamilyMember
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // Avatar + Name
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(member.status.color, lineWidth: 3)
                        .frame(width: 56, height: 56)
                    Circle()
                        .fill(member.avatarColor)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(member.avatarInitial)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                    HStack(spacing: 4) {
                        Image(systemName: member.status.icon)
                            .font(.system(size: 12))
                            .foregroundColor(member.status.color)
                        Text(member.status.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(member.status.color)
                    }
                }
                Spacer()

                Text(member.relationship)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.aquaPrimary.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.top)

            // Details
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title3)
                        .foregroundColor(.aquaPrimary)
                    Text(member.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(.aquaPrimary)
                    Text(member.lastSeenString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.aquaPrimary)
                    Text(member.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Call button
            Button(action: {
                if let url = URL(string: "tel://\(member.phone.replacingOccurrences(of: " ", with: ""))") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Call")
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
        .padding(.horizontal)
        .padding(.bottom)
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

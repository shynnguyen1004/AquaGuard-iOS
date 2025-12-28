//
//  Untitled.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI
import MapKit

struct FloodMapView: View {
    @StateObject var viewModel = MapViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // FIX: Sử dụng selection với Hashable FloodZone
            Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedZone) {
                ForEach(viewModel.zones) { zone in
                    Marker(zone.name, coordinate: zone.coordinate)
                        .tint(zone.severity.color)
                        .tag(zone) // Tag hoạt động được nhờ FloodZone đã Hashable
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            
            // Map Legend
            VStack {
                HStack(spacing: 12) {
                    Label("Safe", systemImage: "circle.fill")
                        .foregroundColor(.aquaSafe)
                        .font(.caption)
                    Label("Severe", systemImage: "circle.fill")
                        .foregroundColor(.aquaDanger)
                        .font(.caption)
                    Label("Moderate", systemImage: "circle.fill")
                        .foregroundColor(.aquaWarning)
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
            .padding(.top, 50)
        }
        .sheet(item: $viewModel.selectedZone) { zone in
            ZoneDetailSheet(zone: zone)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct ZoneDetailSheet: View {
    let zone: FloodZone
    
    var body: some View {
        VStack(spacing: 20) {
            Text(zone.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.aquaNavy)
                .padding(.top)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Severity")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(zone.severity.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(zone.severity.color)
                }
                
                Divider().frame(height: 40)
                
                VStack {
                    Text("Water Level")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", zone.waterLevel))m")
                        .font(.headline)
                        .foregroundColor(.aquaNavy)
                }
            }
            
            Button(action: {}) {
                Text("Navigate to Zone")
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

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
            // 1. MAP VIEW
            Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedZone) {
                // BỔ SUNG: Hiển thị chấm xanh vị trí người dùng
                UserAnnotation()
                
                // CODE CŨ: Hiển thị các vùng ngập
                ForEach(viewModel.zones) { zone in
                    Marker(zone.name, coordinate: zone.coordinate)
                        .tint(zone.severity.color)
                        .tag(zone)
                }
            }
            .mapControls {
                // Bỏ MapUserLocationButton() mặc định đi để dùng nút custom xịn hơn ở dưới
                MapCompass()
                MapScaleView()
            }
            
            // 2. NÚT LOCATE (CUSTOM BUTTON) - Nằm góc trên phải
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.checkLocationPermission()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.aquaNavy)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 60) // Cách tai thỏ một chút
                }
                Spacer()
            }
            
            // 3. MAP LEGEND (CODE CŨ GIỮ NGUYÊN)
            VStack {
                HStack(spacing: 12) {
                    Label("Safe", systemImage: "circle.fill")
                        .foregroundColor(.aquaSafe) // Đảm bảo bạn có màu này trong Assets hoặc Extension
                        .font(.caption)
                    Label("Severe", systemImage: "circle.fill")
                        .foregroundColor(.aquaDanger) // Đảm bảo bạn có màu này
                        .font(.caption)
                    Label("Moderate", systemImage: "circle.fill")
                        .foregroundColor(.aquaWarning) // Đảm bảo bạn có màu này
                        .font(.caption)
                    Label("Critical", systemImage: "circle.fill")
                        .foregroundColor(.aquaCritical) // Đảm bảo bạn có màu này
                        .font(.caption)
                }
                .padding(8)
                .background(.thinMaterial)
                .cornerRadius(20)
                Spacer() // Đẩy Legend lên trên một chút nếu cần, hoặc để nó nằm dưới cùng
            }
            .padding(.top, 30) // Cách đáy màn hình một chút
        }
        .sheet(item: $viewModel.selectedZone) { zone in
            ZoneDetailSheet(zone: zone)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
}

// Struct ZoneDetailSheet giữ nguyên như cũ...
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
                    .background(Color.aquaPrimary) // Đảm bảo màu này tồn tại
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

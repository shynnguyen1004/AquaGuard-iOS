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
                // User Location
                UserAnnotation()
                
                // Flood Zones Pins
                ForEach(viewModel.zones) { zone in
                    Marker(zone.name, coordinate: zone.coordinate)
                        .tint(zone.severity.color)
                        .tag(zone)
                }
                
                // --- VẼ ĐƯỜNG ĐI NẾU CÓ ---
                if let route = viewModel.route {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5) // Đường màu xanh, dày 5pt
                }
            }
            .mapControls {
                // Bỏ MapUserLocationButton() mặc định đi để dùng nút custom xịn hơn ở dưới
                MapCompass()
                MapScaleView()
            }
            
            // --- NÚT XÓA ĐƯỜNG ĐI (Hiện ra khi đang dẫn đường) ---
            if viewModel.route != nil {
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
            
            // 2. NÚT LOCATE (CUSTOM BUTTON) - Nằm góc trên phải
            VStack {
                HStack {
                    Spacer()
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
                    .padding(.trailing, 16)
                    .padding(.top, 70) // Cách tai thỏ một chút
                }
                Spacer()
            }
            
            // 3. MAP LEGEND (CODE CŨ GIỮ NGUYÊN)
            VStack {
                HStack(spacing: 12) {
                    Label("Safe", systemImage: "circle.fill")
                        .foregroundColor(.aquaSafe) // Đảm bảo bạn có màu này trong Assets hoặc Extension
                        .font(.caption)
                    Label("Moderate", systemImage: "circle.fill")
                        .foregroundColor(.aquaWarning) // Đảm bảo bạn có màu này
                        .font(.caption)
                    Label("Severe", systemImage: "circle.fill")
                        .foregroundColor(.aquaDanger) // Đảm bảo bạn có màu này
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
            ZoneDetailSheet(zone: zone, viewModel: viewModel)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
}

// --- CẬP NHẬT SHEET CHI TIẾT ---
struct ZoneDetailSheet: View {
    let zone: FloodZone
    @ObservedObject var viewModel: MapViewModel // Nhận viewModel từ cha
    @Environment(\.dismiss) var dismiss // Để đóng sheet sau khi bấm nút
    
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
                    Text(zone.severity.rawValue.capitalized).font(.headline).foregroundColor(zone.severity.color)
                }
                Divider().frame(height: 40)
                VStack {
                    Text("Water Level").font(.caption).foregroundColor(.gray)
                    Text("\(String(format: "%.1f", zone.waterLevel))m").font(.headline).foregroundColor(.aquaNavy)
                }
            }
            
            // --- NÚT NAVIGATE MỚI ---
            Button(action: {
                // 1. Gọi hàm tìm đường
                viewModel.getDirections(to: zone)
                // 2. Đóng sheet lại để user nhìn thấy bản đồ
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
                .background(Color.aquaPrimary) // Đổi màu xanh dương cho giống nút dẫn đường chuẩn
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

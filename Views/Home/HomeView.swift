//
//  HomeView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Image("AquaLogoHeader")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding(.top, -20)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Responder Alpha")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.aquaNavy)
                        }
                        Spacer()
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Risk Status Card
                    StatusCard(location: viewModel.currentRiskLocation, level: viewModel.currentRiskLevel)
                        .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.aquaNavy)
                            .padding(.horizontal)
                        
                        HStack(spacing: 15) {
                            // Nút Shelter (Giữ nguyên)
                            QuickActionButton(icon: "house.fill", label: "Shelter", color: .aquaPrimary)
                            
                            // Nút SOS (Đã chỉnh sửa: Nền đỏ, chữ trắng)
                            Button(action: {}) {
                                VStack(spacing: 10) {
                                    // Tạo hình tròn mờ làm nền cho Icon
                                    Circle()
                                        .fill(Color.white.opacity(0.2)) // Màu trắng mờ 20%
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "phone.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text("SOS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.94, green: 0.27, blue: 0.27)) // Nền đỏ full nút
                                .cornerRadius(15)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            
                            // Nút Family (Giữ nguyên)
                            QuickActionButton(icon: "person.2.fill", label: "Family", color: .orange)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Active Alerts
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Active Alerts")
                                .font(.headline)
                                .foregroundColor(.aquaNavy)
                            Spacer()
                            Text("\(viewModel.activeAlerts.count) Active")
                                .font(.caption)
                                .padding(6)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        ForEach(viewModel.activeAlerts) { alert in
                            AlertRow(alert: alert)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color.aquaBackground)
            .navigationTitle("AquaGuard")
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Subcomponents
struct StatusCard: View {
    let location: String
    let level: SeverityLevel
    
    // 1. Logic xác định Tiêu đề dựa trên level
    private var statusTitle: String {
        switch level {
        case .low: return "Safe"
        case .moderate: return "Caution"
        case .severe: return "Danger"
        case .critical: return "Critical"
        }
    }
    
    // 2. Logic xác định Màu nền
    private var backgroundColor: Color {
        switch level {
        case .low: return Color.aquaSafe // Hoặc dùng Color("aquaSafe") nếu bạn có
        case .moderate: return Color.aquaWarning
        case .severe: return Color.aquaDanger
        case .critical: return Color.aquaCritical //(red: 0.6, green: 0, blue: 0) // Màu đỏ đậm/huyết dụ cho Critical
        }
    }
    
    // 3. Logic xác định Icon
    private var iconName: String {
        switch level {
        case .low: return "checkmark.shield.fill"
        case .moderate: return "cloud.sun.fill"
        case .severe: return "cloud.heavyrain.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Current Status")
                }
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                
                // Sử dụng biến statusTitle đã định nghĩa ở trên
                Text(statusTitle)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
                Text("Location: \(location)")
                    .font(.subheadline)
                    .opacity(0.9)
                
                Text("Take action immediately")
                    .font(.caption)
                    .padding(.top, 4)
            }
            Spacer()
            // Sử dụng biến iconName đã định nghĩa ở trên
            Image(systemName: iconName)
                .font(.system(size: 60))
                .opacity(0.8)
        }
        .foregroundColor(.white)
        .padding(20)
        // Sử dụng biến backgroundColor đã định nghĩa ở trên
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: backgroundColor.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 10) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: icon).foregroundColor(color))
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.aquaNavy)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.aquaCard)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct AlertRow: View {
    let alert: Alert
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(alert.severity == .severe ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: alert.iconName)
                    .foregroundColor(alert.severity == .severe ? .red : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaNavy)
                Text(alert.location)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(alert.timeAgo)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.aquaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(alert.severity == .severe ? Color.red : Color.orange, lineWidth: 1)
                .opacity(0.3)
        )
    }
}

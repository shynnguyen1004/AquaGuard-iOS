//
//  HomeView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import FirebaseAuth
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @State private var showLogoutAlert = false

    // UPDATE 1: Nhận Binding để điều khiển TabView
    @Binding var selectedTab: Int

    // UPDATE 2: Biến trạng thái cho thông báo SOS
    @State private var showSOSAlert = false

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
                            Text(Auth.auth().currentUser?.displayName ?? "Responder Alpha")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.aquaNavy)
                        }
                        Spacer()
                        /*Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                         */
                        // --- ĐOẠN CODE MỚI ---
                        // Kiểm tra xem User hiện tại có ảnh Avatar không?
                        // --- ĐOẠN CODE AVATAR CÓ CHỨC NĂNG ĐĂNG XUẤT ---
                        Menu {
                            Button(role: .destructive) {
                                do {
                                    try Auth.auth().signOut()
                                    // Khi đăng xuất, AquaGuardApp sẽ tự động phát hiện
                                    // và chuyển về màn hình LoginView ngay lập tức.
                                } catch {
                                    print("Lỗi đăng xuất: \(error.localizedDescription)")
                                }
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            // Phần giao diện Avatar (Code cũ của bạn nằm trong này)
                            if let photoURL = Auth.auth().currentUser?.photoURL {
                                AsyncImage(url: photoURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(Color.aquaPrimary, lineWidth: 2)
                                            )
                                            .shadow(radius: 3)
                                    default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Risk Status Card
                    StatusCard(
                        location: viewModel.currentRiskLocation, level: viewModel.currentRiskLevel
                    )
                    .padding(.horizontal)

                    // --- QUICK ACTIONS (PHẦN CHỈNH SỬA CHÍNH) ---
                    VStack(alignment: .leading) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.aquaNavy)
                            .padding(.horizontal)

                        HStack(spacing: 15) {
                            // UPDATE 3: Nút Shelter -> Chuyển sang Tab Rescue (Tag 4)
                            QuickActionButton(
                                icon: "house.fill", label: "Shelter", color: .aquaPrimary
                            ) {
                                selectedTab = 4
                            }

                            // UPDATE 4: Nút SOS -> Hiện Alert
                            Button(action: {
                                showSOSAlert = true
                            }) {
                                VStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
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
                                .background(Color(red: 0.94, green: 0.27, blue: 0.27))
                                .cornerRadius(15)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                            }

                            // UPDATE 5: Nút Family -> Chuyển sang Tab Rescue (Tag 4)
                            QuickActionButton(
                                icon: "person.2.fill", label: "Family", color: .orange
                            ) {
                                selectedTab = 4
                            }
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
            .alert("SOS Sent", isPresented: $showSOSAlert) {
                Button("OK") {
                    // Khi bấm OK -> Chuyển sang Tab Safety (Tag 3)
                    selectedTab = 3
                }
            } message: {
                Text("Your information is sent! Stay at your current position and wait for help")
            }
        }
    }
}

// UPDATE 7: Cập nhật QuickActionButton để nhận Action
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var action: () -> Void  // Thêm biến closure hành động

    var body: some View {
        Button(action: action) {  // Gọi action khi bấm
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
        case .low: return Color.aquaSafe  // Hoặc dùng Color("aquaSafe") nếu bạn có
        case .moderate: return Color.aquaWarning
        case .severe: return Color.aquaDanger
        case .critical: return Color.aquaCritical  //(red: 0.6, green: 0, blue: 0) // Màu đỏ đậm/huyết dụ cho Critical
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

struct AlertRow: View {
    let alert: FloodAlert

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        alert.severity == .severe
                            ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)
                    )
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

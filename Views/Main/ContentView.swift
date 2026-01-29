//
//  ContentView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct ContentView: View {
    // 1. Thêm biến quản lý Tab được chọn (Mặc định là 0 - Home)
    @State private var selectedTab = 0
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }
    
    var body: some View {
        // 2. Binding biến selectedTab vào TabView
        TabView(selection: $selectedTab) {
            // 3. Truyền binding xuống HomeView để nút bấm có thể đổi tab
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0) // Đánh dấu số 0
            
            FloodMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1) // Đánh dấu số 1
            
            ReportView()
                .tabItem {
                    Label("Report", systemImage: "exclamationmark.bubble.fill")
                }
                .tag(2) // Đánh dấu số 2
            
            SafetyView()
                .tabItem {
                    Label("Safety", systemImage: "shield.fill")
                }
                .tag(3) // Đánh dấu số 3 (Trang Safety)
            
            RescueView()
                .tabItem {
                    Label("Rescue", systemImage: "dot.radiowaves.left.and.right")
                }
                .tag(4) // Đánh dấu số 4 (Trang Rescue)
        }
        .tint(Color.aquaPrimary)
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var locationService = LocationService()

    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            FloodMapView(locationService: locationService)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)

            ReportView(locationService: locationService)
                .tabItem {
                    Label("Report", systemImage: "exclamationmark.bubble.fill")
                }
                .tag(2)

            SafetyView()
                .tabItem {
                    Label("Safety", systemImage: "shield.fill")
                }
                .tag(3)

            RescueView()
                .tabItem {
                    Label("Rescue", systemImage: "dot.radiowaves.left.and.right")
                }
                .tag(4)
        }
        .tint(Color.aquaPrimary)
    }
}

#Preview {
    ContentView()
}

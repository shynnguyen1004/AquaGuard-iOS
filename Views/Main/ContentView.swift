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
    @EnvironmentObject var languageManager: LanguageManager

    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label(languageManager.localize("Home"), systemImage: "house.fill")
                }
                .tag(0)

            FloodMapView(locationService: locationService)
                .tabItem {
                    Label(languageManager.localize("Map"), systemImage: "map.fill")
                }
                .tag(1)

            EmergencyTabView(locationService: locationService)
                .tabItem {
                    Label(
                        languageManager.localize("Emergency"),
                        systemImage: "sos")
                }
                .tag(2)

            SafetyView()
                .tabItem {
                    Label(languageManager.localize("Safety"), systemImage: "shield.fill")
                }
                .tag(3)

            ProfileView(locationService: locationService)
                .tabItem {
                    Label(languageManager.localize("Profile"), systemImage: "person.crop.circle.fill")
                }
                .tag(4)
        }
        .tint(Color.aquaPrimary)
    }
}

#Preview {
    ContentView()
}

//
//  RescuerContentView.swift
//  AquaGuard
//
//  Main tab view for the Rescuer role.
//  5 tabs: Bản đồ, Yêu cầu, Nhiệm vụ, Đội, Cài đặt
//

import SwiftUI

struct RescuerContentView: View {
    @State private var selectedTab = 0
    @StateObject private var locationService = LocationService()
    @EnvironmentObject var languageManager: LanguageManager

    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FloodMapView(locationService: locationService)
                .tabItem {
                    Label(languageManager.localize("Bản đồ"), systemImage: "map.fill")
                }
                .tag(0)

            RescuerRequestsView()
                .tabItem {
                    Label(languageManager.localize("Yêu cầu"), systemImage: "light.beacon.max.fill")
                }
                .tag(1)

            RescuerDashboardView()
                .tabItem {
                    Label(languageManager.localize("Nhiệm vụ"), systemImage: "doc.text.fill")
                }
                .tag(2)

            RescuerTeamView()
                .tabItem {
                    Label(languageManager.localize("Đội"), systemImage: "person.3.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(languageManager.localize("Cài đặt"), systemImage: "gear")
                }
                .tag(4)
        }
        .tint(Color.aquaPrimary)
    }
}

//
//  AdminContentView.swift
//  AquaGuard
//
//  Main tab view for the Admin role.
//  4 tabs: Quản trị, SOS, Thống kê, Cài đặt
//

import SwiftUI

struct AdminContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView()
                .tabItem {
                    Label(languageManager.localize("Quản trị"), systemImage: "person.badge.shield.checkmark.fill")
                }
                .tag(0)

            AdminSOSView()
                .tabItem {
                    Label(languageManager.localize("SOS"), systemImage: "light.beacon.max.fill")
                }
                .tag(1)

            AdminAnalyticsView()
                .tabItem {
                    Label(languageManager.localize("Thống kê"), systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(languageManager.localize("Cài đặt"), systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.purple)
    }
}

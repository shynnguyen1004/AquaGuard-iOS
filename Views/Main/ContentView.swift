//
//  ContentView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import SwiftUI

struct ContentView: View {
    // Customizing TabBar appearance
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            FloodMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            ReportView()
                .tabItem {
                    Label("Report", systemImage: "exclamationmark.bubble.fill")
                }
            
            SafetyView()
                .tabItem {
                    Label("Safety", systemImage: "shield.fill")
                }
            
            RescueView()
                .tabItem {
                    Label("Rescue", systemImage: "dot.radiowaves.left.and.right")
                }
        }
        .tint(Color.aquaPrimary)
    }
}

#Preview {
    ContentView()
}

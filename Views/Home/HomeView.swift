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
                            QuickActionButton(icon: "phone.fill", label: "Emergency", color: .red)
                            QuickActionButton(icon: "house.fill", label: "Shelter", color: .aquaPrimary)
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
                
                Text(level == .severe ? "Danger" : "Warning")
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
            Image(systemName: level == .severe ? "cloud.heavyrain.fill" : "cloud.rain.fill")
                .font(.system(size: 60))
                .opacity(0.8)
        }
        .foregroundColor(.white)
        .padding(20)
        .background(level == .severe ? Color.aquaDanger : Color.aquaWarning)
        .cornerRadius(20)
        .shadow(color: level.color.opacity(0.4), radius: 10, x: 0, y: 5)
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

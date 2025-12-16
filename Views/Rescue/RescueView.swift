//
//  RescueView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 16/12/25.
//

import SwiftUI

struct ResourceCard: View {
    let icon: String
    let title: String
    let current: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                Spacer()
                Text("\(current)/\(total)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.aquaNavy)
            
            ProgressView(value: Double(current), total: Double(total))
                .tint(color)
        }
        .padding()
        .background(Color.aquaCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct RescueRequestRow: View {
    let address: String
    let people: Int
    let time: String
    let status: String
    let team: String?
    let severityColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 10, height: 10)
                Text(address)
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                Spacer()
                Text(status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            HStack(spacing: 15) {
                Label("\(people) people", systemImage: "person.2")
                Text("•")
                Label(time, systemImage: "clock")
                if let team = team {
                    Text("•")
                    Text(team).foregroundColor(.aquaPrimary)
                }
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            if status == "In Progress" {
                HStack {
                    Button("Track") {}.buttonStyle(.bordered)
                    Button("Complete") {}.buttonStyle(.borderedProminent).tint(.green)
                }
                .controlSize(.small)
            } else if status == "Pending" {
                Button(action: {}) {
                    Text("Assign Team")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.aquaPrimary.opacity(0.2))
                        .foregroundColor(.aquaPrimary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.aquaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(severityColor, lineWidth: status == "Pending" ? 2 : 0)
        )
    }
    
    var statusColor: Color {
        switch status {
        case "In Progress": return .blue
        case "Completed": return .green
        default: return .orange
        }
    }
}

struct RescueView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Resource Availability
                    Text("Resource Availability")
                        .font(.headline).foregroundColor(.aquaNavy)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ResourceCard(icon: "ferry", title: "Rescue Boats", current: 8, total: 12, color: .teal)
                        ResourceCard(icon: "house", title: "Shelters Open", current: 5, total: 8, color: .blue)
                        ResourceCard(icon: "heart", title: "Medical Teams", current: 6, total: 10, color: .orange)
                        ResourceCard(icon: "person.3", title: "Active Rescues", current: 3, total: 3, color: .gray)
                    }
                    .padding(.horizontal)
                    
                    // Rescue Requests
                    HStack {
                        Text("Rescue Requests")
                            .font(.headline).foregroundColor(.aquaNavy)
                        Spacer()
                        Text("2 Pending")
                            .font(.caption).bold()
                            .padding(4).background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(4)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        RescueRequestRow(address: "123 Ly Thuong Kiet", people: 4, time: "10 min ago", status: "In Progress", team: "Team Alpha", severityColor: .orange)
                        RescueRequestRow(address: "456 To Hien Thanh", people: 2, time: "5 min ago", status: "Pending", team: nil, severityColor: .red)
                        RescueRequestRow(address: "789 Nguyen Tri Phuong", people: 6, time: "45 min ago", status: "Completed", team: "Team Bravo", severityColor: .orange)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.aquaBackground)
            .navigationTitle("AquaGuard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

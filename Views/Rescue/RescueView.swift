//
//  RescueView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 16/12/25.
//

import SwiftUI

struct ResourceCard: View {
    let resource: RescueResource

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(resource.color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: resource.icon)
                        .foregroundColor(resource.color)
                }
                Spacer()
                Text("\(resource.current)/\(resource.total)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }

            Text(resource.title)
                .font(.subheadline)
                .foregroundColor(.aquaNavy)

            ProgressView(value: Double(resource.current), total: Double(resource.total))
                .tint(resource.color)
        }
        .padding()
        .background(Color.aquaCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct RescueRequestRow: View {
    let request: RescueRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(request.severityColor)
                    .frame(width: 10, height: 10)
                Text(request.address)
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                Spacer()
                Text(request.status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }

            HStack(spacing: 15) {
                Label("\(request.people) people", systemImage: "person.2")
                Text("•")
                Label(request.time, systemImage: "clock")
                if let team = request.team {
                    Text("•")
                    Text(team).foregroundColor(.aquaPrimary)
                }
            }
            .font(.caption)
            .foregroundColor(.gray)

            if request.status == "In Progress" {
                HStack {
                    Button("Track") {}.buttonStyle(.bordered)
                    Button("Complete") {}.buttonStyle(.borderedProminent).tint(.green)
                }
                .controlSize(.small)
            } else if request.status == "Pending" {
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
                .stroke(request.severityColor, lineWidth: request.status == "Pending" ? 2 : 0)
        )
    }

    var statusColor: Color {
        switch request.status {
        case "In Progress": return .blue
        case "Completed": return .green
        default: return .orange
        }
    }
}

struct RescueView: View {
    @StateObject var viewModel = RescueViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Resource Availability
                    LogoHeaderView()

                    Text("Resource Availability")
                        .font(.headline).foregroundColor(.aquaNavy)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15)
                    {
                        ForEach(viewModel.resources) { resource in
                            ResourceCard(resource: resource)
                        }
                    }
                    .padding(.horizontal)

                    // Rescue Requests
                    HStack {
                        Text("Rescue Requests")
                            .font(.headline).foregroundColor(.aquaNavy)
                        Spacer()
                        Text("\(viewModel.pendingCount) Pending")
                            .font(.caption).bold()
                            .padding(4).background(Color.red.opacity(0.1)).foregroundColor(.red)
                            .cornerRadius(4)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(viewModel.requests) { request in
                            RescueRequestRow(request: request)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
        }
    }
}

//
//  RequestHistoryCard.swift
//  AquaGuard
//
//  Card component displaying an emergency request
//  with address, status badge, description, and timestamp.
//

import SwiftUI

struct RequestHistoryCard: View {
    let request: EmergencyRequest
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Address + Status badge
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.aquaPrimary)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.address)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.aquaNavy)
                            .lineLimit(1)
                        // GPS coordinates
                        Text(request.locationString)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                Spacer()
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: request.status.icon)
                        .font(.caption2)
                    Text(request.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(request.status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(request.status.color.opacity(0.12))
                .cornerRadius(20)
            }

            // Description
            if !request.description.isEmpty {
                Text(request.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            // Bottom: Type badge + Timestamp
            HStack {
                // Request type badge
                HStack(spacing: 3) {
                    Image(
                        systemName: request.requestType == .quickSOS
                            ? "bolt.fill" : "doc.text.fill"
                    )
                    .font(.system(size: 8))
                    Text(request.requestType == .quickSOS ? "Quick SOS" : "Detailed")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(
                    request.requestType == .quickSOS ? .aquaDanger : .aquaPrimary
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (request.requestType == .quickSOS ? Color.aquaDanger : Color.aquaPrimary)
                        .opacity(0.1)
                )
                .cornerRadius(8)

                Spacer()

                // Timestamp
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                    Text(request.timeAgoString)
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }

            // Tracking hint for active requests
            if request.status == .inProgress {
                HStack(spacing: 6) {
                    Image(systemName: "location.viewfinder")
                        .font(.caption2)
                    Text("Tap to track rescuer")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.aquaPrimary)
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.aquaCard)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

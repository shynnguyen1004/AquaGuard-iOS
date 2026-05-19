//
//  FloodReportCard.swift
//  AquaGuard
//
//  Card component displaying a single flood report
//  with photo, GPS overlay, and timestamp — Locket style.
//

import SwiftUI

struct FloodReportCard: View {
    let report: FloodReport
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            // Photo
            Image(uiImage: report.image)
                .resizable()
                .scaledToFill()
                .frame(minHeight: 180)
                .clipped()

            // Bottom gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Info overlay
            VStack(alignment: .leading, spacing: 6) {
                // Caption
                if !report.caption.isEmpty {
                    Text(report.caption)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    // GPS
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                        Text(report.locationString)
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.85))

                    Spacer()

                    // Timestamp
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                        Text(report.relativeTimeString)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(12)
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Full-size card for feed

struct FloodReportFullCard: View {
    let report: FloodReport
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo with overlay
            ZStack(alignment: .bottom) {
                Image(uiImage: report.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()

                // Gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)

                // Overlay info
                HStack {
                    // GPS badge
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(report.locationString)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .cornerRadius(20)

                    Spacer()

                    // Time badge
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(report.timeString)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .cornerRadius(20)
                }
                .padding(12)
            }

            // Caption section
            if !report.caption.isEmpty {
                Text(report.caption)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.aquaCard)
            }
        }
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

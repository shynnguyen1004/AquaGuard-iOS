//
//  CommunityFeedView.swift
//  AquaGuard
//
//  Locket-style full-page community flood report card.
//  Each card fills the entire visible area with photo,
//  location badge, user info, and severity indicator.
//

import SwiftUI

// MARK: - Community Feed Card (full page, Locket-style)

struct CommunityFeedCard: View {
    let report: CommunityReport
    @Environment(\.colorScheme) var colorScheme

    // Gradient backgrounds for dummy image placeholders
    private var gradientForImage: LinearGradient {
        switch report.imageName {
        case "flood_street":
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.3, green: 0.5, blue: 0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case "flood_rain":
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.2, green: 0.35, blue: 0.55)],
                startPoint: .top, endPoint: .bottom
            )
        case "flood_market":
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.35, blue: 0.2), Color(red: 0.4, green: 0.55, blue: 0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case "flood_school":
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.25, blue: 0.15), Color(red: 0.55, green: 0.45, blue: 0.3)],
                startPoint: .top, endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.4, blue: 0.4), Color(red: 0.3, green: 0.6, blue: 0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private var floodIcon: String {
        switch report.severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "severe": return "cloud.heavyrain.fill"
        case "moderate": return "cloud.rain.fill"
        default: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo card
            ZStack {
                // Placeholder image (gradient + icon)
                gradientForImage
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: floodIcon)
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.white.opacity(0.25))
                            Text(report.severity.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.2))
                                .tracking(4)
                        }
                    )
                    .cornerRadius(28)

                // Bottom overlay gradient
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    .cornerRadius(28)
                }

                // Content overlay
                VStack {
                    // Top right: severity badge
                    HStack {
                        Spacer()
                        HStack(spacing: 5) {
                            Circle()
                                .fill(report.severityColor)
                                .frame(width: 8, height: 8)
                            Text(report.severity.capitalized)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .cornerRadius(16)
                        .padding(16)
                    }

                    Spacer()

                    // Bottom: location + caption
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.aquaPrimary)
                            Text(report.locationName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial.opacity(0.6))
                        .cornerRadius(20)

                        if !report.caption.isEmpty {
                            Text(report.caption)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(3)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 16)

            // User info below card
            HStack(spacing: 10) {
                Image(systemName: report.userAvatar)
                    .font(.system(size: 28))
                    .foregroundColor(.aquaPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.aquaNavy)
                    Text(report.relativeTimeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.aquaPrimary)
                    Text("\(report.reactions)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }
}

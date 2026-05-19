//
//  AdminAnalyticsView.swift
//  AquaGuard
//
//  Admin analytics: KPI cards, user distribution,
//  SOS overview with progress bars, response metrics.
//  Matching guide.md spec exactly.
//

import SwiftUI

// MARK: - Analytics Data

struct AnalyticsOverview {
    let totalUsers: Int
    let newUsers7d: Int
    let totalRequests: Int
    let avgResponseMinutes: Int
    let resolutionRate: Int
    let pendingRequests: Int
    let activeRequests: Int
    let resolvedRequests: Int
    let fastestResponseMin: Int
    let slowestResponseMin: Int

    static let overview = AnalyticsOverview(
        totalUsers: 156,
        newUsers7d: 12,
        totalRequests: 89,
        avgResponseMinutes: 18,
        resolutionRate: 87,
        pendingRequests: 5,
        activeRequests: 3,
        resolvedRequests: 81,
        fastestResponseMin: 5,
        slowestResponseMin: 45
    )
}

struct RoleDistribution {
    let role: String
    let count: Int
    let label: String
    let color: Color

    static let data: [RoleDistribution] = [
        RoleDistribution(role: "citizen", count: 120, label: "Công dân", color: .green),
        RoleDistribution(role: "rescuer", count: 28, label: "Cứu hộ", color: .orange),
        RoleDistribution(role: "admin", count: 8, label: "Quản trị", color: .aquaPrimary),
    ]
}

// MARK: - View

struct AdminAnalyticsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    private let stats = AnalyticsOverview.overview
    private let roleDist = RoleDistribution.data
    private var totalRoleCount: Int { roleDist.reduce(0) { $0 + $1.count } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Header
                    headerSection

                    // 2. KPI Cards (2x2)
                    kpiGrid

                    // 3. Phân bố người dùng
                    userDistribution

                    // 4. Tổng quan SOS
                    sosOverview

                    // 5. Hiệu suất phản hồi
                    responsePerformance

                    Spacer(minLength: 30)
                }
                .padding(.top, 8)
            }
            .background(Color.aquaBackground)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 18))
                .foregroundColor(.aquaPrimary)
            Text("Thống kê hệ thống")
                .font(.headline)
                .foregroundColor(.aquaNavy)
            Spacer()
        }
        .padding(16)
    }

    // MARK: - KPI Grid

    private var kpiGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            kpiCard(icon: "person.2.fill", label: "Tổng người dùng", value: "\(stats.totalUsers)", subtitle: nil, color: .aquaPrimary)
            kpiCard(icon: "person.badge.plus", label: "Mới (7 ngày)", value: "\(stats.newUsers7d)", subtitle: "Last 7d", color: .green)
            kpiCard(icon: "exclamationmark.triangle.fill", label: "Tổng SOS", value: "\(stats.totalRequests)", subtitle: nil, color: .red)
            kpiCard(icon: "gauge.with.dots.needle.67percent", label: "Phản hồi TB", value: "\(stats.avgResponseMinutes)", subtitle: "phút", color: .orange)
        }
        .padding(.horizontal, 16)
    }

    private func kpiCard(icon: String, label: String, value: String, subtitle: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .cornerRadius(8)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.aquaNavy)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption2)
                        .foregroundColor(.aquaSubtitle)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - User Distribution

    private var userDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phân bố người dùng")
                .font(.headline)
                .foregroundColor(.aquaNavy)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                // Stacked bar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(Array(roleDist.enumerated()), id: \.offset) { _, dist in
                            let fraction = CGFloat(dist.count) / CGFloat(max(totalRoleCount, 1))
                            Rectangle()
                                .fill(dist.color)
                                .frame(width: geo.size.width * fraction)
                        }
                    }
                    .cornerRadius(6)
                }
                .frame(height: 18)

                // Legend
                ForEach(Array(roleDist.enumerated()), id: \.offset) { _, dist in
                    HStack(spacing: 8) {
                        Circle().fill(dist.color).frame(width: 8, height: 8)
                        Text(dist.label).font(.caption).foregroundColor(.aquaNavy)
                        Spacer()
                        Text("\(dist.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.aquaNavy)
                        Text("(\(Int(Double(dist.count) / Double(max(totalRoleCount, 1)) * 100))%)")
                            .font(.caption2)
                            .foregroundColor(.aquaSubtitle)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.aquaCard)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - SOS Overview

    private var sosOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tổng quan SOS")
                .font(.headline)
                .foregroundColor(.aquaNavy)
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                progressBar(label: "Đang chờ", count: stats.pendingRequests, total: stats.totalRequests, color: .orange)
                progressBar(label: "Đang xử lý", count: stats.activeRequests, total: stats.totalRequests, color: .aquaPrimary)
                progressBar(label: "Hoàn thành", count: stats.resolvedRequests, total: stats.totalRequests, color: .green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.aquaCard)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }

    private func progressBar(label: String, count: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.caption).foregroundColor(.aquaNavy)
                Spacer()
                Text("\(count)").font(.caption).fontWeight(.bold).foregroundColor(color)
                Text("(\(total > 0 ? Int(Double(count) / Double(total) * 100) : 0)%)")
                    .font(.caption2).foregroundColor(.aquaSubtitle)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(total > 0 ? Double(count) / Double(total) : 0), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Response Performance

    private var responsePerformance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hiệu suất phản hồi")
                .font(.headline)
                .foregroundColor(.aquaNavy)
                .padding(.horizontal, 20)

            // 2 big cards
            HStack(spacing: 12) {
                bigMetricCard(label: "Tỷ lệ giải quyết", value: "\(stats.resolutionRate)%", color: .green)
                bigMetricCard(label: "Phản hồi TB", value: "\(stats.avgResponseMinutes) phút", color: .aquaPrimary)
            }
            .padding(.horizontal, 16)

            // Metrics list
            VStack(spacing: 0) {
                metricRow(label: "Phản hồi nhanh nhất", value: "\(stats.fastestResponseMin) phút", color: .green)
                Divider().padding(.leading, 16)
                metricRow(label: "Phản hồi chậm nhất", value: "\(stats.slowestResponseMin) phút", color: .red)
                Divider().padding(.leading, 16)
                metricRow(label: "Phản hồi trung bình", value: "\(stats.avgResponseMinutes) phút", color: .orange)
                Divider().padding(.leading, 16)
                metricRow(label: "SOS đang chờ", value: "\(stats.pendingRequests)", color: .orange)
                Divider().padding(.leading, 16)
                metricRow(label: "Đang cứu hộ", value: "\(stats.activeRequests)", color: .aquaPrimary)
                Divider().padding(.leading, 16)
                metricRow(label: "Đã hoàn thành", value: "\(stats.resolvedRequests)", color: .green)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.aquaCard)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }

    private func bigMetricCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }

    private func metricRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.aquaNavy)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

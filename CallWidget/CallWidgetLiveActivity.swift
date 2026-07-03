//
//  CallWidgetLiveActivity.swift
//  CallWidget
//
//  Dynamic Island + Lock Screen UI for an ongoing AquaGuard voice call.
//  Uses the shared `CallActivityAttributes` (member of both the app and this
//  extension target). Started/ended by `CallLiveActivityManager` in the app.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct CallWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CallActivityAttributes.self) { context in
            // ── Lock Screen / banner presentation ──
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AquaGuard — Cuộc gọi cứu hộ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.attributes.peerName)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                Text(timerInterval: context.state.startedAt...Date.distantFuture,
                     countsDown: false)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.green)
                    .frame(maxWidth: 64)
            }
            .padding(14)
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded (long-press / while active) ──
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.peerName)
                            .font(.headline)
                            .lineLimit(1)
                        Text("Đang trong cuộc gọi")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startedAt...Date.distantFuture,
                         countsDown: false)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.green)
                        .frame(maxWidth: 56)
                        .padding(.trailing, 6)
                }
            } compactLeading: {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.green)
            } compactTrailing: {
                Text(timerInterval: context.state.startedAt...Date.distantFuture,
                     countsDown: false)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.green)
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

//
//  CallLiveActivityManager.swift
//  AquaGuard
//
//  Starts/ends the in-call Live Activity so an ongoing voice call stays visible
//  in the Dynamic Island (iPhone 14 Pro+) and on the Lock Screen when the user
//  leaves the app. Driven by `CallManager` (start on .active, end on teardown).
//
//  The visual comes from the CallWidget extension's `ActivityConfiguration` —
//  without that target the activity is requested but nothing is rendered.
//

import ActivityKit
import Foundation

@MainActor
final class CallLiveActivityManager {

    static let shared = CallLiveActivityManager()

    private var activity: Activity<CallActivityAttributes>?

    private init() {}

    /// Begin the Live Activity for a just-connected call. No-op if one is
    /// already running or the user disabled Live Activities in Settings.
    func start(peerName: String) {
        guard activity == nil else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Disabled in Settings — skipping")
            return
        }

        let attributes = CallActivityAttributes(peerName: peerName)
        let state = CallActivityAttributes.ContentState(startedAt: Date())
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            print("[LiveActivity] Started for \(peerName)")
        } catch {
            print("[LiveActivity] Failed to start: \(error.localizedDescription)")
        }
    }

    /// Dismiss the Live Activity (call ended for any reason).
    func end() {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("[LiveActivity] Ended")
        }
    }
}

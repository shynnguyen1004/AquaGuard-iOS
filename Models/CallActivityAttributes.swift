//
//  CallActivityAttributes.swift
//  AquaGuard
//
//  Shared shape of the in-call Live Activity (Dynamic Island + Lock Screen).
//
//  ⚠️ Target membership: this file must belong to BOTH the app target and the
//  CallWidget extension target (File Inspector → Target Membership) — ActivityKit
//  matches the activity by this type's name and structure on both sides.
//

import ActivityKit
import Foundation

struct CallActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the call connected — the island renders a live timer from this.
        var startedAt: Date
    }

    /// Who we're talking to (fixed for the life of the activity).
    var peerName: String
}

//
//  CallWidgetBundle.swift
//  CallWidget
//
//  AquaGuard's widget extension currently ships only the in-call Live Activity
//  (Dynamic Island / Lock Screen). The sample home-screen widget and control
//  that Xcode generated were removed.
//

import SwiftUI
import WidgetKit

@main
struct CallWidgetBundle: WidgetBundle {
    var body: some Widget {
        CallWidgetLiveActivity()
    }
}

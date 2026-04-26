//
//  ThemeManager.swift
//  AquaGuard
//
//  Manages app-wide Light / Dark / System theme preference.
//

import Combine
import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("appTheme") var currentRaw: String = AppTheme.system.rawValue {
        didSet { objectWillChange.send() }
    }

    var current: AppTheme {
        get { AppTheme(rawValue: currentRaw) ?? .system }
        set { currentRaw = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        current.colorScheme
    }
}

//
//  LanguageManager.swift
//  AquaGuard
//
//  Manages the app's language preference (English / Vietnamese).
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .vietnamese: return "🇻🇳"
        }
    }
}

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "app_language")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        self.current = AppLanguage(rawValue: saved) ?? .english
    }

    func toggle() {
        current = (current == .english) ? .vietnamese : .english
    }
}

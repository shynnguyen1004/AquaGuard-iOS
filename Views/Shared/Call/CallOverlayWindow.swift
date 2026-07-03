//
//  CallOverlayWindow.swift
//  AquaGuard
//
//  Hosts `CallOverlayView` in a dedicated high-level `UIWindow` so the call UI
//  floats ABOVE everything — including presented `.sheet`s (e.g. the live-tracking
//  sheet where the call button lives). A plain ZStack overlay in the WindowGroup
//  sits *behind* active sheets, which is why the call screen was covered by the map.
//
//  Driven by `CallManager.shared.phase`: the window appears while a call exists and
//  is torn down when the call ends.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class CallOverlayWindow {
    static let shared = CallOverlayWindow()

    private var window: UIWindow?
    private var cancellable: AnyCancellable?

    private init() {}

    /// Begin observing call state. Safe to call more than once.
    func start() {
        guard cancellable == nil else { return }
        cancellable = CallManager.shared.$phase
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                if phase == .idle {
                    self?.hide()
                } else {
                    self?.show()
                }
            }
    }

    private func show() {
        guard window == nil else { return }
        guard let scene = Self.activeWindowScene() else { return }

        let host = UIHostingController(rootView: CallOverlayView())
        host.view.backgroundColor = .clear

        let overlay = UIWindow(windowScene: scene)
        overlay.windowLevel = .alert + 1        // above app content and sheets
        overlay.rootViewController = host
        overlay.isHidden = false
        window = overlay
    }

    private func hide() {
        window?.isHidden = true
        window = nil
    }

    private static func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

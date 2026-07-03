//
//  CallOverlayView.swift
//  AquaGuard
//
//  Full-screen voice-call overlay, driven by `CallManager.shared`. Rendered above
//  the whole app (see AquaGuardApp) so it appears for both citizen and rescuer on
//  any screen. Hidden while there is no call (`phase == .idle`).
//

import SwiftUI

struct CallOverlayView: View {
    @ObservedObject private var call = CallManager.shared

    var body: some View {
        if call.phase != .idle {
            content
                .transition(.opacity)
                .zIndex(100)
        }
    }

    private var content: some View {
        ZStack {
            // Fully opaque backdrop — the call screen must not show the app
            // behind it (no transparency in the gradient stops).
            Color.black.ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color.aquaPrimary,
                    Color(red: 0.05, green: 0.25, blue: 0.35),
                    Color(red: 0.02, green: 0.08, blue: 0.14),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                avatar
                Text(call.callInfo?.peerName ?? "—")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.85))

                Spacer()

                controls
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
        .animation(.easeInOut(duration: 0.2), value: call.phase)
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 130, height: 130)
            Text(initials)
                .font(.system(size: 46, weight: .semibold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle().stroke(.white.opacity(0.35), lineWidth: 2)
        )
        .scaleEffect(isRinging ? 1.04 : 1.0)
        .animation(isRinging ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                   value: isRinging)
    }

    private var initials: String {
        let name = call.callInfo?.peerName ?? ""
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    // MARK: - Status text

    private var statusText: String {
        switch call.phase {
        case .outgoing:   return "Đang gọi…"
        case .incoming:   return "Cuộc gọi thoại đến"
        case .connecting: return "Đang kết nối…"
        case .active:     return durationText
        case .ended:      return call.endReason?.message ?? "Cuộc gọi đã kết thúc"
        case .idle:       return ""
        }
    }

    private var isRinging: Bool {
        call.phase == .outgoing || call.phase == .incoming
    }

    private var durationText: String {
        let s = call.durationSeconds
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - Controls per phase

    @ViewBuilder
    private var controls: some View {
        switch call.phase {
        case .incoming:
            HStack(spacing: 72) {
                CircleButton(icon: "phone.down.fill", tint: .red, label: "Từ chối") { call.reject() }
                CircleButton(icon: "phone.fill", tint: .green, label: "Nhận") { call.accept() }
            }

        case .outgoing:
            CircleButton(icon: "phone.down.fill", tint: .red, label: "Huỷ") { call.cancel() }

        case .connecting, .active:
            VStack(spacing: 28) {
                HStack(spacing: 48) {
                    CircleButton(icon: call.isMuted ? "mic.slash.fill" : "mic.fill",
                                 tint: call.isMuted ? .white : .white.opacity(0.25),
                                 iconColor: call.isMuted ? .black : .white,
                                 label: call.isMuted ? "Bật mic" : "Tắt mic") {
                        call.toggleMute()
                    }
                    CircleButton(icon: "speaker.wave.3.fill",
                                 tint: call.isSpeaker ? .white : .white.opacity(0.25),
                                 iconColor: call.isSpeaker ? .black : .white,
                                 label: "Loa ngoài") {
                        call.toggleSpeaker()
                    }
                }
                CircleButton(icon: "phone.down.fill", tint: .red, label: "Kết thúc") { call.hangup() }
            }

        case .ended, .idle:
            EmptyView()
        }
    }
}

// MARK: - Round control button

private struct CircleButton: View {
    let icon: String
    let tint: Color
    var iconColor: Color = .white
    let label: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    Circle().fill(tint).frame(width: 68, height: 68)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(iconColor)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

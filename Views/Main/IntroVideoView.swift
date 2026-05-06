//
//  IntroVideoView.swift
//  AquaGuard
//
//  Created by AquaGuard Team on 06/05/26.
//

import AVKit
import SwiftUI

struct IntroVideoView: View {
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var opacity: Double = 1.0
    @State private var showSkipButton: Bool = false

    var body: some View {
        ZStack {
            // Background color matching video
            Color.white
                .ignoresSafeArea()

            // Video player
            if let player = player {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Skip button (appears after 1.5s)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if showSkipButton {
                        Button(action: {
                            finishIntro()
                        }) {
                            HStack(spacing: 6) {
                                Text("Skip")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .opacity(opacity)
        .onAppear {
            setupPlayer()

            // Show skip button after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSkipButton = true
                }
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "aquaguard_effect", withExtension: "mp4") else {
            print("IntroVideoView: Could not find aquaguard_effect.mp4 in bundle")
            // If video not found, skip intro
            onFinished()
            return
        }

        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = false
        self.player = avPlayer

        // Listen for video end
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            finishIntro()
        }

        // Start playing
        avPlayer.play()

        // Limit playback to 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            finishIntro()
        }
    }

    private func finishIntro() {
        // Prevent double calls
        guard opacity == 1.0 else { return }

        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            player?.pause()
            player = nil
            onFinished()
        }
    }
}

// MARK: - AVPlayer UIViewRepresentable Wrapper
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(player: player)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)

        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

#Preview {
    IntroVideoView(onFinished: {})
}

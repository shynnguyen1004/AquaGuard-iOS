//
//  SplashScreenView.swift
//  AquaGuard
//
//  Animated splash/intro screen shown when the app first launches.
//  Displays the appropriate logo based on the current color scheme
//  (dark mode → Logo_Dark, light mode → Logo_Light).
//

import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Animation State
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo – switches automatically with color scheme
                Image(colorScheme == .dark ? "SplashLogoDark" : "SplashLogoLight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .shadow(
                        color: colorScheme == .dark
                            ? Color.cyan.opacity(0.35)
                            : Color.black.opacity(0.15),
                        radius: 30, x: 0, y: 10
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            // Logo entrance animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Shimmer sweep
            withAnimation(.easeInOut(duration: 1.2).delay(0.5)) {
                shimmerOffset = 200
            }
        }
    }

    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.14),
                        Color(red: 0.04, green: 0.06, blue: 0.10),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.88, green: 0.93, blue: 0.98),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

#Preview("Light") {
    SplashScreenView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashScreenView()
        .preferredColorScheme(.dark)
}

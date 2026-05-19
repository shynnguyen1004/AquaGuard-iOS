//
//  WeatherLayerPanel.swift
//  AquaGuard
//
//  Compact floating panel for selecting Windy weather overlay layers.
//

import SwiftUI

struct WeatherLayerPanel: View {
    @Binding var selectedLayer: WeatherLayer
    @Binding var isVisible: Bool
    var onHideWeatherMap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Layer Options (compact grid)
            VStack(spacing: 4) {
                ForEach(WeatherLayer.allCases, id: \.self) { layer in
                    layerRow(layer)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
                .padding(.horizontal, 8)

            // MARK: - Hide button (compact)
            Button(action: onHideWeatherMap) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash")
                        .font(.caption2)
                    Text("Hide")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .frame(width: 165)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    // MARK: - Layer Row (compact)

    @ViewBuilder
    private func layerRow(_ layer: WeatherLayer) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedLayer = layer
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: layer.icon)
                    .font(.caption)
                    .foregroundColor(selectedLayer == layer ? .aquaPrimary : .white.opacity(0.6))
                    .frame(width: 18)

                Text(layer.displayName)
                    .font(.caption)
                    .fontWeight(selectedLayer == layer ? .semibold : .regular)
                    .foregroundColor(selectedLayer == layer ? .white : .white.opacity(0.75))

                Spacer()

                if selectedLayer == layer {
                    Circle()
                        .fill(Color.aquaPrimary)
                        .frame(width: 6, height: 6)
                        .transition(.scale)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedLayer == layer ? Color.aquaPrimary.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

//
//  LiveTrackingSheet.swift
//  AquaGuard
//
//  Map sheet showing real-time tracking between
//  the victim and assigned rescuer.
//

import MapKit
import SwiftUI

struct LiveTrackingSheet: View {
    let request: EmergencyRequest
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    // Camera position for the map
    @State private var cameraPosition: MapCameraPosition

    init(request: EmergencyRequest) {
        self.request = request
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: request.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status header
                statusHeader

                // Map
                Map(position: $cameraPosition) {
                    // Victim pin
                    Annotation(
                        languageManager.localize("Your Location"),
                        coordinate: request.coordinate
                    ) {
                        VStack(spacing: 2) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.aquaDanger)
                                .background(Circle().fill(.white).padding(-2))
                        }
                    }

                    // Rescuer pin (if assigned)
                    if request.rescuerId != nil {
                        // Simulated rescuer position (nearby)
                        let rescuerCoord = CLLocationCoordinate2D(
                            latitude: request.latitude + 0.003,
                            longitude: request.longitude + 0.002
                        )
                        Annotation(
                            languageManager.localize("Rescuer"),
                            coordinate: rescuerCoord
                        ) {
                            VStack(spacing: 2) {
                                Image(systemName: "figure.wave")
                                    .font(.title)
                                    .foregroundColor(.aquaPrimary)
                                    .background(Circle().fill(.white).padding(-2))
                            }
                        }
                    }
                }
                .mapStyle(.standard)

                // Request info bar
                requestInfoBar
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Live Tracking"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localize("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.aquaPrimary)
                }
            }
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack(spacing: 12) {
            // Status icon with pulse animation
            ZStack {
                if request.status == .inProgress {
                    Circle()
                        .fill(request.status.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                Image(systemName: request.status.icon)
                    .font(.title2)
                    .foregroundColor(request.status.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(request.status.rawValue)
                    .font(.headline)
                    .foregroundColor(.aquaNavy)

                if request.status == .pending {
                    Text(languageManager.localize("Waiting for a rescuer to accept..."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if request.status == .inProgress {
                    Text(languageManager.localize("Rescuer is on the way"))
                        .font(.caption)
                        .foregroundColor(.aquaPrimary)
                } else {
                    Text(languageManager.localize("This request has been resolved"))
                        .font(.caption)
                        .foregroundColor(.aquaSafe)
                }
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: request.status.icon)
                    .font(.caption2)
                Text(request.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(request.status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(request.status.color.opacity(0.12))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.aquaCard)
    }

    // MARK: - Request Info Bar

    private var requestInfoBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.aquaPrimary)
                Text(request.address)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.aquaNavy)
                    .lineLimit(1)
            }

            if !request.description.isEmpty {
                Text(request.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(request.timeAgoString)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aquaCard)
    }
}

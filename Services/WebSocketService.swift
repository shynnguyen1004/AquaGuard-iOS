//
//  WebSocketService.swift
//  AquaGuard
//
//  Real-time WebSocket client for live GPS tracking
//  between citizens and rescuers during active SOS missions.
//
//  Protocol:
//    → { type: "join_tracking", requestId }
//    → { type: "location_update", latitude, longitude }
//    ← { type: "location_update", userId, role, latitude, longitude, timestamp }
//    ← { type: "tracking_started", requestId, rescuerId, ... }
//    ← { type: "tracking_cancelled", requestId }
//    ← { type: "tracking_ended", requestId }
//

import Combine
import CoreLocation
import Foundation

// MARK: - WebSocket Message Types

enum WSMessageType: String {
    case joinTracking = "join_tracking"
    case locationUpdate = "location_update"
    case trackingStarted = "tracking_started"
    case trackingCancelled = "tracking_cancelled"
    case trackingEnded = "tracking_ended"
}

/// Incoming location update from another user
struct WSLocationUpdate {
    let userId: Int
    let role: String
    let latitude: Double
    let longitude: Double
    let timestamp: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Incoming tracking started event
struct WSTrackingStarted {
    let requestId: Int
    let rescuerId: Int
    let rescuerName: String
    let rescuerLatitude: Double?
    let rescuerLongitude: Double?
    let citizenLatitude: Double?
    let citizenLongitude: Double?
}

// MARK: - WebSocket Service

class WebSocketService: ObservableObject {

    static let shared = WebSocketService()

    // MARK: - Published State

    @Published var isConnected: Bool = false
    @Published var rescuerLocation: CLLocationCoordinate2D?
    @Published var citizenLocation: CLLocationCoordinate2D?
    @Published var trackingStartedEvent: WSTrackingStarted?
    @Published var trackingEnded: Bool = false
    @Published var trackingCancelled: Bool = false

    // MARK: - Private

    private var webSocket: URLSessionWebSocketTask?
    private var currentRequestId: Int?
    private var pingTimer: Timer?

    private init() {}

    // MARK: - Connect

    /// Connect to WebSocket server with JWT token
    func connect() {
        guard let token = TokenManager.shared.getToken() else {
            print("[WS] No token — cannot connect")
            return
        }

        guard let url = URL(string: "\(NetworkConfig.wsBaseURL)?token=\(token)") else {
            print("[WS] Invalid WebSocket URL")
            return
        }

        // Close existing connection
        disconnect()

        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        DispatchQueue.main.async {
            self.isConnected = true
            self.trackingEnded = false
            self.trackingCancelled = false
        }

        // Start receiving messages
        receiveMessage()

        // Start ping timer (keep alive)
        startPingTimer()

        print("[WS] Connected")
    }

    /// Disconnect and clean up
    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        currentRequestId = nil

        DispatchQueue.main.async {
            self.isConnected = false
            self.rescuerLocation = nil
            self.citizenLocation = nil
            self.trackingStartedEvent = nil
        }

        print("[WS] Disconnected")
    }

    // MARK: - Send Messages

    /// Join a tracking room for a specific rescue request
    func joinTracking(requestId: Int) {
        currentRequestId = requestId

        let message: [String: Any] = [
            "type": WSMessageType.joinTracking.rawValue,
            "requestId": requestId,
        ]

        sendJSON(message)
        print("[WS] Joined tracking room: \(requestId)")
    }

    /// Send current GPS location to the tracking room
    func sendLocation(latitude: Double, longitude: Double) {
        let message: [String: Any] = [
            "type": WSMessageType.locationUpdate.rawValue,
            "latitude": latitude,
            "longitude": longitude,
        ]

        sendJSON(message)
    }

    // MARK: - Receive Messages

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }

                // Continue receiving
                self?.receiveMessage()

            case .failure(let error):
                print("[WS] Receive error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else { return }

        switch type {
        case WSMessageType.locationUpdate.rawValue:
            guard let userId = json["userId"] as? Int,
                  let role = json["role"] as? String,
                  let lat = json["latitude"] as? Double,
                  let lng = json["longitude"] as? Double
            else { return }

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)

            DispatchQueue.main.async {
                if role == "rescuer" {
                    self.rescuerLocation = coord
                } else {
                    self.citizenLocation = coord
                }
            }

        case WSMessageType.trackingStarted.rawValue:
            let event = WSTrackingStarted(
                requestId: json["requestId"] as? Int ?? 0,
                rescuerId: json["rescuerId"] as? Int ?? 0,
                rescuerName: json["rescuerName"] as? String ?? "Rescuer",
                rescuerLatitude: json["rescuerLatitude"] as? Double,
                rescuerLongitude: json["rescuerLongitude"] as? Double,
                citizenLatitude: json["citizenLatitude"] as? Double,
                citizenLongitude: json["citizenLongitude"] as? Double
            )

            DispatchQueue.main.async {
                self.trackingStartedEvent = event
                if let lat = event.rescuerLatitude, let lng = event.rescuerLongitude {
                    self.rescuerLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }
            }

        case WSMessageType.trackingCancelled.rawValue:
            DispatchQueue.main.async {
                self.trackingCancelled = true
                self.rescuerLocation = nil
            }

        case WSMessageType.trackingEnded.rawValue:
            DispatchQueue.main.async {
                self.trackingEnded = true
            }

        default:
            print("[WS] Unknown message type: \(type)")
        }
    }

    // MARK: - Helpers

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8)
        else { return }

        webSocket?.send(.string(text)) { error in
            if let error = error {
                print("[WS] Send error: \(error.localizedDescription)")
            }
        }
    }

    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.webSocket?.sendPing { error in
                if let error = error {
                    print("[WS] Ping error: \(error.localizedDescription)")
                }
            }
        }
    }
}

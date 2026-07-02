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

    // MARK: - Call Signaling

    /// Parsed WebRTC call signaling messages. `CallManager` subscribes to this.
    /// The same socket carries both tracking and call signaling (one socket per
    /// user, matching the backend's `userSockets` registry).
    let callSignals = PassthroughSubject<CallSignal, Never>()

    // MARK: - Reconnection

    /// True while we intend to stay connected (i.e. logged in). Enables the call
    /// channel to survive transient network drops so incoming calls still ring.
    private var shouldStayConnected = false
    private var reconnectAttempt = 0

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

        // We intend to stay connected from now on (until an explicit disconnect).
        shouldStayConnected = true

        // Tear down any existing socket without cancelling the reconnect intent.
        closeSocket()

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

        // Re-join a tracking room if one was active before a reconnect.
        if let requestId = currentRequestId {
            joinTracking(requestId: requestId)
        }

        print("[WS] Connected")
    }

    /// Fully disconnect (e.g. on logout) — stops reconnecting.
    func disconnect() {
        shouldStayConnected = false
        reconnectAttempt = 0
        currentRequestId = nil
        closeSocket()

        DispatchQueue.main.async {
            self.isConnected = false
            self.rescuerLocation = nil
            self.citizenLocation = nil
            self.trackingStartedEvent = nil
        }

        print("[WS] Disconnected")
    }

    /// Cancel the current socket + ping timer without changing reconnect intent.
    private func closeSocket() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
    }

    /// Called when the socket drops. Reconnects (with backoff) if we still want
    /// to be connected, so the call channel survives transient network loss.
    private func handleConnectionDrop() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isConnected = false
            guard self.shouldStayConnected else { return }

            self.reconnectAttempt += 1
            let delay = min(Double(self.reconnectAttempt) * 2.0, 20.0)   // 2s, 4s, … capped at 20s
            print("[WS] Connection dropped — reconnecting in \(delay)s (attempt \(self.reconnectAttempt))")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.shouldStayConnected else { return }
                self.connect()
            }
        }
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

    // MARK: - Send Call Signaling
    //
    // The backend resolves the counterpart from `requestId` (citizen + assigned
    // rescuer of an active mission), so the client only ever sends `requestId`.

    func sendCallInvite(requestId: Int, media: String = "audio") {
        sendJSON(["type": "call_invite", "requestId": requestId, "media": media])
    }

    func sendCallAccept(requestId: Int) {
        sendJSON(["type": "call_accept", "requestId": requestId])
    }

    func sendCallReject(requestId: Int) {
        sendJSON(["type": "call_reject", "requestId": requestId])
    }

    func sendCallCancel(requestId: Int) {
        sendJSON(["type": "call_cancel", "requestId": requestId])
    }

    func sendCallHangup(requestId: Int) {
        sendJSON(["type": "call_hangup", "requestId": requestId])
    }

    /// The `type` (offer/answer) is conveyed by the message type itself; the
    /// `sdp` field carries the raw SDP string.
    func sendOffer(requestId: Int, sdp: String) {
        sendJSON(["type": "webrtc_offer", "requestId": requestId, "sdp": sdp])
    }

    func sendAnswer(requestId: Int, sdp: String) {
        sendJSON(["type": "webrtc_answer", "requestId": requestId, "sdp": sdp])
    }

    /// `candidate` matches the web's `RTCIceCandidate` JSON shape:
    /// `{ candidate, sdpMid, sdpMLineIndex }`.
    func sendIce(requestId: Int, candidate: [String: Any]) {
        sendJSON(["type": "webrtc_ice", "requestId": requestId, "candidate": candidate])
    }

    // MARK: - Receive Messages

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                // We are receiving fine — reset the reconnect backoff.
                self?.reconnectAttempt = 0
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
                self?.handleConnectionDrop()
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

        // ── WebRTC call signaling → forwarded to CallManager via `callSignals` ──

        case "call_incoming":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.incoming(
                requestId: requestId,
                media: json["media"] as? String ?? "audio",
                fromUserId: json["fromUserId"] as? Int ?? 0,
                fromName: json["fromName"] as? String ?? "",
                fromRole: json["fromRole"] as? String ?? ""
            ))

        case "call_ringing":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.ringing(requestId: requestId, toName: json["toName"] as? String ?? ""))

        case "call_unavailable":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.unavailable(requestId: requestId, reason: json["reason"] as? String ?? ""))

        case "call_accepted":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.accepted(requestId: requestId))

        case "call_rejected":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.rejected(requestId: requestId))

        case "call_cancelled":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.cancelled(requestId: requestId))

        case "call_hangup":
            guard let requestId = json["requestId"] as? Int else { return }
            emitCall(.hangup(requestId: requestId))

        case "webrtc_offer":
            guard let requestId = json["requestId"] as? Int,
                  let sdp = sdpString(from: json["sdp"]) else { return }
            emitCall(.offer(requestId: requestId, sdp: sdp))

        case "webrtc_answer":
            guard let requestId = json["requestId"] as? Int,
                  let sdp = sdpString(from: json["sdp"]) else { return }
            emitCall(.answer(requestId: requestId, sdp: sdp))

        case "webrtc_ice":
            guard let requestId = json["requestId"] as? Int,
                  let cand = json["candidate"] as? [String: Any],
                  let candidateStr = cand["candidate"] as? String else { return }
            let payload = ICECandidatePayload(
                candidate: candidateStr,
                sdpMid: cand["sdpMid"] as? String,
                sdpMLineIndex: Int32((cand["sdpMLineIndex"] as? Int) ?? 0)
            )
            emitCall(.ice(requestId: requestId, candidate: payload))

        default:
            print("[WS] Unknown message type: \(type)")
        }
    }

    /// Publish a parsed call signal on the main thread (CallManager is UI-facing).
    private func emitCall(_ signal: CallSignal) {
        DispatchQueue.main.async { self.callSignals.send(signal) }
    }

    /// Accept `sdp` either as a plain SDP string or as an `{ type, sdp }` object,
    /// so we interoperate regardless of how the web client serializes it.
    private func sdpString(from value: Any?) -> String? {
        if let s = value as? String { return s }
        if let dict = value as? [String: Any], let s = dict["sdp"] as? String { return s }
        return nil
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

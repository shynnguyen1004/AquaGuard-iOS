//
//  CallModels.swift
//  AquaGuard
//
//  Types for the 1-1 voice call between a citizen and their assigned rescuer
//  during an active rescue mission (status `assigned` / `in_progress`).
//
//  Mirrors the backend WebRTC signaling protocol (see backend/index.js) so calls
//  are interoperable with the React web client:
//
//    Client → Server: call_invite / call_accept / call_reject / call_cancel /
//                     call_hangup / webrtc_offer / webrtc_answer / webrtc_ice
//    Server → Client: call_incoming / call_ringing / call_unavailable /
//                     call_accepted / call_rejected / call_cancelled /
//                     call_hangup / webrtc_offer / webrtc_answer / webrtc_ice
//

import Foundation

// MARK: - Call Phase (state machine)

/// Lifecycle of the single active call. `CallManager` drives transitions.
enum CallPhase: Equatable {
    case idle          // no call
    case outgoing      // I invited — ringing the peer, waiting for accept
    case incoming      // the peer is calling me — showing accept/decline
    case connecting    // accepted — establishing the WebRTC peer connection
    case active        // media flowing
    case ended         // terminal, shown briefly then reset to `.idle`
}

// MARK: - Call Info

/// Immutable-ish description of the current call. `peerName` may be refined once
/// the backend sends the authoritative display name.
struct CallInfo: Equatable {
    let requestId: Int
    var peerName: String
    let isCaller: Bool
    let media: String   // "audio" for now (backend also supports "video")
}

// MARK: - End Reason

enum CallEndReason: Equatable {
    case hangup                 // normal end, or the peer hung up
    case rejected               // callee declined
    case cancelled              // caller cancelled before it was answered
    case unavailable(String)    // backend said the call can't proceed
    case failed                 // WebRTC connection failed

    /// Vietnamese message shown on the ended screen.
    var message: String {
        switch self {
        case .hangup:    return "Cuộc gọi đã kết thúc"
        case .rejected:  return "Cuộc gọi bị từ chối"
        case .cancelled: return "Đã huỷ cuộc gọi"
        case .failed:    return "Kết nối thất bại"
        case .unavailable(let reason):
            switch reason {
            case "offline":  return "Người nhận hiện không trực tuyến"
            case "inactive": return "Chỉ gọi được khi ca cứu hộ đang diễn ra"
            case "no_peer":  return "Chưa có người để gọi"
            default:         return "Không thể kết nối cuộc gọi"
            }
        }
    }
}

// MARK: - ICE Servers (GET /api/rtc/ice-servers)

/// Response shape: `{ success: Bool, iceServers: [...] }` — note this endpoint does
/// NOT use the standard `{ success, data }` envelope, so it can't go through
/// `APIService.get`. `CallManager` fetches it directly.
struct ICEServersResponse: Decodable {
    let success: Bool
    let iceServers: [ICEServerConfig]
}

/// A single ICE server. `urls` may arrive as a string or an array of strings.
struct ICEServerConfig: Decodable {
    let urls: [String]
    let username: String?
    let credential: String?

    private enum CodingKeys: String, CodingKey { case urls, username, credential }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let single = try? c.decode(String.self, forKey: .urls) {
            urls = [single]
        } else {
            urls = (try? c.decode([String].self, forKey: .urls)) ?? []
        }
        username = try? c.decode(String.self, forKey: .username)
        credential = try? c.decode(String.self, forKey: .credential)
    }
}

// MARK: - Incoming Signaling

/// An ICE candidate as exchanged over the wire (matches the web's
/// `RTCIceCandidate` JSON: `candidate`, `sdpMid`, `sdpMLineIndex`).
struct ICECandidatePayload {
    let candidate: String
    let sdpMid: String?
    let sdpMLineIndex: Int32
}

/// A call/WebRTC signaling message received from the server, already parsed.
/// `WebSocketService` emits these on `callSignals`; `CallManager` consumes them.
enum CallSignal {
    case incoming(requestId: Int, media: String, fromUserId: Int, fromName: String, fromRole: String)
    case ringing(requestId: Int, toName: String)
    case unavailable(requestId: Int, reason: String)
    case accepted(requestId: Int)
    case rejected(requestId: Int)
    case cancelled(requestId: Int)
    case hangup(requestId: Int)
    case offer(requestId: Int, sdp: String)
    case answer(requestId: Int, sdp: String)
    case ice(requestId: Int, candidate: ICECandidatePayload)
}

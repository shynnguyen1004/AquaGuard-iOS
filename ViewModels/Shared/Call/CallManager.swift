//
//  CallManager.swift
//  AquaGuard
//
//  Orchestrates the 1-1 voice call between a citizen and their assigned rescuer.
//  Bridges signaling (`WebSocketService`) and media (`WebRTCService`) and exposes
//  a small observable state machine that `CallOverlayView` renders.
//
//  Call flow (matches the web / backend):
//    caller: startCall → call_invite → (call_accepted) → offer → send webrtc_offer
//    callee: (call_incoming) → accept → call_accept → (webrtc_offer) → answer
//    both:   exchange webrtc_ice → ICE connected → .active → hangup
//

import Combine
import Foundation
import WebRTC

final class CallManager: ObservableObject {

    static let shared = CallManager()

    // MARK: - Published State

    @Published private(set) var phase: CallPhase = .idle
    @Published private(set) var callInfo: CallInfo?
    @Published private(set) var isMuted = false
    @Published private(set) var isSpeaker = false
    @Published private(set) var durationSeconds = 0
    @Published private(set) var endReason: CallEndReason?

    // MARK: - Private

    private var webrtc: WebRTCService?
    private var cancellables = Set<AnyCancellable>()
    private var durationTimer: Timer?

    /// Captured on the main thread so the off-main WebRTC delegate can read it
    /// safely when relaying ICE candidates.
    private var activeRequestId: Int?

    /// Incoming ICE candidates are buffered until the remote description is set,
    /// otherwise WebRTC rejects them.
    private var hasRemoteDescription = false
    private var pendingCandidates: [ICECandidatePayload] = []

    private init() {
        WebSocketService.shared.callSignals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in self?.handle(signal) }
            .store(in: &cancellables)
    }

    // MARK: - Public API (called from the UI, main thread)

    /// Place a call to the counterpart of an active rescue request.
    func startCall(requestId: Int, peerName: String) {
        guard phase == .idle else { return }
        endReason = nil
        callInfo = CallInfo(requestId: requestId, peerName: peerName, isCaller: true, media: "audio")
        activeRequestId = requestId
        phase = .outgoing
        WebSocketService.shared.sendCallInvite(requestId: requestId)
    }

    /// Accept the incoming call. Prepares the peer connection (prompts mic
    /// permission) and waits for the caller's offer.
    func accept() {
        guard phase == .incoming, let info = callInfo else { return }
        phase = .connecting
        WebSocketService.shared.sendCallAccept(requestId: info.requestId)
        prepareWebRTC()   // callee is ready to answer when the offer arrives
    }

    /// Decline an incoming call.
    func reject() {
        guard phase == .incoming, let info = callInfo else { return }
        WebSocketService.shared.sendCallReject(requestId: info.requestId)
        resetToIdle()
    }

    /// Cancel an outgoing call before it is answered.
    func cancel() {
        guard phase == .outgoing, let info = callInfo else { return }
        WebSocketService.shared.sendCallCancel(requestId: info.requestId)
        resetToIdle()
    }

    /// Hang up an in-progress (connecting/active) call.
    func hangup() {
        guard let info = callInfo, phase == .connecting || phase == .active else { return }
        WebSocketService.shared.sendCallHangup(requestId: info.requestId)
        resetToIdle()
    }

    func toggleMute() {
        isMuted.toggle()
        webrtc?.setMuted(isMuted)
    }

    func toggleSpeaker() {
        isSpeaker.toggle()
        webrtc?.setSpeaker(isSpeaker)
    }

    // MARK: - Signal Handling (main thread)

    private func handle(_ signal: CallSignal) {
        switch signal {
        case let .incoming(requestId, media, _, fromName, _):
            // Busy with another call → politely decline the newcomer.
            guard phase == .idle else {
                WebSocketService.shared.sendCallReject(requestId: requestId)
                return
            }
            endReason = nil
            callInfo = CallInfo(requestId: requestId,
                                peerName: fromName.isEmpty ? "Người gọi" : fromName,
                                isCaller: false,
                                media: media)
            activeRequestId = requestId
            phase = .incoming

        case let .ringing(requestId, toName):
            guard phase == .outgoing, callInfo?.requestId == requestId else { return }
            if !toName.isEmpty { callInfo?.peerName = toName }

        case let .unavailable(requestId, reason):
            guard callInfo?.requestId == requestId else { return }
            endWithReason(.unavailable(reason))

        case let .accepted(requestId):
            // Caller side: the callee picked up → we create and send the offer.
            guard phase == .outgoing, let info = callInfo, info.isCaller,
                  info.requestId == requestId else { return }
            phase = .connecting
            beginCallerOffer()

        case let .rejected(requestId):
            guard callInfo?.requestId == requestId else { return }
            endWithReason(.rejected)

        case let .cancelled(requestId):
            guard callInfo?.requestId == requestId else { return }
            endWithReason(.cancelled)

        case let .hangup(requestId):
            guard callInfo?.requestId == requestId else { return }
            endWithReason(.hangup)

        case let .offer(requestId, sdp):
            // Callee side: answer the caller's offer.
            guard let info = callInfo, !info.isCaller, info.requestId == requestId,
                  let webrtc else { return }
            Task { [weak self] in
                do {
                    let answerSdp = try await webrtc.answer(forRemoteSdp: sdp)
                    WebSocketService.shared.sendAnswer(requestId: requestId, sdp: answerSdp)
                    self?.remoteDescriptionApplied()
                } catch {
                    self?.failCall()
                }
            }

        case let .answer(requestId, sdp):
            // Caller side: apply the callee's answer.
            guard let info = callInfo, info.isCaller, info.requestId == requestId,
                  let webrtc else { return }
            Task { [weak self] in
                do {
                    try await webrtc.setRemoteAnswer(sdp: sdp)
                    self?.remoteDescriptionApplied()
                } catch {
                    self?.failCall()
                }
            }

        case let .ice(requestId, candidate):
            guard callInfo?.requestId == requestId else { return }
            if hasRemoteDescription, let webrtc {
                webrtc.add(candidate: candidate)
            } else {
                pendingCandidates.append(candidate)
            }
        }
    }

    // MARK: - WebRTC setup

    /// Create the peer connection and, once ICE servers are fetched, configure it.
    /// Used by the callee at accept() time.
    private func prepareWebRTC() {
        let service = makeWebRTC()
        Task { [weak self] in
            let ice = await self?.fetchICEServers() ?? []
            service.configure(iceServers: ice)
        }
    }

    /// Caller side after `call_accepted`: configure, create the offer, send it.
    private func beginCallerOffer() {
        let service = makeWebRTC()
        Task { [weak self] in
            guard let self else { return }
            let ice = await self.fetchICEServers()
            service.configure(iceServers: ice)
            do {
                let sdp = try await service.offer()
                if let requestId = self.activeRequestId {
                    WebSocketService.shared.sendOffer(requestId: requestId, sdp: sdp)
                }
            } catch {
                self.failCall()
            }
        }
    }

    private func makeWebRTC() -> WebRTCService {
        let service = WebRTCService()
        service.delegate = self
        webrtc = service
        hasRemoteDescription = false
        pendingCandidates.removeAll()
        return service
    }

    /// Flush buffered ICE once the remote description is in place.
    @MainActor
    private func remoteDescriptionApplied() {
        hasRemoteDescription = true
        guard let webrtc else { return }
        for candidate in pendingCandidates { webrtc.add(candidate: candidate) }
        pendingCandidates.removeAll()
    }

    private func fetchICEServers() async -> [ICEServerConfig] {
        guard let token = TokenManager.shared.getToken(),
              let url = URL(string: "\(NetworkConfig.apiBaseURL)/rtc/ice-servers") else {
            return []
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(ICEServersResponse.self, from: data).iceServers
        } catch {
            print("[Call] ICE fetch failed (\(error.localizedDescription)) — falling back to STUN")
            return []
        }
    }

    // MARK: - Termination

    @MainActor
    private func failCall() {
        if let info = callInfo {
            WebSocketService.shared.sendCallHangup(requestId: info.requestId)
        }
        endWithReason(.failed)
    }

    /// Peer-initiated / error end: show the ended screen briefly, then reset.
    private func endWithReason(_ reason: CallEndReason) {
        guard phase != .idle, phase != .ended else { return }
        endReason = reason
        phase = .ended
        teardownMedia()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.phase == .ended else { return }
            self.resetToIdle()
        }
    }

    /// Self-initiated end (reject/cancel/hangup): dismiss immediately.
    private func resetToIdle() {
        teardownMedia()
        phase = .idle
        callInfo = nil
        activeRequestId = nil
        endReason = nil
        isMuted = false
        isSpeaker = false
        durationSeconds = 0
    }

    private func teardownMedia() {
        durationTimer?.invalidate()
        durationTimer = nil
        webrtc?.close()
        webrtc = nil
        hasRemoteDescription = false
        pendingCandidates.removeAll()
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationSeconds = 0
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.durationSeconds += 1
        }
    }
}

// MARK: - WebRTCServiceDelegate (callbacks arrive off-main)

extension CallManager: WebRTCServiceDelegate {
    func webRTC(_ service: WebRTCService, didGenerate candidate: RTCIceCandidate) {
        // Called on WebRTC's signaling thread — extract Sendable values and hop
        // to main so we read `activeRequestId` and send in a well-defined order.
        let sdp = candidate.sdp
        let mid = candidate.sdpMid
        let mLineIndex = candidate.sdpMLineIndex
        DispatchQueue.main.async { [weak self] in
            guard let self, let requestId = self.activeRequestId else { return }
            var dict: [String: Any] = ["candidate": sdp, "sdpMLineIndex": mLineIndex]
            if let mid { dict["sdpMid"] = mid }
            WebSocketService.shared.sendIce(requestId: requestId, candidate: dict)
        }
    }

    func webRTC(_ service: WebRTCService, didChange state: RTCIceConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch state {
            case .connected, .completed:
                if self.phase == .connecting {
                    self.phase = .active
                    self.startDurationTimer()
                }
            case .failed:
                self.failCall()
            case .closed:
                if self.phase == .connecting || self.phase == .active {
                    self.endWithReason(.hangup)
                }
            default:
                break
            }
        }
    }
}

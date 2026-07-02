//
//  WebRTCService.swift
//  AquaGuard
//
//  Thin wrapper around the WebRTC (stasel/WebRTC) framework for an audio-only
//  peer-to-peer call. Owns a single `RTCPeerConnection`, the local mic track,
//  and the voice-chat audio session. `CallManager` drives it.
//
//  Prerequisite: add the `WebRTC` Swift package (https://github.com/stasel/WebRTC)
//  to the AquaGuard target.
//

import AVFoundation
import Foundation
import WebRTC

// MARK: - Delegate

protocol WebRTCServiceDelegate: AnyObject {
    /// A locally-gathered ICE candidate to relay to the peer.
    func webRTC(_ service: WebRTCService, didGenerate candidate: RTCIceCandidate)
    /// ICE connection state changed (connected / disconnected / failed …).
    func webRTC(_ service: WebRTCService, didChange state: RTCIceConnectionState)
}

enum WebRTCError: Error { case failed }

// MARK: - Service

final class WebRTCService: NSObject {

    weak var delegate: WebRTCServiceDelegate?

    /// One factory for the whole app — creating it is expensive, and it holds the
    /// SSL/codec setup.
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        return RTCPeerConnectionFactory()
    }()

    private var peerConnection: RTCPeerConnection?
    private var localAudioTrack: RTCAudioTrack?

    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "com.aquaguard.webrtc.audio")

    /// We only care about audio for both directions.
    private static let mediaConstraints: [String: String] = [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse,
    ]

    // MARK: - Setup

    /// Build the peer connection with the given ICE servers and attach the mic.
    func configure(iceServers: [ICEServerConfig]) {
        let config = RTCConfiguration()
        config.iceServers = iceServers.map { server in
            if let username = server.username, let credential = server.credential {
                return RTCIceServer(urlStrings: server.urls, username: username, credential: credential)
            }
            return RTCIceServer(urlStrings: server.urls)
        }
        if config.iceServers.isEmpty {
            config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        }
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        peerConnection = WebRTCService.factory.peerConnection(with: config, constraints: constraints, delegate: self)

        createLocalAudioTrack()
        configureAudioSession()
    }

    private func createLocalAudioTrack() {
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let source = WebRTCService.factory.audioSource(with: audioConstraints)
        let track = WebRTCService.factory.audioTrack(with: source, trackId: "audio0")
        peerConnection?.add(track, streamIds: ["stream0"])
        localAudioTrack = track
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [])
                try self.rtcAudioSession.setActive(true)
            } catch {
                print("[WebRTC] Audio session error: \(error.localizedDescription)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }

    // MARK: - SDP

    /// Create an offer, set it as local description, return the SDP string.
    func offer() async throws -> String {
        let constraints = RTCMediaConstraints(mandatoryConstraints: Self.mediaConstraints, optionalConstraints: nil)
        let sdp: RTCSessionDescription = try await withCheckedThrowingContinuation { cont in
            peerConnection?.offer(for: constraints) { sdp, error in
                if let sdp { cont.resume(returning: sdp) } else { cont.resume(throwing: error ?? WebRTCError.failed) }
            }
        }
        try await setLocalDescription(sdp)
        return sdp.sdp
    }

    /// Given the remote offer SDP, produce our answer SDP string.
    func answer(forRemoteSdp remoteSdp: String) async throws -> String {
        try await setRemoteDescription(sdp: remoteSdp, type: .offer)
        let constraints = RTCMediaConstraints(mandatoryConstraints: Self.mediaConstraints, optionalConstraints: nil)
        let sdp: RTCSessionDescription = try await withCheckedThrowingContinuation { cont in
            peerConnection?.answer(for: constraints) { sdp, error in
                if let sdp { cont.resume(returning: sdp) } else { cont.resume(throwing: error ?? WebRTCError.failed) }
            }
        }
        try await setLocalDescription(sdp)
        return sdp.sdp
    }

    /// Apply the peer's answer SDP (caller side, after they accepted).
    func setRemoteAnswer(sdp: String) async throws {
        try await setRemoteDescription(sdp: sdp, type: .answer)
    }

    func add(candidate: ICECandidatePayload) {
        let rtc = RTCIceCandidate(sdp: candidate.candidate,
                                  sdpMLineIndex: candidate.sdpMLineIndex,
                                  sdpMid: candidate.sdpMid)
        peerConnection?.add(rtc)
    }

    private func setLocalDescription(_ sdp: RTCSessionDescription) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            peerConnection?.setLocalDescription(sdp) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    private func setRemoteDescription(sdp: String, type: RTCSdpType) async throws {
        let desc = RTCSessionDescription(type: type, sdp: sdp)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            peerConnection?.setRemoteDescription(desc) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    // MARK: - Controls

    /// Mute/unmute the local microphone.
    func setMuted(_ muted: Bool) {
        localAudioTrack?.isEnabled = !muted
    }

    /// Route audio to the loudspeaker vs the earpiece.
    func setSpeaker(_ enabled: Bool) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(enabled ? .speaker : .none)
            } catch {
                print("[WebRTC] Speaker override error: \(error.localizedDescription)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }

    // MARK: - Teardown

    func close() {
        peerConnection?.close()
        peerConnection = nil
        localAudioTrack = nil
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.rtcAudioSession.lockForConfiguration()
            try? self.rtcAudioSession.setActive(false)
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
}

// MARK: - RTCPeerConnectionDelegate
//
// Callbacks arrive on WebRTC's signaling thread; the delegate (CallManager)
// hops to main where needed.

extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnection(_ pc: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        delegate?.webRTC(self, didGenerate: candidate)
    }

    func peerConnection(_ pc: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        delegate?.webRTC(self, didChange: newState)
    }

    func peerConnection(_ pc: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ pc: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ pc: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ pc: RTCPeerConnection) {}
    func peerConnection(_ pc: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ pc: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ pc: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}

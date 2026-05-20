//
//  CameraPreviewView.swift
//  AquaGuard
//
//  UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
//  to display live camera feed in SwiftUI.
//

import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var mirrored: Bool = false

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.cornerRadius = 24
        previewLayer.masksToBounds = true
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        applyMirroring(to: previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let previewLayer = context.coordinator.previewLayer else { return }
            previewLayer.frame = uiView.bounds
            applyMirroring(to: previewLayer)
        }
    }

    private func applyMirroring(to previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection, connection.isVideoMirroringSupported else {
            return
        }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = mirrored
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

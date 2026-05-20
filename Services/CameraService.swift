//
//  CameraService.swift
//  AquaGuard
//
//  AVCaptureSession-based camera service for live preview
//  and photo capture — Locket-style instant capture.
//

import AVFoundation
import Combine
import UIKit

class CameraService: NSObject, ObservableObject {

    // MARK: - Published

    @Published var capturedImage: UIImage?
    @Published var isFlashOn = false
    @Published var isFrontCamera = false
    @Published var isAuthorized = false

    // MARK: - Session

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?

    // MARK: - Init

    override init() {
        super.init()
        checkPermission()
    }

    // MARK: - Permission

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            isAuthorized = false
        }
    }

    // MARK: - Setup

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Camera input
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            session.commitConfiguration()
            return
        }

        currentDevice = device

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Photo output
        if session.outputs.isEmpty {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }

        session.commitConfiguration()
    }

    // MARK: - Actions

    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()

        // Flash
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func toggleFlash() {
        isFlashOn.toggle()
    }

    func flipCamera() {
        isFrontCamera.toggle()
        setupSession()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Front-camera preview is mirrored; keep the saved photo matching what the user saw.
            self.capturedImage = self.isFrontCamera ? image.horizontallyMirrored() : image
        }
    }
}

// MARK: - UIImage mirroring (match front-camera preview)

private extension UIImage {
    func horizontallyMirrored() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.translateBy(x: size.width, y: 0)
            context.scaleBy(x: -1, y: 1)
            draw(in: rect)
        }
    }
}

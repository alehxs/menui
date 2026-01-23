//
//  CameraManager.swift
//  Menui
//
//  Handles AVFoundation camera setup and photo capture.
//
//  Created by Alex on 12/29/25.
//

import AVFoundation
import UIKit

enum CameraLens {
    case ultraWide  // 0.5x (builtInUltraWideCamera at zoom 1.0)
    case wide       // 1x-5x (builtInWideAngleCamera)
}

class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var currentZoomFactor: CGFloat = 1.0
    @Published var isFlashEnabled: Bool = false
    @Published var activeLens: CameraLens = .wide

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var videoDevice: AVCaptureDevice?

    // Store references to both cameras
    private var wideCamera: AVCaptureDevice?
    private var ultraWideCamera: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?

    // Track switching state to prevent concurrent switches
    private var isSwitchingLens = false
    private var isSessionReady = false
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Discover both wide and ultra-wide cameras
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,
                .builtInDualWideCamera,
                .builtInDualCamera,
                .builtInWideAngleCamera,
                .builtInUltraWideCamera
            ],
            mediaType: .video,
            position: .back
        )

        // Find the wide-angle camera (standard 1x lens)
        wideCamera = discoverySession.devices.first { device in
            device.deviceType == .builtInWideAngleCamera
        }

        // Find the ultra-wide camera (0.5x lens)
        ultraWideCamera = discoverySession.devices.first { device in
            device.deviceType == .builtInUltraWideCamera
        }

        // Log discovered cameras
        if let wide = wideCamera {
            print("✓ Found wide-angle camera")
            print("  - Min zoom: \(wide.minAvailableVideoZoomFactor)x")
            print("  - Max zoom: \(wide.maxAvailableVideoZoomFactor)x")
        }

        if let ultraWide = ultraWideCamera {
            print("✓ Found ultra-wide camera")
            print("  - Min zoom: \(ultraWide.minAvailableVideoZoomFactor)x")
            print("  - Max zoom: \(ultraWide.maxAvailableVideoZoomFactor)x")
        }

        // Add photo output
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        // Add initial camera input (wide lens at 1.0x)
        if let wide = wideCamera {
            do {
                let input = try AVCaptureDeviceInput(device: wide)
                if session.canAddInput(input) {
                    session.addInput(input)
                    currentInput = input
                    videoDevice = wide

                    // Set initial zoom
                    try wide.lockForConfiguration()
                    wide.videoZoomFactor = 1.0
                    wide.unlockForConfiguration()

                    print("✓ Initial camera input added (wide lens at 1.0x)")
                }
            } catch {
                print("❌ Error adding initial camera input: \(error)")
            }
        }

        session.commitConfiguration()
    }
    
    func switchToLens(_ lens: CameraLens, zoom: CGFloat? = nil) {
        // Guard against concurrent switches
        guard !isSwitchingLens else {
            print("⏭️ Lens switch already in progress, ignoring request")
            return
        }

        // Don't switch if already on the target lens
        if activeLens == lens {
            print("ℹ️ Already on \(lens == .wide ? "wide" : "ultra-wide") lens")
            return
        }

        isSwitchingLens = true
        defer { isSwitchingLens = false }

        session.beginConfiguration()

        // Remove existing input if present
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }

        // Select the appropriate camera
        let targetDevice: AVCaptureDevice?
        let targetZoom: CGFloat

        switch lens {
        case .ultraWide:
            targetDevice = ultraWideCamera
            // Ultra-wide at zoom 1.0 = visual 0.5x
            targetZoom = zoom ?? 1.0
            print("🔄 Switching to ultra-wide lens (0.5x)")

        case .wide:
            targetDevice = wideCamera
            // Wide at zoom 1.0 = visual 1.0x
            targetZoom = zoom ?? 1.0
            print("🔄 Switching to wide lens (1x)")
        }

        guard let device = targetDevice else {
            print("❌ Target lens not available")
            session.commitConfiguration()
            return
        }

        do {
            // Add new input
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
                videoDevice = device

                // Set zoom on the new device
                try device.lockForConfiguration()

                // Clamp zoom to device capabilities
                let minZoom = device.minAvailableVideoZoomFactor
                let maxZoom = device.maxAvailableVideoZoomFactor
                let clampedZoom = min(max(targetZoom, minZoom), maxZoom)

                device.videoZoomFactor = clampedZoom
                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.activeLens = lens
                    // For ultra-wide, report visual 0.5x even though device is at 1.0x
                    self.currentZoomFactor = lens == .ultraWide ? 0.5 : clampedZoom
                }

                print("✓ Lens switched successfully, zoom: \(clampedZoom)x (visual: \(lens == .ultraWide ? 0.5 : clampedZoom)x)")
            }
        } catch {
            print("❌ Error switching lens: \(error)")
        }

        session.commitConfiguration()
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
                print("📹 Camera session started")

                // Log initial zoom level
                if let device = self.videoDevice {
                    print("📹 Initial zoom: \(device.videoZoomFactor)x")
                }

                // Mark session as ready
                DispatchQueue.main.async {
                    self.isSessionReady = true
                    print("✅ Camera session ready")
                }
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionReady = false
                }
            }
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()

        // Set flash mode based on current flash state
        if let device = videoDevice, device.hasFlash {
            settings.flashMode = isFlashEnabled ? .on : .off
        }

        output.capturePhoto(with: settings, delegate: self)
    }

    func setZoom(_ factor: CGFloat) {
        // Wait for session to be ready before allowing zoom changes
        guard isSessionReady else {
            print("⏳ Waiting for camera session to be ready...")
            return
        }

        // Determine which lens should be active for this zoom level
        if factor < 1.0 {
            // Sub-1x zoom requires ultra-wide lens
            if activeLens != .ultraWide {
                switchToLens(.ultraWide, zoom: 1.0)
            }
            // For ultra-wide, we keep device at 1.0x (visual 0.5x)
            // The UI will show 0.5x
            return
        }

        // 1x and above requires wide lens
        if activeLens != .wide {
            switchToLens(.wide, zoom: factor)
            return
        }

        // Already on correct lens, just adjust zoom
        guard let device = videoDevice else {
            print("❌ Cannot set zoom: no video device")
            return
        }

        do {
            try device.lockForConfiguration()

            // Clamp to device's actual capabilities
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = device.maxAvailableVideoZoomFactor
            let clampedFactor = min(max(factor, minZoom), maxZoom)

            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()

            DispatchQueue.main.async {
                self.currentZoomFactor = clampedFactor
            }

            print("✓ Zoom set to \(clampedFactor)x on \(self.activeLens == .wide ? "wide" : "ultra-wide") lens")
        } catch {
            print("❌ Error setting zoom: \(error)")
        }
    }

    func toggleFlash() {
        guard let device = videoDevice, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                DispatchQueue.main.async {
                    self.isFlashEnabled = false
                }
            } else {
                device.torchMode = .on
                DispatchQueue.main.async {
                    self.isFlashEnabled = true
                }
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

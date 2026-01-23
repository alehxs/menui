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

class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var currentZoomFactor: CGFloat = 1.0
    @Published var isFlashEnabled: Bool = false

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var videoDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Use system-preferred device (works best for ultra-wide on iPhone 15 Pro)
        // This virtual device automatically handles switching between physical cameras
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("❌ No video device available")
            return
        }

        // Store device reference for zoom and flash control
        self.videoDevice = device

        // Log detailed camera capabilities
        print("✓ Using system video device")
        print("Camera capabilities:")
        print("  - Device type: \(device.deviceType.rawValue)")
        print("  - Min zoom: \(device.minAvailableVideoZoomFactor)x")
        print("  - Max zoom: \(device.maxAvailableVideoZoomFactor)x")
        print("  - Virtual device: \(device.isVirtualDevice)")
        print("  - Has flash: \(device.hasFlash)")
        print("  - Has torch: \(device.hasTorch)")

        // If this device doesn't support ultra-wide, try discovery session
        if device.minAvailableVideoZoomFactor > 0.5 {
            print("⚠️ Primary device doesn't support 0.5x, trying discovery session...")

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

            // Find a device that supports zoom < 1.0
            if let ultraWideDevice = discoverySession.devices.first(where: { $0.minAvailableVideoZoomFactor <= 0.5 }) {
                self.videoDevice = ultraWideDevice
                print("✓ Found ultra-wide capable device: \(ultraWideDevice.deviceType.rawValue)")
                print("  - Min zoom: \(ultraWideDevice.minAvailableVideoZoomFactor)x")
                print("  - Max zoom: \(ultraWideDevice.maxAvailableVideoZoomFactor)x")
            } else {
                print("⚠️ No ultra-wide device found, 0.5x zoom may not be available")
            }
        }

        guard let finalDevice = self.videoDevice else {
            print("❌ No camera device available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: finalDevice)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("❌ Error setting up camera input: \(error)")
            return
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        // Set initial zoom to 1.0x
        do {
            try finalDevice.lockForConfiguration()
            if finalDevice.minAvailableVideoZoomFactor <= 1.0 && finalDevice.maxAvailableVideoZoomFactor >= 1.0 {
                finalDevice.videoZoomFactor = 1.0
                DispatchQueue.main.async {
                    self.currentZoomFactor = 1.0
                }
                print("✓ Initial zoom set to 1.0x")
            }
            finalDevice.unlockForConfiguration()
        } catch {
            print("⚠️ Could not set initial zoom: \(error)")
        }
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
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                self.session.stopRunning()
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

            // Debug log for troubleshooting
            if factor != clampedFactor {
                print("⚠️ Zoom adjusted: requested \(factor)x → applied \(clampedFactor)x (device range: \(minZoom)x-\(maxZoom)x)")
            } else {
                print("✓ Zoom set to \(clampedFactor)x")
            }
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

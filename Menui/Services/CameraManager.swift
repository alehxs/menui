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

        // Try to get a camera device that supports ultra-wide zoom (< 1.0x)
        var device: AVCaptureDevice?

        // Priority order for devices that support 0.5x zoom:
        // 1. Triple camera (iPhone 11 Pro+) - supports ultra-wide, wide, telephoto
        if let tripleCamera = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            device = tripleCamera
            print("✓ Using triple camera - zoom range: \(tripleCamera.minAvailableVideoZoomFactor)x - \(tripleCamera.maxAvailableVideoZoomFactor)x")
        }
        // 2. Dual wide camera (iPhone 11+) - supports ultra-wide + wide
        else if let dualWideCamera = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            device = dualWideCamera
            print("✓ Using dual wide camera - zoom range: \(dualWideCamera.minAvailableVideoZoomFactor)x - \(dualWideCamera.maxAvailableVideoZoomFactor)x")
        }
        // 3. Dual camera (older devices with wide + telephoto)
        else if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            device = dualCamera
            print("✓ Using dual camera - zoom range: \(dualCamera.minAvailableVideoZoomFactor)x - \(dualCamera.maxAvailableVideoZoomFactor)x")
        }
        // 4. Fallback to standard wide angle camera (may not support < 1.0x zoom)
        else if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            device = wideCamera
            print("⚠️ Using wide angle camera - zoom range: \(wideCamera.minAvailableVideoZoomFactor)x - \(wideCamera.maxAvailableVideoZoomFactor)x")
            print("⚠️ This device may not support 0.5x zoom")
        }

        guard let captureDevice = device else {
            print("❌ No back camera found")
            return
        }

        // Store device reference for zoom and flash control
        self.videoDevice = captureDevice

        // Log detailed camera capabilities
        print("Camera capabilities:")
        print("  - Min zoom: \(captureDevice.minAvailableVideoZoomFactor)x")
        print("  - Max zoom: \(captureDevice.maxAvailableVideoZoomFactor)x")
        print("  - Has flash: \(captureDevice.hasFlash)")
        print("  - Has torch: \(captureDevice.hasTorch)")

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
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
            try captureDevice.lockForConfiguration()
            if captureDevice.minAvailableVideoZoomFactor <= 1.0 && captureDevice.maxAvailableVideoZoomFactor >= 1.0 {
                captureDevice.videoZoomFactor = 1.0
                DispatchQueue.main.async {
                    self.currentZoomFactor = 1.0
                }
                print("✓ Initial zoom set to 1.0x")
            }
            captureDevice.unlockForConfiguration()
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

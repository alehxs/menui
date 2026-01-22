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

        // Try to get dual camera or wide angle camera (supports lower zoom on newer devices)
        var device: AVCaptureDevice?

        // First try to get dual camera (iPhone with multiple cameras)
        if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            device = dualCamera
            print("Using dual camera - zoom range: \(dualCamera.minAvailableVideoZoomFactor)-\(dualCamera.maxAvailableVideoZoomFactor)")
        }
        // Fallback to wide angle camera
        else if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            device = wideCamera
            print("Using wide angle camera - zoom range: \(wideCamera.minAvailableVideoZoomFactor)-\(wideCamera.maxAvailableVideoZoomFactor)")
        }

        guard let captureDevice = device else {
            print("No back camera found")
            return
        }

        // Store device reference for zoom and flash control
        self.videoDevice = captureDevice

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
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
        guard let device = videoDevice else { return }

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
            print("Requested zoom: \(factor), Applied zoom: \(clampedFactor), Device range: \(minZoom)-\(maxZoom)")
        } catch {
            print("Error setting zoom: \(error)")
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

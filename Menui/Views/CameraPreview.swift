//
//  CameraPreview.swift
//  Menui
//
//  Shows live camera feed in SwiftUI using AVCaptureVideoPreviewLayer.
//
//  Created by Alex on 12/29/25.
//

//
//  CameraPreview.swift
//  Menui
//
//  Shows live camera feed in SwiftUI using AVCaptureVideoPreviewLayer.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // No update needed
    }
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

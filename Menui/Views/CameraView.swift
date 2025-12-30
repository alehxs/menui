//
//  CameraView.swift
//  Menui
//
//  Main camera screen with live preview, capture button, and photo library access.
//

import SwiftUI
import PhotosUI

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showingResults = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Show captured image or live preview
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea(edges: .top)
                } else {
                    CameraPreview(session: cameraManager.session)
                        .ignoresSafeArea(edges: .top)
                }
                
                // Bottom control bar
                ZStack {
                    Color.black
                    
                    HStack {
                        // Photo library button (bottom left)
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                )
                        }
                        
                        Spacer()
                        
                        // Capture button (center)
                        Button {
                            cameraManager.capturePhoto()
                        } label: {
                            Circle()
                                .strokeBorder(.white, lineWidth: 4)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 58, height: 58)
                                )
                        }
                        
                        Spacer()
                        
                        // Empty space to balance layout (bottom right)
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 50, height: 50)
                    }
                    .padding(.horizontal, 30)
                }
                .frame(height: 120)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage {
                capturedImage = image
                cameraManager.stopSession()
                showingResults = true
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                    cameraManager.stopSession()
                    showingResults = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingResults) {
            if let image = capturedImage {
                ResultsView(image: image)
                    .onDisappear {
                        capturedImage = nil
                        cameraManager.capturedImage = nil
                        selectedPhoto = nil
                        cameraManager.startSession()
                    }
            }
        }
    }
}

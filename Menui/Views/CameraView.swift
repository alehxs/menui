//
//  CameraView.swift
//  Menui
//
//  Main camera screen with live preview and native-style controls.
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

            // Live camera preview
            if capturedImage == nil {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
            }

            // Flash toggle button (top-right)
            VStack {
                HStack {
                    Spacer()

                    Button {
                        cameraManager.toggleFlash()
                    } label: {
                        Image(systemName: cameraManager.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(cameraManager.isFlashEnabled ? .yellow : .white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            )
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                    .opacity(capturedImage == nil ? 1 : 0)
                }

                Spacer()
            }

            // Bottom controls
            VStack {
                Spacer()

                // Zoom control (hybrid gesture: tap for presets, drag for dial)
                if capturedImage == nil {
                    ZoomDialControl(
                        currentZoom: $cameraManager.currentZoomFactor,
                        onZoomChange: { newZoom in
                            cameraManager.setZoom(newZoom)
                        }
                    )
                    .padding(.bottom, 20)
                }

                // Main control bar
                HStack(spacing: 80) {
                    // Photo library button (bottom left)
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                    }

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

                    // Empty space for balance (bottom right)
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 50, height: 50)
                }
                .padding(.bottom, 50)
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

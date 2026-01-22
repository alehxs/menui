//
//  CameraView.swift
//  Menui
//
//  Main camera screen using native iOS camera interface.
//

import SwiftUI
import PhotosUI

struct CameraView: View {
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingResults = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                // Welcome message when no camera is active
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.3))

                    Text("Menui")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Scan menu to get started")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Bottom controls
                HStack(spacing: 60) {
                    // Photo library button
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                    }

                    // Camera button
                    Button {
                        showingCamera = true
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

                    // Placeholder for balance
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 50, height: 50)
                }
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Select Photo")
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                showingResults = true
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                    showingResults = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingResults) {
            if let image = capturedImage {
                ResultsView(image: image)
                    .onDisappear {
                        capturedImage = nil
                        selectedPhoto = nil
                    }
            }
        }
    }
}

//
//  ResultsView.swift
//  Menui
//
//  Displays extracted dish names with food images from API.
//
//  Created by Alex on 12/29/25.
//

import SwiftUI
import SwiftData

struct ResultsView: View {
    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var dishNames: [String] = []
    @State private var dishImages: [String: [String]] = [:]
    @State private var isProcessing = true
    @State private var isFetchingImages = false
    @State private var errorMessage: String?

    private let ocrService = OCRService()
    private let parserService = DishParserService()

    var body: some View {
        NavigationView {
            VStack {
                // Scanned image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .cornerRadius(12)
                    .padding(.horizontal)

                // Loading or results
                if isProcessing {
                    Spacer()
                    ProgressView("Scanning menu...")
                    Spacer()
                } else if isFetchingImages {
                    Spacer()
                    ProgressView("Fetching dish images...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if dishNames.isEmpty {
                    Spacer()
                    Text("No dishes found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(dishNames, id: \.self) { dish in
                        DishRow(name: dish, imageUrls: dishImages[dish] ?? [])
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await processImage()
            }
        }
    }

    /// Runs OCR, parser, and fetches images from API
    private func processImage() async {
        // Step 1: OCR
        let ocrLines = await ocrService.recognizeText(from: image)
        dishNames = parserService.extractDishes(from: ocrLines)
        isProcessing = false

        guard !dishNames.isEmpty else { return }

        // Step 2: Fetch images from backend
        isFetchingImages = true
        do {
            dishImages = try await APIService.shared.fetchDishImages(for: dishNames)

            // Step 3: Auto-save to history after successful image fetch
            await saveScanSession()
        } catch {
            errorMessage = "Failed to load images"
            print("API Error: \(error)")
        }
        isFetchingImages = false
    }

    /// Saves the current scan to history
    private func saveScanSession() async {
        // Create dish models with their image URLs
        let dishModels = dishNames.map { dishName in
            Dish(name: dishName, imageURLs: dishImages[dishName] ?? [])
        }

        // Convert UIImage to Data for storage
        let imageData = image.jpegData(compressionQuality: 0.7)

        // Create and save session
        let session = ScanSession(
            timestamp: Date(),
            restaurantName: nil,
            dishes: dishModels,
            originalImageData: imageData
        )

        modelContext.insert(session)

        do {
            try modelContext.save()
            print("✓ Scan session saved to history")
        } catch {
            print("Failed to save scan session: \(error)")
        }
    }
}

// MARK: - Dish Row

struct DishRow: View {
    let name: String
    let imageUrls: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)

            if imageUrls.isEmpty {
                Text("No images available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(imageUrls.prefix(3), id: \.self) { urlString in
                        AsyncImage(url: URL(string: urlString)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

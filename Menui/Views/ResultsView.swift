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
        NavigationStack {
            Group {
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Scanning menu...")
                            .foregroundColor(.secondary)
                    }
                } else if isFetchingImages {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Fetching dish images...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(error)
                            .foregroundColor(.secondary)
                    }
                } else if dishNames.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No dishes found")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(dishNames, id: \.self) { dish in
                        DishRow(name: dish, imageUrls: dishImages[dish] ?? [])
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Dishes")
            .navigationBarTitleDisplayMode(.large)
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
        HStack(spacing: 12) {
            // Thumbnail image (left side)
            AsyncImage(url: URL(string: imageUrls.first ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }

            // Dish name (right side)
            Text(name)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

//
//  Untitled.swift
//  Menui
//
//  Displays extracted dish names from scanned menu image.
//
//  Created by Alex on 12/29/25.
//

//
//  ResultsView.swift
//  Menui
//
//  Displays extracted dish names from scanned menu image.
//

import SwiftUI

struct ResultsView: View {
    let image: UIImage
    
    @Environment(\.dismiss) private var dismiss
    @State private var dishNames: [String] = []
    @State private var isProcessing = true
    
    private let ocrService = OCRService()
    private let parserService = DishParserService()
    
    var body: some View {
        NavigationView {
            VStack {
                // Scanned image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .padding()
                
                // Loading or results
                if isProcessing {
                    ProgressView("Scanning menu...")
                        .padding()
                    Spacer()
                } else if dishNames.isEmpty {
                    Text("No dishes found")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(dishNames, id: \.self) { dish in
                        Text(dish)
                    }
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
    
    /// Runs OCR and parser on the image
    private func processImage() async {
        let ocrLines = await ocrService.recognizeText(from: image)
        dishNames = parserService.extractDishes(from: ocrLines)
        isProcessing = false
    }
}

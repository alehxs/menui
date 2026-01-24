//
//  ResultsViewV2.swift
//  Menui
//
//  Updated results view using the new MenuParser with spatial layout analysis
//

import SwiftUI
import SwiftData

struct ResultsViewV2: View {
    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var parsedMenu: ParsedMenu?
    @State private var isProcessing = true
    @State private var errorMessage: String?

    private let ocrService = OCRService()
    private let menuParser = MenuParser()

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
                    ProgressView("Analyzing menu structure...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if let menu = parsedMenu, !menu.menuSections.isEmpty {
                    // Display structured menu
                    List {
                        ForEach(menu.menuSections, id: \.sectionName) { section in
                            Section(header: Text(section.sectionName)
                                .font(.headline)
                                .foregroundColor(.primary)) {
                                ForEach(section.items, id: \.id) { item in
                                    MenuItemRow(item: item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    Spacer()
                    Text("No menu items found")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Menu Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if let menu = parsedMenu {
                        Button("Export JSON") {
                            exportJSON(menu: menu)
                        }
                    }
                }
            }
            .task {
                await processImage()
            }
        }
    }

    /// Process image using new MenuParser
    private func processImage() async {
        // Step 1: OCR with spatial layout
        let blocks = await ocrService.recognizeTextWithLayout(from: image)
        print("📸 OCR extracted \(blocks.count) text blocks")

        // Step 2: Parse menu structure
        let menu = menuParser.parse(blocks: blocks)
        parsedMenu = menu
        isProcessing = false

        // Print JSON for debugging
        if let jsonData = try? JSONEncoder().encode(menu),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📋 Parsed Menu JSON:")
            print(jsonString)
        }
    }

    /// Export menu as JSON
    private func exportJSON(menu: ParsedMenu) {
        guard let jsonData = try? JSONEncoder().encode(menu),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        // Copy to clipboard
        UIPasteboard.general.string = jsonString
        print("📋 JSON copied to clipboard")
    }
}

// MARK: - Menu Item Row

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)

                Spacer()

                if let price = item.price {
                    Text(String(format: "$%.2f", price))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let description = item.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if !item.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            if !item.modifiers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add-ons:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(item.modifiers, id: \.text) { modifier in
                        HStack {
                            Text("• \(modifier.text)")
                                .font(.caption)
                            if let price = modifier.price {
                                Text(String(format: "+$%.2f", price))
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

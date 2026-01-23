//
//  MenuParserTestView.swift
//  Menui
//
//  Simple test view to verify MenuParser functionality locally
//

import SwiftUI

struct MenuParserTestView: View {
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var parsedMenu: ParsedMenu?
    @State private var isProcessing = false
    @State private var jsonOutput = ""
    @State private var debugLog: [String] = []

    private let ocrService = OCRService()
    private let menuParser = MenuParser()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Selection
                    Button("Select Menu Image") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    // Selected Image Preview
                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Image")
                                .font(.headline)

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .border(Color.gray, width: 1)

                            Button("Process Menu") {
                                Task {
                                    await processMenu()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isProcessing)
                        }
                    }

                    // Processing Indicator
                    if isProcessing {
                        HStack {
                            ProgressView()
                            Text("Processing...")
                        }
                    }

                    // Debug Log
                    if !debugLog.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Log")
                                .font(.headline)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(debugLog, id: \.self) { log in
                                        Text(log)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    // Parsed Results
                    if let menu = parsedMenu {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Parsed Menu (\(menu.menuSections.count) sections)")
                                .font(.headline)

                            ForEach(menu.menuSections, id: \.sectionName) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(section.sectionName)
                                        .font(.title3)
                                        .fontWeight(.bold)

                                    ForEach(section.items, id: \.id) { item in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(item.name)
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                if let price = item.price {
                                                    Text(String(format: "$%.2f", price))
                                                        .foregroundColor(.green)
                                                }
                                            }

                                            if let desc = item.description {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            if !item.tags.isEmpty {
                                                Text("Tags: \(item.tags.joined(separator: ", "))")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color.blue.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // JSON Output
                    if !jsonOutput.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("JSON Output")
                                    .font(.headline)

                                Spacer()

                                Button("Copy") {
                                    UIPasteboard.general.string = jsonOutput
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            ScrollView {
                                Text(jsonOutput)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 300)
                            .padding(8)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Menu Parser Test")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }

    private func processMenu() async {
        guard let image = selectedImage else { return }

        isProcessing = true
        debugLog = []
        parsedMenu = nil
        jsonOutput = ""

        // Capture console output
        debugLog.append("🔍 Starting OCR...")

        // Step 1: OCR with spatial layout
        let blocks = await ocrService.recognizeTextWithLayout(from: image)
        debugLog.append("📸 OCR extracted \(blocks.count) text blocks")

        // Log some sample blocks
        for (index, block) in blocks.prefix(5).enumerated() {
            debugLog.append("  Block \(index): '\(block.text)' at (\(String(format: "%.2f", block.centerX)), \(String(format: "%.2f", block.centerY)))")
        }

        // Step 2: Parse menu
        debugLog.append("🧮 Parsing menu structure...")
        let menu = menuParser.parse(blocks: blocks)
        parsedMenu = menu

        debugLog.append("✅ Found \(menu.menuSections.count) sections")
        for section in menu.menuSections {
            debugLog.append("  Section '\(section.sectionName)': \(section.items.count) items")
        }

        // Step 3: Generate JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let prettyJsonData = try? encoder.encode(menu),
           let prettyJsonString = String(data: prettyJsonData, encoding: .utf8) {
            jsonOutput = prettyJsonString
            debugLog.append("📋 JSON generated (\(prettyJsonString.count) chars)")
        }

        isProcessing = false
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    MenuParserTestView()
}

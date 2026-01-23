//
//  OCRService.swift
//  Menui

//  Uses Apple Vision Framework to extract text lines from images.
//  Runs entirely on-device, no network calls
//
//  Created by Alex on 12/27/25.
//

import Vision
import UIKit

class OCRService {
    /// Extracts text lines from an image using Apple Vision OCR (legacy method).
    ///  - Parameter image: The image to scan for text
    ///  - Returns: Array of detected text lines, empty if none are found.
    func recognizeText(from image: UIImage) async -> [String] {
        let blocks = await recognizeTextWithLayout(from: image)
        return blocks.map { $0.text }
    }

    /// Extracts text WITH spatial layout information from an image.
    ///  - Parameter image: The image to scan for text
    ///  - Returns: Array of OCRBlock objects containing text + bounding boxes
    func recognizeTextWithLayout(from image: UIImage) async -> [OCRBlock] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Filter out browser UI and non-menu content
                let filteredObs = observations.filter { obs in
                    guard let text = obs.topCandidates(1).first?.string else { return false }

                    let box = obs.boundingBox
                    let centerX = box.midX
                    let centerY = box.midY

                    // Basic spatial filtering - exclude edges and top (where browser tabs are)
                    // Top 15% is usually browser chrome/tabs
                    // Bottom 10% is usually status bar
                    guard centerX > 0.05 && centerX < 0.95 && centerY > 0.15 && centerY < 0.90 else {
                        return false
                    }

                    // Filter out browser UI text (case-insensitive)
                    let lowerText = text.lowercased()
                    let browserUIKeywords = [
                        "http", "https", "www.", ".com", ".net", ".org",
                        "chrome", "safari", "firefox", "edge",
                        "bookmark", "favorites", "history", "downloads",
                        "back", "forward", "reload", "refresh",
                        "search google", "search or type",
                        "new tab", "close tab",
                        "file", "edit", "view", "window", "help",
                        "settings", "preferences", "extensions",
                        "sign in", "log in", "account",
                        // Browser tab patterns
                        "website", "jobs", "startup", "reddit", "r/",
                        "font:", "dev.", "ubi "
                    ]

                    for keyword in browserUIKeywords {
                        if lowerText.contains(keyword) {
                            print("🚫 Filtered browser UI: '\(text)'")
                            return false
                        }
                    }

                    // Filter out business hours patterns
                    if text.contains("AM") && text.contains("PM") && text.contains("-") {
                        print("🚫 Filtered hours: '\(text)'")
                        return false
                    }

                    // Filter out day ranges (MONDAY TO FRIDAY)
                    let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
                    let matchedDays = days.filter { lowerText.contains($0) }.count
                    if matchedDays >= 2 {
                        print("🚫 Filtered day range: '\(text)'")
                        return false
                    }

                    // Filter out single characters (likely UI icons)
                    if text.trimmingCharacters(in: .whitespaces).count < 2 {
                        return false
                    }

                    // Filter out text that's too small (likely footnotes/browser chrome)
                    // In normalized coordinates, browser UI is typically very small
                    if box.height < 0.015 {
                        return false
                    }

                    return true
                }

                // Convert to OCRBlock objects
                let blocks = filteredObs.compactMap { observation -> OCRBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }

                    // Vision uses bottom-left origin, convert to top-left
                    let box = observation.boundingBox
                    let convertedBox = CGRect(
                        x: box.minX,
                        y: 1.0 - box.maxY,  // Flip Y axis
                        width: box.width,
                        height: box.height
                    )

                    return OCRBlock(
                        text: candidate.string,
                        boundingBox: convertedBox,
                        confidence: candidate.confidence
                    )
                }

                // Debug logging
                print("📸 OCR Results:")
                print("   Total detected: \(observations.count)")
                print("   After filtering: \(blocks.count)")
                print("   Filtered out: \(observations.count - blocks.count)")

                // Show sample of what was kept
                print("   Sample blocks kept:")
                for (i, block) in blocks.prefix(10).enumerated() {
                    print("     [\(i)] '\(block.text)' (y: \(String(format: "%.2f", block.centerY)))")
                }

                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "es-419"]

            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}

//
//  DishParserService.swift
//  Menui
//
//  Takes raw OCR lines, cleans lines up, and returns only dish names
//
//  Created by Alex on 12/29/25.
//

import Foundation

class DishParserService {
    private let skipPatterns = [
            "appetizer", "entree", "dessert", "beverage", "drink", "side",
            "main menu", "starters", "mains", "drinks",

            "grilled", "finished", "served", "roasted", "confit", "focaccia",
            "braised", "sauteed", "fried", "baked", "steamed",

            "consuming", "raw", "undercooked", "may increase",

            "garlic", "tomato", "basil", "arugula"
        ]

    // Common words that indicate a description fragment, not a dish name
    private let fragmentStarters = [
        "or ", "and ", "with ", "topped ", "served ", "covered ",
        "your ", "choice ", "lettuce ", "shredded ", "ground ",
        "red ", "green ", "white ", "black ", "brown ",
        "beans ", "rice ", "cheese ", "sauce ", "cream ",
        "flour ", "corn ", "meat ", "chicken ", "beef ", "pork ",
        "onions ", "tomatoes ", "peppers "
    ]

    // Common descriptor/ingredient words that shouldn't dominate a dish name
    private let commonDescriptors = [
        "topped", "with", "covered", "filled", "served", "choice",
        "sauce", "cheese", "beans", "rice", "lettuce", "cream",
        "onions", "tomatoes", "peppers", "meat", "ground", "shredded"
    ]

    
    /// Extracts dish names from raw OCR lines.
    /// - Parameter lines: Raw text lines from OCR.
    /// - Returns: Filtered list of dish names only.
    func extractDishes(from lines: [String]) -> [String] {
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard trimmed.count > 2 else { return nil }

            // Skip all-caps section headers (longer than 3 chars)
            if trimmed == trimmed.uppercased() && trimmed.count > 3 {
                return nil
            }

            let lower = trimmed.lowercased()

            // Skip lines starting with lowercase (likely description fragments)
            // Exception: very short lines might be legitimate (e.g., "al pastor")
            if let firstChar = trimmed.first, firstChar.isLowercase && trimmed.count > 10 {
                return nil
            }

            // Skip section headers and common skip patterns
            if skipPatterns.contains(where: { lower.contains($0) }) {
                return nil
            }

            // Skip lines starting with conjunctions/prepositions (description fragments)
            if fragmentStarters.contains(where: { lower.hasPrefix($0) }) {
                return nil
            }

            // Skip lines with too many descriptor words (likely descriptions)
            let words = lower.split(separator: " ")
            let descriptorCount = words.filter { word in
                commonDescriptors.contains(String(word))
            }.count
            if descriptorCount >= 3 || (words.count > 0 && Double(descriptorCount) / Double(words.count) > 0.5) {
                return nil
            }

            // Skip very long lines (likely descriptions)
            if trimmed.count > 45 { return nil }

            // Skip lines with pipes
            if trimmed.contains("|") { return nil }

            // Skip lines with periods in the middle (sentence fragments)
            if let dotIndex = trimmed.firstIndex(of: "."),
               dotIndex != trimmed.index(before: trimmed.endIndex) {
                return nil
            }

            // Require minimum length or spaces
            if trimmed.count < 4 && !trimmed.contains(" ") { return nil }

            // Clean up the text
            let cleaned = trimmed
                // Remove asterisks, bullets, quotes, slashes at the end (menu markers)
                .replacingOccurrences(of: #"[\s\*•·\"'/]+$"#, with: "", options: .regularExpression)
                // Remove ½ Dz suffix (e.g., "Oysters Rockefeller ½ Dz")
                .replacingOccurrences(of: #"\s*½?\s*Dz\s*$"#, with: "", options: .regularExpression)
                // Remove prices at the end
                .replacingOccurrences(of: #"\s*\$?\d+°?\s*$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            return cleaned.isEmpty ? nil : cleaned
        }
    }
}

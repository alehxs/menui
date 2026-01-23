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

            "garlic", "tomato", "basil", "arugula",

            // Browser UI patterns
            "http", "www.", ".com", ".net", ".org",
            "bookmark", "favorites", "tab", "browser",
            "chrome", "safari", "firefox",
            "search", "google", "address bar",
            "zoom", "refresh", "reload", "print"
        ]

    // Common words that indicate a description fragment, not a dish name
    private let fragmentStarters = [
        "or ", "and ", "with ", "topped ", "served ", "covered ",
        "your ", "choice ", "lettuce ", "shredded ", "ground ",
        "red ", "green ", "white ", "black ", "brown ",
        "beans ", "rice ", "cheese ", "sauce ", "cream ",
        "flour ", "corn ", "meat ", "chicken ", "beef ", "pork ",
        "onions ", "tomatoes ", "peppers ", "a flat", "a crispy"
    ]

    // Common descriptor/ingredient words that shouldn't dominate a dish name
    private let commonDescriptors = [
        "topped", "with", "covered", "filled", "served", "choice",
        "sauce", "cheese", "beans", "rice", "lettuce", "cream",
        "onions", "tomatoes", "peppers", "meat", "ground", "shredded"
    ]

    // Single words that are never dish names (fragments from descriptions)
    private let neverDishNames = [
        "flour", "corn", "white", "red", "green", "black", "brown",
        "soft", "hard", "crispy", "flat", "topped", "topp", "with",
        "and", "or", "the", "a", "an", "flot", "flo", "greer", "chee",
        "your", "choice", "jj", "si"
    ]

    // Common Mexican/Latin American dish names (allow lowercase and all-caps)
    private let mexicanDishStarters = [
        "taco", "tacos", "tamale", "tamales", "burrito", "burritos",
        "enchilada", "enchiladas", "quesadilla", "quesadillas",
        "torta", "tortas", "chilaquiles", "pozole", "menudo", "mole",
        "carnitas", "al pastor", "carne asada", "barbacoa",
        "fajita", "fajitas", "chimichanga", "chimichangas",
        "tostada", "tostadas", "sope", "sopes", "gordita", "gorditas",
        "huarache", "huaraches", "flautas", "chalupa", "chalupas",
        "tostaguac", "chile relleno", "chile", "relleno"
    ]

    // Section headers to skip (all-caps only)
    private let sectionHeaders = [
        "appetizers", "appetizer", "entrees", "entree", "entrées",
        "desserts", "dessert", "beverages", "beverage", "drinks",
        "starters", "mains", "main menu", "sides", "salads",
        "soups", "sandwiches", "breakfast", "lunch", "dinner",
        "specials", "pick one", "choose one", "includes"
    ]

    
    /// Extracts dish names from raw OCR lines.
    /// - Parameter lines: Raw text lines from OCR.
    /// - Returns: Filtered list of dish names only.
    func extractDishes(from lines: [String]) -> [String] {
        // First pass: Filter out obvious browser/UI junk
        let preFiltered = lines.filter { line in
            let lower = line.lowercased()

            // Skip browser tab-like patterns
            if lower.contains("website") || lower.contains("jobs") ||
               lower.contains("reddit") || lower.contains("r/") ||
               lower.contains("font:") || lower.contains("startup") ||
               lower.contains("dev.") || lower.contains("ubi ") {
                print("🚫 Skipping browser tab: '\(line)'")
                return false
            }

            // Skip time ranges (business hours)
            if line.contains("AM") && line.contains("PM") && line.contains("-") {
                print("🚫 Skipping hours: '\(line)'")
                return false
            }

            // Skip day ranges (MONDAY TO FRIDAY)
            let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            let hasDays = days.filter { lower.contains($0) }.count >= 2
            if hasDays {
                print("🚫 Skipping day range: '\(line)'")
                return false
            }

            return true
        }

        return preFiltered.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard trimmed.count > 2 else { return nil }

            let lower = trimmed.lowercased()

            // Skip all-caps section headers (but allow dish names)
            if trimmed == trimmed.uppercased() && trimmed.count > 3 {
                // Check if it's a known dish name
                let isDishName = mexicanDishStarters.contains { lower.hasPrefix($0) || lower.contains($0) }
                let isSectionHeader = sectionHeaders.contains { lower.contains($0) }

                // Skip only if it's a section header, not a dish name
                if isSectionHeader && !isDishName {
                    return nil
                }
            }

            // Skip lines starting with lowercase (likely description fragments)
            // Exception: very short lines or Mexican/Latin American dishes
            let startsWithMexicanDish = mexicanDishStarters.contains { lower.hasPrefix($0) }
            if let firstChar = trimmed.first, firstChar.isLowercase && trimmed.count > 10 && !startsWithMexicanDish {
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

            // Skip single-word fragments that are never dish names
            let words = lower.split(separator: " ")
            if words.count == 1 && neverDishNames.contains(String(words[0])) {
                return nil
            }

            // Skip lines with too many descriptor words (likely descriptions)
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
        // Filter out dishes that don't meet backend validation (2-100 chars)
        .filter { dish in
            let length = dish.trimmingCharacters(in: .whitespaces).count
            let lower = dish.lowercased()

            // Length check
            guard length >= 2 && length <= 100 else { return false }

            // Skip lines that start with parentheses (descriptions)
            if dish.hasPrefix("(") {
                return false
            }

            // Skip lines with sauce descriptions
            if lower.contains("sauce") && lower.contains(",") {
                return false
            }

            // Skip cooking method descriptions
            if lower.hasPrefix("beef and") || lower.hasPrefix("chicken is") ||
               lower.hasPrefix("cooked with") {
                return false
            }

            return true
        }
        // Limit to 20 items max (backend constraint)
        .prefix(20)
        .map { $0 }
    }
}

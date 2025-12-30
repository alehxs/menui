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

    
    /// Extracts dish names from raw OCR lines.
    /// - Parameter lines: Raw text lines from OCR.
    /// - Returns: Filtered list of dish names only.
    func extractDishes(from lines: [String]) -> [String] {
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            guard trimmed.count > 2 else { return nil }
            
            if trimmed == trimmed.uppercased() && trimmed.count > 3 {
                return nil
            }
            
            let lower = trimmed.lowercased()
            if skipPatterns.contains(where: { lower.contains($0) }) {
                return nil
            }
            
            if trimmed.count > 45 { return nil }
            
            if trimmed.contains("|") { return nil }
            
            if trimmed.count < 4 && !trimmed.contains(" ") { return nil}
            
            let cleaned = trimmed
            
                .replacingOccurrences(of: #"\s*\*+/?\**\s*$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\s*½?\s*Dz\s*$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\s*\$?\d+°?\s*$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            
            return cleaned.isEmpty ? nil :cleaned
        }
    }
}

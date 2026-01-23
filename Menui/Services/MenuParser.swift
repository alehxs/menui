//
//  MenuParser.swift
//  Menui
//
//  Advanced menu parser using spatial layout analysis
//  Implements: column detection, price anchors, vertical grouping, section detection
//

import Foundation
import CoreGraphics

class MenuParser {

    // MARK: - Public API

    /// Parse OCR blocks into structured menu data
    func parse(blocks: [OCRBlock]) -> ParsedMenu {
        // Step 1: Column Detection
        let columns = detectColumns(blocks: blocks)
        print("📐 Detected \(columns.count) column(s)")

        var allSections: [MenuSection] = []

        // Step 2: Process each column independently
        for (index, column) in columns.enumerated() {
            print("📖 Processing column \(index + 1)...")
            let columnSections = processColumn(blocks: column)
            allSections.append(contentsOf: columnSections)
        }

        return ParsedMenu(menuSections: allSections)
    }

    // MARK: - Step 1: Column Detection

    /// Detect if the page is split into multiple columns
    private func detectColumns(blocks: [OCRBlock]) -> [[OCRBlock]] {
        guard !blocks.isEmpty else { return [] }

        // Calculate vertical midline
        let midX: CGFloat = 0.5

        // Find the "gutter" - a vertical whitespace channel
        // Check if there's a consistent gap around the midline
        let blocksInMiddle = blocks.filter { block in
            // Check if block crosses or is near the midline
            (block.left < midX && block.right > midX) ||  // Crosses midline
            (abs(block.centerX - midX) < 0.1)              // Near midline
        }

        // If many blocks cross the midline, it's centered (not columnar)
        let crossingRatio = CGFloat(blocksInMiddle.count) / CGFloat(blocks.count)
        if crossingRatio > 0.3 {
            print("  ✓ Centered layout detected (not columnar)")
            return [sortedTopToBottom(blocks: blocks)]
        }

        // Check for gutter by measuring vertical span of middle area
        let sortedByY = blocks.sorted { $0.top < $1.top }
        let pageHeight = (sortedByY.last?.bottom ?? 1.0) - (sortedByY.first?.top ?? 0.0)

        // Find blocks in the middle zone
        let middleZoneBlocks = blocks.filter { block in
            block.centerX > 0.4 && block.centerX < 0.6
        }

        // Calculate vertical coverage of middle zone
        var coveredRanges: [(CGFloat, CGFloat)] = []
        for block in middleZoneBlocks {
            coveredRanges.append((block.top, block.bottom))
        }

        // Merge overlapping ranges
        let mergedRanges = mergeRanges(coveredRanges)
        let middleCoverage = mergedRanges.reduce(0.0) { $0 + ($1.1 - $1.0) }
        let coverageRatio = middleCoverage / pageHeight

        // If middle zone is mostly empty, we have a gutter
        if coverageRatio < 0.4 {
            print("  ✓ Gutter detected (multi-column layout)")

            // Split into left and right columns
            let leftColumn = blocks.filter { $0.centerX < midX }
            let rightColumn = blocks.filter { $0.centerX >= midX }

            return [
                sortedTopToBottom(blocks: leftColumn),
                sortedTopToBottom(blocks: rightColumn)
            ].filter { !$0.isEmpty }
        }

        // Default: single column
        print("  ✓ Single column layout")
        return [sortedTopToBottom(blocks: blocks)]
    }

    /// Merge overlapping vertical ranges
    private func mergeRanges(_ ranges: [(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] {
        guard !ranges.isEmpty else { return [] }

        let sorted = ranges.sorted { $0.0 < $1.0 }
        var merged: [(CGFloat, CGFloat)] = []
        var current = sorted[0]

        for range in sorted.dropFirst() {
            if range.0 <= current.1 {
                // Overlapping, merge
                current = (current.0, max(current.1, range.1))
            } else {
                merged.append(current)
                current = range
            }
        }
        merged.append(current)
        return merged
    }

    /// Sort blocks top-to-bottom, left-to-right
    private func sortedTopToBottom(blocks: [OCRBlock]) -> [OCRBlock] {
        return blocks.sorted { a, b in
            if abs(a.centerY - b.centerY) < 0.02 {
                // Same row, sort left to right
                return a.centerX < b.centerX
            }
            return a.centerY < b.centerY
        }
    }

    // MARK: - Step 2: Process Column

    /// Process a single column to extract sections and items
    private func processColumn(blocks: [OCRBlock]) -> [MenuSection] {
        // Step 2a: Identify price anchors
        let priceBlocks = findPriceBlocks(blocks: blocks)
        print("  💰 Found \(priceBlocks.count) price anchors")

        // Step 2b: Build menu items using price anchors
        var items = buildItemsFromPriceAnchors(blocks: blocks, priceBlocks: priceBlocks)
        print("  🍽️  Built \(items.count) menu items")

        // Step 2c: Group items into sections
        let sections = groupIntoSections(blocks: blocks, items: &items)
        print("  📑 Organized into \(sections.count) sections")

        return sections
    }

    // MARK: - Step 3: Price Anchor Strategy

    /// Find all blocks that contain prices
    private func findPriceBlocks(blocks: [OCRBlock]) -> [OCRBlock] {
        let priceRegex = try! NSRegularExpression(pattern: #"\$?\d+\.\d{2}"#)

        return blocks.filter { block in
            let range = NSRange(block.text.startIndex..., in: block.text)
            return priceRegex.firstMatch(in: block.text, range: range) != nil
        }
    }

    /// Extract price value from text
    private func extractPrice(from text: String) -> Double? {
        let priceRegex = try! NSRegularExpression(pattern: #"(\d+\.\d{2})"#)
        let range = NSRange(text.startIndex..., in: text)

        guard let match = priceRegex.firstMatch(in: text, range: range),
              let priceRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Double(text[priceRange])
    }

    /// Build menu items by anchoring on prices
    private func buildItemsFromPriceAnchors(blocks: [OCRBlock], priceBlocks: [OCRBlock]) -> [MenuItem] {
        var items: [MenuItem] = []

        for priceBlock in priceBlocks {
            guard let price = extractPrice(from: priceBlock.text) else { continue }

            // Find the dish name (scan left and up from price)
            guard let nameBlock = findDishName(for: priceBlock, in: blocks) else { continue }

            // Find description (scan below dish name)
            let descriptionBlocks = findDescriptionBlocks(below: nameBlock, in: blocks, priceBlock: priceBlock)
            let description = descriptionBlocks.map { $0.text }.joined(separator: " ")

            // Create menu item
            var item = MenuItem(
                name: cleanDishName(nameBlock.text),
                description: description.isEmpty ? nil : description,
                price: price
            )

            // Extract tags from description
            item.tags = extractTags(from: description)

            items.append(item)
        }

        return items
    }

    /// Find the dish name associated with a price
    private func findDishName(for priceBlock: OCRBlock, in blocks: [OCRBlock]) -> OCRBlock? {
        // Strategy 1: Look for horizontally aligned block to the left
        let horizontalCandidates = blocks.filter { block in
            block.isHorizontallyAligned(with: priceBlock) &&
            block.isLeftOf(priceBlock) &&
            !block.text.isEmpty
        }

        if let nearest = horizontalCandidates.max(by: { $0.right < $1.right }) {
            return nearest
        }

        // Strategy 2: Look for block directly above price
        let aboveCandidates = blocks.filter { block in
            block.bottom <= priceBlock.top &&
            abs(block.centerX - priceBlock.centerX) < 0.2 &&  // Roughly same X position
            !block.text.isEmpty
        }

        if let nearest = aboveCandidates.max(by: { $0.bottom < $1.bottom }) {
            return nearest
        }

        return nil
    }

    // MARK: - Step 4: Burger Stack Grouping

    /// Find description blocks below a dish name
    private func findDescriptionBlocks(below nameBlock: OCRBlock, in blocks: [OCRBlock], priceBlock: OCRBlock) -> [OCRBlock] {
        var descriptionBlocks: [OCRBlock] = []

        // Find blocks that are below the name, above the next price, and within reasonable X bounds
        let candidates = blocks.filter { block in
            block.top > nameBlock.bottom &&  // Below name
            block.bottom < priceBlock.top && // Above price (or same row as price)
            abs(block.centerX - nameBlock.centerX) < 0.3 &&  // Roughly aligned
            !block.text.isEmpty
        }

        // Sort by vertical position
        let sorted = candidates.sorted { $0.top < $1.top }

        for block in sorted {
            // Check if this looks like a description
            if isDescriptionBlock(block) {
                descriptionBlocks.append(block)
            } else {
                // Stop at first non-description block
                break
            }
        }

        return descriptionBlocks
    }

    /// Heuristic: is this block a description?
    private func isDescriptionBlock(_ block: OCRBlock) -> Bool {
        let text = block.text.lowercased()

        // Contains descriptive separators
        if text.contains("|") || text.contains(",") {
            return true
        }

        // Starts with lowercase (common for descriptions)
        if let firstChar = block.text.first, firstChar.isLowercase {
            return true
        }

        // Contains descriptive words
        let descriptorWords = ["with", "topped", "served", "or", "and", "choice"]
        if descriptorWords.contains(where: { text.contains($0) }) {
            return true
        }

        // Smaller font size (heuristic: shorter height)
        // This is approximate since we don't have font size directly
        if block.height < 0.02 {
            return true
        }

        return false
    }

    // MARK: - Step 5: Section & Modifier Detection

    /// Group items into sections based on headers
    private func groupIntoSections(blocks: [OCRBlock], items: inout [MenuItem]) -> [MenuSection] {
        // Find section headers
        let headers = findSectionHeaders(blocks: blocks)

        if headers.isEmpty {
            // No sections, return all items in a default section
            return [MenuSection(sectionName: "Menu", items: items)]
        }

        var sections: [MenuSection] = []

        for (_, header) in headers.enumerated() {
            let headerText = header.text.trimmingCharacters(in: .whitespaces)

            // Filter items within this section
            let sectionItems = items.filter { _ in
                // We need to track the original block position for each item
                // For now, use a simpler heuristic
                true  // TODO: improve by tracking item positions
            }

            // Check for modifiers at the end of the section
            let (itemsWithoutModifiers, _) = extractModifiers(from: sectionItems)

            let section = MenuSection(sectionName: headerText, items: itemsWithoutModifiers)
            sections.append(section)
        }

        // Fallback: if no sections created, put all items in default section
        if sections.isEmpty {
            return [MenuSection(sectionName: "Menu", items: items)]
        }

        return sections
    }

    /// Find section header blocks
    private func findSectionHeaders(blocks: [OCRBlock]) -> [OCRBlock] {
        return blocks.filter { block in
            let text = block.text.trimmingCharacters(in: .whitespaces)

            // All caps
            let isAllCaps = text == text.uppercased() && text.count > 2

            // Common section keywords
            let sectionKeywords = ["LUNCH", "DINNER", "APPETIZER", "ENTREE", "DESSERT",
                                   "BREAKFAST", "DRINK", "BEVERAGE", "SPECIAL",
                                   "PICK ONE", "CHOOSE", "BURRITO", "TACO", "ENCHILADA"]
            let hasKeyword = sectionKeywords.contains { text.uppercased().contains($0) }

            // Centered (roughly in middle third)
            let isCentered = block.centerX > 0.33 && block.centerX < 0.67

            // Large font (heuristic: taller than average)
            let isLarge = block.height > 0.025

            return (isAllCaps || isCentered || isLarge) && hasKeyword
        }
    }

    /// Extract modifiers from items (e.g., "Add meat .50")
    private func extractModifiers(from items: [MenuItem]) -> ([MenuItem], [Modifier]) {
        var cleanItems: [MenuItem] = []
        var modifiers: [Modifier] = []

        for item in items {
            let name = item.name.lowercased()

            // Check if this is a modifier
            if name.hasPrefix("add ") || name.hasPrefix("extra ") || name.contains("additional") {
                let modifier = Modifier(text: item.name, price: item.price)
                modifiers.append(modifier)
            } else {
                cleanItems.append(item)
            }
        }

        return (cleanItems, modifiers)
    }

    // MARK: - Helper Functions

    /// Clean up dish name text
    private func cleanDishName(_ text: String) -> String {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            // Remove trailing dots (from dotted lines)
            .replacingOccurrences(of: #"\.{2,}.*$"#, with: "", options: .regularExpression)
            // Remove price if present
            .replacingOccurrences(of: #"\$?\d+\.\d{2}.*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return cleaned
    }

    /// Extract tags from description
    private func extractTags(from description: String) -> [String] {
        let keywords = ["beef", "chicken", "pork", "fish", "vegetarian", "vegan",
                       "spicy", "gluten-free", "burrito", "taco", "enchilada",
                       "rice", "beans", "cheese"]

        let lowerDescription = description.lowercased()
        return keywords.filter { lowerDescription.contains($0) }
    }
}

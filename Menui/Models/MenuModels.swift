//
//  MenuModels.swift
//  Menui
//
//  Data models for menu parsing with spatial layout information
//

import Foundation
import CoreGraphics

// MARK: - OCR Block (Text + Spatial Info)

struct OCRBlock {
    let text: String
    let boundingBox: CGRect  // Normalized (0-1) coordinates
    let confidence: Float

    // Computed properties for convenience
    var centerX: CGFloat { boundingBox.midX }
    var centerY: CGFloat { boundingBox.midY }
    var left: CGFloat { boundingBox.minX }
    var right: CGFloat { boundingBox.maxX }
    var top: CGFloat { boundingBox.minY }
    var bottom: CGFloat { boundingBox.maxY }
    var width: CGFloat { boundingBox.width }
    var height: CGFloat { boundingBox.height }

    // Check if this block is horizontally aligned with another (same row)
    func isHorizontallyAligned(with other: OCRBlock, tolerance: CGFloat = 0.02) -> Bool {
        abs(centerY - other.centerY) < tolerance
    }

    // Check if this block is vertically below another
    func isBelow(_ other: OCRBlock) -> Bool {
        top > other.bottom
    }

    // Check if this block is to the left of another
    func isLeftOf(_ other: OCRBlock) -> Bool {
        right < other.left
    }
}

// MARK: - Menu Item (Parsed Dish)

struct MenuItem: Codable {
    let id: String
    let name: String
    var description: String?
    var price: Double?
    var tags: [String]
    var modifiers: [Modifier]

    init(name: String, description: String? = nil, price: Double? = nil, tags: [String] = [], modifiers: [Modifier] = []) {
        self.id = "item_\(UUID().uuidString.prefix(8))"
        self.name = name
        self.description = description
        self.price = price
        self.tags = tags
        self.modifiers = modifiers
    }
}

struct Modifier: Codable {
    let text: String
    let price: Double?
}

// MARK: - Menu Section

struct MenuSection: Codable {
    let sectionName: String
    var items: [MenuItem]
}

// MARK: - Complete Menu Structure

struct ParsedMenu: Codable {
    var menuSections: [MenuSection]

    enum CodingKeys: String, CodingKey {
        case menuSections = "menu_sections"
    }
}

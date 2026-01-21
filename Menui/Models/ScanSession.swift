//
//  ScanSession.swift
//  Menui
//
//  Represents a single menu scan session with all detected dishes
//

import Foundation
import SwiftData

@Model
final class ScanSession {
    var timestamp: Date
    var restaurantName: String?
    @Relationship(deleteRule: .cascade) var dishes: [Dish]
    @Attribute(.externalStorage) var originalImageData: Data?

    init(timestamp: Date = Date(), restaurantName: String? = nil, dishes: [Dish] = [], originalImageData: Data? = nil) {
        self.timestamp = timestamp
        self.restaurantName = restaurantName
        self.dishes = dishes
        self.originalImageData = originalImageData
    }
}

@Model
final class Dish {
    var name: String
    var imageURLs: [String]

    init(name: String, imageURLs: [String] = []) {
        self.name = name
        self.imageURLs = imageURLs
    }
}

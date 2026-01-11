//
//  APIService.swift
//  Menui
//
//  Calls backend API to fetch dish images
//

import Foundation

class APIService {
    static let shared = APIService()

    // TODO: Update to deployed URL (Railway/Fly.io)
    private let baseURL = "http://192.168.1.211:8000"

    private init() {}

    /// Fetches image URLs for a list of dish names
    /// - Parameter dishes: Array of dish names from OCR
    /// - Returns: Dictionary mapping dish name -> image URLs
    func fetchDishImages(for dishes: [String]) async throws -> [String: [String]] {
        guard !dishes.isEmpty else { return [:] }

        let url = URL(string: "\(baseURL)/api/dishes/images")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["dishes": dishes]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        let decoded = try JSONDecoder().decode(DishImagesResponse.self, from: data)

        // Convert to dictionary for easy lookup
        var result: [String: [String]] = [:]
        for item in decoded.results {
            result[item.dishName] = item.imageUrls
        }
        return result
    }
}

// MARK: - Response Models

struct DishImagesResponse: Codable {
    let results: [DishImageResult]
    let totalDishes: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalDishes = "total_dishes"
    }
}

struct DishImageResult: Codable {
    let dishName: String
    let imageUrls: [String]
    let fromCache: Bool

    enum CodingKeys: String, CodingKey {
        case dishName = "dish_name"
        case imageUrls = "image_urls"
        case fromCache = "from_cache"
    }
}

// MARK: - Errors

enum APIError: Error {
    case requestFailed
    case invalidResponse
}

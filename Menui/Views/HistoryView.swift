//
//  HistoryView.swift
//  Menui
//
//  Displays timeline of saved scan sessions
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScanSession.timestamp, order: .reverse) private var sessions: [ScanSession]

    var body: some View {
        NavigationView {
            Group {
                if sessions.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No scan history yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Scan a menu to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Timeline of scans
                    List(sessions) { session in
                        SessionRow(session: session)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ScanSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // LEFT SIDE: The Artifact (Menu Scan)
            if let imageData = session.originalImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 85, height: 113) // 3:4 aspect ratio (85 × 113.33)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                // Fallback if no image
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 85, height: 113)
                    .overlay(
                        Image(systemName: "doc.text.image")
                            .foregroundColor(.secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }

            // RIGHT SIDE: The Context
            VStack(alignment: .leading, spacing: 4) {
                // Top row: Headline + Date
                HStack(alignment: .top) {
                    Text(displayName)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .lineLimit(1)

                    Spacer()

                    Text(relativeOrAbsoluteDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Subhead: Dish count
                Text("\(session.dishes.count) Dish\(session.dishes.count == 1 ? "" : "es")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Tags (first 2 dish names as preview)
                HStack(spacing: 6) {
                    ForEach(session.dishes.prefix(2), id: \.name) { dish in
                        Text(dish.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(uiColor: .tertiarySystemFill))
                            )
                            .lineLimit(1)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var displayName: String {
        if let name = session.restaurantName, !name.isEmpty {
            return name
        }

        // Time-based placeholder
        let hour = Calendar.current.component(.hour, from: session.timestamp)
        switch hour {
        case 5..<11:
            return "Breakfast Scan"
        case 11..<16:
            return "Lunch Scan"
        case 16..<22:
            return "Dinner Scan"
        default:
            return "Late Night Scan"
        }
    }

    private var relativeOrAbsoluteDate: String {
        let now = Date()
        let interval = now.timeIntervalSince(session.timestamp)

        // Less than 24 hours: show relative time
        if interval < 86400 {
            let minutes = Int(interval / 60)
            let hours = Int(interval / 3600)

            if minutes < 1 {
                return "Just now"
            } else if minutes < 60 {
                return "\(minutes)m ago"
            } else {
                return "\(hours)h ago"
            }
        } else {
            // More than 24 hours: show absolute date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: session.timestamp)
        }
    }
}

// MARK: - Preview Data

extension ScanSession {
    static func previewSession(restaurantName: String?, dishNames: [String], hoursAgo: Int = 0) -> ScanSession {
        let timestamp = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: Date()) ?? Date()
        let dishes = dishNames.map { Dish(name: $0, imageURLs: []) }

        // Create a sample menu image (gray rectangle)
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemGray4.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return ScanSession(
            timestamp: timestamp,
            restaurantName: restaurantName,
            dishes: dishes,
            originalImageData: image.jpegData(compressionQuality: 0.7)
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: ScanSession.self, Dish.self)

    // Add preview data
    let session1 = ScanSession.previewSession(
        restaurantName: "Taco Bell",
        dishNames: ["Crunchy Taco", "Burrito Supreme", "Nachos"],
        hoursAgo: 0
    )
    let session2 = ScanSession.previewSession(
        restaurantName: nil,
        dishNames: ["Pad Thai", "Green Curry", "Spring Rolls", "Tom Yum Soup"],
        hoursAgo: 5
    )
    let session3 = ScanSession.previewSession(
        restaurantName: "The Italian Place",
        dishNames: ["Margherita Pizza", "Carbonara"],
        hoursAgo: 72
    )

    container.mainContext.insert(session1)
    container.mainContext.insert(session2)
    container.mainContext.insert(session3)

    HistoryView()
        .modelContainer(container)
}

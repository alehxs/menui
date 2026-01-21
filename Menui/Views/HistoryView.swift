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
        VStack(alignment: .leading, spacing: 8) {
            // Restaurant name or "Unnamed"
            Text(session.restaurantName ?? "Unnamed Restaurant")
                .font(.headline)

            // Date and dish count
            HStack {
                Text(session.timestamp, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(session.dishes.count) dish\(session.dishes.count == 1 ? "" : "es")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Thumbnail preview of original image if available
            if let imageData = session.originalImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [ScanSession.self, Dish.self])
}

//
//  SessionDetailView.swift
//  Menui
//
//  Detail view for a single scan session
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: ScanSession
    @State private var selectedDishName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Original scanned image
                if let imageData = session.originalImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 8)
                }

                // Scan metadata
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.secondary)
                        Text("\(session.dishes.count) dish\(session.dishes.count == 1 ? "" : "es") found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Dishes section header
                Text("Dishes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                // List of dishes
                if session.dishes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No dishes found in this scan")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(session.dishes, id: \.name) { dish in
                            DishDetailCard(dish: dish)
                                .onTapGesture {
                                    selectedDishName = dish.name
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(session.restaurantName ?? "Scan Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: {
                guard let name = selectedDishName,
                      let dish = session.dishes.first(where: { $0.name == name }) else {
                    return nil
                }
                return DishWrapper(dish: dish)
            },
            set: { newValue in
                selectedDishName = newValue?.dish.name
            }
        )) { wrapper in
            DishImageGallery(dish: wrapper.dish)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.timestamp)
    }
}

// MARK: - Wrapper for Sheet Presentation

struct DishWrapper: Identifiable {
    let id = UUID()
    let dish: Dish
}

// MARK: - Dish Detail Card

struct DishDetailCard: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail image
            if let firstImageUrl = dish.imageURLs.first {
                AsyncImage(url: URL(string: firstImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // No images available
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            // Dish info
            VStack(alignment: .leading, spacing: 6) {
                Text(dish.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !dish.imageURLs.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.caption)
                        Text("\(dish.imageURLs.count) image\(dish.imageURLs.count == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } else {
                    Text("No images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Chevron indicator
            if !dish.imageURLs.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Dish Image Gallery

struct DishImageGallery: View {
    let dish: Dish
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if dish.imageURLs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No images available")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(dish.imageURLs, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 250)
                                        .cornerRadius(12)
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 250)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 250)
                                        .cornerRadius(12)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundColor(.secondary)
                                                Text("Failed to load")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(dish.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SessionDetailView(
            session: ScanSession.previewSession(
                restaurantName: "Taco Bell",
                dishNames: ["Crunchy Taco", "Burrito Supreme"],
                hoursAgo: 2
            )
        )
    }
}

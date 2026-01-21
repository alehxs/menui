//
//  MainTabView.swift
//  Menui
//
//  Main tab navigation for the app.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Scan")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }

            PlaceholderView(title: "Favorites")
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
        }
    }
}

// MARK: - Placeholder View

struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.largeTitle)
            .foregroundColor(.secondary)
    }
}

#Preview {
    MainTabView()
}

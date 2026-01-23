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
        }
    }
}

#Preview {
    MainTabView()
}

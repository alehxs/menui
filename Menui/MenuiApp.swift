//
//  MenuiApp.swift
//  Menui
//
//  Created by Alex on 10/25/25.
//

import SwiftUI
import SwiftData

@main
struct MenuiApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [ScanSession.self, Dish.self])
    }
}

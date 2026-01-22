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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Session Detail")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)

                Text("Coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .navigationTitle(session.restaurantName ?? "Scan Details")
        .navigationBarTitleDisplayMode(.inline)
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

//
//  MainTabView.swift
//  Menui
//
//  Created by Alex on 12/27/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var ocrResults: [String] = []
    private let ocrService = OCRService()
    
    var body: some View {
        TabView {
            VStack {
                Button("Test OCR") {
                    Task {
                        if let image = UIImage(named: "digital-lala-menu") {
                            ocrResults = await ocrService.recognizeText(from: image)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                List(ocrResults, id: \.self) { line in
                    Text(line)
                }
            }
            .tabItem {
                Image(systemName: "camera")
                Text("Scan")
            }
            
//            Text("Camera")
//                .tabItem{
//                    Image(systemName: "camera")
//                    Text("Scan")
//                }
            
            Text("History")
                .tabItem{
                    Image(systemName: "clock")
                    Text("History")
                }
            
            Text("Favorites")
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
        }
    }
}

#Preview {
    MainTabView()
}

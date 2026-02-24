//
//  CameraFrameGuide.swift
//  Menui
//
//  Visual guide overlay to help users frame menu content properly
//

import SwiftUI

struct CameraFrameGuide: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed overlay on edges
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                // Clear center rectangle for menu
                Rectangle()
                    .fill(Color.clear)
                    .frame(
                        width: geometry.size.width * 0.85,
                        height: geometry.size.height * 0.7
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 2)
                            .shadow(color: .black, radius: 2)
                    )
                    .blendMode(.destinationOut)

                // Instructions at top
                VStack {
                    Text("Frame the menu inside the box")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 60)

                    Spacer()

                    // Tips at bottom
                    VStack(spacing: 4) {
                        Text("💡 Tips:")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("• Fill the frame with just the menu")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))

                        Text("• Avoid browser bars and tabs")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))

                        Text("• Ensure text is clear and readable")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 120)
                }
            }
            .compositingGroup()
        }
        .allowsHitTesting(false)  // Pass through taps to camera controls
    }
}

// MARK: - Preview

struct CameraFrameGuide_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            CameraFrameGuide()
        }
    }
}

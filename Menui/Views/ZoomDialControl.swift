//
//  ZoomDialControl.swift
//  Menui
//
//  Hybrid gesture zoom control: tap for presets, hold & slide for precision dial.
//

import SwiftUI

struct ZoomDialControl: View {
    @Binding var currentZoom: CGFloat
    let onZoomChange: (CGFloat) -> Void

    // Preset zoom levels
    let presets: [CGFloat] = [0.5, 1.0]

    // State management
    @State private var showingDial = false
    @State private var dragStartTime: Date?
    @State private var initialTouchLocation: CGPoint?
    @State private var lastZoom: CGFloat = 1.0

    private let dragThreshold: CGFloat = 15

    var body: some View {
        ZStack {
            if showingDial {
                precisionDialView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                presetButtonsView
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingDial)
    }

    // MARK: - Preset Buttons View

    var presetButtonsView: some View {
        HStack(spacing: 15) {
            ForEach(presets, id: \.self) { level in
                presetButton(for: level)
            }
        }
    }

    func presetButton(for level: CGFloat) -> some View {
        Text(formatZoomLabel(level))
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isActiveZoom(level) ? .yellow : .white)
            .frame(width: 45, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActiveZoom(level) ? Color.white.opacity(0.3) : Color.clear)
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value, preset: level)
                    }
                    .onEnded { value in
                        handleDragEnded(value, preset: level)
                    }
            )
    }

    // MARK: - Precision Dial View

    var precisionDialView: some View {
        VStack(spacing: 8) {
            // Current zoom value display
            Text(String(format: "%.1f×", currentZoom))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.3), radius: 2)

            // Ruler with tick marks
            ZStack {
                // Tick marks ruler
                HStack(spacing: 3) {
                    ForEach(5...100, id: \.self) { tick in
                        let zoomValue = CGFloat(tick) / 10.0
                        if zoomValue >= 0.5 && zoomValue <= 10.0 {
                            tickMark(for: zoomValue)
                        }
                    }
                }
                .frame(height: 35)

                // Center indicator line
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 35)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDialDrag(value)
                }
                .onEnded { _ in
                    exitDialMode()
                }
        )
    }

    func tickMark(for zoom: CGFloat) -> some View {
        let isMajor = zoom.truncatingRemainder(dividingBy: 1.0) == 0
        let isHalf = zoom.truncatingRemainder(dividingBy: 0.5) == 0

        let height: CGFloat = isMajor ? 25 : (isHalf ? 18 : 12)
        let distance = abs(zoom - currentZoom)
        let opacity = distance > 3.0 ? 0.2 : (distance > 1.5 ? 0.5 : 1.0)

        return Rectangle()
            .fill(Color.white.opacity(opacity))
            .frame(width: isMajor ? 2.5 : 1.5, height: height)
    }

    // MARK: - Gesture Handlers

    func handleDragChanged(_ value: DragGesture.Value, preset: CGFloat) {
        if dragStartTime == nil {
            // First touch
            dragStartTime = Date()
            initialTouchLocation = value.location
            lastZoom = currentZoom
        }

        guard let startLocation = initialTouchLocation else { return }

        let dragDistance = hypot(
            value.location.x - startLocation.x,
            value.location.y - startLocation.y
        )

        // If dragged beyond threshold, enter dial mode
        if !showingDial && dragDistance > dragThreshold {
            showingDial = true
            lastZoom = preset
            onZoomChange(preset)
        }

        // If in dial mode, handle continuous zoom
        if showingDial {
            let sensitivity: CGFloat = 0.015
            let delta = value.translation.width * sensitivity
            let newZoom = max(0.5, min(10.0, lastZoom + delta))
            onZoomChange(newZoom)
        }
    }

    func handleDragEnded(_ value: DragGesture.Value, preset: CGFloat) {
        defer {
            dragStartTime = nil
            initialTouchLocation = nil
        }

        guard let startLocation = initialTouchLocation else { return }

        let dragDistance = hypot(
            value.location.x - startLocation.x,
            value.location.y - startLocation.y
        )

        // If it was a tap (short distance, not in dial mode)
        if dragDistance < dragThreshold && !showingDial {
            onZoomChange(preset)
        }

        // Exit dial mode
        if showingDial {
            exitDialMode()
        }
    }

    func handleDialDrag(_ value: DragGesture.Value) {
        let sensitivity: CGFloat = 0.015
        let delta = value.translation.width * sensitivity
        let newZoom = max(0.5, min(10.0, lastZoom + delta))
        onZoomChange(newZoom)
    }

    func exitDialMode() {
        withAnimation(.easeOut(duration: 0.2)) {
            showingDial = false
        }
        lastZoom = currentZoom
    }

    // MARK: - Helper Functions

    func formatZoomLabel(_ level: CGFloat) -> String {
        if level == 0.5 { return ".5×" }
        if level == 1.0 { return "1×" }
        return "\(Int(level))×"
    }

    func isActiveZoom(_ level: CGFloat) -> Bool {
        abs(currentZoom - level) < 0.15
    }
}

// MacFrameView.swift
// Botcrew

import SwiftUI

enum TrafficLight {
    case close, minimize, maximize
}

struct MacFrameView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isWindowHovered = false
    @State private var hoveredButton: TrafficLight?

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                trafficLightButton(.close, color: Color(red: 1.0, green: 0.373, blue: 0.341), icon: "xmark")
                trafficLightButton(.minimize, color: Color(red: 0.996, green: 0.741, blue: 0.180), icon: "minus")
                trafficLightButton(.maximize, color: Color(red: 0.157, green: 0.784, blue: 0.251), icon: "arrow.up.arrow.down")
            }
            .padding(.leading, 13)

            Spacer()

            Text("BotCrew")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary(colorScheme))

            Spacer()

            // Balance the traffic lights width
            Color.clear.frame(width: 70)
        }
        .frame(height: 36)
        .background(
            colorScheme == .dark
                ? Color(white: 40/255, opacity: 0.95)
                : Color(white: 240/255, opacity: 0.95)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isWindowHovered = hovering
            }
        }
    }

    private func trafficLightButton(_ light: TrafficLight, color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .opacity(buttonOpacity(for: light))

            if hoveredButton == light {
                Image(systemName: icon)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.black.opacity(0.5))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredButton = hovering ? light : nil
            }
        }
    }

    private func buttonOpacity(for light: TrafficLight) -> Double {
        if hoveredButton == light { return 1.0 }
        if isWindowHovered { return 1.0 }
        return 0.4
    }
}

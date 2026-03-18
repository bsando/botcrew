// RootTabView.swift
// Botcrew

import SwiftUI

struct RootTabView: View {
    let agent: Agent
    let subAgents: [Agent]
    let isExpanded: Bool
    let isSelected: Bool

    private var hasError: Bool {
        agent.status == .error || subAgents.contains { $0.status == .error }
    }

    var body: some View {
        HStack(spacing: 6) {
            SpriteThumbnail(bodyColor: agent.bodyColor, size: .root)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(agent.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)

                    PulsingPip(color: statusColor(agent.status), shouldPulse: agent.status == .error)
                }

                if !isExpanded && !subAgents.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(subAgents) { sub in
                            PulsingPip(color: statusColor(sub.status), shouldPulse: sub.status == .error, size: 4)
                        }
                    }
                }
            }

            if isExpanded {
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(tabBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(tabBorder, lineWidth: 1)
        )
    }

    private var tabBackground: Color {
        if isSelected {
            return Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.15)
        }
        if isExpanded {
            return Color(white: 50/255, opacity: 0.6)
        }
        return Color(white: 50/255, opacity: 0.3)
    }

    private var tabBorder: Color {
        if hasError {
            return Color(hex: 0xFF5F57).opacity(0.4)
        }
        if isSelected {
            return Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.3)
        }
        return Color.clear
    }

    private func statusColor(_ status: AgentStatus) -> Color {
        switch status {
        case .typing, .reading: Color(hex: 0x28C840)
        case .waiting: Color(hex: 0xFEBC2E)
        case .idle: Color(hex: 0x888780)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

// MARK: - Pulsing status pip

struct PulsingPip: View {
    let color: Color
    let shouldPulse: Bool
    var size: CGFloat = 6
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(shouldPulse && isPulsing ? 0.4 : 1.0)
            .onAppear {
                if shouldPulse {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: shouldPulse) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    isPulsing = false
                }
            }
    }
}

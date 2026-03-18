// RootTabView.swift
// Botcrew

import SwiftUI

struct RootTabView: View {
    let agent: Agent
    let subAgents: [Agent]
    let isExpanded: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            // Sprite thumbnail (12x16)
            SpriteThumbnail(bodyColor: agent.bodyColor, size: .root)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(agent.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)

                    // Status pip
                    Circle()
                        .fill(statusColor(agent.status))
                        .frame(width: 6, height: 6)
                }

                // Collapsed: show sub-status dots inline
                if !isExpanded && !subAgents.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(subAgents) { sub in
                            Circle()
                                .fill(statusColor(sub.status))
                                .frame(width: 4, height: 4)
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

// SubTabView.swift
// Botcrew

import SwiftUI

struct SubTabView: View {
    let agent: Agent
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 5) {
            // Sprite thumbnail (10x14)
            SpriteThumbnail(bodyColor: agent.bodyColor, size: .sub)

            Text(agent.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)

            Circle()
                .fill(statusColor(agent.status))
                .frame(width: 5, height: 5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected
                      ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.15)
                      : Color(white: 50/255, opacity: 0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(isSelected
                              ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.3)
                              : Color.clear, lineWidth: 1)
        )
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

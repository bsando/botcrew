// SubTabView.swift
// Botcrew

import SwiftUI

struct SubTabView: View {
    let agent: Agent
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editText: String
    var onCommitRename: () -> Void = {}
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 5) {
            SpriteThumbnail(bodyColor: agent.bodyColor, size: .sub)

            if isEditing {
                TextField("Name", text: $editText, onCommit: onCommitRename)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 70)
                    .focused($isFocused)
                    .onAppear { isFocused = true }
            } else {
                Text(agent.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }

            PulsingPip(color: statusColor(agent.status), shouldPulse: agent.status == .error, size: 5)
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
                .strokeBorder(tabBorder, lineWidth: 1)
        )
    }

    private var tabBorder: Color {
        if agent.status == .error {
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

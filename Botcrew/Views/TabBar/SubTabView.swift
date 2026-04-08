// SubTabView.swift
// Botcrew

import SwiftUI

struct SubTabView: View {
    let agent: Agent
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editText: String
    var onCommitRename: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 5) {
            SpriteThumbnail(bodyColor: agent.bodyColor, size: .sub)

            if isEditing {
                TextField("Name", text: $editText, onCommit: onCommitRename)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 70)
                    .focused($isFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
            } else {
                Text(agent.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .lineLimit(1)
            }

            PulsingPip(color: statusColor(agent.status), shouldPulse: agent.status == .error, size: 5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(Theme.subTabBg(colorScheme, isSelected: isSelected))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .strokeBorder(tabBorder, lineWidth: 1)
        )
    }

    private var tabBorder: Color {
        if agent.status == .error {
            return Theme.statusRed.opacity(0.4)
        }
        if isSelected {
            return Theme.systemBlue.opacity(0.3)
        }
        return Color.clear
    }

    private func statusColor(_ status: AgentStatus) -> Color {
        switch status {
        case .typing, .reading: Theme.statusGreen
        case .waiting: Theme.statusAmber
        case .idle: Theme.statusGray
        case .error: Theme.statusRed
        }
    }
}

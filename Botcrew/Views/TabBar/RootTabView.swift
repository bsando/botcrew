// RootTabView.swift
// Botcrew

import SwiftUI

struct RootTabView: View {
    let agent: Agent
    let subAgents: [Agent]
    let isExpanded: Bool
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editText: String
    var onCommitRename: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    private var hasError: Bool {
        agent.status == .error || subAgents.contains { $0.status == .error }
    }

    var body: some View {
        HStack(spacing: 6) {
            SpriteThumbnail(bodyColor: agent.bodyColor, size: .root)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if isEditing {
                        TextField("Name", text: $editText, onCommit: onCommitRename)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 80)
                            .focused($isFocused)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isFocused = true
                                }
                            }
                    } else {
                        Text(agent.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textPrimary(colorScheme))
                            .lineLimit(1)
                    }

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
                    .foregroundStyle(Theme.textTertiary(colorScheme))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(tabBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .strokeBorder(tabBorder, lineWidth: 1)
        )
    }

    private var tabBackground: Color {
        Theme.tabBg(colorScheme, isSelected: isSelected, isExpanded: isExpanded)
    }

    private var tabBorder: Color {
        if hasError {
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

// MARK: - Pulsing status pip

struct PulsingPip: View {
    let color: Color
    let shouldPulse: Bool
    var size: CGFloat = 6
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(shouldPulse && isPulsing && !reduceMotion ? 0.4 : 1.0)
            .onAppear {
                if shouldPulse && !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: shouldPulse) { _, newValue in
                if newValue && !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    isPulsing = false
                }
            }
    }
}

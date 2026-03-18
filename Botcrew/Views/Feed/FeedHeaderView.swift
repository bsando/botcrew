// FeedHeaderView.swift
// Botcrew

import SwiftUI

struct FeedHeaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 10) {
            if let agent = appState.selectedAgent {
                // Color swatch
                RoundedRectangle(cornerRadius: 3)
                    .fill(agent.bodyColor)
                    .frame(width: 14, height: 14)

                Text(agent.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                // Role label
                if agent.parentId == nil {
                    Text("root")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.06))
                        )
                }

                // Status pill
                StatusPill(status: agent.status)
            } else {
                Text("Select an agent")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Activity / Terminal toggle
            HStack(spacing: 0) {
                ToggleButton(label: "Activity", isActive: !appState.showTerminal) {
                    appState.showTerminal = false
                }
                ToggleButton(label: "Terminal", isActive: appState.showTerminal) {
                    appState.showTerminal = true
                }
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(Color(white: 30/255, opacity: 0.6))
    }
}

struct StatusPill: View {
    let status: AgentStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)

            if status == .reading {
                ThinkingDots()
            } else {
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor.opacity(0.12))
        )
    }

    private var statusColor: Color {
        switch status {
        case .typing: Color(hex: 0x34d399)
        case .reading: Color(hex: 0x60a5fa)
        case .waiting: Color(hex: 0xfbbf24)
        case .idle: Color(hex: 0x888780)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

struct ThinkingDots: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: 0x60a5fa))
                    .frame(width: 3, height: 3)
                    .opacity(phase == i ? 1.0 : 0.3)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: false)) {
                phase = 2
            }
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

struct ToggleButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(isActive ? 0.85 : 0.35))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? Color.white.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

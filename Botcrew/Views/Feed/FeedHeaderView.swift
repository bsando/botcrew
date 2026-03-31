// FeedHeaderView.swift
// Botcrew

import SwiftUI

enum FeedMode: String, CaseIterable {
    case activity, terminal, allAgents
}

struct FeedHeaderView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var feedMode: FeedMode {
        if appState.showTerminal { return .terminal }
        if appState.showAllAgentsFeed { return .allAgents }
        return .activity
    }

    var body: some View {
        HStack(spacing: 8) {
            // Breadcrumb: project > root > agent
            breadcrumb

            Spacer()

            // Feed mode picker (native segmented control)
            Picker("Feed Mode", selection: Binding(
                get: { feedMode },
                set: { newMode in
                    switch newMode {
                    case .activity:
                        appState.showTerminal = false
                        appState.showAllAgentsFeed = false
                    case .terminal:
                        appState.showTerminal = true
                        appState.showAllAgentsFeed = false
                    case .allAgents:
                        appState.showTerminal = false
                        appState.showAllAgentsFeed = true
                    }
                }
            )) {
                Text("Activity").tag(FeedMode.activity)
                Text("Terminal").tag(FeedMode.terminal)
                Text("All").tag(FeedMode.allAgents)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Theme.contentBg(colorScheme))
    }

    @ViewBuilder
    private var breadcrumb: some View {
        HStack(spacing: 4) {
            if let project = appState.selectedProject {
                // Project name
                Text(project.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x0A84FF).opacity(0.8))
                    .onTapGesture {
                        appState.selectedAgentId = nil
                    }

                if let agent = appState.selectedAgent {
                    Text("/")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary(colorScheme))

                    // If sub-agent, show parent first
                    if let parentId = agent.parentId,
                       let parent = appState.selectedProject?.agents.first(where: { $0.id == parentId }) {
                        Text(parent.name)
                            .font(.system(size: 12))
                            .foregroundStyle(parent.bodyColor.opacity(0.8))
                            .onTapGesture {
                                appState.selectAgent(parent.id)
                            }

                        Text("/")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary(colorScheme))
                    }

                    // Current agent
                    Text(agent.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(agent.bodyColor)

                    // Status dot
                    StatusPill(status: agent.status)
                }
            } else {
                Text("No project selected")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted(colorScheme))
            }
        }
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
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? Theme.textPrimary(colorScheme) : Theme.textMuted(colorScheme))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? Theme.separator(colorScheme) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

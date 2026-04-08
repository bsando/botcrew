// OfficePanelView.swift
// Botcrew

import SwiftUI

struct OfficePanelView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var internalDividerRatio: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 0) {
            // Office bar (always visible, even collapsed)
            officeBar
                .frame(height: 26)
                .background(Theme.officeBarBg)

            // Canvas (hidden when collapsed)
            if appState.officePanelSnap == .expanded {
                // Ops mode: sprites top, terminals bottom (only if terminal not already shown in main area)
                if appState.showTerminal {
                    // Terminal already visible in main feed area — just show sprites
                    OfficeCanvasView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.officeFloorBg)
                } else {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            OfficeCanvasView()
                                .frame(height: geo.size.height * internalDividerRatio)
                                .background(Theme.officeFloorBg)

                            // Internal divider
                            Rectangle()
                                .fill(Theme.separator(colorScheme))
                                .frame(height: 1)

                            MultiTerminalGrid()
                                .frame(maxHeight: .infinity)
                        }
                    }
                }
            } else if appState.officePanelSnap != .collapsed {
                OfficeCanvasView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.officeFloorBg)
            }
        }
    }

    private var officeBar: some View {
        HStack(spacing: 6) {
            Text("OFFICE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.66)
                .foregroundStyle(Theme.textOnDark(colorScheme).opacity(0.3))

            if let project = appState.selectedProject {
                Text("— \(project.name)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textOnDark(colorScheme).opacity(0.18))

                // Cluster dot groups
                ForEach(appState.rootAgents) { root in
                    HStack(spacing: 2) {
                        Circle()
                            .fill(agentDotColor(root.status))
                            .frame(width: 5, height: 5)
                        ForEach(appState.subAgents(for: root.id)) { sub in
                            Circle()
                                .fill(agentDotColor(sub.status))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.leading, 4)
                }
            }

            Spacer()

            // Reset layout button (only show if positions are customized)
            if let project = appState.selectedProject,
               !project.officeLayout.spritePositions.isEmpty {
                Button {
                    if let pid = appState.selectedProjectId {
                        appState.resetOfficeLayout(projectId: pid)
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textOnDark(colorScheme).opacity(0.35))
                }
                .buttonStyle(.plain)
                .help("Reset sprite positions")
            }

            // Theme picker
            Menu {
                ForEach(SpriteTheme.allBuiltIn) { theme in
                    Button {
                        appState.selectedThemeId = theme.id
                        appState.saveState()
                    } label: {
                        HStack {
                            Text(theme.name)
                            if theme.id == appState.selectedThemeId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 9))
                    Text(appState.selectedTheme.name)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(Theme.textOnDark(colorScheme).opacity(0.35))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Click to restore from collapsed
            if appState.officePanelSnap == .collapsed {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        appState.snapOfficePanel(to: .ambient)
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.textOnDark(colorScheme).opacity(0.35))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 12)
    }

    private func agentDotColor(_ status: AgentStatus) -> Color {
        switch status {
        case .typing, .reading: Color(hex: 0x28C840)
        case .waiting: Color(hex: 0xFEBC2E)
        case .idle: Color(hex: 0x888780)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

// MARK: - Multi-Terminal Grid

struct MultiTerminalGrid: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var terminalAgents: [Agent] {
        let ids = appState.openTerminalIds
        guard let project = appState.selectedProject else { return [] }
        return ids.compactMap { id in
            project.agents.first { $0.id == id }
        }
    }

    var body: some View {
        let agents = terminalAgents
        if agents.isEmpty {
            // Show selected agent's terminal or empty state
            if appState.selectedAgent != nil {
                TerminalView()
            } else {
                VStack {
                    Text("No terminal open")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.terminalBg(colorScheme))
            }
        } else if agents.count == 1 {
            // Full width
            TerminalView()
        } else if agents.count == 2 {
            // Side by side
            HStack(spacing: 1) {
                TerminalView()
                TerminalView()
            }
        } else {
            // 2×2 grid
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    TerminalView()
                    TerminalView()
                }
                if agents.count > 2 {
                    HStack(spacing: 1) {
                        TerminalView()
                        if agents.count > 3 {
                            TerminalView()
                        }
                    }
                }
            }
        }
    }
}

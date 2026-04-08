// ContentView.swift
// Botcrew

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            MacFrameView()

            HSplitView {
                // Panel 1: Agent Tree
                if appState.showAgentTree {
                    AgentTreeView()
                        .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)
                        .background(Theme.sidebarBg(colorScheme))
                }

                // Panel 2: Activity Feed (center)
                VStack(spacing: 0) {
                    if appState.selectedProject == nil {
                        EmptyProjectView()
                    } else if appState.rootAgents.isEmpty {
                        if appState.showTerminal, let projectId = appState.selectedProjectId,
                           let proc = appState.processes[projectId], !proc.terminalOutput.isEmpty {
                            ActivityFeedView()
                                .frame(maxHeight: .infinity)
                        } else {
                            EmptyAgentView()
                        }
                    } else {
                        ActivityFeedView()
                            .frame(maxHeight: .infinity)

                        if let approval = appState.pendingApproval {
                            ToolApprovalBanner(approval: approval)
                        }
                    }

                    // Office panel (easter egg — hidden by default)
                    if appState.showOfficePanel {
                        DragDividerView()
                        OfficePanelView()
                            .frame(height: appState.officePanelHeight)
                    }
                }
                .frame(minWidth: 300)

                // Panel 3: File Tree
                if appState.showFileTree {
                    FileTreeView()
                        .frame(minWidth: 200, idealWidth: 260, maxWidth: 320)
                        .background(Theme.contentBg(colorScheme))
                }
            }

            // Prompt bar spans full width below all panels
            PromptInputBar()
        }
        .sheet(isPresented: Bindable(appState).showGitPanel) {
            GitPanelView()
                .environment(appState)
        }
    }
}

// MARK: - Keyboard Shortcut Commands

struct BotcrewCommands: Commands {
    @Bindable var appState: AppState

    var body: some Commands {
        // Navigation
        CommandMenu("Navigate") {
            Button("Previous Project") {
                appState.selectPreviousProject()
            }
            .keyboardShortcut(.upArrow, modifiers: .command)

            Button("Next Project") {
                appState.selectNextProject()
            }
            .keyboardShortcut(.downArrow, modifiers: .command)

            Divider()

            Button("Previous Agent") {
                appState.selectPreviousAgent()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)

            Button("Next Agent") {
                appState.selectNextAgent()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }

        // View
        CommandMenu("Panels") {
            Button("Toggle Agent Tree") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showAgentTree.toggle()
                }
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Focus Feed") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showAgentTree = false
                    appState.showFileTree = false
                }
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Toggle File Tree") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showFileTree.toggle()
                }
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("Show All Panels") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showAgentTree = true
                    appState.showFileTree = true
                }
            }
            .keyboardShortcut("0", modifiers: [.command, .shift])

            Divider()

            Button("Toggle Terminal") {
                appState.showTerminal.toggle()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Toggle Office Panel") {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.showOfficePanel.toggle()
                }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Divider()

            Button("Git Panel") {
                appState.showGitPanel.toggle()
            }
            .keyboardShortcut("g", modifiers: .command)

            Divider()

            Toggle("Sound Notifications", isOn: $appState.soundEnabled)
            Toggle("Desktop Notifications", isOn: $appState.notificationsEnabled)
        }
    }
}

// MARK: - Empty States

struct EmptyProjectView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "folder.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textMuted(colorScheme))

            Text("No project selected")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textPrimary(colorScheme))

            Text("Add a project from the sidebar to get started")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary(colorScheme))

            Button("Add Project") {
                appState.showAddProjectSheet = true
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color(hex: 0x0A84FF))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: 0x0A84FF).opacity(0.12))
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.contentBg(colorScheme))
    }
}

struct EmptyAgentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0x0A84FF).opacity(0.08))
                        .frame(width: 72, height: 72)
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: 0x0A84FF).opacity(0.6))
                }

                VStack(spacing: 6) {
                    Text("No active sessions")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary(colorScheme))

                    if let project = appState.selectedProject {
                        Text("No Claude Code sessions running in **\(project.name)**")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary(colorScheme))
                    }
                }

                Text("Type a prompt to get started")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary(colorScheme))

                HStack(spacing: 8) {
                    QuickActionChip(icon: "doc.text.magnifyingglass", label: "Review code") {
                        if let projectId = appState.selectedProjectId {
                            appState.sendPrompt(projectId: projectId, prompt: "Review this codebase for issues and improvements")
                            appState.showTerminal = true
                        }
                    }
                    QuickActionChip(icon: "checkmark.circle", label: "Run tests") {
                        if let projectId = appState.selectedProjectId {
                            appState.sendPrompt(projectId: projectId, prompt: "Run the test suite and report results")
                            appState.showTerminal = true
                        }
                    }
                    QuickActionChip(icon: "hammer", label: "Fix build") {
                        if let projectId = appState.selectedProjectId {
                            appState.sendPrompt(projectId: projectId, prompt: "Check for and fix any build errors")
                            appState.showTerminal = true
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.contentBg(colorScheme))
    }
}

struct QuickActionChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Theme.textSecondary(colorScheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.cardBg(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.separator(colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

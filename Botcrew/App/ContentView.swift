// ContentView.swift
// Botcrew

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HSplitView {
            if !appState.isSidebarCollapsed {
                SidebarView()
                    .frame(width: 168)
                    .background(Theme.sidebarBg(colorScheme))
            } else {
                CollapsedSidebarView()
                    .frame(width: 44)
                    .background(Theme.sidebarBg(colorScheme))
            }

            VStack(spacing: 0) {
                MacFrameView()

                if appState.selectedProject == nil {
                    EmptyProjectView()
                } else if appState.rootAgents.isEmpty {
                    // No agents yet — show empty state with start session CTA
                    EmptyAgentView()
                    PromptInputBar()
                } else {
                    TabBarView()
                        .frame(height: 38)

                    Divider()
                        .opacity(0.08)

                    ActivityFeedView()
                        .frame(maxHeight: .infinity)

                    if let approval = appState.pendingApproval {
                        ToolApprovalBanner(approval: approval)
                    }

                    PromptInputBar()

                    DragDividerView()

                    OfficePanelView()
                        .frame(height: appState.officePanelHeight)
                }
            }
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

            Divider()

            Button("Toggle Cluster") {
                if let rootId = appState.activeClusterId ?? appState.rootAgents.first?.id {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.toggleCluster(rootId)
                    }
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
        }

        // View
        CommandMenu("Panels") {
            Button("Toggle Sidebar") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.isSidebarCollapsed.toggle()
                }
            }
            .keyboardShortcut("\\", modifiers: .command)

            Button("Toggle Terminal") {
                appState.showTerminal.toggle()
            }
            .keyboardShortcut("t", modifiers: .command)

            Divider()

            Button("Expand Office Panel") {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.officePanelSnapUp()
                }
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .shift])

            Button("Collapse Office Panel") {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.officePanelSnapDown()
                }
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .shift])

            Divider()

            Button("Git Panel") {
                appState.showGitPanel.toggle()
            }
            .keyboardShortcut("g", modifiers: .command)

            Divider()

            Toggle("Sound Notifications", isOn: $appState.soundEnabled)
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
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: 0x0A84FF).opacity(0.08))
                        .frame(width: 72, height: 72)
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: 0x0A84FF).opacity(0.6))
                }

                // Title + subtitle
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

                // Quick action chips
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

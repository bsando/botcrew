// ContentView.swift
// Botcrew

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HSplitView {
            if !appState.isSidebarCollapsed {
                SidebarView()
                    .frame(width: 168)
                    .background(Color(white: 30/255, opacity: 0.7))
            } else {
                CollapsedSidebarView()
                    .frame(width: 44)
                    .background(Color(white: 30/255, opacity: 0.7))
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

                    DragDividerView()

                    OfficePanelView()
                        .frame(height: appState.officePanelHeight)

                    PromptInputBar()
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

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "folder.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.35))

            Text("No project selected")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            Text("Add a project from the sidebar to get started")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.50))

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
        .background(Color(white: 30/255, opacity: 0.6))
    }
}

struct EmptyAgentView: View {
    @Environment(AppState.self) private var appState
    @State private var quickPrompt = ""
    @FocusState private var isFocused: Bool

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
                        .foregroundStyle(.white.opacity(0.85))

                    if let project = appState.selectedProject {
                        Text("Start a Claude Code session in **\(project.name)**")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                }

                // Quick start buttons
                VStack(spacing: 10) {
                    Button {
                        if let projectId = appState.selectedProjectId {
                            appState.sendPrompt(projectId: projectId, prompt: "Review this codebase and summarize the architecture")
                            appState.showTerminal = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                            Text("Start Session")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color(hex: 0x0A84FF))
                        )
                    }
                    .buttonStyle(.plain)

                    Text("or type a prompt below")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.30))
                }

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
        .background(Color(white: 30/255, opacity: 0.6))
    }
}

struct QuickActionChip: View {
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
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

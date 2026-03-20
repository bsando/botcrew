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
                    EmptyAgentView()
                } else {
                    TabBarView()
                        .frame(height: 38)

                    Divider()
                        .opacity(0.08)

                    ActivityFeedView()
                        .frame(maxHeight: .infinity)

                    DragDividerView()

                    OfficePanelView()
                        .frame(height: appState.officePanelHeight)
                }
            }
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
                .foregroundStyle(.white.opacity(0.15))

            Text("No project selected")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))

            Text("Add a project from the sidebar to get started")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.25))

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

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "terminal")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.15))

            Text("No active sessions")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))

            if let project = appState.selectedProject {
                Text("Start a Claude Code session in \(project.name)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.25))

                Button("Start Session") {
                    appState.startSession(projectId: project.id, prompt: "Help me with this project")
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
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 30/255, opacity: 0.6))
    }
}

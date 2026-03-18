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
                    // Empty state: no project selected
                    EmptyProjectView()
                } else if appState.rootAgents.isEmpty {
                    // Empty state: project has no agents
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

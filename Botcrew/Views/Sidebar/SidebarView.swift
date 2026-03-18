// SidebarView.swift
// Botcrew

import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PROJECTS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.66)
                .foregroundStyle(.white.opacity(0.25))
                .padding(.horizontal, 16)
                .padding(.top, 52)
                .padding(.bottom, 8)

            if appState.projects.isEmpty {
                Text("No projects")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            } else {
                List(appState.projects) { project in
                    SidebarProjectRow(project: project)
                }
                .listStyle(.sidebar)
            }

            Spacer()

            TokenCard()
                .padding(12)
        }
    }
}

struct SidebarProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor(project.status))
                .frame(width: 6, height: 6)

            Text(project.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .active: Color(red: 0.157, green: 0.784, blue: 0.251)
        case .idle: Color(white: 0.533, opacity: 0.5)
        case .error: Color(red: 1.0, green: 0.373, blue: 0.341)
        }
    }
}

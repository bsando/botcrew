// SidebarView.swift
// Botcrew

import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var editingProjectId: UUID?
    @State private var projectEditText: String = ""
    @State private var historyProjectId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with collapse button
            HStack {
                Text("PROJECTS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Theme.textSecondary(colorScheme))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isSidebarCollapsed = true
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.iconDefault(colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 52)
            .padding(.bottom, 8)

            // Project list
            if appState.projects.isEmpty {
                VStack(spacing: 12) {
                    Text("No projects")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                    Button("Add Project") {
                        appState.showAddProjectSheet = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0x0A84FF))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(appState.projects) { project in
                            let isEditingThis = editingProjectId == project.id
                            SidebarProjectRow(
                                project: project,
                                isSelected: project.id == appState.selectedProjectId,
                                isEditing: isEditingThis,
                                editText: $projectEditText,
                                onCommitRename: { commitProjectRename(project.id) }
                            )
                            .onTapGesture {
                                guard !isEditingThis else { return }
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    appState.selectProject(project.id)
                                }
                            }
                            .contextMenu {
                                Button("Rename") { startEditingProject(project) }
                                Button("Session History...") {
                                    historyProjectId = project.id
                                }
                                Divider()
                                Button("Remove Project") {
                                    appState.removeProject(project.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }

            Spacer()

            // Add project button
            Button {
                appState.showAddProjectSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                    Text("Add Project")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.textSecondary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            TokenCard()
                .padding(12)
        }
        .background {
            // Invisible background to catch clicks outside rows and cancel rename
            if editingProjectId != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingProjectId = nil
                    }
            }
        }
        .sheet(isPresented: Binding(
            get: { appState.showAddProjectSheet },
            set: { appState.showAddProjectSheet = $0 }
        )) {
            AddProjectSheet()
                .environment(appState)
        }
        .sheet(isPresented: Binding(
            get: { historyProjectId != nil },
            set: { if !$0 { historyProjectId = nil } }
        )) {
            if let pid = historyProjectId {
                SessionHistoryView(projectId: pid)
                    .environment(appState)
            }
        }
    }

    private func startEditingProject(_ project: Project) {
        projectEditText = project.name
        editingProjectId = project.id
    }

    private func commitProjectRename(_ projectId: UUID) {
        appState.renameProject(projectId, to: projectEditText)
        editingProjectId = nil
    }
}

// MARK: - Project Row

struct SidebarProjectRow: View {
    let project: Project
    let isSelected: Bool
    var isEditing: Bool = false
    @Binding var editText: String
    var onCommitRename: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor(project.status))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("Name", text: $editText, onCommit: onCommitRename)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, weight: .medium))
                        .focused($isFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                            }
                        }
                } else {
                    Text(project.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                }

                if !project.agents.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(project.agents) { agent in
                            Circle()
                                .fill(agentStatusColor(agent.status))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected
                      ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.15)
                      : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isSelected
                              ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.3)
                              : Color.clear, lineWidth: 1)
        )
    }

    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .active: Color(red: 0.157, green: 0.784, blue: 0.251)
        case .idle: Color(white: 0.533, opacity: 0.5)
        case .error: Color(red: 1.0, green: 0.373, blue: 0.341)
        }
    }

    private func agentStatusColor(_ status: AgentStatus) -> Color {
        switch status {
        case .typing: Color(hex: 0x34d399)
        case .reading: Color(hex: 0x60a5fa)
        case .waiting: Color(hex: 0xfbbf24)
        case .idle: Color(white: 0.533, opacity: 0.5)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

// MARK: - Add Project Sheet

struct AddProjectSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var projectName = ""
    @State private var selectedPath: URL?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Project")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary(colorScheme))

            VStack(alignment: .leading, spacing: 6) {
                Text("Project Name")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Theme.textSecondary(colorScheme))

                TextField("my-project", text: $projectName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Directory")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Theme.textTertiary(colorScheme))

                HStack {
                    Text(selectedPath?.lastPathComponent ?? "No folder selected")
                        .font(.system(size: 13))
                        .foregroundStyle(selectedPath == nil ? Theme.textSecondary(colorScheme) : Theme.textPrimary(colorScheme))

                    Spacer()

                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK {
                            selectedPath = panel.url
                            if projectName.isEmpty, let name = panel.url?.lastPathComponent {
                                projectName = name
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(hex: 0x0A84FF))
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    if let path = selectedPath {
                        appState.addProject(
                            name: projectName.isEmpty ? path.lastPathComponent : projectName,
                            path: path
                        )
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedPath == nil)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

// MARK: - Collapsed Sidebar

struct CollapsedSidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Expand button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.isSidebarCollapsed = false
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.iconDefault(colorScheme))
            }
            .buttonStyle(.plain)
            .padding(.top, 52)

            // Project dots
            VStack(spacing: 8) {
                ForEach(appState.projects) { project in
                    Circle()
                        .fill(project.id == appState.selectedProjectId
                              ? Color(hex: 0x0A84FF)
                              : statusDotColor(project.status))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            appState.selectProject(project.id)
                        }
                }
            }
            .padding(.top, 16)

            Spacer()
        }
    }

    private func statusDotColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .active: Color(red: 0.157, green: 0.784, blue: 0.251)
        case .idle: Color(white: 0.533, opacity: 0.5)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

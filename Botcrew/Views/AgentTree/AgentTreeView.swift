// AgentTreeView.swift
// Botcrew

import SwiftUI

struct AgentTreeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var historyProjectId: UUID?
    @State private var collapsedProjects: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("PROJECTS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Theme.textSecondary(colorScheme))

                Spacer()

                Button {
                    appState.showAddProjectSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.iconDefault(colorScheme))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 52)
            .padding(.bottom, 8)

            // Agent tree
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
                            ProjectTreeNode(
                                project: project,
                                isCollapsed: collapsedProjects.contains(project.id),
                                onToggle: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if collapsedProjects.contains(project.id) {
                                            collapsedProjects.remove(project.id)
                                        } else {
                                            collapsedProjects.insert(project.id)
                                        }
                                    }
                                },
                                onSelectProject: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        appState.selectProject(project.id)
                                    }
                                }
                            )

                            // Agent hierarchy (if not collapsed)
                            if !collapsedProjects.contains(project.id) {
                                let roots = project.agents.filter { $0.parentId == nil }
                                ForEach(roots) { root in
                                    AgentTreeRow(
                                        agent: root,
                                        isSelected: root.id == appState.selectedAgentId,
                                        isRoot: true
                                    )
                                    .onTapGesture {
                                        appState.selectProject(project.id)
                                        appState.selectAgent(root.id)
                                    }

                                    // Sub-agents
                                    let subs = project.agents.filter { $0.parentId == root.id }
                                    ForEach(subs) { sub in
                                        AgentTreeRow(
                                            agent: sub,
                                            isSelected: sub.id == appState.selectedAgentId,
                                            isRoot: false
                                        )
                                        .onTapGesture {
                                            appState.selectProject(project.id)
                                            appState.selectAgent(sub.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }

            Spacer()

            // Metrics footer
            MetricsFooterView()
                .padding(12)
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
}

// MARK: - Project Tree Node

struct ProjectTreeNode: View {
    let project: Project
    let isCollapsed: Bool
    let onToggle: () -> Void
    let onSelectProject: () -> Void
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var isSelected: Bool {
        project.id == appState.selectedProjectId
    }

    var body: some View {
        HStack(spacing: 6) {
            // Chevron
            Button(action: onToggle) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary(colorScheme))
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)

            Text(project.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.textPrimary(colorScheme) : Theme.textSecondary(colorScheme))

            Spacer()

            // Aggregate status dot
            Circle()
                .fill(projectStatusColor(project.status))
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected
                      ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.08)
                      : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelectProject)
        .contextMenu {
            Button("Session History...") {}
            Divider()
            Button("Remove Project") {
                appState.removeProject(project.id)
            }
        }
    }

    private func projectStatusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .active: Color(hex: 0x28C840)
        case .idle: Color(white: 0.533, opacity: 0.5)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

// MARK: - Agent Tree Row

struct AgentTreeRow: View {
    let agent: Agent
    let isSelected: Bool
    let isRoot: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            // Color swatch (10px, rounded)
            RoundedRectangle(cornerRadius: 3)
                .fill(agent.bodyColor)
                .frame(width: 10, height: 10)

            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .overlay {
                    if agent.status == .error {
                        Circle()
                            .stroke(Color(hex: 0xFF5F57).opacity(0.5), lineWidth: 1)
                            .frame(width: 10, height: 10)
                    }
                }

            // Name
            Text(agent.name)
                .font(.system(size: 12, weight: isRoot ? .medium : .regular))
                .foregroundStyle(isSelected ? Theme.textPrimary(colorScheme) : Theme.textSecondary(colorScheme))
                .lineLimit(1)

            Spacer()

            // Status label (root agents only — sub-agents use dots alone)
            if isRoot {
                Text(agent.status.rawValue)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary(colorScheme))
            }
        }
        .padding(.leading, isRoot ? 20 : 36)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected
                      ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.15)
                      : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(isSelected
                              ? Color(red: 10/255, green: 132/255, blue: 255/255, opacity: 0.3)
                              : Color.clear, lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch agent.status {
        case .typing: Color(hex: 0x28C840)
        case .reading: Color(hex: 0x28C840)
        case .waiting: Color(hex: 0xFEBC2E)
        case .idle: Color(white: 0.533, opacity: 0.5)
        case .error: Color(hex: 0xFF5F57)
        }
    }
}

// MARK: - Metrics Footer

struct MetricsFooterView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var activeAgentCount: Int {
        appState.projects.flatMap(\.agents).filter {
            $0.status == .typing || $0.status == .reading || $0.status == .waiting
        }.count
    }

    private var todayCost: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return appState.costHistory
            .filter { calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Active")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary(colorScheme))
                Spacer()
                Text("\(activeAgentCount) agents")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(activeAgentCount > 0 ? Color(hex: 0x28C840) : Theme.textSecondary(colorScheme))
                    .monospacedDigit()
            }

            HStack {
                Text("Today")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary(colorScheme))
                Spacer()
                Text(String(format: "$%.2f", todayCost))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                    .monospacedDigit()
            }

            // Rate limit bar
            if let rateLimit = appState.rateLimitInfo, !rateLimit.isExpired {
                HStack {
                    Text("Rate")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                    Spacer()
                    Text(tierLabel(rateLimit.tier))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cardBg(colorScheme))
        )
    }

    private func tierLabel(_ tier: RateLimitInfo.UsageTier) -> String {
        switch tier {
        case .allowed: "OK"
        case .overage: "Overage"
        case .rateLimited: "Limited"
        }
    }
}

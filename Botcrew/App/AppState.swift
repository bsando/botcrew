// AppState.swift
// Botcrew

import SwiftUI

@Observable
class AppState {
    var projects: [Project] = []
    var selectedProjectId: UUID?
    var selectedAgentId: UUID?
    var activeClusterId: UUID?
    var openTerminalIds: [UUID] = []
    var isSidebarCollapsed = false
    var showAddProjectSheet = false
    var showTerminal = false

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectId }
    }

    var selectedAgent: Agent? {
        selectedProject?.agents.first { $0.id == selectedAgentId }
    }

    var eventsForSelectedAgent: [ActivityEvent] {
        guard let project = selectedProject, let agentId = selectedAgentId else { return [] }
        return project.events
            .filter { $0.agentId == agentId }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var rootAgents: [Agent] {
        selectedProject?.agents.filter { $0.parentId == nil } ?? []
    }

    func subAgents(for rootId: UUID) -> [Agent] {
        selectedProject?.agents.filter { $0.parentId == rootId } ?? []
    }

    func selectAgent(_ id: UUID) {
        guard let project = selectedProject,
              let agent = project.agents.first(where: { $0.id == id }) else { return }
        selectedAgentId = id
        // If selecting a sub-agent, expand its parent cluster
        // If selecting a root agent, expand that cluster
        activeClusterId = agent.parentId ?? agent.id
    }

    func toggleCluster(_ rootId: UUID) {
        if activeClusterId == rootId {
            // Collapse: deselect sub-agents, keep root selected
            activeClusterId = nil
            if let agent = selectedAgent, agent.parentId == rootId {
                selectedAgentId = rootId
            }
        } else {
            activeClusterId = rootId
            selectedAgentId = rootId
        }
    }

    func selectProject(_ id: UUID) {
        selectedProjectId = id
        selectedAgentId = nil
        activeClusterId = nil
        openTerminalIds = []
    }

    func removeProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        if selectedProjectId == id {
            selectedProjectId = projects.first?.id
            selectedAgentId = nil
            activeClusterId = nil
            openTerminalIds = []
        }
    }

    func addProject(name: String, path: URL) {
        let project = Project(
            id: UUID(),
            name: name,
            path: path,
            status: .idle,
            agents: [],
            events: [],
            tokenCount: 0,
            estimatedCost: 0
        )
        projects.append(project)
        selectProject(project.id)
    }

    static func withMockData() -> AppState {
        let state = AppState()

        let root1Id = UUID()
        let sub1Id = UUID()
        let sub2Id = UUID()
        let root2Id = UUID()
        let sub3Id = UUID()
        let sub4Id = UUID()

        let agents = [
            Agent(id: root1Id, name: "orchestrator", parentId: nil, status: .reading,
                  bodyColor: Color(hex: 0xc0a8ff), shirtColor: Color(hex: 0x5030a0), spawnTime: Date().addingTimeInterval(-300)),
            Agent(id: sub1Id, name: "writer-1", parentId: root1Id, status: .typing,
                  bodyColor: Color(hex: 0x80e8a0), shirtColor: Color(hex: 0x0a4020), spawnTime: Date().addingTimeInterval(-240)),
            Agent(id: sub2Id, name: "test-runner", parentId: root1Id, status: .waiting,
                  bodyColor: Color(hex: 0xffd080), shirtColor: Color(hex: 0x6a3800), spawnTime: Date().addingTimeInterval(-180)),
            Agent(id: root2Id, name: "ui-builder", parentId: nil, status: .typing,
                  bodyColor: Color(hex: 0xffb090), shirtColor: Color(hex: 0x802010), spawnTime: Date().addingTimeInterval(-120)),
            Agent(id: sub3Id, name: "style-fixer", parentId: root2Id, status: .idle,
                  bodyColor: Color(hex: 0x80c8ff), shirtColor: Color(hex: 0x0a3060), spawnTime: Date().addingTimeInterval(-60)),
            Agent(id: sub4Id, name: "component-gen", parentId: root2Id, status: .typing,
                  bodyColor: Color(hex: 0x80e8a0), shirtColor: Color(hex: 0x0a4020), spawnTime: Date().addingTimeInterval(-45)),
        ]

        let now = Date()
        let mockEvents: [ActivityEvent] = [
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-290),
                          type: .spawn, meta: "Session started"),
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-280),
                          type: .read, file: "CLAUDE.md", meta: "Reading project instructions"),
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-260),
                          type: .thinking, meta: "Planning implementation approach"),
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-240),
                          type: .spawn, meta: "Spawned writer-1"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-235),
                          type: .read, file: "ContentView.swift", meta: "Reading existing code"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-220),
                          type: .write, file: "SidebarView.swift", meta: "Implementing sidebar"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-200),
                          type: .write, file: "TokenCard.swift", meta: "Adding token display"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-180),
                          type: .bash, meta: "xcodebuild -scheme Botcrew build"),
            ActivityEvent(id: UUID(), agentId: sub2Id, timestamp: now.addingTimeInterval(-170),
                          type: .spawn, meta: "Spawned by orchestrator"),
            ActivityEvent(id: UUID(), agentId: sub2Id, timestamp: now.addingTimeInterval(-160),
                          type: .bash, meta: "xcodebuild test"),
            ActivityEvent(id: UUID(), agentId: sub2Id, timestamp: now.addingTimeInterval(-150),
                          type: .thinking, meta: "Analyzing test results"),
            ActivityEvent(id: UUID(), agentId: root2Id, timestamp: now.addingTimeInterval(-110),
                          type: .write, file: "TabBarView.swift", meta: "Building tab components"),
            ActivityEvent(id: UUID(), agentId: sub3Id, timestamp: now.addingTimeInterval(-50),
                          type: .read, file: "theme.css", meta: "Checking design tokens"),
            ActivityEvent(id: UUID(), agentId: sub4Id, timestamp: now.addingTimeInterval(-40),
                          type: .write, file: "ButtonStyles.swift", meta: "Generating button components"),
            ActivityEvent(id: UUID(), agentId: sub4Id, timestamp: now.addingTimeInterval(-30),
                          type: .write, file: "CardView.swift", meta: "Generating card components"),
        ]

        let project1 = Project(
            id: UUID(), name: "botcrew", path: URL(fileURLWithPath: "/Users/brian/botcrew"),
            status: .active, agents: agents, events: mockEvents, tokenCount: 24_500, estimatedCost: 0.48
        )
        let project2 = Project(
            id: UUID(), name: "api-server", path: URL(fileURLWithPath: "/Users/brian/api-server"),
            status: .idle, agents: [], events: [], tokenCount: 8_200, estimatedCost: 0.16
        )
        let docWriterId = UUID()
        let project3 = Project(
            id: UUID(), name: "docs-site", path: URL(fileURLWithPath: "/Users/brian/docs-site"),
            status: .error, agents: [
                Agent(id: docWriterId, name: "doc-writer", parentId: nil, status: .error,
                      bodyColor: Color(hex: 0x80c8ff), shirtColor: Color(hex: 0x0a3060), spawnTime: now.addingTimeInterval(-60)),
            ], events: [
                ActivityEvent(id: UUID(), agentId: docWriterId, timestamp: now.addingTimeInterval(-55),
                              type: .write, file: "README.md", meta: "Updating docs"),
                ActivityEvent(id: UUID(), agentId: docWriterId, timestamp: now.addingTimeInterval(-40),
                              type: .error, meta: "Build failed: missing module"),
            ], tokenCount: 3_100, estimatedCost: 0.06
        )

        state.projects = [project1, project2, project3]
        state.selectedProjectId = project1.id
        return state
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

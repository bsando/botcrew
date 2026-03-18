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

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectId }
    }

    var selectedAgent: Agent? {
        selectedProject?.agents.first { $0.id == selectedAgentId }
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
            tokenCount: 0,
            estimatedCost: 0
        )
        projects.append(project)
        selectProject(project.id)
    }

    static func withMockData() -> AppState {
        let state = AppState()

        let rootId = UUID()
        let sub1Id = UUID()
        let sub2Id = UUID()

        let agents = [
            Agent(id: rootId, name: "orchestrator", parentId: nil, status: .reading,
                  bodyColor: Color(hex: 0xc0a8ff), shirtColor: Color(hex: 0x5030a0), spawnTime: Date().addingTimeInterval(-300)),
            Agent(id: sub1Id, name: "writer-1", parentId: rootId, status: .typing,
                  bodyColor: Color(hex: 0x80e8a0), shirtColor: Color(hex: 0x0a4020), spawnTime: Date().addingTimeInterval(-240)),
            Agent(id: sub2Id, name: "test-runner", parentId: rootId, status: .waiting,
                  bodyColor: Color(hex: 0xffd080), shirtColor: Color(hex: 0x6a3800), spawnTime: Date().addingTimeInterval(-180)),
        ]

        let project1 = Project(
            id: UUID(), name: "botcrew", path: URL(fileURLWithPath: "/Users/brian/botcrew"),
            status: .active, agents: agents, tokenCount: 24_500, estimatedCost: 0.48
        )
        let project2 = Project(
            id: UUID(), name: "api-server", path: URL(fileURLWithPath: "/Users/brian/api-server"),
            status: .idle, agents: [], tokenCount: 8_200, estimatedCost: 0.16
        )
        let project3 = Project(
            id: UUID(), name: "docs-site", path: URL(fileURLWithPath: "/Users/brian/docs-site"),
            status: .error, agents: [
                Agent(id: UUID(), name: "doc-writer", parentId: nil, status: .error,
                      bodyColor: Color(hex: 0x80c8ff), shirtColor: Color(hex: 0x0a3060), spawnTime: Date().addingTimeInterval(-60)),
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

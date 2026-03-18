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

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectId }
    }

    var selectedAgent: Agent? {
        selectedProject?.agents.first { $0.id == selectedAgentId }
    }
}

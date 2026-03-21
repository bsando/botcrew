// Project.swift
// Botcrew

import SwiftUI

enum ProjectStatus: String, CaseIterable, Codable {
    case active, idle, error
}

struct Project: Identifiable {
    let id: UUID
    var name: String
    var path: URL
    var status: ProjectStatus
    var agents: [Agent]
    var events: [ActivityEvent]
    var tokenCount: Int
    var estimatedCost: Double
    var lastSessionId: String? = nil
}

// MARK: - Persistence (only project metadata, not ephemeral agents/events)

struct SavedProject: Codable {
    let id: UUID
    var name: String
    var path: URL
    var tokenCount: Int
    var estimatedCost: Double
    var lastSessionId: String?

    init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.path = project.path
        self.tokenCount = project.tokenCount
        self.estimatedCost = project.estimatedCost
        self.lastSessionId = project.lastSessionId
    }

    func toProject() -> Project {
        Project(
            id: id,
            name: name,
            path: path,
            status: .idle,
            agents: [],
            events: [],
            tokenCount: tokenCount,
            estimatedCost: estimatedCost,
            lastSessionId: lastSessionId
        )
    }
}

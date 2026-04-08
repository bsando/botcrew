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
    var isAttached: Bool = false  // true = read-only watch of external session
    var officeLayout: OfficeLayout = OfficeLayout()
}

// MARK: - Persistence (only project metadata, not ephemeral agents/events)

struct SavedProject: Codable {
    let id: UUID
    var name: String
    var path: URL
    var tokenCount: Int
    var estimatedCost: Double
    var lastSessionId: String?
    var officeLayout: OfficeLayout?

    init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.path = project.path
        self.tokenCount = project.tokenCount
        self.estimatedCost = project.estimatedCost
        self.lastSessionId = project.lastSessionId
        self.officeLayout = project.officeLayout
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
            lastSessionId: lastSessionId,
            officeLayout: officeLayout ?? OfficeLayout()
        )
    }
}

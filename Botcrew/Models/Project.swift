// Project.swift
// Botcrew

import SwiftUI

enum ProjectStatus: String, CaseIterable {
    case active, idle, error
}

struct Project: Identifiable {
    let id: UUID
    var name: String
    var path: URL
    var status: ProjectStatus
    var agents: [Agent]
    var tokenCount: Int
    var estimatedCost: Double
}

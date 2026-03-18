// Agent.swift
// Botcrew

import SwiftUI

enum AgentStatus: String, CaseIterable {
    case typing, reading, waiting, idle, error
}

struct Agent: Identifiable {
    let id: UUID
    var name: String
    var parentId: UUID?
    var status: AgentStatus
    var bodyColor: Color
    var shirtColor: Color
    var spawnTime: Date
}

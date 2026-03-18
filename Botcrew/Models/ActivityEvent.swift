// ActivityEvent.swift
// Botcrew

import SwiftUI

enum EventType: String, CaseIterable {
    case spawn, write, read, bash, thinking, error
}

struct ActivityEvent: Identifiable {
    let id: UUID
    let agentId: UUID
    let timestamp: Date
    let type: EventType
    var file: String?
    var meta: String?
}

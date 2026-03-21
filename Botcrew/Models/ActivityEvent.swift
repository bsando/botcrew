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

    // Structured tool data (populated from stream-json)
    var content: String?        // Write: file content. Edit: new_string
    var oldString: String?      // Edit: old_string
    var command: String?         // Bash: command
    var commandOutput: String?   // Bash: output
}

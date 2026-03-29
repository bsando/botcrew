// TerminalEntry.swift
// Botcrew

import Foundation

/// A structured entry in the terminal view, mimicking the Claude CLI display.
struct TerminalEntry: Identifiable, Equatable {
    let id: UUID
    let kind: Kind
    let timestamp: Date

    enum Kind: Equatable {
        /// User prompt (displayed with > prefix)
        case userPrompt(String)
        /// Claude is thinking / working (animated indicator)
        case thinking
        /// Assistant text response
        case assistantText(String)
        /// Tool use header (e.g. "[Read] src/main.swift")
        case toolUse(name: String, summary: String)
        /// Tool result / output
        case toolResult(name: String, output: String)
        /// System message (session start, etc.)
        case system(String)
        /// Error message
        case error(String)
        /// Raw text (stderr, command output, etc.)
        case raw(String)
    }

    init(kind: Kind, timestamp: Date = Date()) {
        self.id = UUID()
        self.kind = kind
        self.timestamp = timestamp
    }
}

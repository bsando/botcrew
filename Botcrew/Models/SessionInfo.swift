// SessionInfo.swift
// Botcrew

import Foundation

struct SessionInfo: Identifiable {
    let id: String          // session ID from JSONL filename
    let filePath: String
    let startDate: Date
    let lastModified: Date
    let summary: String     // first user prompt or "Untitled"
    let fileSize: Int64
}

/// A running session discovered across all Claude Code projects
struct RunningSessionInfo: Identifiable {
    let id: String              // session ID
    let filePath: String
    let projectHash: String     // e.g. "-Users-brian-botcrew"
    let projectPath: String     // reverse-mapped path, e.g. "/Users/brian/botcrew"
    let summary: String
    let lastModified: Date
}

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

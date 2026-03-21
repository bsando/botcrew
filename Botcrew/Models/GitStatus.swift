// GitStatus.swift
// Botcrew

import Foundation

struct GitFileChange: Identifiable {
    let id = UUID()
    let status: String     // "M", "A", "D", "??"
    let filePath: String

    var statusLabel: String {
        switch status {
        case "M": "Modified"
        case "A": "Added"
        case "D": "Deleted"
        case "??": "Untracked"
        case "R": "Renamed"
        default: status
        }
    }
}

struct GitInfo {
    var branch: String = ""
    var changes: [GitFileChange] = []
    var isClean: Bool { changes.isEmpty }
}

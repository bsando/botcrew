// ToolApproval.swift
// Botcrew

import Foundation

/// A tool use that was denied and needs user approval
struct ToolApproval: Identifiable {
    let id = UUID()
    let projectId: UUID
    let sessionId: String
    let denials: [ToolDenial]
    let timestamp: Date

    struct ToolDenial: Identifiable {
        let id = UUID()
        let toolName: String
        let toolUseId: String
        let input: [String: Any]

        var summary: String {
            switch toolName {
            case "Write":
                let path = input["file_path"] as? String ?? "unknown"
                return "Write to \(path)"
            case "Edit":
                let path = input["file_path"] as? String ?? "unknown"
                return "Edit \(path)"
            case "Bash":
                let cmd = input["command"] as? String ?? "unknown"
                let truncated = cmd.count > 80 ? String(cmd.prefix(80)) + "..." : cmd
                return "Run: \(truncated)"
            case "NotebookEdit":
                let path = input["notebook_path"] as? String ?? "unknown"
                return "Edit notebook \(path)"
            default:
                return "\(toolName)"
            }
        }

        var detail: String? {
            switch toolName {
            case "Write":
                if let content = input["content"] as? String {
                    let lines = content.components(separatedBy: .newlines)
                    let preview = lines.prefix(10).joined(separator: "\n")
                    return lines.count > 10 ? preview + "\n... (\(lines.count) lines total)" : preview
                }
                return nil
            case "Edit":
                let old = input["old_string"] as? String ?? ""
                let new = input["new_string"] as? String ?? ""
                return "- \(old.prefix(60))\n+ \(new.prefix(60))"
            case "Bash":
                return input["command"] as? String
            default:
                return nil
            }
        }
    }
}

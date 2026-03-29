// AgentStateParser.swift
// Botcrew

import Foundation
import SwiftUI

/// Parses Claude Code JSONL events into agent states and activity events.
struct AgentStateParser {

    // MARK: - JSONL Line Parsing

    /// Parse a single JSONL line into a structured event
    static func parseJSONLLine(_ line: String) -> JSONLEvent? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return JSONLEvent(raw: json)
    }

    // MARK: - Tool Use → Agent Status

    /// Determine agent status from a tool use event
    static func statusFromToolUse(_ toolName: String) -> AgentStatus {
        switch toolName {
        case "Write", "Edit", "NotebookEdit":
            return .typing
        case "Read", "Glob", "Grep", "LSP":
            return .reading
        case "Bash":
            return .typing // bash is active work
        case "Agent", "Task":
            return .waiting // spawning/waiting on subagent
        default:
            return .reading
        }
    }

    /// Determine EventType from a tool use name
    static func eventTypeFromToolUse(_ toolName: String) -> EventType {
        switch toolName {
        case "Write", "Edit", "NotebookEdit":
            return .write
        case "Read", "Glob", "Grep", "LSP":
            return .read
        case "Bash":
            return .bash
        case "Agent", "Task":
            return .spawn
        default:
            return .thinking
        }
    }

    // MARK: - Token Counting

    /// Extract token usage from a JSONL event's message.usage field
    static func extractUsage(from event: JSONLEvent) -> (input: Int, output: Int)? {
        guard let message = event.raw["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any] else {
            return nil
        }

        let input = (usage["input_tokens"] as? Int ?? 0)
            + (usage["cache_creation_input_tokens"] as? Int ?? 0)
            + (usage["cache_read_input_tokens"] as? Int ?? 0)
        let output = usage["output_tokens"] as? Int ?? 0

        return (input, output)
    }

    /// Estimate cost from token counts (approximate Claude pricing)
    static func estimateCost(inputTokens: Int, outputTokens: Int) -> Double {
        // Approximate pricing: $15/M input, $75/M output for Opus
        let inputCost = Double(inputTokens) / 1_000_000.0 * 15.0
        let outputCost = Double(outputTokens) / 1_000_000.0 * 75.0
        return inputCost + outputCost
    }

    // MARK: - Subagent Detection

    /// Check if this event represents a subagent spawn (Task/Agent tool use)
    static func isSubagentSpawn(_ event: JSONLEvent) -> Bool {
        guard let content = event.contentArray else { return false }
        return content.contains { item in
            guard let type = item["type"] as? String, type == "tool_use",
                  let name = item["name"] as? String else { return false }
            return name == "Agent" || name == "Task"
        }
    }

    /// Extract tool uses from an assistant message
    static func extractToolUses(from event: JSONLEvent) -> [(name: String, input: [String: Any])] {
        guard let content = event.contentArray else { return [] }
        return content.compactMap { item in
            guard let type = item["type"] as? String, type == "tool_use",
                  let name = item["name"] as? String,
                  let input = item["input"] as? [String: Any] else { return nil }
            return (name: name, input: input)
        }
    }

    /// Extract file path from a tool use input
    static func extractFilePath(from toolInput: [String: Any]) -> String? {
        toolInput["file_path"] as? String
            ?? toolInput["path"] as? String
            ?? toolInput["pattern"] as? String
            ?? toolInput["command"] as? String
    }

    /// Extract structured content fields from a tool use for display in feed cards
    static func extractToolContent(from toolName: String, input: [String: Any]) -> (content: String?, oldString: String?, command: String?) {
        switch toolName {
        case "Write", "NotebookEdit":
            return (content: input["content"] as? String, oldString: nil, command: nil)
        case "Edit":
            return (content: input["new_string"] as? String, oldString: input["old_string"] as? String, command: nil)
        case "Bash":
            return (content: nil, oldString: nil, command: input["command"] as? String)
        default:
            return (content: nil, oldString: nil, command: nil)
        }
    }

    // MARK: - Error Detection

    /// Check if event content contains an error
    static func containsError(_ event: JSONLEvent) -> Bool {
        guard let content = event.contentArray else {
            // Check for tool_result errors
            if let message = event.raw["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                return content.contains { ($0["is_error"] as? Bool) == true }
            }
            return false
        }
        // Check for error text in assistant content
        return content.contains { item in
            guard let text = item["text"] as? String else { return false }
            return text.lowercased().contains("error") && text.lowercased().contains("failed")
        }
    }
}

// MARK: - JSONLEvent

/// Lightweight wrapper around a parsed JSONL dictionary
struct JSONLEvent {
    let raw: [String: Any]

    var type: String? { raw["type"] as? String }
    var sessionId: String? { raw["sessionId"] as? String }
    var uuid: String? { raw["uuid"] as? String }
    var parentUuid: String? { raw["parentUuid"] as? String }
    var cwd: String? { raw["cwd"] as? String }
    var timestamp: Date? {
        guard let ts = raw["timestamp"] as? String else { return nil }
        return ISO8601DateFormatter().date(from: ts)
    }

    var isAssistant: Bool { type == "assistant" }
    var isUser: Bool { type == "user" }

    /// Get the content array from message.content (assistant messages have tool_use items)
    var contentArray: [[String: Any]]? {
        guard let message = raw["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]] else {
            return nil
        }
        return content
    }

    /// Get the model from message.model
    var model: String? {
        (raw["message"] as? [String: Any])?["model"] as? String
    }
}

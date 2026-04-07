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

    /// Token usage broken down by billing category
    struct TokenUsage {
        let inputTokens: Int
        let cacheCreationTokens: Int
        let cacheReadTokens: Int
        let outputTokens: Int

        var totalTokens: Int { inputTokens + cacheCreationTokens + cacheReadTokens + outputTokens }
    }

    /// Extract token usage from a JSONL event's message.usage field
    static func extractUsage(from event: JSONLEvent) -> TokenUsage? {
        guard let message = event.raw["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any] else {
            return nil
        }

        return TokenUsage(
            inputTokens: usage["input_tokens"] as? Int ?? 0,
            cacheCreationTokens: usage["cache_creation_input_tokens"] as? Int ?? 0,
            cacheReadTokens: usage["cache_read_input_tokens"] as? Int ?? 0,
            outputTokens: usage["output_tokens"] as? Int ?? 0
        )
    }

    // MARK: - Cost Estimation

    /// Model pricing per million tokens (as of 2026-04)
    struct ModelPricing {
        let inputPerM: Double
        let cacheReadPerM: Double
        let cacheCreationPerM: Double
        let outputPerM: Double
    }

    private static let pricingTable: [String: ModelPricing] = [
        "sonnet": ModelPricing(inputPerM: 3.0, cacheReadPerM: 0.30, cacheCreationPerM: 3.75, outputPerM: 15.0),
        "opus": ModelPricing(inputPerM: 15.0, cacheReadPerM: 1.50, cacheCreationPerM: 18.75, outputPerM: 75.0),
        "haiku": ModelPricing(inputPerM: 0.80, cacheReadPerM: 0.08, cacheCreationPerM: 1.0, outputPerM: 4.0),
    ]

    /// Default pricing when model is unknown (Sonnet — most common in Claude Code)
    private static let defaultPricing = ModelPricing(inputPerM: 3.0, cacheReadPerM: 0.30, cacheCreationPerM: 3.75, outputPerM: 15.0)

    /// Look up pricing for a model string (matches keyword, e.g. "claude-sonnet-4-20250514")
    static func pricingForModel(_ model: String?) -> ModelPricing {
        guard let model = model?.lowercased() else { return defaultPricing }
        for (keyword, pricing) in pricingTable {
            if model.contains(keyword) { return pricing }
        }
        return defaultPricing
    }

    /// Estimate cost from detailed token usage and model
    static func estimateCost(usage: TokenUsage, model: String? = nil) -> Double {
        let p = pricingForModel(model)
        let inputCost = Double(usage.inputTokens) / 1_000_000.0 * p.inputPerM
        let cacheReadCost = Double(usage.cacheReadTokens) / 1_000_000.0 * p.cacheReadPerM
        let cacheCreationCost = Double(usage.cacheCreationTokens) / 1_000_000.0 * p.cacheCreationPerM
        let outputCost = Double(usage.outputTokens) / 1_000_000.0 * p.outputPerM
        return inputCost + cacheReadCost + cacheCreationCost + outputCost
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

    /// Patterns that indicate real errors (not just the word "error" in discussion)
    private static let errorPatterns: [String] = [
        "error:",           // "Error: file not found"
        "failed to",        // "Failed to read file"
        "permission denied", // filesystem/network errors
        "command failed",   // bash tool failures
        "exit code",        // non-zero exit codes
        "traceback",        // Python stack traces
        "panic:",           // Go panics
        "fatal:",           // fatal errors
        "exception:",       // generic exceptions
        "errno",            // system errors
        "segmentation fault",
        "no such file",
        "not found:",
    ]

    /// Check if event content contains an error
    static func containsError(_ event: JSONLEvent) -> Bool {
        // Check for explicit tool_result errors (most reliable signal)
        if let message = event.raw["message"] as? [String: Any],
           let content = message["content"] as? [[String: Any]] {
            if content.contains(where: { ($0["is_error"] as? Bool) == true }) {
                return true
            }
        }

        // Check for error-stop-reason on the message itself
        if let message = event.raw["message"] as? [String: Any],
           let stopReason = message["stop_reason"] as? String,
           stopReason == "error" {
            return true
        }

        // Check for error patterns in assistant text content
        guard let content = event.contentArray else { return false }
        return content.contains { item in
            guard let text = item["text"] as? String else { return false }
            let lower = text.lowercased()
            return errorPatterns.contains { lower.contains($0) }
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

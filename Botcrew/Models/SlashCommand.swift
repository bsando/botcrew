// SlashCommand.swift
// Botcrew

import Foundation

enum SlashCommand: String, CaseIterable {
    // Local commands (handled by Botcrew)
    case help
    case agents
    case cost
    case clear
    case status
    case resume
    case model
    case git
    case templates
    case terminal
    case version

    // Pass-through commands (forwarded to Claude CLI session)
    case compact
    case commit
    case diff
    case review
    case config
    case context
    case permissions
    case plan
    case prComments = "pr-comments"
    case doctor
    case memory
    case hooks
    case mcp
    case effort
    case export
    case login
    case rename
    case files
    case debug
    case init_ = "init"

    var name: String { "/" + rawValue }

    var description: String {
        switch self {
        case .help: "Show available slash commands"
        case .agents: "List agents in the current project"
        case .cost: "Open cost dashboard"
        case .clear: "Clear terminal output"
        case .status: "Show project status"
        case .resume: "Resume a previous session"
        case .model: "Show model info from last session"
        case .git: "Open git panel"
        case .templates: "Open prompt templates"
        case .terminal: "Toggle terminal view"
        case .version: "Show Claude Code version"
        case .compact: "Compact the conversation context"
        case .commit: "Create a git commit"
        case .diff: "View uncommitted changes"
        case .review: "Review a pull request"
        case .config: "Open config panel"
        case .context: "Show current context usage"
        case .permissions: "Manage tool permission rules"
        case .plan: "Enable plan mode"
        case .prComments: "Get comments from a GitHub PR"
        case .doctor: "Diagnose Claude Code installation"
        case .memory: "Edit Claude memory files"
        case .hooks: "View hook configurations"
        case .mcp: "Manage MCP servers"
        case .effort: "Set effort level"
        case .export: "Export conversation to file"
        case .login: "Manage authentication"
        case .rename: "Rename the current conversation"
        case .files: "List files currently in context"
        case .debug: "Enable debug logging"
        case .init_: "Initialize project configuration"
        }
    }

    var icon: String {
        switch self {
        case .help: "questionmark.circle"
        case .agents: "person.3"
        case .cost: "dollarsign.circle"
        case .clear: "trash"
        case .status: "info.circle"
        case .resume: "arrow.clockwise"
        case .model: "cpu"
        case .git: "arrow.triangle.branch"
        case .templates: "list.bullet.rectangle"
        case .terminal: "terminal"
        case .version: "info.circle"
        case .compact: "arrow.down.right.and.arrow.up.left"
        case .commit: "checkmark.circle"
        case .diff: "doc.text.magnifyingglass"
        case .review: "eye"
        case .config: "gearshape"
        case .context: "chart.bar"
        case .permissions: "lock.shield"
        case .plan: "list.number"
        case .prComments: "text.bubble"
        case .doctor: "stethoscope"
        case .memory: "brain"
        case .hooks: "link"
        case .mcp: "server.rack"
        case .effort: "gauge.medium"
        case .export: "square.and.arrow.up"
        case .login: "person.circle"
        case .rename: "pencil"
        case .files: "doc.on.doc"
        case .debug: "ant"
        case .init_: "plus.circle"
        }
    }

    /// Whether this command is handled locally by Botcrew (vs forwarded to Claude)
    var isLocal: Bool {
        switch self {
        case .help, .agents, .cost, .clear, .status, .resume,
             .model, .git, .templates, .terminal, .version:
            return true
        default:
            return false
        }
    }

    /// Filter commands matching a partial query (without the leading /)
    static func matching(_ query: String) -> [SlashCommand] {
        let q = query.lowercased()
        if q.isEmpty { return allCases }
        return allCases.filter { $0.rawValue.hasPrefix(q) }
    }
}

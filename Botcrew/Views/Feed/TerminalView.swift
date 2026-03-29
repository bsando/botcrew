// TerminalView.swift
// Botcrew

import SwiftUI

struct TerminalView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var entries: [TerminalEntry] {
        appState.terminalEntriesForSelectedProject
    }

    private var isThinking: Bool {
        guard let projectId = appState.selectedProjectId,
              let proc = appState.processes[projectId] else { return false }
        return proc.isThinking
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(entries) { entry in
                            entryView(entry)
                        }
                    }

                    if isThinking {
                        ThinkingIndicator()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("terminal-bottom")
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.terminalBg(colorScheme))
            .onChange(of: entries.count) {
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("terminal-bottom", anchor: .bottom)
                }
            }
            .onChange(of: isThinking) {
                proxy.scrollTo("terminal-bottom", anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let agent = appState.selectedAgent {
                Text("Agent: \(agent.name)")
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                Text("Status: \(agent.status.rawValue)")
                    .foregroundStyle(Theme.textMuted(colorScheme))
            } else {
                Text("Waiting for session to start...")
                    .foregroundStyle(Theme.textMuted(colorScheme))
            }
        }
        .font(.system(size: 12, design: .monospaced))
        .padding(16)
    }

    @ViewBuilder
    private func entryView(_ entry: TerminalEntry) -> some View {
        switch entry.kind {
        case .userPrompt(let text):
            UserPromptRow(text: text, colorScheme: colorScheme)

        case .thinking:
            ThinkingIndicator()
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

        case .assistantText(let text):
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary(colorScheme))
                .textSelection(.enabled)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

        case .toolUse(let name, let summary):
            ToolUseRow(name: name, summary: summary, colorScheme: colorScheme)

        case .toolResult(_, let output):
            Text(output)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.textSecondary(colorScheme))
                .textSelection(.enabled)
                .padding(.horizontal, 24)
                .padding(.vertical, 2)

        case .system(let text):
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textMuted(colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 2)

        case .error(let text):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text(text)
                    .font(.system(size: 12, design: .monospaced))
            }
            .foregroundStyle(Color(hex: 0xFF5F57))
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

        case .raw(let text):
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.textSecondary(colorScheme))
                .textSelection(.enabled)
                .padding(.horizontal, 16)
                .padding(.vertical, 1)
        }
    }
}

// MARK: - User Prompt Row

private struct UserPromptRow: View {
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("> ")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: 0x0A84FF))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary(colorScheme))
                .textSelection(.enabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            colorScheme == .dark
                ? Color.white.opacity(0.03)
                : Color.black.opacity(0.03)
        )
    }
}

// MARK: - Tool Use Row

private struct ToolUseRow: View {
    let name: String
    let summary: String
    let colorScheme: ColorScheme

    private var toolColor: Color {
        switch name {
        case "Read", "Glob", "Grep", "LSP":
            return Color(hex: 0x80C8FF)  // Blue — read operations
        case "Write", "Edit", "NotebookEdit":
            return Color(hex: 0x80E8A0)  // Green — write operations
        case "Bash":
            return Color(hex: 0xFFD080)  // Amber — shell
        case "Agent", "Task":
            return Color(hex: 0xC0A8FF)  // Purple — subagents
        default:
            return Theme.textMuted(colorScheme)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("[\(name)]")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(toolColor)
            Text(summary)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.textSecondary(colorScheme))
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }
}

// MARK: - Thinking Indicator

private struct ThinkingIndicator: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: 0xC0A8FF))
                        .frame(width: 4, height: 4)
                        .opacity(i <= dotCount ? 1.0 : 0.3)
                }
            }
            Text("Thinking")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: 0xC0A8FF).opacity(0.7))
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

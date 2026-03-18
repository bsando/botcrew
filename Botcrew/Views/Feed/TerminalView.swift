// TerminalView.swift
// Botcrew

import SwiftUI

struct TerminalView: View {
    @Environment(AppState.self) private var appState

    private var mockOutput: String {
        guard let agent = appState.selectedAgent else {
            return "No agent selected"
        }
        return """
        $ claude --session \(agent.name)
        ╭──────────────────────────────────╮
        │  Claude Code v1.0                │
        │  Agent: \(agent.name.padding(toLength: 25, withPad: " ", startingAt: 0)) │
        │  Status: \(agent.status.rawValue.padding(toLength: 24, withPad: " ", startingAt: 0)) │
        ╰──────────────────────────────────╯

        > Reading project files...
        > Analyzing codebase structure...
        > Planning implementation...
        """
    }

    var body: some View {
        ScrollView {
            Text(mockOutput)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 15/255, green: 15/255, blue: 20/255))
    }
}

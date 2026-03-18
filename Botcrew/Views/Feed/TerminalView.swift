// TerminalView.swift
// Botcrew

import SwiftUI

struct TerminalView: View {
    @Environment(AppState.self) private var appState

    private var output: String {
        let realOutput = appState.terminalOutputForSelectedProject
        if !realOutput.isEmpty {
            return realOutput
        }

        // Fallback to mock output when no process is running
        guard let agent = appState.selectedAgent else {
            return "No agent selected"
        }
        return """
        $ claude --print "..."
        ╭──────────────────────────────────╮
        │  Claude Code v2.1                │
        │  Agent: \(agent.name.padding(toLength: 25, withPad: " ", startingAt: 0)) │
        │  Status: \(agent.status.rawValue.padding(toLength: 24, withPad: " ", startingAt: 0)) │
        ╰──────────────────────────────────╯

        > Waiting for session to start...
        """
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(output)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .id("terminal-bottom")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 15/255, green: 15/255, blue: 20/255))
            .onChange(of: output) {
                proxy.scrollTo("terminal-bottom", anchor: .bottom)
            }
        }
    }
}

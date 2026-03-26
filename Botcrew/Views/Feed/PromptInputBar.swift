// PromptInputBar.swift
// Botcrew

import SwiftUI

struct PromptInputBar: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var promptText = ""
    @State private var selectedCommandIndex = 0
    @FocusState private var isFocused: Bool

    private var isProcessRunning: Bool {
        guard let projectId = appState.selectedProjectId else { return false }
        return appState.processes[projectId]?.isRunning == true
    }

    private var matchingCommands: [SlashCommand] {
        guard promptText.hasPrefix("/") else { return [] }
        let query = String(promptText.dropFirst())
        return SlashCommand.matching(query)
    }

    private var showAutocomplete: Bool {
        promptText.hasPrefix("/") && !matchingCommands.isEmpty && isFocused
    }

    var body: some View {
        VStack(spacing: 0) {
            // Autocomplete popup
            if showAutocomplete {
                SlashCommandAutocomplete(
                    commands: matchingCommands,
                    selectedIndex: selectedCommandIndex,
                    onSelect: { command in
                        executeCommand(command)
                    }
                )
            }

            // Separator
            Rectangle()
                .fill(Theme.separator(colorScheme))
                .frame(height: 1)

            HStack(spacing: 8) {
                // Permission mode picker
                Menu {
                    ForEach(AppState.PermissionMode.allCases, id: \.self) { mode in
                        Button {
                            appState.permissionMode = mode
                        } label: {
                            HStack {
                                Text(mode.label)
                                if mode == appState.permissionMode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: permissionIcon)
                            .font(.system(size: 10))
                        Text(appState.permissionMode.label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(permissionColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(permissionColor.opacity(0.12))
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help(appState.permissionMode.description)

                // Template picker button
                Button {
                    appState.showTemplateSheet = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                }
                .buttonStyle(.plain)
                .help("Prompt templates")
                .popover(isPresented: Binding(
                    get: { appState.showTemplateSheet },
                    set: { appState.showTemplateSheet = $0 }
                )) {
                    PromptTemplateSheet { prompt in
                        promptText = prompt
                    }
                    .environment(appState)
                }

                TextField(placeholder, text: $promptText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .focused($isFocused)
                    .onSubmit { submitPrompt() }
                    .disabled(isProcessRunning)
                    .onChange(of: promptText) { _, newValue in
                        // Reset selection when text changes
                        selectedCommandIndex = 0
                    }
                    .onKeyPress(.upArrow) {
                        guard showAutocomplete else { return .ignored }
                        selectedCommandIndex = max(0, selectedCommandIndex - 1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        guard showAutocomplete else { return .ignored }
                        selectedCommandIndex = min(matchingCommands.count - 1, selectedCommandIndex + 1)
                        return .handled
                    }
                    .onKeyPress(.tab) {
                        guard showAutocomplete, !matchingCommands.isEmpty else { return .ignored }
                        let cmd = matchingCommands[selectedCommandIndex]
                        promptText = cmd.name
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        if showAutocomplete {
                            promptText = ""
                            return .handled
                        }
                        return .ignored
                    }

                if isProcessRunning {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Button {
                        submitPrompt()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(promptText.isEmpty ? Theme.textTertiary(colorScheme) : Color(hex: 0x0A84FF))
                    }
                    .buttonStyle(.plain)
                    .disabled(promptText.isEmpty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.promptBarBg(colorScheme))
        }
        .onChange(of: appState.focusPromptInput) { _, newValue in
            if newValue {
                isFocused = true
                appState.focusPromptInput = false
            }
        }
    }

    private var permissionIcon: String {
        switch appState.permissionMode {
        case .auto: "bolt.fill"
        case .supervised: "shield.checkered"
        case .safe: "lock.fill"
        }
    }

    private var permissionColor: Color {
        switch appState.permissionMode {
        case .auto: Color(hex: 0xFF5F57)
        case .supervised: Color(hex: 0xFEBC2E)
        case .safe: Color(hex: 0x28C840)
        }
    }

    private var placeholder: String {
        if isProcessRunning {
            return "Claude is working..."
        }
        if let projectId = appState.selectedProjectId,
           let proc = appState.processes[projectId], proc.hasRanBefore {
            return "Send a follow-up message..."
        }
        return "Ask Claude something... (type / for commands)"
    }

    private func executeCommand(_ command: SlashCommand) {
        promptText = ""
        guard let projectId = appState.selectedProjectId else { return }
        appState.executeSlashCommand(command, projectId: projectId)
    }

    private func submitPrompt() {
        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let projectId = appState.selectedProjectId else { return }

        // Check if it's a slash command
        if text.hasPrefix("/") {
            let cmdName = String(text.dropFirst()).components(separatedBy: " ").first ?? ""
            if let command = SlashCommand(rawValue: cmdName) {
                promptText = ""
                appState.executeSlashCommand(command, projectId: projectId)
                return
            }
        }

        promptText = ""
        appState.sendPrompt(projectId: projectId, prompt: text)
        appState.showTerminal = true
    }
}

// MARK: - Autocomplete popup

private struct SlashCommandAutocomplete: View {
    let commands: [SlashCommand]
    let selectedIndex: Int
    let onSelect: (SlashCommand) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(commands.enumerated()), id: \.element) { index, command in
                Button {
                    onSelect(command)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: command.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(index == selectedIndex ? .white : Theme.textSecondary(colorScheme))
                            .frame(width: 16)
                        Text(command.name)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(index == selectedIndex ? .white : Theme.textPrimary(colorScheme))
                        Spacer()
                        Text(command.description)
                            .font(.system(size: 11))
                            .foregroundStyle(index == selectedIndex ? .white.opacity(0.7) : Theme.textMuted(colorScheme))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        index == selectedIndex
                            ? Color(hex: 0x0A84FF).opacity(0.8)
                            : Color.clear
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .background(Theme.promptBarBg(colorScheme))
    }
}

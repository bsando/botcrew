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

    private var isAttached: Bool {
        appState.selectedProject?.isAttached == true
    }

    /// Autocomplete items — unified under / prefix (\ still works for backwards compat)
    private var autocompleteItems: [AutocompleteItem] {
        if promptText.hasPrefix("\\") {
            let query = String(promptText.dropFirst())
            return BotcrewCommand.matching(query).map { .botcrew($0) }
        } else if promptText.hasPrefix("/") {
            let query = String(promptText.dropFirst())
            // Show both Botcrew and CLI commands under /
            let botcrew = BotcrewCommand.matching(query).map { AutocompleteItem.botcrew($0) }
            let cli = SlashCommand.matching(query).map { AutocompleteItem.slash($0) }
            return botcrew + cli
        }
        return []
    }

    private var showAutocomplete: Bool {
        !autocompleteItems.isEmpty && isFocused
    }

    var body: some View {
        VStack(spacing: 0) {
            // Autocomplete popup
            if showAutocomplete {
                CommandAutocomplete(
                    items: autocompleteItems,
                    selectedIndex: selectedCommandIndex,
                    onSelect: { item in
                        executeItem(item)
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
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
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
                    .disabled(isProcessRunning || isAttached)
                    .onChange(of: promptText) { _, newValue in
                        selectedCommandIndex = 0
                    }
                    .onKeyPress(.upArrow) {
                        guard showAutocomplete else { return .ignored }
                        selectedCommandIndex = max(0, selectedCommandIndex - 1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        guard showAutocomplete else { return .ignored }
                        selectedCommandIndex = min(autocompleteItems.count - 1, selectedCommandIndex + 1)
                        return .handled
                    }
                    .onKeyPress(.tab) {
                        guard showAutocomplete, !autocompleteItems.isEmpty else { return .ignored }
                        let item = autocompleteItems[selectedCommandIndex]
                        promptText = item.name
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        if showAutocomplete {
                            promptText = ""
                            return .handled
                        }
                        return .ignored
                    }

                if isAttached {
                    Button {
                        if let pid = appState.selectedProjectId {
                            appState.detachSession(projectId: pid)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 10))
                            Text("Detach")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.statusRed)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                .fill(Theme.statusRed.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                } else if isProcessRunning {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Button {
                        submitPrompt()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(promptText.isEmpty ? Theme.textTertiary(colorScheme) : Theme.systemBlue)
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
        case .auto: "bolt.trianglebadge.exclamationmark.fill"
        case .supervised: "shield.checkered"
        case .safe: "lock.fill"
        }
    }

    private var permissionColor: Color {
        switch appState.permissionMode {
        case .auto: Color(hex: 0xFEBC2E)       // amber — permissive, use caution
        case .supervised: Color(hex: 0x0A84FF)  // blue — balanced default
        case .safe: Color(hex: 0x888780)        // gray — locked down
        }
    }

    private var placeholder: String {
        if isAttached {
            return "Attached (read-only)"
        }
        if isProcessRunning {
            return "Claude is working..."
        }
        if let projectId = appState.selectedProjectId,
           let proc = appState.processes[projectId], proc.hasRanBefore {
            return "Send a follow-up message..."
        }
        return "Ask Claude something... (type / for commands)"
    }

    private func executeItem(_ item: AutocompleteItem) {
        promptText = ""
        guard let projectId = appState.selectedProjectId else { return }
        switch item {
        case .botcrew(let cmd):
            appState.executeBotcrewCommand(cmd, projectId: projectId)
        case .slash(let cmd):
            appState.executeSlashCommand(cmd, projectId: projectId)
        }
    }

    private func submitPrompt() {
        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let projectId = appState.selectedProjectId else { return }

        // Check if it's a Botcrew local command (\command)
        if text.hasPrefix("\\") {
            let cmdName = String(text.dropFirst()).components(separatedBy: " ").first ?? ""
            if let command = BotcrewCommand(rawValue: cmdName) {
                promptText = ""
                appState.executeBotcrewCommand(command, projectId: projectId)
                return
            }
        }

        // Check if it's a CLI slash command (/command)
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

// MARK: - Unified autocomplete item

private enum AutocompleteItem: Hashable {
    case botcrew(BotcrewCommand)
    case slash(SlashCommand)

    var name: String {
        switch self {
        case .botcrew(let cmd): cmd.name
        case .slash(let cmd): cmd.name
        }
    }

    var description: String {
        switch self {
        case .botcrew(let cmd): cmd.description
        case .slash(let cmd): cmd.description
        }
    }

    var icon: String {
        switch self {
        case .botcrew(let cmd): cmd.icon
        case .slash(let cmd): cmd.icon
        }
    }
}

// MARK: - Autocomplete popup

private struct CommandAutocomplete: View {
    let items: [AutocompleteItem]
    let selectedIndex: Int
    let onSelect: (AutocompleteItem) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                Button {
                    onSelect(item)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(index == selectedIndex ? .white : Theme.textSecondary(colorScheme))
                            .frame(width: 16)
                        Text(item.name)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(index == selectedIndex ? .white : Theme.textPrimary(colorScheme))
                        Spacer()
                        Text(item.description)
                            .font(.system(size: 11))
                            .foregroundStyle(index == selectedIndex ? .white.opacity(0.7) : Theme.textMuted(colorScheme))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        index == selectedIndex
                            ? Theme.systemBlue.opacity(0.8)
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

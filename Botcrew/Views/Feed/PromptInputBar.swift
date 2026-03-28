// PromptInputBar.swift
// Botcrew

import SwiftUI
import UniformTypeIdentifiers

struct PromptInputBar: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var promptText = ""
    @State private var selectedCommandIndex = 0
    @State private var attachedImages: [ImageAttachment] = []
    @State private var isDragTargeted = false
    @FocusState private var isFocused: Bool

    private let maxAttachments = 5

    private var isProcessBusy: Bool {
        guard let projectId = appState.selectedProjectId,
              let proc = appState.processes[projectId] else { return false }
        return proc.isRunning && !proc.isWaitingForInput
    }

    private var matchingCommands: [SlashCommand] {
        guard promptText.hasPrefix("/") else { return [] }
        let query = String(promptText.dropFirst())
        return SlashCommand.matching(query)
    }

    private var showAutocomplete: Bool {
        promptText.hasPrefix("/") && !matchingCommands.isEmpty && isFocused
    }

    private var canSubmit: Bool {
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachedImages.isEmpty
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

            // Image thumbnail strip
            if !attachedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(attachedImages) { img in
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: img.thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Theme.separator(colorScheme), lineWidth: 1)
                                    )

                                Button {
                                    attachedImages.removeAll { $0.id == img.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 1)
                                }
                                .buttonStyle(.plain)
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(Theme.promptBarBg(colorScheme))
            }

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

                // Attach image button
                Button {
                    showFilePicker()
                } label: {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundStyle(attachedImages.isEmpty ? Theme.textMuted(colorScheme) : Color(hex: 0x0A84FF))
                }
                .buttonStyle(.plain)
                .help("Attach image")
                .disabled(isProcessBusy)

                TextField(placeholder, text: $promptText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .focused($isFocused)
                    .onSubmit { submitPrompt() }
                    .disabled(isProcessBusy)
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

                if isProcessBusy {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Button {
                        submitPrompt()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(!canSubmit ? Theme.textTertiary(colorScheme) : Color(hex: 0x0A84FF))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.promptBarBg(colorScheme))
        }
        .overlay(
            // Drag-and-drop highlight border
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: 0x0A84FF), lineWidth: 2)
                .opacity(isDragTargeted ? 1 : 0)
        )
        .onDrop(of: [.image, .fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .onPasteCommand(of: [.image, .png, .jpeg, .tiff]) { providers in
            handlePaste(providers)
        }
        .onChange(of: appState.focusPromptInput) { _, newValue in
            if newValue {
                isFocused = true
                appState.focusPromptInput = false
            }
        }
    }

    // MARK: - Helpers

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
        if isProcessBusy {
            return "Claude is working..."
        }
        if let projectId = appState.selectedProjectId,
           let proc = appState.processes[projectId], proc.isRunning, proc.isWaitingForInput {
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
        guard canSubmit, let projectId = appState.selectedProjectId else { return }

        // Check if it's a slash command
        if text.hasPrefix("/") && attachedImages.isEmpty {
            let cmdName = String(text.dropFirst()).components(separatedBy: " ").first ?? ""
            if let command = SlashCommand(rawValue: cmdName) {
                promptText = ""
                appState.executeSlashCommand(command, projectId: projectId)
                return
            }
        }

        let images = attachedImages
        promptText = ""
        attachedImages = []

        if images.isEmpty {
            appState.sendPrompt(projectId: projectId, prompt: text)
        } else {
            appState.sendPromptWithImages(projectId: projectId, prompt: text, images: images)
        }
        appState.showTerminal = true
    }

    // MARK: - Image attachment

    private func showFilePicker() {
        guard attachedImages.count < maxAttachments else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            let remaining = maxAttachments - attachedImages.count
            for url in panel.urls.prefix(remaining) {
                if let attachment = ImageProcessor.processFile(at: url) {
                    attachedImages.append(attachment)
                }
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        let remaining = maxAttachments - attachedImages.count
        guard remaining > 0 else { return }

        for provider in providers.prefix(remaining) {
            // Try loading as file URL first
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                    guard let urlData = data as? Data,
                          let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                    if let attachment = ImageProcessor.processFile(at: url) {
                        DispatchQueue.main.async {
                            attachedImages.append(attachment)
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    var image: NSImage?
                    if let nsImage = data as? NSImage {
                        image = nsImage
                    } else if let imageData = data as? Data {
                        image = NSImage(data: imageData)
                    }
                    if let image = image, let attachment = ImageProcessor.processImage(image) {
                        DispatchQueue.main.async {
                            attachedImages.append(attachment)
                        }
                    }
                }
            }
        }
    }

    private func handlePaste(_ providers: [NSItemProvider]) {
        let remaining = maxAttachments - attachedImages.count
        guard remaining > 0 else { return }

        for provider in providers.prefix(remaining) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { data, _ in
                var image: NSImage?
                if let nsImage = data as? NSImage {
                    image = nsImage
                } else if let imageData = data as? Data {
                    image = NSImage(data: imageData)
                }
                if let image = image, let attachment = ImageProcessor.processImage(image, fileName: "pasted-image.png") {
                    DispatchQueue.main.async {
                        attachedImages.append(attachment)
                    }
                }
            }
        }
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

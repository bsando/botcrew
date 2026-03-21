// PromptInputBar.swift
// Botcrew

import SwiftUI

struct PromptInputBar: View {
    @Environment(AppState.self) private var appState
    @State private var promptText = ""
    @FocusState private var isFocused: Bool

    private var isProcessRunning: Bool {
        guard let projectId = appState.selectedProjectId else { return false }
        return appState.processes[projectId]?.isRunning == true
    }

    var body: some View {
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
                    .foregroundStyle(.white.opacity(0.40))
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
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .focused($isFocused)
                .onSubmit { submitPrompt() }
                .disabled(isProcessRunning)

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
                        .foregroundStyle(promptText.isEmpty ? .white.opacity(0.15) : Color(hex: 0x0A84FF))
                }
                .buttonStyle(.plain)
                .disabled(promptText.isEmpty)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 35/255, opacity: 0.9))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
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
        return "Ask Claude something..."
    }

    private func submitPrompt() {
        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let projectId = appState.selectedProjectId else { return }
        promptText = ""
        appState.sendPrompt(projectId: projectId, prompt: text)
        appState.showTerminal = true
    }
}

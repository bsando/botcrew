// GitPanelView.swift
// Botcrew

import SwiftUI

struct GitPanelView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var gitInfo = GitInfo()
    @State private var commitMessage = ""
    @State private var selectedFiles: Set<String> = []
    @State private var diffText = ""
    @State private var showDiff = false
    @State private var commitResult: String?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Git")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                if !gitInfo.branch.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 10))
                        Text(gitInfo.branch)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: 0xc0a8ff).opacity(0.75))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: 0xc0a8ff).opacity(0.1))
                    )
                }

                Spacer()

                Button {
                    refreshStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)

                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x0A84FF))
            }
            .padding(16)

            Divider().opacity(0.15)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if gitInfo.isClean {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: 0x28C840).opacity(0.5))
                    Text("Working tree clean")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
            } else {
                // Changed files
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(gitInfo.changes) { change in
                            fileRow(change)
                        }
                    }
                    .padding(8)
                }

                Divider().opacity(0.15)

                // Commit section
                VStack(spacing: 8) {
                    TextField("Commit message...", text: $commitMessage)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))

                    HStack {
                        Text("\(selectedFiles.count) of \(gitInfo.changes.count) files")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))

                        Button(selectedFiles.count == gitInfo.changes.count ? "Deselect All" : "Select All") {
                            if selectedFiles.count == gitInfo.changes.count {
                                selectedFiles = []
                            } else {
                                selectedFiles = Set(gitInfo.changes.map(\.filePath))
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x0A84FF))

                        Spacer()

                        Button("Commit") {
                            performCommit()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(hex: 0x0A84FF))
                        )
                        .disabled(commitMessage.isEmpty || selectedFiles.isEmpty)
                    }

                    if let result = commitResult {
                        Text(result)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(2)
                    }
                }
                .padding(12)
            }

            // Diff viewer
            if showDiff && !diffText.isEmpty {
                Divider().opacity(0.15)
                ScrollView {
                    Text(diffText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 150)
                .background(Color(white: 0.08))
            }
        }
        .frame(width: 440, height: 500)
        .onAppear { refreshStatus() }
    }

    private func fileRow(_ change: GitFileChange) -> some View {
        let isSelected = selectedFiles.contains(change.filePath)

        return HStack(spacing: 8) {
            Button {
                if isSelected {
                    selectedFiles.remove(change.filePath)
                } else {
                    selectedFiles.insert(change.filePath)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? Color(hex: 0x0A84FF) : .white.opacity(0.3))
            }
            .buttonStyle(.plain)

            Text(change.status)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor(change.status))
                .frame(width: 20)

            Text(change.filePath)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)

            Spacer()

            Button {
                viewDiff(change.filePath)
            } label: {
                Text("diff")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color(hex: 0x0A84FF).opacity(0.06) : Color.clear)
        )
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "M": Color(hex: 0xfbbf24)
        case "A": Color(hex: 0x34d399)
        case "D": Color(hex: 0xFF5F57)
        case "??": Color(hex: 0x888780)
        default: .white.opacity(0.5)
        }
    }

    private func refreshStatus() {
        guard let project = appState.selectedProject else {
            isLoading = false
            return
        }
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let info = GitService.status(at: project.path)
            DispatchQueue.main.async {
                gitInfo = info
                selectedFiles = Set(info.changes.map(\.filePath))
                isLoading = false
            }
        }
    }

    private func viewDiff(_ file: String) {
        guard let project = appState.selectedProject else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let diff = GitService.diff(at: project.path, file: file)
            DispatchQueue.main.async {
                diffText = diff
                showDiff = true
            }
        }
    }

    private func performCommit() {
        guard let project = appState.selectedProject else { return }
        let files = Array(selectedFiles)
        let msg = commitMessage
        DispatchQueue.global(qos: .userInitiated).async {
            let result = GitService.commit(at: project.path, message: msg, files: files)
            DispatchQueue.main.async {
                commitResult = result.output
                if result.success {
                    commitMessage = ""
                    refreshStatus()
                }
            }
        }
    }
}

// AttachSessionSheet.swift
// Botcrew

import SwiftUI

struct AttachSessionSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [RunningSessionInfo] = []
    @State private var isLoading = true

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Attach to Running Session")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                Spacer()
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
            } else if sessions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                    Text("No running Claude sessions found")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                    Text("Start a session with `claude` in your terminal")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(sessions) { session in
                            sessionRow(session)
                        }
                    }
                    .padding(8)
                }
            }

            // Refresh button
            HStack {
                Button {
                    loadSessions()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Refresh")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 440, height: 380)
        .onAppear { loadSessions() }
    }

    private func sessionRow(_ session: RunningSessionInfo) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x28C840))
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.summary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Show project path
                    Text(session.projectPath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text("active \(Self.dateFormatter.string(from: session.lastModified))")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                }
            }

            Spacer()

            Button("Attach") {
                attachToSession(session)
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(hex: 0x28C840))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0x28C840).opacity(0.12))
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.cardBg(colorScheme))
        )
    }

    private func attachToSession(_ session: RunningSessionInfo) {
        // Find or create a project for this path
        let projectPath = URL(fileURLWithPath: session.projectPath, isDirectory: true)
        let projectId: UUID

        if let existing = appState.projects.first(where: { $0.path == projectPath }) {
            projectId = existing.id
        } else {
            // Create a new project for this path
            let name = projectPath.lastPathComponent
            let project = Project(
                id: UUID(),
                name: name,
                path: projectPath,
                status: .idle,
                agents: [],
                events: [],
                tokenCount: 0,
                estimatedCost: 0
            )
            appState.projects.append(project)
            projectId = project.id
        }

        appState.selectProject(projectId)
        appState.attachToSession(projectId: projectId, sessionPath: session.filePath)
    }

    private func loadSessions() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let results = SessionScanner.scanRunningSessions()
            DispatchQueue.main.async {
                sessions = results
                isLoading = false
            }
        }
    }
}

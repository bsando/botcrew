// SessionHistoryView.swift
// Botcrew

import SwiftUI

struct SessionHistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let projectId: UUID

    @State private var sessions: [SessionInfo] = []
    @State private var isLoading = true

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Session History")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
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
                Text("No past sessions found")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
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
        }
        .frame(width: 400, height: 380)
        .onAppear { loadSessions() }
    }

    private func sessionRow(_ session: SessionInfo) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.summary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(Self.dateFormatter.string(from: session.lastModified))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.35))

                    Text(formatSize(session.fileSize))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            Spacer()

            Button("Resume") {
                appState.resumeSession(projectId: projectId, sessionId: session.id)
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(hex: 0x0A84FF))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0x0A84FF).opacity(0.12))
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func loadSessions() {
        guard let project = appState.projects.first(where: { $0.id == projectId }) else {
            isLoading = false
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let results = SessionScanner.scanSessions(projectPath: project.path)
            DispatchQueue.main.async {
                sessions = results
                isLoading = false
            }
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

// FileTreeView.swift
// Botcrew

import SwiftUI

struct FileTreeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedDirs: Set<String> = []
    @State private var isInitialized = false

    private var tracker: FileActivityTracker? {
        appState.selectedFileTracker
    }

    private var projectPath: String {
        appState.selectedProject?.path.path ?? ""
    }

    private var treeNodes: [FileTreeNode] {
        guard let tracker = tracker else { return [] }
        return FileTreeNode.buildTree(from: tracker.latestTouchPerFile, projectPath: projectPath)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("FILES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Theme.textSecondary(colorScheme))

                Spacer()

                if let tracker = tracker, !tracker.touches.isEmpty {
                    Text("\(tracker.touchedFiles.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Theme.cardBg(colorScheme))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 52)
            .padding(.bottom, 8)

            // File tree
            if treeNodes.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                    Text("No file activity yet")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                    Text("Files will appear here as agents read and write them")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(treeNodes) { node in
                            FileTreeNodeRow(
                                node: node,
                                depth: 0,
                                expandedDirs: $expandedDirs
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Conflict section
            if let tracker = tracker, !tracker.conflicts.isEmpty {
                ConflictSection(conflicts: tracker.conflicts)
            }
        }
        .onChange(of: treeNodes.count) { _, _ in
            // Auto-expand directories that contain active files on first load
            if !isInitialized && !treeNodes.isEmpty {
                autoExpandAll(treeNodes)
                isInitialized = true
            }
        }
    }

    private func autoExpandAll(_ nodes: [FileTreeNode]) {
        for node in nodes where node.isDirectory {
            expandedDirs.insert(node.id)
            autoExpandAll(node.children)
        }
    }
}

// MARK: - File Tree Node Row

struct FileTreeNodeRow: View {
    let node: FileTreeNode
    let depth: Int
    @Binding var expandedDirs: Set<String>
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var isExpanded: Bool {
        expandedDirs.contains(node.id)
    }

    var body: some View {
        if node.isDirectory {
            directoryRow
            if isExpanded {
                ForEach(node.children) { child in
                    FileTreeNodeRow(
                        node: child,
                        depth: depth + 1,
                        expandedDirs: $expandedDirs
                    )
                }
            }
        } else {
            fileRow
        }
    }

    private var directoryRow: some View {
        HStack(spacing: 4) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Theme.textTertiary(colorScheme))
                .frame(width: 10)

            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: 0xFEBC2E).opacity(0.7))

            Text(node.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary(colorScheme))

            Spacer()
        }
        .padding(.leading, CGFloat(depth) * 16 + 8)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                if isExpanded {
                    expandedDirs.remove(node.id)
                } else {
                    expandedDirs.insert(node.id)
                }
            }
        }
    }

    private var fileRow: some View {
        let touch = node.touch
        let recency = touch.map { Date().timeIntervalSince($0.timestamp) } ?? 999
        let isActive = recency < 10
        let isRecent = recency < 60

        return HStack(spacing: 0) {
            // Left-edge accent bar (2px) — green for write, blue for read
            if isActive || isRecent, let action = touch?.action {
                RoundedRectangle(cornerRadius: 1)
                    .fill(action == .write ? Color(hex: 0x80e8a0) : Color(hex: 0x80c8ff))
                    .frame(width: 2)
                    .opacity(isActive ? 1.0 : 0.4)
                    .padding(.vertical, 2)
            }

            HStack(spacing: 4) {
                // File name
                Text(node.name)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(fileNameColor(isActive: isActive, isRecent: isRecent, action: touch?.action))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // File badge (action icon + agent + time)
                if let touch = touch {
                    HStack(spacing: 4) {
                        Text(touch.action == .write ? "\u{270E}" : "\u{1F441}")
                            .font(.system(size: 10))

                        Text(abbreviate(touch.agentName))
                            .font(.system(size: 10))
                            .foregroundStyle(touch.agentColor.opacity(0.8))
                            .lineLimit(1)

                        Text(relativeTime(touch.timestamp))
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textMuted(colorScheme))
                            .monospacedDigit()
                    }
                }
            }
            .padding(.leading, CGFloat(depth) * 16 + 20)
            .padding(.trailing, 8)
        }
        .frame(minHeight: 24)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(rowBackground(isActive: isActive, action: touch?.action))
        )
        .contentShape(Rectangle())
        .help(touch.map { "Click to view \($0.agentName)'s activity" } ?? "")
        .onTapGesture {
            if let touch = touch {
                appState.selectAgent(touch.agentId)
            }
        }
    }

    private func fileNameColor(isActive: Bool, isRecent: Bool, action: FileTouch.FileAction?) -> Color {
        if isActive {
            return action == .write ? Color(hex: 0x80e8a0) : Color(hex: 0x80c8ff)
        }
        if isRecent {
            return Theme.textPrimary(colorScheme)
        }
        return Theme.textSecondary(colorScheme)
    }

    private func rowBackground(isActive: Bool, action: FileTouch.FileAction?) -> Color {
        guard isActive else { return .clear }
        if action == .write {
            return Color(hex: 0x80e8a0).opacity(0.06)
        }
        return Color(hex: 0x80c8ff).opacity(0.04)
    }

    private func abbreviate(_ name: String) -> String {
        if name.count <= 8 { return name }
        // Truncate to first 6 chars
        return String(name.prefix(6)) + ".."
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "now" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}

// MARK: - Conflict Section

struct ConflictSection: View {
    let conflicts: [(filePath: String, agents: [String])]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .overlay(Color(hex: 0xFF5F57).opacity(0.15))

            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: 0xFF5F57).opacity(0.7))
                Text("CONFLICTS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Color(hex: 0xFF5F57).opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            ForEach(conflicts, id: \.filePath) { conflict in
                VStack(alignment: .leading, spacing: 2) {
                    Text(lastComponent(conflict.filePath))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary(colorScheme))

                    Text(conflict.agents.joined(separator: " + ") + " both editing")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 8)
    }

    private func lastComponent(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }
}

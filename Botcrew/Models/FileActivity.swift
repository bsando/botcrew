// FileActivity.swift
// Botcrew

import SwiftUI

/// Tracks a single file touch by an agent (read or write)
struct FileTouch: Identifiable {
    let id: UUID
    let filePath: String
    let agentId: UUID
    let agentName: String
    let agentColor: Color
    let timestamp: Date
    let action: FileAction

    enum FileAction: String {
        case read, write
    }
}

/// Tracks all file activity across agents in a project
@Observable
class FileActivityTracker {
    /// All file touches, newest first
    var touches: [FileTouch] = []

    /// Files where multiple agents have written (potential conflicts)
    var conflicts: [(filePath: String, agents: [String])] {
        // Group write touches by file path
        var writesByFile: [String: Set<String>] = [:]
        for touch in touches where touch.action == .write {
            writesByFile[touch.filePath, default: []].insert(touch.agentName)
        }
        return writesByFile
            .filter { $0.value.count > 1 }
            .map { (filePath: $0.key, agents: Array($0.value).sorted()) }
            .sorted { $0.filePath < $1.filePath }
    }

    /// Most recent touch per file (for display)
    var latestTouchPerFile: [String: FileTouch] {
        var result: [String: FileTouch] = [:]
        for touch in touches {
            if result[touch.filePath] == nil || touch.timestamp > result[touch.filePath]!.timestamp {
                result[touch.filePath] = touch
            }
        }
        return result
    }

    /// All unique file paths that have been touched, grouped into a tree structure
    var touchedFiles: [String] {
        Array(Set(touches.map(\.filePath))).sorted()
    }

    /// Record a file touch from a JSONL event
    func recordTouch(filePath: String, agentId: UUID, agentName: String, agentColor: Color, action: FileTouch.FileAction) {
        let touch = FileTouch(
            id: UUID(),
            filePath: filePath,
            agentId: agentId,
            agentName: agentName,
            agentColor: agentColor,
            timestamp: Date(),
            action: action
        )
        touches.insert(touch, at: 0)

        // Cap at 500 touches to prevent memory bloat
        if touches.count > 500 {
            touches = Array(touches.prefix(500))
        }
    }

    /// Clear all activity (e.g. on project switch)
    func clear() {
        touches.removeAll()
    }

    /// Time since the most recent touch for a file
    func recency(for filePath: String) -> TimeInterval? {
        guard let touch = latestTouchPerFile[filePath] else { return nil }
        return Date().timeIntervalSince(touch.timestamp)
    }
}

/// Represents a node in the file tree (either a directory or file)
struct FileTreeNode: Identifiable {
    let id: String // full path
    let name: String
    let isDirectory: Bool
    var children: [FileTreeNode]
    var touch: FileTouch? // latest touch (files only)

    /// Build a tree from a list of file paths with their latest touches
    static func buildTree(from touches: [String: FileTouch], projectPath: String) -> [FileTreeNode] {
        var root: [String: FileTreeNode] = [:]

        for (fullPath, touch) in touches {
            // Make path relative to project
            let relativePath = fullPath.hasPrefix(projectPath)
                ? String(fullPath.dropFirst(projectPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                : fullPath

            let components = relativePath.split(separator: "/").map(String.init)
            guard !components.isEmpty else { continue }

            insertIntoTree(root: &root, components: components, fullPath: fullPath, touch: touch, depth: 0)
        }

        return sortedNodes(from: root)
    }

    private static func insertIntoTree(root: inout [String: FileTreeNode], components: [String], fullPath: String, touch: FileTouch, depth: Int) {
        guard depth < components.count else { return }
        let name = components[depth]
        let isLast = depth == components.count - 1
        let pathKey = components[0...depth].joined(separator: "/")

        if isLast {
            // File node
            root[pathKey] = FileTreeNode(id: fullPath, name: name, isDirectory: false, children: [], touch: touch)
        } else {
            // Directory node
            if root[pathKey] == nil {
                root[pathKey] = FileTreeNode(id: pathKey, name: name, isDirectory: true, children: [], touch: nil)
            }
            var children = childrenDict(from: root[pathKey]!.children)
            insertIntoTree(root: &children, components: components, fullPath: fullPath, touch: touch, depth: depth + 1)
            root[pathKey]!.children = sortedNodes(from: children)
        }
    }

    private static func childrenDict(from nodes: [FileTreeNode]) -> [String: FileTreeNode] {
        var dict: [String: FileTreeNode] = [:]
        for node in nodes {
            dict[node.name] = node
        }
        return dict
    }

    private static func sortedNodes(from dict: [String: FileTreeNode]) -> [FileTreeNode] {
        dict.values.sorted { a, b in
            // Directories first, then alphabetical
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}

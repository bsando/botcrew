// JSONLWatcher.swift
// Botcrew

import Foundation

/// Watches Claude Code JSONL transcript files for changes using DispatchSource.
/// Tails new lines as they're appended and emits parsed events.
@Observable
class JSONLWatcher {
    private(set) var isWatching = false

    private var fileSources: [String: DispatchSourceFileSystemObject] = [:]
    private var fileOffsets: [String: UInt64] = [:]
    private var directorySource: DispatchSourceFileSystemObject?

    /// Callback for new JSONL events. (filePath, event)
    var onEvent: ((String, JSONLEvent) -> Void)?

    /// Callback when a new subagent JSONL file appears
    var onNewSubagent: ((String) -> Void)?

    // MARK: - Watch a session JSONL file

    /// Start watching a specific JSONL file for new lines
    func watchFile(at path: String) {
        guard fileSources[path] == nil else { return }
        guard FileManager.default.fileExists(atPath: path) else { return }

        guard let fh = FileHandle(forReadingAtPath: path) else { return }

        // Seek to end — only read new content
        let endOffset = fh.seekToEndOfFile()
        fileOffsets[path] = endOffset
        fh.closeFile()

        let fd = open(path, O_RDONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.readNewLines(from: path, fd: fd)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileSources[path] = source
        isWatching = !fileSources.isEmpty
    }

    /// Stop watching a specific file
    func unwatchFile(at path: String) {
        fileSources[path]?.cancel()
        fileSources.removeValue(forKey: path)
        fileOffsets.removeValue(forKey: path)
        isWatching = !fileSources.isEmpty
    }

    // MARK: - Watch a session directory for new subagent files

    /// Watch a session's subagents directory for new JSONL files
    func watchSubagentDirectory(at dirPath: String) {
        let subagentsPath = (dirPath as NSString).deletingPathExtension + "/subagents"

        // Create the directory if it doesn't exist (Claude Code creates it on demand)
        try? FileManager.default.createDirectory(
            atPath: subagentsPath,
            withIntermediateDirectories: true
        )

        let fd = open(subagentsPath, O_RDONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.scanForNewSubagents(in: subagentsPath)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        directorySource = source
    }

    /// Stop all watching
    func stopAll() {
        for (_, source) in fileSources {
            source.cancel()
        }
        fileSources.removeAll()
        fileOffsets.removeAll()
        directorySource?.cancel()
        directorySource = nil
        isWatching = false
    }

    // MARK: - Private

    private func readNewLines(from path: String, fd: Int32) {
        guard let lastOffset = fileOffsets[path] else { return }
        guard let fh = FileHandle(forReadingAtPath: path) else { return }

        fh.seek(toFileOffset: lastOffset)
        let data = fh.readDataToEndOfFile()
        let newOffset = fh.offsetInFile
        fh.closeFile()

        guard newOffset > lastOffset else { return }
        fileOffsets[path] = newOffset

        guard let text = String(data: data, encoding: .utf8) else { return }

        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if let event = AgentStateParser.parseJSONLLine(trimmed) {
                onEvent?(path, event)
            }
        }
    }

    private func scanForNewSubagents(in dirPath: String) {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dirPath) else { return }
        for file in files where file.hasSuffix(".jsonl") {
            let fullPath = (dirPath as NSString).appendingPathComponent(file)
            if fileSources[fullPath] == nil {
                onNewSubagent?(fullPath)
                watchFile(at: fullPath)
            }
        }
    }

    // MARK: - JSONL Path Helpers

    /// Get the Claude projects base directory
    static var claudeProjectsDir: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/projects"
    }

    /// Convert a project path to its Claude hash directory name
    /// e.g. /Users/brian/botcrew → -Users-brian-botcrew
    static func projectHash(for projectPath: String) -> String {
        return projectPath.replacingOccurrences(of: "/", with: "-")
    }

    /// Find the most recent JSONL session file for a project path
    static func findLatestSession(for projectPath: String) -> String? {
        let hash = projectHash(for: projectPath)
        let dir = "\(claudeProjectsDir)/\(hash)"

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else {
            return nil
        }

        let jsonlFiles = files
            .filter { $0.hasSuffix(".jsonl") }
            .map { (dir as NSString).appendingPathComponent($0) }
            .sorted { path1, path2 in
                let attr1 = try? FileManager.default.attributesOfItem(atPath: path1)
                let attr2 = try? FileManager.default.attributesOfItem(atPath: path2)
                let date1 = attr1?[.modificationDate] as? Date ?? .distantPast
                let date2 = attr2?[.modificationDate] as? Date ?? .distantPast
                return date1 > date2
            }

        return jsonlFiles.first
    }

    /// Read all existing events from a JSONL file (for initial load)
    static func readAllEvents(from path: String) -> [JSONLEvent] {
        guard let data = FileManager.default.contents(atPath: path),
              let text = String(data: data, encoding: .utf8) else {
            return []
        }

        return text.components(separatedBy: .newlines)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }
                return AgentStateParser.parseJSONLLine(trimmed)
            }
    }
}

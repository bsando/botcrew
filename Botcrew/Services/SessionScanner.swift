// SessionScanner.swift
// Botcrew

import Foundation

enum SessionScanner {
    /// Scan for past Claude Code sessions for a project
    static func scanSessions(projectPath: URL) -> [SessionInfo] {
        let hash = JSONLWatcher.projectHash(for: projectPath.path)
        let dirPath = "\(JSONLWatcher.claudeProjectsDir)/\(hash)"
        let projectDir = URL(fileURLWithPath: dirPath, isDirectory: true)

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: dirPath) else {
            return []
        }

        let jsonlFiles = contents
            .filter { $0.hasSuffix(".jsonl") }
            .map { projectDir.appendingPathComponent($0) }

        return jsonlFiles.compactMap { fileURL -> SessionInfo? in
            let sessionId = fileURL.deletingPathExtension().lastPathComponent

            // Get file attributes
            guard let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                  let modDate = attrs[.modificationDate] as? Date,
                  let fileSize = attrs[.size] as? Int64 else {
                return nil
            }

            // Parse first few lines for summary and start date
            let (summary, startDate) = parseSessionHead(fileURL)

            return SessionInfo(
                id: sessionId,
                filePath: fileURL.path,
                startDate: startDate ?? modDate,
                lastModified: modDate,
                summary: summary ?? "Untitled session",
                fileSize: fileSize
            )
        }
        .sorted { $0.lastModified > $1.lastModified }
    }

    /// Scan ALL Claude Code projects for actively running sessions (recently modified JSONL files)
    static func scanRunningSessions(recencyThreshold: TimeInterval = 60) -> [RunningSessionInfo] {
        let baseDir = JSONLWatcher.claudeProjectsDir
        let fm = FileManager.default

        guard let projectDirs = try? fm.contentsOfDirectory(atPath: baseDir) else {
            return []
        }

        var results: [RunningSessionInfo] = []

        for hash in projectDirs {
            let dirPath = (baseDir as NSString).appendingPathComponent(hash)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dirPath, isDirectory: &isDir), isDir.boolValue else { continue }

            guard let files = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }
            let jsonlFiles = files.filter { $0.hasSuffix(".jsonl") }

            for file in jsonlFiles {
                let filePath = (dirPath as NSString).appendingPathComponent(file)
                guard let attrs = try? fm.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date,
                      Date().timeIntervalSince(modDate) < recencyThreshold else { continue }

                let sessionId = (file as NSString).deletingPathExtension
                let fileURL = URL(fileURLWithPath: filePath)

                // Reverse-map hash to project path: "-Users-brian-project" → "/Users/brian/project"
                // The hash replaces all "/" with "-", so reverse by replacing "-" with "/"
                // then validate the path exists
                let reversedPath = "/" + hash.dropFirst().replacingOccurrences(of: "-", with: "/")

                // Validate: check if the reversed path exists as a directory
                let projectPath: String
                if fm.fileExists(atPath: reversedPath, isDirectory: &isDir), isDir.boolValue {
                    projectPath = reversedPath
                } else {
                    projectPath = reversedPath  // best guess, user can confirm
                }

                let (summary, _) = parseSessionHead(fileURL)

                results.append(RunningSessionInfo(
                    id: sessionId,
                    filePath: filePath,
                    projectHash: hash,
                    projectPath: projectPath,
                    summary: summary ?? "Untitled session",
                    lastModified: modDate
                ))
            }
        }

        return results.sorted { $0.lastModified > $1.lastModified }
    }

    /// Parse the first few lines of a JSONL file to extract the first user prompt and timestamp
    private static func parseSessionHead(_ fileURL: URL) -> (summary: String?, startDate: Date?) {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else { return (nil, nil) }
        defer { handle.closeFile() }

        // Read first 8KB — enough for a few events
        let data = handle.readData(ofLength: 8192)
        guard let text = String(data: data, encoding: .utf8) else { return (nil, nil) }

        var summary: String?
        var startDate: Date?
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in text.components(separatedBy: .newlines).prefix(10) {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            // Get timestamp from first event
            if startDate == nil, let ts = json["timestamp"] as? String {
                startDate = formatter.date(from: ts)
            }

            // Get first user message content for summary
            if summary == nil,
               let type = json["type"] as? String, type == "user",
               let message = json["message"] as? [String: Any],
               let content = message["content"] as? String {
                summary = String(content.prefix(100))
            }

            // Also check for content array format
            if summary == nil,
               let type = json["type"] as? String, type == "user",
               let message = json["message"] as? [String: Any],
               let contentArray = message["content"] as? [[String: Any]] {
                for item in contentArray {
                    if let text = item["text"] as? String {
                        summary = String(text.prefix(100))
                        break
                    }
                }
            }

            if summary != nil && startDate != nil { break }
        }

        return (summary, startDate)
    }
}

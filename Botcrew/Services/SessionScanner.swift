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

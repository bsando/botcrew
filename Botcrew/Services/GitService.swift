// GitService.swift
// Botcrew

import Foundation

enum GitService {
    /// Run a git command and return stdout
    private static func run(_ args: [String], at path: URL) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        proc.arguments = args
        proc.currentDirectoryURL = path

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()

        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    /// Check if path is a git repo
    static func isGitRepo(at path: URL) -> Bool {
        let result = run(["rev-parse", "--is-inside-work-tree"], at: path)
        return result == "true"
    }

    /// Get current branch and changed files
    static func status(at path: URL) -> GitInfo {
        var info = GitInfo()

        // Branch
        if let branch = run(["rev-parse", "--abbrev-ref", "HEAD"], at: path) {
            info.branch = branch
        }

        // Status
        if let output = run(["status", "--porcelain"], at: path) {
            info.changes = output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { line in
                    let status = String(line.prefix(2)).trimmingCharacters(in: .whitespaces)
                    let file = String(line.dropFirst(3))
                    return GitFileChange(status: status, filePath: file)
                }
        }

        return info
    }

    /// Get diff for a specific file or all changes
    static func diff(at path: URL, file: String? = nil) -> String {
        var args = ["diff"]
        if let file = file {
            args.append(file)
        }
        return run(args, at: path) ?? ""
    }

    /// Stage files and commit
    static func commit(at path: URL, message: String, files: [String]) -> (success: Bool, output: String) {
        // Stage specific files
        for file in files {
            _ = run(["add", file], at: path)
        }

        // Commit
        let result = run(["commit", "-m", message], at: path)
        let success = result?.contains("file changed") == true ||
                      result?.contains("files changed") == true ||
                      result?.contains("insertions") == true
        return (success, result ?? "Commit failed")
    }
}

// ClaudeCodeProcess.swift
// Botcrew

import Foundation

/// Wraps a Foundation.Process that runs the `claude` CLI.
/// Captures stdout into a ring buffer for the terminal view.
@Observable
class ClaudeCodeProcess: Identifiable {
    let id: UUID
    let projectPath: URL
    let prompt: String

    private(set) var isRunning = false
    private(set) var sessionId: String?
    private(set) var ringBuffer: [String] = []
    private(set) var exitCode: Int32?

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private let bufferCapacity = 2000

    /// Path to the claude CLI
    private static let claudePath: String = {
        // Check common locations
        let candidates = [
            "/Users/\(NSUserName())/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return "claude" // fallback, rely on PATH
    }()

    init(id: UUID = UUID(), projectPath: URL, prompt: String) {
        self.id = id
        self.projectPath = projectPath
        self.prompt = prompt
    }

    /// Launch the claude process
    func start() {
        guard !isRunning else { return }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-l", "-c", "\(Self.claudePath) --print \"\(prompt.replacingOccurrences(of: "\"", with: "\\\""))\""]
        proc.currentDirectoryURL = projectPath

        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardOutput = stdout
        proc.standardError = stderr

        self.stdoutPipe = stdout
        self.stderrPipe = stderr
        self.process = proc

        // Read stdout asynchronously
        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let text = String(data: data, encoding: .utf8) {
                let lines = text.components(separatedBy: .newlines)
                DispatchQueue.main.async {
                    self.appendToBuffer(lines)
                }
            }
        }

        // Read stderr too (claude outputs progress on stderr)
        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let text = String(data: data, encoding: .utf8) {
                let lines = text.components(separatedBy: .newlines)
                DispatchQueue.main.async {
                    self.appendToBuffer(lines)
                }
            }
        }

        proc.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.exitCode = proc.terminationStatus
                self?.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self?.stderrPipe?.fileHandleForReading.readabilityHandler = nil
            }
        }

        do {
            try proc.run()
            isRunning = true
            appendToBuffer(["$ claude --print \"\(prompt)\"", ""])
        } catch {
            appendToBuffer(["Error launching claude: \(error.localizedDescription)"])
            isRunning = false
        }
    }

    /// Stop the running process
    func stop() {
        guard isRunning, let proc = process, proc.isRunning else { return }
        proc.terminate()
    }

    /// Get the full terminal output as a single string
    var terminalOutput: String {
        ringBuffer.joined(separator: "\n")
    }

    private func appendToBuffer(_ lines: [String]) {
        ringBuffer.append(contentsOf: lines.filter { !$0.isEmpty })
        // Trim to capacity
        if ringBuffer.count > bufferCapacity {
            ringBuffer.removeFirst(ringBuffer.count - bufferCapacity)
        }
    }
}

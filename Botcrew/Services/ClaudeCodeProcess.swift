// ClaudeCodeProcess.swift
// Botcrew

import Foundation

/// Wraps a Foundation.Process that runs the `claude` CLI.
/// Captures stdout into a ring buffer for the terminal view.
/// Parses stream-json events for structured output and permission denials.
@Observable
class ClaudeCodeProcess: Identifiable {
    let id: UUID
    let projectPath: URL

    private(set) var isRunning = false
    private(set) var exitCode: Int32?
    private(set) var hasRanBefore = false
    private(set) var lastSessionId: String?
    private(set) var lastPermissionDenials: [[String: Any]] = []

    /// Terminal output snapshot — updated at most every 200ms
    private(set) var terminalOutput: String = ""

    /// Callback when permission denials are detected
    var onPermissionDenials: ((_ sessionId: String, _ denials: [[String: Any]]) -> Void)?

    /// Callback when a structured event is received
    var onStreamEvent: ((_ event: [String: Any]) -> Void)?

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private let bufferCapacity = 2000

    // Ring buffer internals — NOT observed (mutations don't trigger SwiftUI updates)
    private var _ringBuffer: [String] = []
    private var _bufferDirty = false
    private var _flushTimer: Timer?

    /// Path to the claude CLI
    static let claudePath: String = {
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
        return "claude"
    }()

    init(id: UUID = UUID(), projectPath: URL) {
        self.id = id
        self.projectPath = projectPath
    }

    /// Launch claude with a prompt
    func send(
        prompt: String,
        isContinuation: Bool = false,
        permissionMode: String = "default",
        allowedTools: [String]? = nil,
        resumeSessionId: String? = nil
    ) {
        guard !isRunning else { return }

        let escapedPrompt = prompt.replacingOccurrences(of: "\"", with: "\\\"")
        var args = "--print --output-format stream-json --verbose"

        if let sessionId = resumeSessionId {
            args += " --resume \(sessionId)"
        } else if isContinuation {
            args += " --continue"
        }

        // Permission flags
        switch permissionMode {
        case "auto":
            args += " --dangerously-skip-permissions"
        case "safe":
            args += " --allowedTools \"Read Glob Grep LSP\""
        default: // "supervised"
            args += " --permission-mode default"
        }

        // Additional allowed tools (for re-running after approval)
        if let tools = allowedTools, !tools.isEmpty {
            args += " --allowedTools \"\(tools.joined(separator: " "))\""
        }

        let command = "\(Self.claudePath) \(args) \"\(escapedPrompt)\""

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-l", "-c", command]
        proc.currentDirectoryURL = projectPath

        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardOutput = stdout
        proc.standardError = stderr

        self.stdoutPipe = stdout
        self.stderrPipe = stderr
        self.process = proc
        self.lastPermissionDenials = []

        // Start throttled flush timer
        startFlushTimer()

        // Parse stream-json from stdout
        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.processStreamJSON(text)
                }
            }
        }

        // Stderr for progress info
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
                self?.hasRanBefore = true
                self?.exitCode = proc.terminationStatus
                self?.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self?.stderrPipe?.fileHandleForReading.readabilityHandler = nil
                self?.flushBuffer() // Final flush
                self?._flushTimer?.invalidate()
                self?._flushTimer = nil
            }
        }

        do {
            try proc.run()
            isRunning = true
            let modeLabel = isContinuation ? " --continue" : ""
            appendToBuffer(["", "$ claude\(modeLabel) \"\(prompt)\"", ""])
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

    // MARK: - Throttled buffer flush

    private func startFlushTimer() {
        _flushTimer?.invalidate()
        _flushTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.flushBuffer()
        }
    }

    /// Push ring buffer contents to the observed terminalOutput property
    private func flushBuffer() {
        guard _bufferDirty else { return }
        _bufferDirty = false
        terminalOutput = _ringBuffer.joined(separator: "\n")
    }

    // MARK: - Stream JSON parsing

    private var jsonLineBuffer = ""

    private func processStreamJSON(_ text: String) {
        jsonLineBuffer += text
        let lines = jsonLineBuffer.components(separatedBy: "\n")
        // Keep the last incomplete line in the buffer
        jsonLineBuffer = lines.last ?? ""

        for line in lines.dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard let data = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                appendToBuffer([trimmed])
                continue
            }

            let eventType = json["type"] as? String ?? ""
            onStreamEvent?(json)

            switch eventType {
            case "system":
                if let sessionId = json["session_id"] as? String {
                    lastSessionId = sessionId
                }

            case "assistant":
                if let message = json["message"] as? [String: Any],
                   let content = message["content"] as? [[String: Any]] {
                    for item in content {
                        let itemType = item["type"] as? String ?? ""
                        if itemType == "text", let text = item["text"] as? String {
                            appendToBuffer(text.components(separatedBy: .newlines))
                        } else if itemType == "tool_use" {
                            let name = item["name"] as? String ?? "?"
                            let input = item["input"] as? [String: Any] ?? [:]
                            let summary = toolUseSummary(name: name, input: input)
                            appendToBuffer(["", "[\(name)] \(summary)"])
                        }
                    }
                }

            case "result":
                if let denials = json["permission_denials"] as? [[String: Any]], !denials.isEmpty {
                    lastPermissionDenials = denials
                    if let sessionId = json["session_id"] as? String {
                        onPermissionDenials?(sessionId, denials)
                    }
                }

            default:
                break
            }
        }
    }

    private func toolUseSummary(name: String, input: [String: Any]) -> String {
        switch name {
        case "Read":
            return input["file_path"] as? String ?? ""
        case "Write":
            return input["file_path"] as? String ?? ""
        case "Edit":
            return input["file_path"] as? String ?? ""
        case "Bash":
            let cmd = input["command"] as? String ?? ""
            return cmd.count > 60 ? String(cmd.prefix(60)) + "..." : cmd
        case "Glob":
            return input["pattern"] as? String ?? ""
        case "Grep":
            return input["pattern"] as? String ?? ""
        default:
            return ""
        }
    }

    private func appendToBuffer(_ lines: [String]) {
        _ringBuffer.append(contentsOf: lines.filter { !$0.isEmpty })
        if _ringBuffer.count > bufferCapacity {
            _ringBuffer.removeFirst(_ringBuffer.count - bufferCapacity)
        }
        _bufferDirty = true
    }
}

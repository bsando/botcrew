// ClaudeCodeProcess.swift
// Botcrew

import Foundation

/// Wraps a Foundation.Process that runs the `claude` CLI.
/// Parses stream-json events into structured terminal entries.
@Observable
class ClaudeCodeProcess: Identifiable {
    let id: UUID
    let projectPath: URL

    private(set) var isRunning = false
    private(set) var exitCode: Int32?
    private(set) var hasRanBefore = false
    private(set) var lastSessionId: String?
    private(set) var lastPermissionDenials: [[String: Any]] = []

    /// Structured terminal entries — the primary display model
    private(set) var terminalEntries: [TerminalEntry] = []

    /// Legacy plain-text output (joined from entries for compatibility)
    private(set) var terminalOutput: String = ""

    /// Whether Claude is currently generating a response
    private(set) var isThinking = false

    /// Callback when permission denials are detected
    var onPermissionDenials: ((_ sessionId: String, _ denials: [[String: Any]]) -> Void)?

    /// Callback when a structured event is received
    var onStreamEvent: ((_ event: [String: Any]) -> Void)?

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private let maxEntries = 500

    // Throttled update internals
    private var _pendingEntries: [TerminalEntry] = []
    private var _dirty = false
    private var _flushTimer: Timer?

    // Accumulate assistant text within a single message
    private var _currentAssistantText: String = ""

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
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                DispatchQueue.main.async {
                    for line in lines {
                        self.addEntry(.init(kind: .raw(line)))
                    }
                }
            }
        }

        proc.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.finalizeAssistantText()
                self?.isRunning = false
                self?.isThinking = false
                self?.hasRanBefore = true
                self?.exitCode = proc.terminationStatus
                self?.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self?.stderrPipe?.fileHandleForReading.readabilityHandler = nil
                self?.flushEntries()
                self?._flushTimer?.invalidate()
                self?._flushTimer = nil
            }
        }

        do {
            try proc.run()
            isRunning = true
            // Add user prompt entry
            addEntry(.init(kind: .userPrompt(prompt)))
            isThinking = true
        } catch {
            addEntry(.init(kind: .error("Error launching claude: \(error.localizedDescription)")))
            isRunning = false
        }
    }

    /// Stop the running process
    func stop() {
        guard isRunning, let proc = process, proc.isRunning else { return }
        proc.terminate()
    }

    // MARK: - Throttled entry flush

    private func startFlushTimer() {
        _flushTimer?.invalidate()
        _flushTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.flushEntries()
        }
    }

    private func flushEntries() {
        guard _dirty else { return }
        _dirty = false
        terminalEntries = _pendingEntries
        rebuildPlainText()
    }

    private func addEntry(_ entry: TerminalEntry) {
        _pendingEntries.append(entry)
        if _pendingEntries.count > maxEntries {
            _pendingEntries.removeFirst(_pendingEntries.count - maxEntries)
        }
        _dirty = true
    }

    /// Replace the last entry if it matches a predicate, or append
    private func replaceLastOrAdd(_ entry: TerminalEntry, where predicate: (TerminalEntry) -> Bool) {
        if let lastIdx = _pendingEntries.lastIndex(where: predicate) {
            _pendingEntries[lastIdx] = entry
        } else {
            _pendingEntries.append(entry)
        }
        _dirty = true
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
                addEntry(.init(kind: .raw(trimmed)))
                continue
            }

            let eventType = json["type"] as? String ?? ""
            onStreamEvent?(json)

            switch eventType {
            case "system":
                if let sessionId = json["session_id"] as? String {
                    lastSessionId = sessionId
                }

            case "user":
                // User messages from continuation/resume
                if let message = json["message"] as? [String: Any] {
                    if let content = message["content"] as? String, !content.isEmpty {
                        addEntry(.init(kind: .userPrompt(content)))
                        isThinking = true
                    } else if let contentArr = message["content"] as? [[String: Any]] {
                        for item in contentArr {
                            if item["type"] as? String == "text",
                               let text = item["text"] as? String, !text.isEmpty {
                                addEntry(.init(kind: .userPrompt(text)))
                                isThinking = true
                            }
                        }
                    }
                }

            case "assistant":
                isThinking = false
                if let message = json["message"] as? [String: Any],
                   let content = message["content"] as? [[String: Any]] {
                    for item in content {
                        let itemType = item["type"] as? String ?? ""
                        if itemType == "text", let text = item["text"] as? String {
                            // Accumulate text into current assistant message
                            _currentAssistantText += text
                            // Update or add the assistant text entry
                            let entry = TerminalEntry(kind: .assistantText(_currentAssistantText))
                            replaceLastOrAdd(entry) { e in
                                if case .assistantText = e.kind { return true }
                                return false
                            }
                        } else if itemType == "tool_use" {
                            // Finalize any pending assistant text before tool use
                            finalizeAssistantText()
                            let name = item["name"] as? String ?? "?"
                            let input = item["input"] as? [String: Any] ?? [:]
                            let summary = toolUseSummary(name: name, input: input)
                            addEntry(.init(kind: .toolUse(name: name, summary: summary)))
                            // Claude will be "thinking" again after tool use
                            isThinking = true
                        }
                    }
                }

            case "result":
                isThinking = false
                finalizeAssistantText()
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

    /// Finalize accumulated assistant text so a new message can start
    private func finalizeAssistantText() {
        if !_currentAssistantText.isEmpty {
            _currentAssistantText = ""
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
            return cmd.count > 80 ? String(cmd.prefix(80)) + "..." : cmd
        case "Glob":
            return input["pattern"] as? String ?? ""
        case "Grep":
            return input["pattern"] as? String ?? ""
        case "Agent", "Task":
            return input["description"] as? String ?? input["prompt"] as? String ?? ""
        default:
            return ""
        }
    }

    // MARK: - Legacy plain text

    private func rebuildPlainText() {
        terminalOutput = terminalEntries.map { entry in
            switch entry.kind {
            case .userPrompt(let text):
                return "\n> \(text)\n"
            case .thinking:
                return "  Thinking..."
            case .assistantText(let text):
                return text
            case .toolUse(let name, let summary):
                return "  [\(name)] \(summary)"
            case .toolResult(_, let output):
                return "  \(output)"
            case .system(let text):
                return "  \(text)"
            case .error(let text):
                return "  Error: \(text)"
            case .raw(let text):
                return text
            }
        }.joined(separator: "\n")
    }

    // MARK: - Public helpers

    /// Inject text into the terminal (for command output, etc.)
    func appendOutput(_ lines: [String]) {
        for line in lines where !line.isEmpty {
            addEntry(.init(kind: .raw(line)))
        }
        flushEntries()
    }

    /// Clear the terminal
    func clearBuffer() {
        _pendingEntries.removeAll()
        _dirty = true
        flushEntries()
    }
}

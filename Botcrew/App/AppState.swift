// AppState.swift
// Botcrew

import SwiftUI

@Observable
class AppState {
    var projects: [Project] = []
    var selectedProjectId: UUID?
    var selectedAgentId: UUID?
    var activeClusterId: UUID?
    var openTerminalIds: [UUID] = []
    var isSidebarCollapsed = false
    var showAddProjectSheet = false
    var showTerminal = false
    var focusPromptInput = false
    var officePanelHeight: CGFloat = 148 // snap: 26 (collapsed), 148 (ambient), 270 (expanded)
    static let zoomStep: CGFloat = 80 // pixels per step

    // MARK: - File Activity Tracking
    var fileTrackers: [UUID: FileActivityTracker] = [:]  // projectId → tracker

    /// Get or create the file tracker for a project
    func fileTracker(for projectId: UUID) -> FileActivityTracker {
        if let existing = fileTrackers[projectId] { return existing }
        let tracker = FileActivityTracker()
        fileTrackers[projectId] = tracker
        return tracker
    }

    /// File tracker for the currently selected project
    var selectedFileTracker: FileActivityTracker? {
        guard let id = selectedProjectId else { return nil }
        return fileTrackers[id]
    }

    // MARK: - Cross-Agent Feed Mode
    var showAllAgentsFeed = false

    /// Events across all agents in the selected project (for cross-agent mode)
    var eventsForAllAgents: [ActivityEvent] {
        guard let project = selectedProject else { return [] }
        return project.events.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Panel Visibility
    var showAgentTree = true
    var showFileTree = true

    // MARK: - Office Panel Easter Egg
    var showOfficePanel = false

    init(skipPersistence: Bool = false) {
        if !skipPersistence {
            loadState()
            // Restore sessions after a short delay to let UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.restoreSessions()
            }
        }
    }

    func zoomIn() {
        resizeWindow(by: Self.zoomStep)
    }

    func zoomOut() {
        resizeWindow(by: -Self.zoomStep)
    }

    func zoomReset() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSApplication.shared.windows.first else { return }
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let newFrame = NSRect(
            x: (screen.visibleFrame.width - 900) / 2 + screen.visibleFrame.origin.x,
            y: (screen.visibleFrame.height - 640) / 2 + screen.visibleFrame.origin.y,
            width: 1100,
            height: 700
        )
        window.setFrame(newFrame, display: true, animate: true)
    }

    private func resizeWindow(by delta: CGFloat) {
        guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSApplication.shared.windows.first else { return }
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let maxFrame = screen.visibleFrame

        let aspectRatio: CGFloat = 1100.0 / 700.0
        let deltaH = delta / aspectRatio

        var newFrame = window.frame
        newFrame.size.width = max(1100, min(maxFrame.width, newFrame.size.width + delta))
        newFrame.size.height = max(700, min(maxFrame.height, newFrame.size.height + deltaH))
        // Keep centered by adjusting origin
        newFrame.origin.x -= (newFrame.size.width - window.frame.size.width) / 2
        newFrame.origin.y -= (newFrame.size.height - window.frame.size.height) / 2
        // Clamp to screen bounds
        newFrame.origin.x = max(maxFrame.origin.x, min(maxFrame.maxX - newFrame.size.width, newFrame.origin.x))
        newFrame.origin.y = max(maxFrame.origin.y, min(maxFrame.maxY - newFrame.size.height, newFrame.origin.y))

        window.setFrame(newFrame, display: true, animate: true)
    }

    // MARK: - Permission Mode

    enum PermissionMode: String, CaseIterable, Codable {
        case auto       // --dangerously-skip-permissions (auto-approve everything)
        case supervised // --permission-mode default (deny dangerous tools, show approval)
        case safe       // --allowedTools "Read Glob Grep LSP" (read-only)

        var label: String {
            switch self {
            case .auto: "Auto"
            case .supervised: "Supervised"
            case .safe: "Safe"
            }
        }

        var description: String {
            switch self {
            case .auto: "Auto-approve all tools"
            case .supervised: "Review writes & commands"
            case .safe: "Read-only, no changes"
            }
        }
    }

    var permissionMode: PermissionMode = .supervised

    /// Pending tool approval for the selected project
    var pendingApproval: ToolApproval?

    // MARK: - Prompt Templates
    var promptTemplates: [PromptTemplate] = []
    var showTemplateSheet = false

    // MARK: - Cost Tracking
    var costHistory: [CostRecord] = []
    var showCostDashboard = false

    // MARK: - Session History
    var showSessionHistory = false

    // MARK: - Attach Mode
    var showAttachSheet = false
    private var attachTimers: [UUID: Timer] = [:]  // projectId → stale-check timer

    // MARK: - Git
    var showGitPanel = false

    // MARK: - Sound Notifications
    var soundEnabled = true

    // MARK: - Rate Limit (account-level, transient)
    var rateLimitInfo: RateLimitInfo?

    func resumeSession(projectId: UUID, sessionId: String) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let project = projects[idx]

        // Create root agent for the resumed session
        let rootAgent = Agent(
            id: UUID(),
            name: "claude",
            parentId: nil,
            status: .reading,
            bodyColor: Color(hex: 0xc0a8ff),
            shirtColor: Color(hex: 0x5030a0),
            spawnTime: Date()
        )
        projects[idx].agents.append(rootAgent)
        projects[idx].status = .active
        projects[idx].events.append(ActivityEvent(
            id: UUID(), agentId: rootAgent.id, timestamp: Date(),
            type: .spawn, meta: "Resumed session"
        ))
        selectAgent(rootAgent.id)

        // Launch process with --resume
        let proc = ClaudeCodeProcess(projectPath: project.path)
        proc.onPermissionDenials = { [weak self] sid, denials in
            self?.handlePermissionDenials(projectId: projectId, sessionId: sid, denials: denials)
        }
        proc.onStreamEvent = { [weak self] event in
            self?.handleStreamEvent(event, projectId: projectId)
        }
        processes[projectId] = proc
        proc.send(prompt: "continue where you left off", isContinuation: false, permissionMode: permissionMode.rawValue, resumeSessionId: sessionId)
        showTerminal = true
    }

    func recordCost(projectId: UUID, cost: Double, inputTokens: Int, outputTokens: Int, model: String?) {
        let record = CostRecord(
            id: UUID(), projectId: projectId, date: Date(),
            cost: cost, inputTokens: inputTokens, outputTokens: outputTokens, model: model
        )
        costHistory.append(record)
        // Also update project totals
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            projects[idx].tokenCount += inputTokens + outputTokens
            projects[idx].estimatedCost += cost
        }
        saveState()
    }

    func saveTemplate(name: String, prompt: String, category: TemplateCategory) {
        let template = PromptTemplate(
            id: UUID(), name: name, prompt: prompt,
            category: category, isBuiltIn: false
        )
        promptTemplates.append(template)
        saveState()
    }

    func deleteTemplate(_ id: UUID) {
        promptTemplates.removeAll { $0.id == id }
        saveState()
    }

    // MARK: - Process Management (Phase 6)
    var processes: [UUID: ClaudeCodeProcess] = [:]  // projectId → process
    var watchers: [UUID: JSONLWatcher] = [:]        // projectId → watcher
    private var idleTimers: [UUID: Timer] = [:]      // agentId → idle timer
    private var agentSessionMap: [String: UUID] = [:]  // JSONL path → agentId

    enum OfficePanelSnap: CGFloat {
        case collapsed = 26
        case ambient = 148
        case expanded = 270
    }

    var officePanelSnap: OfficePanelSnap {
        if officePanelHeight <= 60 { return .collapsed }
        if officePanelHeight >= 220 { return .expanded }
        return .ambient
    }

    func snapOfficePanel(to snap: OfficePanelSnap) {
        officePanelHeight = snap.rawValue
    }

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectId }
    }

    var selectedAgent: Agent? {
        selectedProject?.agents.first { $0.id == selectedAgentId }
    }

    var eventsForSelectedAgent: [ActivityEvent] {
        guard let project = selectedProject, let agentId = selectedAgentId else { return [] }
        return project.events
            .filter { $0.agentId == agentId }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var rootAgents: [Agent] {
        selectedProject?.agents.filter { $0.parentId == nil } ?? []
    }

    func subAgents(for rootId: UUID) -> [Agent] {
        selectedProject?.agents.filter { $0.parentId == rootId } ?? []
    }

    func selectAgent(_ id: UUID) {
        guard let project = selectedProject,
              let agent = project.agents.first(where: { $0.id == id }) else { return }
        selectedAgentId = id
        // If selecting a sub-agent, expand its parent cluster
        // If selecting a root agent, expand that cluster
        activeClusterId = agent.parentId ?? agent.id
    }

    func toggleCluster(_ rootId: UUID) {
        if activeClusterId == rootId {
            // Collapse: deselect sub-agents, keep root selected
            activeClusterId = nil
            if let agent = selectedAgent, agent.parentId == rootId {
                selectedAgentId = rootId
            }
        } else {
            activeClusterId = rootId
            selectedAgentId = rootId
        }
    }

    func selectProject(_ id: UUID) {
        selectedProjectId = id
        selectedAgentId = nil
        activeClusterId = nil
        openTerminalIds = []
    }

    func removeProject(_ id: UUID) {
        // Clean up attach timers, watchers, and session map before removing
        attachTimers[id]?.invalidate()
        attachTimers.removeValue(forKey: id)
        watchers[id]?.stopAll()
        watchers.removeValue(forKey: id)
        processes[id]?.stop()
        processes.removeValue(forKey: id)
        agentSessionMap = agentSessionMap.filter { _, agentId in
            !(projects.first(where: { $0.id == id })?.agents.contains(where: { $0.id == agentId }) ?? false)
        }
        projects.removeAll { $0.id == id }
        if selectedProjectId == id {
            selectedProjectId = projects.first?.id
            selectedAgentId = nil
            activeClusterId = nil
            openTerminalIds = []
        }
        saveState()
    }

    func addProject(name: String, path: URL) {
        let project = Project(
            id: UUID(),
            name: name,
            path: path,
            status: .idle,
            agents: [],
            events: [],
            tokenCount: 0,
            estimatedCost: 0
        )
        projects.append(project)
        selectProject(project.id)
        saveState()
    }

    // MARK: - Renaming

    func renameAgent(_ agentId: UUID, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        for i in projects.indices {
            if let j = projects[i].agents.firstIndex(where: { $0.id == agentId }) {
                projects[i].agents[j].name = trimmed
                saveState()
                return
            }
        }
    }

    func renameProject(_ projectId: UUID, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let i = projects.firstIndex(where: { $0.id == projectId }) {
            projects[i].name = trimmed
            saveState()
        }
    }

    // MARK: - Keyboard Navigation

    /// Select the next project in the list (⌘↓)
    func selectNextProject() {
        guard let currentId = selectedProjectId,
              let idx = projects.firstIndex(where: { $0.id == currentId }) else {
            selectedProjectId = projects.first?.id
            return
        }
        let nextIdx = (idx + 1) % projects.count
        selectProject(projects[nextIdx].id)
    }

    /// Select the previous project in the list (⌘↑)
    func selectPreviousProject() {
        guard let currentId = selectedProjectId,
              let idx = projects.firstIndex(where: { $0.id == currentId }) else {
            selectedProjectId = projects.last?.id
            return
        }
        let prevIdx = (idx - 1 + projects.count) % projects.count
        selectProject(projects[prevIdx].id)
    }

    /// Select the next agent tab (⌘→)
    func selectNextAgent() {
        guard let project = selectedProject else { return }
        let allAgents = project.agents
        guard !allAgents.isEmpty else { return }

        if let currentId = selectedAgentId,
           let idx = allAgents.firstIndex(where: { $0.id == currentId }) {
            let nextIdx = (idx + 1) % allAgents.count
            selectAgent(allAgents[nextIdx].id)
        } else {
            selectAgent(allAgents[0].id)
        }
    }

    /// Select the previous agent tab (⌘←)
    func selectPreviousAgent() {
        guard let project = selectedProject else { return }
        let allAgents = project.agents
        guard !allAgents.isEmpty else { return }

        if let currentId = selectedAgentId,
           let idx = allAgents.firstIndex(where: { $0.id == currentId }) {
            let prevIdx = (idx - 1 + allAgents.count) % allAgents.count
            selectAgent(allAgents[prevIdx].id)
        } else {
            selectAgent(allAgents.last!.id)
        }
    }

    /// Cycle office panel snap state up (⌘⇧↑)
    func officePanelSnapUp() {
        switch officePanelSnap {
        case .collapsed: snapOfficePanel(to: .ambient)
        case .ambient: snapOfficePanel(to: .expanded)
        case .expanded: break
        }
    }

    /// Cycle office panel snap state down (⌘⇧↓)
    func officePanelSnapDown() {
        switch officePanelSnap {
        case .expanded: snapOfficePanel(to: .ambient)
        case .ambient: snapOfficePanel(to: .collapsed)
        case .collapsed: break
        }
    }

    // MARK: - Session Management (Phase 6)

    /// Start a new Claude Code session for a project
    func startSession(projectId: UUID, prompt: String) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let project = projects[idx]

        // Create root agent
        let rootAgent = Agent(
            id: UUID(),
            name: "claude",
            parentId: nil,
            status: .reading,
            bodyColor: Color(hex: 0xc0a8ff),
            shirtColor: Color(hex: 0x5030a0),
            spawnTime: Date()
        )
        projects[idx].agents.append(rootAgent)
        projects[idx].status = .active
        projects[idx].events.append(ActivityEvent(
            id: UUID(), agentId: rootAgent.id, timestamp: Date(),
            type: .spawn, meta: "Session started"
        ))

        // Map the root agent
        selectAgent(rootAgent.id)

        // Launch process
        let proc = ClaudeCodeProcess(projectPath: project.path)
        proc.onPermissionDenials = { [weak self] sessionId, denials in
            self?.handlePermissionDenials(projectId: projectId, sessionId: sessionId, denials: denials)
        }
        proc.onStreamEvent = { [weak self] event in
            self?.handleStreamEvent(event, projectId: projectId)
        }
        processes[projectId] = proc
        proc.send(prompt: prompt, permissionMode: permissionMode.rawValue)

        // Set up JSONL watcher after a short delay (file needs to be created)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.setupWatcher(for: projectId, rootAgentId: rootAgent.id)
        }
    }

    /// Send a follow-up prompt to an existing session, or start a new one
    func sendPrompt(projectId: UUID, prompt: String) {
        pendingApproval = nil
        // If a process exists and has run before (finished), send a continuation
        if let proc = processes[projectId], !proc.isRunning, proc.hasRanBefore {
            proc.send(prompt: prompt, isContinuation: true, permissionMode: permissionMode.rawValue)
            // Update agent status
            if let idx = projects.firstIndex(where: { $0.id == projectId }),
               let agentIdx = projects[idx].agents.firstIndex(where: { $0.parentId == nil }) {
                projects[idx].agents[agentIdx].status = .reading
                projects[idx].status = .active
            }
        } else if processes[projectId] == nil || processes[projectId]?.isRunning == false {
            // No session yet — start fresh
            startSession(projectId: projectId, prompt: prompt)
        }
        // If already running, ignore (user should wait)
    }

    // MARK: - Commands

    /// Execute a Botcrew-local command (\command)
    func executeBotcrewCommand(_ command: BotcrewCommand, projectId: UUID) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let project = projects[idx]

        switch command {
        case .help:
            var lines = ["", "  Available commands:", ""]
            lines.append("  Botcrew (\\command):")
            lines += BotcrewCommand.allCases.map { "    \($0.name.padding(toLength: 16, withPad: " ", startingAt: 0)) \($0.description)" }
            lines.append("")
            lines.append("  Claude CLI (/command):")
            lines += SlashCommand.allCases.map { "    \($0.name.padding(toLength: 16, withPad: " ", startingAt: 0)) \($0.description)" }
            lines.append("")
            appendCommandOutput(lines, projectId: projectId)

        case .cost:
            showCostDashboard = true
            let sessionCost = String(format: "$%.4f", project.estimatedCost)
            let tokens = formatTokens(project.tokenCount)
            appendCommandOutput(["", "  Session: \(tokens) tokens (\(sessionCost))", "  Opening cost dashboard...", ""], projectId: projectId)

        case .clear:
            clearTerminal(projectId: projectId)

        case .status:
            let status = project.status.rawValue
            let agentCount = project.agents.count
            let running = processes[projectId]?.isRunning == true
            let sessionId = processes[projectId]?.lastSessionId ?? "none"
            var lines = [
                "",
                "  Project: \(project.name)",
                "  Status:  \(status)",
                "  Agents:  \(agentCount)",
                "  Process: \(running ? "running" : "stopped")",
                "  Session: \(sessionId)",
                "  Path:    \(project.path.path)",
                ""
            ]
            if let rateLimit = rateLimitInfo, !rateLimit.isExpired {
                lines.insert("  Rate:    \(rateLimit.tier)", at: lines.count - 1)
            }
            appendCommandOutput(lines, projectId: projectId)

        case .resume:
            showSessionHistory = true
            appendCommandOutput(["", "  Opening session history...", ""], projectId: projectId)

        case .model:
            let model = lastModelUsed(projectId: projectId) ?? "unknown"
            appendCommandOutput(["", "  Model: \(model)", ""], projectId: projectId)

        case .git:
            showGitPanel = true
            appendCommandOutput(["", "  Opening git panel... (⌘G)", ""], projectId: projectId)

        case .templates:
            showTemplateSheet = true
            appendCommandOutput(["", "  Opening prompt templates...", ""], projectId: projectId)

        case .terminal:
            showTerminal.toggle()
            let state = showTerminal ? "shown" : "hidden"
            appendCommandOutput(["", "  Terminal \(state). (⌘T)", ""], projectId: projectId)

        case .version:
            runClaudeVersion(projectId: projectId)
        }
    }

    /// Forward a slash command to the active Claude CLI session (/command)
    func executeSlashCommand(_ command: SlashCommand, projectId: UUID) {
        if let proc = processes[projectId], !proc.isRunning, proc.hasRanBefore {
            proc.send(prompt: command.name, isContinuation: true, permissionMode: permissionMode.rawValue)
            showTerminal = true
        } else if processes[projectId]?.isRunning == true {
            appendCommandOutput(["", "  Cannot run \(command.name) while Claude is working.", ""], projectId: projectId)
        } else {
            // No session — start a new one with the slash command
            sendPrompt(projectId: projectId, prompt: command.name)
            showTerminal = true
        }
    }

    private func runClaudeVersion(projectId: UUID) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-l", "-c", "\(ClaudeCodeProcess.claudePath) --version"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        proc.terminationHandler = { [weak self] _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
            DispatchQueue.main.async {
                self?.appendCommandOutput(["", "  Claude Code: \(output)", ""], projectId: projectId)
            }
        }
        do { try proc.run() } catch {
            appendCommandOutput(["", "  Error: \(error.localizedDescription)", ""], projectId: projectId)
        }
    }

    private func appendCommandOutput(_ lines: [String], projectId: UUID) {
        let proc: ClaudeCodeProcess
        if let existing = processes[projectId] {
            proc = existing
        } else if let project = projects.first(where: { $0.id == projectId }) {
            let newProc = ClaudeCodeProcess(projectPath: project.path)
            processes[projectId] = newProc
            proc = newProc
        } else {
            return
        }
        proc.appendOutput(lines)
        showTerminal = true
    }

    private func clearTerminal(projectId: UUID) {
        // Replace the process's terminal output by creating a fresh buffer
        if let proc = processes[projectId] {
            proc.clearBuffer()
        }
    }

    private func lastModelUsed(projectId: UUID) -> String? {
        costHistory.last(where: { $0.projectId == projectId })?.model
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fk", Double(count) / 1_000) }
        return "\(count)"
    }

    /// Handle permission denials from stream-json output
    private func handlePermissionDenials(projectId: UUID, sessionId: String, denials: [[String: Any]]) {
        let toolDenials = denials.compactMap { denial -> ToolApproval.ToolDenial? in
            guard let name = denial["tool_name"] as? String,
                  let toolUseId = denial["tool_use_id"] as? String,
                  let input = denial["tool_input"] as? [String: Any] else { return nil }
            return ToolApproval.ToolDenial(toolName: name, toolUseId: toolUseId, input: input)
        }
        guard !toolDenials.isEmpty else { return }
        pendingApproval = ToolApproval(
            projectId: projectId,
            sessionId: sessionId,
            denials: toolDenials,
            timestamp: Date()
        )
    }

    /// Approve denied tools and re-run with them allowed
    func approveAndContinue() {
        guard let approval = pendingApproval else { return }
        let toolNames = Array(Set(approval.denials.map(\.toolName)))
        pendingApproval = nil

        if let proc = processes[approval.projectId] {
            proc.send(
                prompt: "Please continue with the previously denied tool uses",
                isContinuation: true,
                permissionMode: permissionMode.rawValue,
                allowedTools: toolNames
            )
        }
    }

    /// Deny the pending approval
    func denyApproval() {
        pendingApproval = nil
    }

    /// Handle stream-json events for cost tracking and session completion
    private func handleStreamEvent(_ event: [String: Any], projectId: UUID) {
        let type = event["type"] as? String ?? ""

        // Store session ID when we get it
        if type == "system", let sessionId = event["session_id"] as? String {
            if let idx = projects.firstIndex(where: { $0.id == projectId }) {
                projects[idx].lastSessionId = sessionId
                saveState()
            }
        }

        // Parse account-level rate limit info
        if type == "rate_limit_event",
           let info = event["rate_limit_info"] as? [String: Any] {
            parseRateLimitInfo(info)
        }

        guard type == "result" else { return }

        // Session completed — play sound
        if soundEnabled { SoundService.play(.sessionComplete) }

        let cost = event["total_cost_usd"] as? Double ?? 0
        guard cost > 0 else { return }

        let usage = event["usage"] as? [String: Any] ?? [:]
        let inputTokens = usage["input_tokens"] as? Int ?? 0
        let outputTokens = usage["output_tokens"] as? Int ?? 0

        // Extract model from modelUsage keys
        let modelUsage = event["modelUsage"] as? [String: Any] ?? [:]
        let model = modelUsage.keys.first

        recordCost(projectId: projectId, cost: cost, inputTokens: inputTokens, outputTokens: outputTokens, model: model)
    }

    private func parseRateLimitInfo(_ info: [String: Any]) {
        let status = info["status"] as? String ?? "allowed"
        let resetsAtUnix = info["resetsAt"] as? TimeInterval ?? 0
        let rateLimitType = info["rateLimitType"] as? String ?? "five_hour"
        let overageStatus = info["overageStatus"] as? String ?? "allowed"
        let overageResetsAtUnix = info["overageResetsAt"] as? TimeInterval ?? 0
        let isUsingOverage = info["isUsingOverage"] as? Bool ?? false

        rateLimitInfo = RateLimitInfo(
            status: status,
            resetsAt: Date(timeIntervalSince1970: resetsAtUnix),
            rateLimitType: rateLimitType,
            overageStatus: overageStatus,
            overageResetsAt: Date(timeIntervalSince1970: overageResetsAtUnix),
            isUsingOverage: isUsingOverage,
            receivedAt: Date()
        )
    }

    /// Stop a running session
    func stopSession(projectId: UUID) {
        processes[projectId]?.stop()
        watchers[projectId]?.stopAll()
        watchers.removeValue(forKey: projectId)
        attachTimers[projectId]?.invalidate()
        attachTimers.removeValue(forKey: projectId)

        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            for i in projects[idx].agents.indices {
                if projects[idx].agents[i].status != .error {
                    projects[idx].agents[i].status = .idle
                }
            }
            projects[idx].status = .idle
            projects[idx].isAttached = false
        }
    }

    // MARK: - Attach Mode

    /// Attach to an externally-running Claude session (read-only watch)
    func attachToSession(projectId: UUID, sessionPath: String) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }

        if projects[idx].isAttached { detachSession(projectId: projectId) }
        if processes[projectId] != nil { stopSession(projectId: projectId) }

        projects[idx].agents.removeAll()
        projects[idx].events.removeAll()

        let events = JSONLWatcher.readAllEvents(from: sessionPath)
        let modDate = (try? FileManager.default.attributesOfItem(atPath: sessionPath))?[.modificationDate] as? Date ?? Date()

        let rootAgent = Agent(
            id: UUID(),
            name: "claude",
            parentId: nil,
            status: .idle,
            bodyColor: Color(hex: 0xc0a8ff),
            shirtColor: Color(hex: 0x5030a0),
            spawnTime: modDate
        )
        projects[idx].agents.append(rootAgent)
        agentSessionMap[sessionPath] = rootAgent.id

        var lastStatus: AgentStatus = .idle
        for event in events {
            guard event.isAssistant else { continue }
            let toolUses = AgentStateParser.extractToolUses(from: event)
            for toolUse in toolUses {
                let eventType = AgentStateParser.eventTypeFromToolUse(toolUse.name)
                let filePath = AgentStateParser.extractFilePath(from: toolUse.input)
                lastStatus = AgentStateParser.statusFromToolUse(toolUse.name)

                let toolContent = AgentStateParser.extractToolContent(from: toolUse.name, input: toolUse.input)
                var activityEvent = ActivityEvent(
                    id: UUID(),
                    agentId: rootAgent.id,
                    timestamp: event.timestamp ?? modDate,
                    type: eventType,
                    file: filePath,
                    meta: toolUse.name
                )
                activityEvent.content = toolContent.content
                activityEvent.oldString = toolContent.oldString
                activityEvent.command = toolContent.command
                projects[idx].events.append(activityEvent)
            }
            if AgentStateParser.containsError(event) {
                lastStatus = .error
                projects[idx].events.append(ActivityEvent(
                    id: UUID(), agentId: rootAgent.id, timestamp: event.timestamp ?? modDate,
                    type: .error, meta: "Error detected"
                ))
            }
            if let usage = AgentStateParser.extractUsage(from: event) {
                projects[idx].tokenCount += usage.totalTokens
            }
        }

        // Keep live status — session may be actively running
        if let agentIdx = projects[idx].agents.firstIndex(where: { $0.id == rootAgent.id }) {
            projects[idx].agents[agentIdx].status = lastStatus
        }
        projects[idx].status = lastStatus == .error ? .error : .active
        projects[idx].isAttached = true

        projects[idx].lastSessionId = (sessionPath as NSString).lastPathComponent
            .replacingOccurrences(of: ".jsonl", with: "")

        let subagentsDir = (sessionPath as NSString).deletingPathExtension + "/subagents"
        if let subFiles = try? FileManager.default.contentsOfDirectory(atPath: subagentsDir) {
            for file in subFiles where file.hasSuffix(".jsonl") {
                let subPath = (subagentsDir as NSString).appendingPathComponent(file)
                restoreSubagent(at: subPath, projectIdx: idx, rootAgentId: rootAgent.id)
            }
        }

        let watcher = JSONLWatcher()
        watcher.onEvent = { [weak self] filePath, event in
            self?.handleJSONLEvent(event, filePath: filePath, projectId: projectId)
        }
        watcher.onNewSubagent = { [weak self] filePath in
            self?.handleNewSubagent(filePath: filePath, projectId: projectId, rootAgentId: rootAgent.id)
        }
        watcher.watchFile(at: sessionPath)
        watcher.watchSubagentDirectory(at: sessionPath)
        watchers[projectId] = watcher

        // Auto-detach when file stops being written (60s stale threshold)
        let staleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: sessionPath),
                  let lastMod = attrs[.modificationDate] as? Date else { return }
            if Date().timeIntervalSince(lastMod) > 60 {
                self.detachSession(projectId: projectId)
            }
        }
        attachTimers[projectId] = staleTimer

        if selectedProjectId == projectId {
            selectAgent(rootAgent.id)
        }
    }

    /// Detach from an attached session (stop watching, keep history)
    func detachSession(projectId: UUID) {
        attachTimers[projectId]?.invalidate()
        attachTimers.removeValue(forKey: projectId)

        watchers[projectId]?.stopAll()
        watchers.removeValue(forKey: projectId)

        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            let agentIds = Set(projects[idx].agents.map(\.id))
            agentSessionMap = agentSessionMap.filter { !agentIds.contains($0.value) }
            for i in projects[idx].agents.indices {
                if projects[idx].agents[i].status != .error {
                    projects[idx].agents[i].status = .idle
                }
            }
            projects[idx].status = .idle
            projects[idx].isAttached = false
        }
    }

    /// Scan for running Claude sessions not already being watched
    func scanForRunningSessions() -> [RunningSessionInfo] {
        let allRunning = SessionScanner.scanRunningSessions()
        // Filter out sessions we're already watching
        let watchedPaths = Set(agentSessionMap.keys)
        return allRunning.filter { !watchedPaths.contains($0.filePath) }
    }

    /// Set up JSONL file watcher for a project
    private func setupWatcher(for projectId: UUID, rootAgentId: UUID) {
        guard let project = projects.first(where: { $0.id == projectId }) else { return }

        let projectPath = project.path.path
        let watcher = JSONLWatcher()

        // Handle new JSONL events
        watcher.onEvent = { [weak self] filePath, event in
            self?.handleJSONLEvent(event, filePath: filePath, projectId: projectId)
        }

        // Handle new subagent files
        watcher.onNewSubagent = { [weak self] filePath in
            self?.handleNewSubagent(filePath: filePath, projectId: projectId, rootAgentId: rootAgentId)
        }

        // Find and watch the latest session file
        if let sessionPath = JSONLWatcher.findLatestSession(for: projectPath) {
            agentSessionMap[sessionPath] = rootAgentId
            watcher.watchFile(at: sessionPath)
            watcher.watchSubagentDirectory(at: sessionPath)
        }

        watchers[projectId] = watcher
    }

    /// Handle a parsed JSONL event
    private func handleJSONLEvent(_ event: JSONLEvent, filePath: String, projectId: UUID) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }),
              let agentId = agentSessionMap[filePath] else { return }

        // Only process assistant messages (they contain tool uses)
        guard event.isAssistant else { return }

        // Extract tool uses and update agent state
        let toolUses = AgentStateParser.extractToolUses(from: event)
        for toolUse in toolUses {
            let newStatus = AgentStateParser.statusFromToolUse(toolUse.name)
            let eventType = AgentStateParser.eventTypeFromToolUse(toolUse.name)
            let filePath = AgentStateParser.extractFilePath(from: toolUse.input)

            // Update agent status
            if let agentIdx = projects[idx].agents.firstIndex(where: { $0.id == agentId }) {
                projects[idx].agents[agentIdx].status = newStatus
            }

            // Add activity event with structured content
            let toolContent = AgentStateParser.extractToolContent(from: toolUse.name, input: toolUse.input)
            var activityEvent = ActivityEvent(
                id: UUID(),
                agentId: agentId,
                timestamp: event.timestamp ?? Date(),
                type: eventType,
                file: filePath,
                meta: toolUse.name
            )
            activityEvent.content = toolContent.content
            activityEvent.oldString = toolContent.oldString
            activityEvent.command = toolContent.command
            projects[idx].events.append(activityEvent)

            // Record file touch for the file tree
            if let fp = filePath,
               let agent = projects[idx].agents.first(where: { $0.id == agentId }) {
                let action: FileTouch.FileAction = (eventType == .write) ? .write : .read
                fileTracker(for: projectId).recordTouch(
                    filePath: fp, agentId: agentId,
                    agentName: agent.name, agentColor: agent.bodyColor,
                    action: action
                )
            }

            // Reset idle timer for this agent
            resetIdleTimer(agentId: agentId, projectIdx: idx)
        }

        // Check for errors
        if AgentStateParser.containsError(event) {
            if let agentIdx = projects[idx].agents.firstIndex(where: { $0.id == agentId }) {
                projects[idx].agents[agentIdx].status = .error
                projects[idx].status = .error
            }
            projects[idx].events.append(ActivityEvent(
                id: UUID(), agentId: agentId, timestamp: event.timestamp ?? Date(),
                type: .error, meta: "Error detected"
            ))
            if soundEnabled { SoundService.play(.error) }
        }

        // Update token counts and cost estimate
        if let usage = AgentStateParser.extractUsage(from: event) {
            projects[idx].tokenCount += usage.totalTokens
            projects[idx].estimatedCost += AgentStateParser.estimateCost(
                usage: usage, model: event.model
            )
        }
    }

    /// Handle a new subagent JSONL file appearing
    private func handleNewSubagent(filePath: String, projectId: UUID, rootAgentId: UUID) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }

        // Assign color from palette based on agent count
        let subColors: [(body: UInt32, shirt: UInt32)] = [
            (0x80e8a0, 0x0a4020), // green - writer
            (0xffd080, 0x6a3800), // amber - test
            (0x80c8ff, 0x0a3060), // blue - utility
            (0xffb090, 0x802010), // coral - UI
        ]
        let colorIdx = projects[idx].agents.count % subColors.count
        let colors = subColors[colorIdx]

        // Extract agent name from filename (e.g. "agent-a3f8f2e.jsonl" → "agent-a3f8f2e")
        let name = (filePath as NSString).lastPathComponent
            .replacingOccurrences(of: ".jsonl", with: "")

        let subAgent = Agent(
            id: UUID(),
            name: name,
            parentId: rootAgentId,
            status: .reading,
            bodyColor: Color(hex: colors.body),
            shirtColor: Color(hex: colors.shirt),
            spawnTime: Date()
        )

        projects[idx].agents.append(subAgent)
        agentSessionMap[filePath] = subAgent.id

        // Add spawn event
        projects[idx].events.append(ActivityEvent(
            id: UUID(), agentId: subAgent.id, timestamp: Date(),
            type: .spawn, meta: "Subagent spawned"
        ))

        // Auto-expand the root cluster to show new sub
        activeClusterId = rootAgentId
        if soundEnabled { SoundService.play(.subagentSpawned) }
    }

    /// Reset the idle timer for an agent (goes idle after 2s of no events)
    private func resetIdleTimer(agentId: UUID, projectIdx: Int) {
        idleTimers[agentId]?.invalidate()
        idleTimers[agentId] = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if projectIdx < self.projects.count,
               let agentIdx = self.projects[projectIdx].agents.firstIndex(where: { $0.id == agentId }),
               self.projects[projectIdx].agents[agentIdx].status != .error {
                self.projects[projectIdx].agents[agentIdx].status = .idle
            }
        }
    }

    /// Get terminal output for the selected project's process
    var terminalOutputForSelectedProject: String {
        guard let projectId = selectedProjectId,
              let proc = processes[projectId] else {
            return ""
        }
        return proc.terminalOutput
    }

    /// Get structured terminal entries for the selected project
    var terminalEntriesForSelectedProject: [TerminalEntry] {
        guard let projectId = selectedProjectId,
              let proc = processes[projectId] else {
            return []
        }
        return proc.terminalEntries
    }

    /// Whether the selected project has a running session
    var selectedProjectHasSession: Bool {
        guard let projectId = selectedProjectId else { return false }
        return processes[projectId]?.isRunning == true
    }

    // MARK: - Persistence

    private static let saveFileName = "botcrew-state.json"

    private static let saveFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let botcrewDir = appSupport.appendingPathComponent("BotCrew", isDirectory: true)
        // One-time migration from old "Botcrew" directory name
        let oldDir = appSupport.appendingPathComponent("Botcrew", isDirectory: true)
        if FileManager.default.fileExists(atPath: oldDir.path) && !FileManager.default.fileExists(atPath: botcrewDir.path) {
            try? FileManager.default.moveItem(at: oldDir, to: botcrewDir)
        }
        try? FileManager.default.createDirectory(at: botcrewDir, withIntermediateDirectories: true)
        return botcrewDir.appendingPathComponent(saveFileName)
    }()

    struct SavedState: Codable {
        var projects: [SavedProject]
        var selectedProjectId: UUID?
        var isSidebarCollapsed: Bool
        var officePanelHeight: CGFloat
        var permissionMode: PermissionMode?
        var promptTemplates: [PromptTemplate]?
        var costHistory: [CostRecord]?
        var soundEnabled: Bool?
    }

    func saveState() {
        let saved = SavedState(
            projects: projects.map { SavedProject(from: $0) },
            selectedProjectId: selectedProjectId,
            isSidebarCollapsed: isSidebarCollapsed,
            officePanelHeight: officePanelHeight,
            permissionMode: permissionMode,
            promptTemplates: promptTemplates,
            costHistory: costHistory,
            soundEnabled: soundEnabled
        )
        do {
            let data = try JSONEncoder().encode(saved)
            try data.write(to: Self.saveFileURL, options: .atomic)
        } catch {
            print("Botcrew: failed to save state: \(error)")
        }
    }

    func loadState() {
        guard let data = try? Data(contentsOf: Self.saveFileURL),
              let saved = try? JSONDecoder().decode(SavedState.self, from: data) else {
            return
        }
        projects = saved.projects.map { $0.toProject() }.filter {
            FileManager.default.fileExists(atPath: $0.path.path)
        }
        if let id = saved.selectedProjectId, projects.contains(where: { $0.id == id }) {
            selectedProjectId = id
        } else {
            selectedProjectId = projects.first?.id
        }
        isSidebarCollapsed = saved.isSidebarCollapsed
        officePanelHeight = saved.officePanelHeight
        permissionMode = saved.permissionMode ?? .supervised
        promptTemplates = saved.promptTemplates ?? []
        costHistory = saved.costHistory ?? []
        soundEnabled = saved.soundEnabled ?? true
    }

    // MARK: - Session Restore

    /// On app launch, scan for recent JSONL sessions and restore agent state
    private func restoreSessions() {
        for project in projects {
            restoreProjectSession(project)
        }
    }

    /// Restore a single project's session from its latest JSONL file
    private func restoreProjectSession(_ project: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        let projectPath = project.path.path

        // Find the latest session file
        guard let sessionPath = JSONLWatcher.findLatestSession(for: projectPath) else { return }

        // Check if the session is recent (modified within last 10 minutes)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: sessionPath),
              let modDate = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modDate) < 600 else { return }

        // Read all events from the session to reconstruct state
        let events = JSONLWatcher.readAllEvents(from: sessionPath)
        guard !events.isEmpty else { return }

        // Create root agent
        let rootAgent = Agent(
            id: UUID(),
            name: "claude",
            parentId: nil,
            status: .idle,
            bodyColor: Color(hex: 0xc0a8ff),
            shirtColor: Color(hex: 0x5030a0),
            spawnTime: modDate
        )
        projects[idx].agents.append(rootAgent)
        agentSessionMap[sessionPath] = rootAgent.id

        // Replay events to reconstruct activity and determine final status
        var lastStatus: AgentStatus = .idle
        for event in events {
            guard event.isAssistant else { continue }
            let toolUses = AgentStateParser.extractToolUses(from: event)
            for toolUse in toolUses {
                let eventType = AgentStateParser.eventTypeFromToolUse(toolUse.name)
                let filePath = AgentStateParser.extractFilePath(from: toolUse.input)
                lastStatus = AgentStateParser.statusFromToolUse(toolUse.name)

                let toolContent = AgentStateParser.extractToolContent(from: toolUse.name, input: toolUse.input)
                var activityEvent = ActivityEvent(
                    id: UUID(),
                    agentId: rootAgent.id,
                    timestamp: event.timestamp ?? modDate,
                    type: eventType,
                    file: filePath,
                    meta: toolUse.name
                )
                activityEvent.content = toolContent.content
                activityEvent.oldString = toolContent.oldString
                activityEvent.command = toolContent.command
                projects[idx].events.append(activityEvent)
            }
            if AgentStateParser.containsError(event) {
                lastStatus = .error
                projects[idx].events.append(ActivityEvent(
                    id: UUID(), agentId: rootAgent.id, timestamp: event.timestamp ?? modDate,
                    type: .error, meta: "Error detected"
                ))
            }
            if let usage = AgentStateParser.extractUsage(from: event) {
                projects[idx].tokenCount += usage.totalTokens
            }
        }

        // Set final status (idle since session isn't running, unless error)
        if let agentIdx = projects[idx].agents.firstIndex(where: { $0.id == rootAgent.id }) {
            projects[idx].agents[agentIdx].status = lastStatus == .error ? .error : .idle
        }
        projects[idx].status = lastStatus == .error ? .error : .idle

        // Scan for subagents
        let subagentsDir = (sessionPath as NSString).deletingPathExtension + "/subagents"
        if let subFiles = try? FileManager.default.contentsOfDirectory(atPath: subagentsDir) {
            for file in subFiles where file.hasSuffix(".jsonl") {
                let subPath = (subagentsDir as NSString).appendingPathComponent(file)
                restoreSubagent(at: subPath, projectIdx: idx, rootAgentId: rootAgent.id)
            }
        }

        // Extract session ID from the filename
        let sessionId = (sessionPath as NSString).lastPathComponent
            .replacingOccurrences(of: ".jsonl", with: "")
        projects[idx].lastSessionId = sessionId

        // Set up watcher for live updates going forward
        let watcher = JSONLWatcher()
        watcher.onEvent = { [weak self] filePath, event in
            self?.handleJSONLEvent(event, filePath: filePath, projectId: project.id)
        }
        watcher.onNewSubagent = { [weak self] filePath in
            self?.handleNewSubagent(filePath: filePath, projectId: project.id, rootAgentId: rootAgent.id)
        }
        watcher.watchFile(at: sessionPath)
        watcher.watchSubagentDirectory(at: sessionPath)
        watchers[project.id] = watcher

        // Auto-select if this was the selected project
        if selectedProjectId == project.id {
            selectAgent(rootAgent.id)
        }
    }

    /// Restore a subagent from its JSONL file
    private func restoreSubagent(at filePath: String, projectIdx: Int, rootAgentId: UUID) {
        let subColors: [(body: UInt32, shirt: UInt32)] = [
            (0x80e8a0, 0x0a4020),
            (0xffd080, 0x6a3800),
            (0x80c8ff, 0x0a3060),
            (0xffb090, 0x802010),
        ]
        let colorIdx = projects[projectIdx].agents.count % subColors.count
        let colors = subColors[colorIdx]

        let name = (filePath as NSString).lastPathComponent
            .replacingOccurrences(of: ".jsonl", with: "")

        let subAgent = Agent(
            id: UUID(),
            name: name,
            parentId: rootAgentId,
            status: .idle,
            bodyColor: Color(hex: colors.body),
            shirtColor: Color(hex: colors.shirt),
            spawnTime: Date()
        )
        projects[projectIdx].agents.append(subAgent)
        agentSessionMap[filePath] = subAgent.id

        // Replay subagent events
        let events = JSONLWatcher.readAllEvents(from: filePath)
        var lastStatus: AgentStatus = .idle
        for event in events {
            guard event.isAssistant else { continue }
            let toolUses = AgentStateParser.extractToolUses(from: event)
            for toolUse in toolUses {
                let eventType = AgentStateParser.eventTypeFromToolUse(toolUse.name)
                let fp = AgentStateParser.extractFilePath(from: toolUse.input)
                lastStatus = AgentStateParser.statusFromToolUse(toolUse.name)

                let toolContent = AgentStateParser.extractToolContent(from: toolUse.name, input: toolUse.input)
                var activityEvent = ActivityEvent(
                    id: UUID(),
                    agentId: subAgent.id,
                    timestamp: event.timestamp ?? Date(),
                    type: eventType,
                    file: fp,
                    meta: toolUse.name
                )
                activityEvent.content = toolContent.content
                activityEvent.oldString = toolContent.oldString
                activityEvent.command = toolContent.command
                projects[projectIdx].events.append(activityEvent)
            }
            if AgentStateParser.containsError(event) {
                lastStatus = .error
            }
        }

        if let agentIdx = projects[projectIdx].agents.firstIndex(where: { $0.id == subAgent.id }) {
            projects[projectIdx].agents[agentIdx].status = lastStatus == .error ? .error : .idle
        }
    }

    static func withMockData() -> AppState {
        let state = AppState(skipPersistence: true)

        let root1Id = UUID()
        let sub1Id = UUID()
        let sub2Id = UUID()
        let root2Id = UUID()
        let sub3Id = UUID()
        let sub4Id = UUID()

        let agents = [
            Agent(id: root1Id, name: "orchestrator", parentId: nil, status: .reading,
                  bodyColor: Color(hex: 0xc0a8ff), shirtColor: Color(hex: 0x5030a0), spawnTime: Date().addingTimeInterval(-300)),
            Agent(id: sub1Id, name: "writer-1", parentId: root1Id, status: .typing,
                  bodyColor: Color(hex: 0x80e8a0), shirtColor: Color(hex: 0x0a4020), spawnTime: Date().addingTimeInterval(-240)),
            Agent(id: sub2Id, name: "test-runner", parentId: root1Id, status: .waiting,
                  bodyColor: Color(hex: 0xffd080), shirtColor: Color(hex: 0x6a3800), spawnTime: Date().addingTimeInterval(-180)),
            Agent(id: root2Id, name: "ui-builder", parentId: nil, status: .typing,
                  bodyColor: Color(hex: 0xffb090), shirtColor: Color(hex: 0x802010), spawnTime: Date().addingTimeInterval(-120)),
            Agent(id: sub3Id, name: "style-fixer", parentId: root2Id, status: .idle,
                  bodyColor: Color(hex: 0x80c8ff), shirtColor: Color(hex: 0x0a3060), spawnTime: Date().addingTimeInterval(-60)),
            Agent(id: sub4Id, name: "component-gen", parentId: root2Id, status: .typing,
                  bodyColor: Color(hex: 0x80e8a0), shirtColor: Color(hex: 0x0a4020), spawnTime: Date().addingTimeInterval(-45)),
        ]

        let now = Date()
        let mockEvents: [ActivityEvent] = [
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-290),
                          type: .spawn, meta: "Session started"),
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-280),
                          type: .read, file: "CLAUDE.md", meta: "Reading project instructions"),
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-260),
                          type: .thinking, meta: "Planning implementation approach"),
            ActivityEvent(id: UUID(), agentId: root1Id, timestamp: now.addingTimeInterval(-240),
                          type: .spawn, meta: "Spawned writer-1"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-235),
                          type: .read, file: "ContentView.swift", meta: "Reading existing code"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-220),
                          type: .write, file: "SidebarView.swift", meta: "Implementing sidebar"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-200),
                          type: .write, file: "TokenCard.swift", meta: "Adding token display"),
            ActivityEvent(id: UUID(), agentId: sub1Id, timestamp: now.addingTimeInterval(-180),
                          type: .bash, meta: "xcodebuild -scheme Botcrew build"),
            ActivityEvent(id: UUID(), agentId: sub2Id, timestamp: now.addingTimeInterval(-170),
                          type: .spawn, meta: "Spawned by orchestrator"),
            ActivityEvent(id: UUID(), agentId: sub2Id, timestamp: now.addingTimeInterval(-160),
                          type: .bash, meta: "xcodebuild test"),
            ActivityEvent(id: UUID(), agentId: sub2Id, timestamp: now.addingTimeInterval(-150),
                          type: .thinking, meta: "Analyzing test results"),
            ActivityEvent(id: UUID(), agentId: root2Id, timestamp: now.addingTimeInterval(-110),
                          type: .write, file: "TabBarView.swift", meta: "Building tab components"),
            ActivityEvent(id: UUID(), agentId: sub3Id, timestamp: now.addingTimeInterval(-50),
                          type: .read, file: "theme.css", meta: "Checking design tokens"),
            ActivityEvent(id: UUID(), agentId: sub4Id, timestamp: now.addingTimeInterval(-40),
                          type: .write, file: "ButtonStyles.swift", meta: "Generating button components"),
            ActivityEvent(id: UUID(), agentId: sub4Id, timestamp: now.addingTimeInterval(-30),
                          type: .write, file: "CardView.swift", meta: "Generating card components"),
        ]

        let project1 = Project(
            id: UUID(), name: "botcrew", path: URL(fileURLWithPath: "/Users/brian/botcrew"),
            status: .active, agents: agents, events: mockEvents, tokenCount: 24_500, estimatedCost: 0.48
        )
        let project2 = Project(
            id: UUID(), name: "api-server", path: URL(fileURLWithPath: "/Users/brian/api-server"),
            status: .idle, agents: [], events: [], tokenCount: 8_200, estimatedCost: 0.16
        )
        let docWriterId = UUID()
        let project3 = Project(
            id: UUID(), name: "docs-site", path: URL(fileURLWithPath: "/Users/brian/docs-site"),
            status: .error, agents: [
                Agent(id: docWriterId, name: "doc-writer", parentId: nil, status: .error,
                      bodyColor: Color(hex: 0x80c8ff), shirtColor: Color(hex: 0x0a3060), spawnTime: now.addingTimeInterval(-60)),
            ], events: [
                ActivityEvent(id: UUID(), agentId: docWriterId, timestamp: now.addingTimeInterval(-55),
                              type: .write, file: "README.md", meta: "Updating docs"),
                ActivityEvent(id: UUID(), agentId: docWriterId, timestamp: now.addingTimeInterval(-40),
                              type: .error, meta: "Build failed: missing module"),
            ], tokenCount: 3_100, estimatedCost: 0.06
        )

        state.projects = [project1, project2, project3]
        state.selectedProjectId = project1.id
        state.selectedAgentId = root1Id
        state.activeClusterId = root1Id

        // Mock file activity for the file tree
        let tracker = state.fileTracker(for: project1.id)
        let mockFiles: [(String, UUID, String, Color, FileTouch.FileAction, TimeInterval)] = [
            ("Botcrew/App/AppState.swift", root1Id, "orchestrator", Color(hex: 0xc0a8ff), .write, -3),
            ("Botcrew/App/ContentView.swift", sub1Id, "writer-1", Color(hex: 0x80e8a0), .read, -8),
            ("Botcrew/Views/Sidebar/SidebarView.swift", sub1Id, "writer-1", Color(hex: 0x80e8a0), .write, -5),
            ("Botcrew/Views/Sidebar/TokenCard.swift", sub2Id, "test-runner", Color(hex: 0xffd080), .read, -20),
            ("Botcrew/Views/Feed/ActivityFeedView.swift", sub1Id, "writer-1", Color(hex: 0x80e8a0), .write, -60),
            ("Botcrew/Services/AgentStateParser.swift", root1Id, "orchestrator", Color(hex: 0xc0a8ff), .read, -12),
            ("Botcrew/Models/Project.swift", root1Id, "orchestrator", Color(hex: 0xc0a8ff), .write, -120),
            ("BotcrewTests/AppStateTests.swift", sub2Id, "test-runner", Color(hex: 0xffd080), .write, -5),
            ("Botcrew/App/Theme.swift", sub3Id, "style-fixer", Color(hex: 0x80c8ff), .read, -15),
            ("Botcrew/Views/TabBar/TabBarView.swift", root2Id, "ui-builder", Color(hex: 0xffb090), .write, -25),
            // Conflict: two agents wrote the same file
            ("Botcrew/Views/Sidebar/SidebarView.swift", sub4Id, "component-gen", Color(hex: 0x80e8a0), .write, -2),
        ]
        for (path, agentId, name, color, action, offset) in mockFiles {
            tracker.recordTouch(filePath: path, agentId: agentId, agentName: name, agentColor: color, action: action)
            // Adjust timestamp
            if let idx = tracker.touches.firstIndex(where: { $0.filePath == path && $0.agentId == agentId }) {
                let adjusted = FileTouch(
                    id: tracker.touches[idx].id,
                    filePath: path, agentId: agentId, agentName: name, agentColor: color,
                    timestamp: now.addingTimeInterval(offset), action: action
                )
                tracker.touches[idx] = adjusted
            }
        }

        return state
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

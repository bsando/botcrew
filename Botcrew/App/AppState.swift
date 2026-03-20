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
    var officePanelHeight: CGFloat = 148 // snap: 26 (collapsed), 148 (ambient), 270 (expanded)
    var zoomLevel: CGFloat = 1.0 // 0.75 … 1.5, changed via Cmd+/Cmd-

    static let zoomMin: CGFloat = 0.75
    static let zoomMax: CGFloat = 1.5
    static let zoomStep: CGFloat = 0.1

    func zoomIn() {
        zoomLevel = min(Self.zoomMax, ((zoomLevel + Self.zoomStep) * 100).rounded() / 100)
    }

    func zoomOut() {
        zoomLevel = max(Self.zoomMin, ((zoomLevel - Self.zoomStep) * 100).rounded() / 100)
    }

    func zoomReset() {
        zoomLevel = 1.0
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
        projects.removeAll { $0.id == id }
        if selectedProjectId == id {
            selectedProjectId = projects.first?.id
            selectedAgentId = nil
            activeClusterId = nil
            openTerminalIds = []
        }
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
        let proc = ClaudeCodeProcess(projectPath: project.path, prompt: prompt)
        processes[projectId] = proc
        proc.start()

        // Set up JSONL watcher after a short delay (file needs to be created)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.setupWatcher(for: projectId, rootAgentId: rootAgent.id)
        }
    }

    /// Stop a running session
    func stopSession(projectId: UUID) {
        processes[projectId]?.stop()
        watchers[projectId]?.stopAll()
        watchers.removeValue(forKey: projectId)

        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            // Mark all agents idle
            for i in projects[idx].agents.indices {
                if projects[idx].agents[i].status != .error {
                    projects[idx].agents[i].status = .idle
                }
            }
            projects[idx].status = .idle
        }
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

            // Add activity event
            let activityEvent = ActivityEvent(
                id: UUID(),
                agentId: agentId,
                timestamp: event.timestamp ?? Date(),
                type: eventType,
                file: filePath,
                meta: toolUse.name
            )
            projects[idx].events.append(activityEvent)

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
        }

        // Update token counts
        if let usage = AgentStateParser.extractUsage(from: event) {
            projects[idx].tokenCount += usage.input + usage.output
            projects[idx].estimatedCost = AgentStateParser.estimateCost(
                inputTokens: projects[idx].tokenCount,
                outputTokens: usage.output
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

    /// Whether the selected project has a running session
    var selectedProjectHasSession: Bool {
        guard let projectId = selectedProjectId else { return false }
        return processes[projectId]?.isRunning == true
    }

    static func withMockData() -> AppState {
        let state = AppState()

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

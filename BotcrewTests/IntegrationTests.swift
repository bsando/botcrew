// IntegrationTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class IntegrationTests: XCTestCase {

    // MARK: - End-to-End Session Flow

    func testFullSessionLifecycle() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        state.projects = [Project(
            id: projectId, name: "test-project", path: URL(fileURLWithPath: "/tmp/test"),
            status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        // Start session
        state.startSession(projectId: projectId, prompt: "test prompt")

        // Verify root agent created
        XCTAssertEqual(state.projects[0].agents.count, 1)
        XCTAssertEqual(state.projects[0].agents[0].name, "claude")
        XCTAssertNil(state.projects[0].agents[0].parentId)
        XCTAssertEqual(state.projects[0].status, .active)

        // Verify agent is selected
        XCTAssertEqual(state.selectedAgentId, state.projects[0].agents[0].id)
        XCTAssertEqual(state.activeClusterId, state.projects[0].agents[0].id)

        // Verify spawn event
        XCTAssertEqual(state.projects[0].events.count, 1)
        XCTAssertEqual(state.projects[0].events[0].type, .spawn)

        // Stop session
        state.stopSession(projectId: projectId)
        XCTAssertEqual(state.projects[0].agents[0].status, .idle)
        XCTAssertEqual(state.projects[0].status, .idle)
    }

    func testSessionWithErrorPreservedOnStop() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        state.startSession(projectId: projectId, prompt: "test")

        // Simulate error
        state.projects[0].agents[0].status = .error
        state.projects[0].status = .error

        // Stop — error should be preserved
        state.stopSession(projectId: projectId)
        XCTAssertEqual(state.projects[0].agents[0].status, .error)
    }

    // MARK: - JSONL Event Processing Flow

    func testJSONLEventToActivityEvent() {
        // Simulate what happens when a JSONL event arrives
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Write","input":{"file_path":"/tmp/hello.swift","content":"print(\\"hello\\")"}}],"usage":{"input_tokens":500,"output_tokens":100}},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!

        // Extract tool uses
        let toolUses = AgentStateParser.extractToolUses(from: event)
        XCTAssertEqual(toolUses.count, 1)
        XCTAssertEqual(toolUses[0].name, "Write")

        // Map to status
        let status = AgentStateParser.statusFromToolUse(toolUses[0].name)
        XCTAssertEqual(status, .typing)

        // Map to event type
        let eventType = AgentStateParser.eventTypeFromToolUse(toolUses[0].name)
        XCTAssertEqual(eventType, .write)

        // Extract file path
        let filePath = AgentStateParser.extractFilePath(from: toolUses[0].input)
        XCTAssertEqual(filePath, "/tmp/hello.swift")

        // Extract usage
        let usage = AgentStateParser.extractUsage(from: event)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.input, 500)
        XCTAssertEqual(usage?.output, 100)

        // Not an error
        XCTAssertFalse(AgentStateParser.containsError(event))

        // Not a subagent spawn
        XCTAssertFalse(AgentStateParser.isSubagentSpawn(event))
    }

    func testSubagentSpawnFlow() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Agent","input":{"prompt":"write tests","description":"test writer"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!

        XCTAssertTrue(AgentStateParser.isSubagentSpawn(event))

        let status = AgentStateParser.statusFromToolUse("Agent")
        XCTAssertEqual(status, .waiting) // parent waits on sub

        let eventType = AgentStateParser.eventTypeFromToolUse("Agent")
        XCTAssertEqual(eventType, .spawn)
    }

    // MARK: - Project + Agent Selection Flow

    func testFullSelectionFlow() {
        let state = AppState.withMockData()
        let project1 = state.projects[0]

        // Mock data pre-selects the first root agent
        let root1 = state.rootAgents[0]
        XCTAssertEqual(state.selectedAgentId, root1.id)
        XCTAssertEqual(state.activeClusterId, root1.id)

        // Re-select same agent
        state.selectAgent(root1.id)
        XCTAssertEqual(state.selectedAgentId, root1.id)
        XCTAssertEqual(state.activeClusterId, root1.id)

        // Expand cluster (already expanded, so this toggles)
        state.toggleCluster(root1.id)
        XCTAssertNil(state.activeClusterId) // collapsed

        // Re-expand
        state.toggleCluster(root1.id)
        XCTAssertEqual(state.activeClusterId, root1.id)

        // Click a sub-agent
        let subs = state.subAgents(for: root1.id)
        XCTAssertFalse(subs.isEmpty)
        state.selectAgent(subs[0].id)
        XCTAssertEqual(state.selectedAgentId, subs[0].id)
        XCTAssertEqual(state.activeClusterId, root1.id) // parent cluster stays expanded

        // Verify events for selected agent
        let events = state.eventsForSelectedAgent
        // All events should belong to the selected agent
        for event in events {
            XCTAssertEqual(event.agentId, subs[0].id)
        }

        // Switch to another project
        state.selectProject(state.projects[1].id)
        XCTAssertNil(state.selectedAgentId) // cleared
        XCTAssertNil(state.activeClusterId) // cleared
        XCTAssertEqual(state.selectedProjectId, state.projects[1].id)
    }

    // MARK: - Office Panel Interaction Flow

    func testOfficePanelSnapFlow() {
        let state = AppState(skipPersistence: true)
        // Default is ambient
        XCTAssertEqual(state.officePanelHeight, 148)
        XCTAssertEqual(state.officePanelSnap, .ambient)

        // Collapse
        state.snapOfficePanel(to: .collapsed)
        XCTAssertEqual(state.officePanelSnap, .collapsed)
        XCTAssertEqual(state.officePanelHeight, 26)

        // Expand to ops mode
        state.snapOfficePanel(to: .expanded)
        XCTAssertEqual(state.officePanelSnap, .expanded)
        XCTAssertEqual(state.officePanelHeight, 270)

        // Back to ambient
        state.snapOfficePanel(to: .ambient)
        XCTAssertEqual(state.officePanelSnap, .ambient)
    }

    // MARK: - Error Recovery Flow

    func testErrorRecoveryFlow() {
        let state = AppState.withMockData()

        // Switch to error project (docs-site)
        let errorProject = state.projects[2]
        state.selectProject(errorProject.id)

        // Select the error agent
        let errorAgent = errorProject.agents[0]
        state.selectAgent(errorAgent.id)

        // Verify error state
        XCTAssertEqual(state.selectedAgent?.status, .error)

        // Error recovery: open terminal
        state.showTerminal = true
        XCTAssertTrue(state.showTerminal)

        // Verify we can see events
        let events = state.eventsForSelectedAgent
        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.contains { $0.type == .error })
    }

    // MARK: - Add Project Flow

    func testAddProjectFlow() {
        let state = AppState(skipPersistence: true)
        XCTAssertTrue(state.projects.isEmpty)

        state.addProject(name: "new-project", path: URL(fileURLWithPath: "/tmp/new"))
        XCTAssertEqual(state.projects.count, 1)
        XCTAssertEqual(state.projects[0].name, "new-project")
        XCTAssertEqual(state.selectedProjectId, state.projects[0].id)
        XCTAssertEqual(state.projects[0].status, .idle)
        XCTAssertTrue(state.projects[0].agents.isEmpty)
        XCTAssertTrue(state.projects[0].events.isEmpty)
        XCTAssertEqual(state.projects[0].tokenCount, 0)
        XCTAssertEqual(state.projects[0].estimatedCost, 0)
    }

    // MARK: - Multi-Event JSONL Processing

    func testMultipleToolUsesInSingleMessage() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"/tmp/a.swift"}},{"type":"tool_use","id":"t2","name":"Write","input":{"file_path":"/tmp/b.swift","content":"x"}},{"type":"tool_use","id":"t3","name":"Bash","input":{"command":"swift build"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let toolUses = AgentStateParser.extractToolUses(from: event)
        XCTAssertEqual(toolUses.count, 3)

        // Last tool use determines final status
        let statuses = toolUses.map { AgentStateParser.statusFromToolUse($0.name) }
        XCTAssertEqual(statuses, [.reading, .typing, .typing])
    }

    // MARK: - Real JSONL Format Validation

    func testRealWorldJSONLUserMessage() {
        let line = """
        {"parentUuid":null,"isSidechain":false,"userType":"external","cwd":"/Users/brian/project","sessionId":"abc-123","version":"2.1.78","gitBranch":"main","type":"user","message":{"role":"user","content":"read claude.md"},"uuid":"uuid-1","timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        XCTAssertEqual(event.type, "user")
        XCTAssertTrue(event.isUser)
        XCTAssertFalse(event.isAssistant)
        XCTAssertEqual(event.sessionId, "abc-123")
        XCTAssertEqual(event.cwd, "/Users/brian/project")
    }

    func testRealWorldJSONLAssistantMessage() {
        let line = """
        {"parentUuid":"uuid-1","isSidechain":false,"userType":"external","cwd":"/Users/brian/project","sessionId":"abc-123","version":"2.1.78","gitBranch":"main","message":{"model":"claude-opus-4-6","id":"msg_123","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_123","name":"Read","input":{"file_path":"/Users/brian/project/CLAUDE.md"}}],"usage":{"input_tokens":3930,"cache_read_input_tokens":17890,"output_tokens":14}},"type":"assistant","uuid":"uuid-2","timestamp":"2026-03-17T12:00:01.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        XCTAssertTrue(event.isAssistant)
        XCTAssertEqual(event.model, "claude-opus-4-6")

        let toolUses = AgentStateParser.extractToolUses(from: event)
        XCTAssertEqual(toolUses.count, 1)
        XCTAssertEqual(toolUses[0].name, "Read")

        let usage = AgentStateParser.extractUsage(from: event)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.input, 3930 + 17890) // input + cache_read
        XCTAssertEqual(usage?.output, 14)
    }

    // MARK: - Tool Content Extraction

    func testExtractToolContentWrite() {
        let (content, oldString, command) = AgentStateParser.extractToolContent(
            from: "Write", input: ["file_path": "/tmp/hello.swift", "content": "print(\"hello\")"]
        )
        XCTAssertEqual(content, "print(\"hello\")")
        XCTAssertNil(oldString)
        XCTAssertNil(command)
    }

    func testExtractToolContentEdit() {
        let (content, oldString, command) = AgentStateParser.extractToolContent(
            from: "Edit", input: ["file_path": "/tmp/a.swift", "old_string": "let x = 1", "new_string": "let x = 2"]
        )
        XCTAssertEqual(content, "let x = 2")
        XCTAssertEqual(oldString, "let x = 1")
        XCTAssertNil(command)
    }

    func testExtractToolContentBash() {
        let (content, oldString, command) = AgentStateParser.extractToolContent(
            from: "Bash", input: ["command": "swift build"]
        )
        XCTAssertNil(content)
        XCTAssertNil(oldString)
        XCTAssertEqual(command, "swift build")
    }

    func testExtractToolContentRead() {
        let (content, oldString, command) = AgentStateParser.extractToolContent(
            from: "Read", input: ["file_path": "/tmp/a.swift"]
        )
        XCTAssertNil(content)
        XCTAssertNil(oldString)
        XCTAssertNil(command)
    }

    func testJSONLEventPopulatesActivityEventContent() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Edit","input":{"file_path":"/tmp/a.swift","old_string":"let x = 1","new_string":"let x = 2"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let toolUses = AgentStateParser.extractToolUses(from: event)
        let toolContent = AgentStateParser.extractToolContent(from: toolUses[0].name, input: toolUses[0].input)
        XCTAssertEqual(toolContent.content, "let x = 2")
        XCTAssertEqual(toolContent.oldString, "let x = 1")
    }

    func testRealWorldFileHistorySnapshot() {
        let line = """
        {"type":"file-history-snapshot","messageId":"uuid-1","snapshot":{"messageId":"uuid-1","trackedFileBackups":{},"timestamp":"2026-03-17T12:00:00.000Z"},"isSnapshotUpdate":false}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        XCTAssertEqual(event.type, "file-history-snapshot")
        XCTAssertFalse(event.isAssistant)
        XCTAssertFalse(event.isUser)
    }
}

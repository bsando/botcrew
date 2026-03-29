// ProcessIntegrationTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class ProcessIntegrationTests: XCTestCase {

    // MARK: - AgentStateParser

    func testStatusFromWriteTool() {
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Write"), .typing)
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Edit"), .typing)
    }

    func testStatusFromReadTool() {
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Read"), .reading)
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Grep"), .reading)
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Glob"), .reading)
    }

    func testStatusFromBashTool() {
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Bash"), .typing)
    }

    func testStatusFromAgentTool() {
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Agent"), .waiting)
        XCTAssertEqual(AgentStateParser.statusFromToolUse("Task"), .waiting)
    }

    func testStatusFromUnknownTool() {
        XCTAssertEqual(AgentStateParser.statusFromToolUse("SomeNewTool"), .reading)
    }

    func testEventTypeFromWriteTool() {
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Write"), .write)
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Edit"), .write)
    }

    func testEventTypeFromReadTool() {
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Read"), .read)
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Grep"), .read)
    }

    func testEventTypeFromBashTool() {
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Bash"), .bash)
    }

    func testEventTypeFromSpawnTool() {
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Agent"), .spawn)
        XCTAssertEqual(AgentStateParser.eventTypeFromToolUse("Task"), .spawn)
    }

    // MARK: - JSONL Parsing

    func testParseValidJSONLLine() {
        let line = """
        {"type":"assistant","sessionId":"abc-123","message":{"role":"assistant","content":[{"type":"text","text":"hello"}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.type, "assistant")
        XCTAssertEqual(event?.sessionId, "abc-123")
        XCTAssertTrue(event?.isAssistant == true)
    }

    func testParseInvalidJSONLLine() {
        let event = AgentStateParser.parseJSONLLine("not json")
        XCTAssertNil(event)
    }

    func testParseEmptyLine() {
        let event = AgentStateParser.parseJSONLLine("")
        XCTAssertNil(event)
    }

    func testExtractToolUses() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Write","input":{"file_path":"/tmp/test.swift","content":"hello"}},{"type":"tool_use","id":"t2","name":"Read","input":{"file_path":"/tmp/other.swift"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let toolUses = AgentStateParser.extractToolUses(from: event)
        XCTAssertEqual(toolUses.count, 2)
        XCTAssertEqual(toolUses[0].name, "Write")
        XCTAssertEqual(toolUses[1].name, "Read")
    }

    func testExtractFilePath() {
        XCTAssertEqual(
            AgentStateParser.extractFilePath(from: ["file_path": "/tmp/test.swift"]),
            "/tmp/test.swift"
        )
        XCTAssertEqual(
            AgentStateParser.extractFilePath(from: ["command": "ls -la"]),
            "ls -la"
        )
        XCTAssertNil(AgentStateParser.extractFilePath(from: [:]))
    }

    func testIsSubagentSpawn() {
        let spawnLine = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Agent","input":{"prompt":"do something"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(spawnLine)!
        XCTAssertTrue(AgentStateParser.isSubagentSpawn(event))

        let nonSpawnLine = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Write","input":{"file_path":"/tmp/x"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event2 = AgentStateParser.parseJSONLLine(nonSpawnLine)!
        XCTAssertFalse(AgentStateParser.isSubagentSpawn(event2))
    }

    // MARK: - Token Counting

    func testExtractUsage() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[],"usage":{"input_tokens":100,"output_tokens":50,"cache_creation_input_tokens":200,"cache_read_input_tokens":300}},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let usage = AgentStateParser.extractUsage(from: event)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.input, 600) // 100 + 200 + 300
        XCTAssertEqual(usage?.output, 50)
    }

    func testEstimateCost() {
        let cost = AgentStateParser.estimateCost(inputTokens: 1_000_000, outputTokens: 100_000)
        // $15/M input + $7.5/100k output = $15 + $7.5 = $22.5
        XCTAssertEqual(cost, 22.5, accuracy: 0.01)
    }

    // MARK: - ClaudeCodeProcess

    func testProcessInitialization() {
        let proc = ClaudeCodeProcess(
            projectPath: URL(fileURLWithPath: "/tmp")
        )
        XCTAssertFalse(proc.isRunning)
        XCTAssertNil(proc.lastSessionId)
        XCTAssertTrue(proc.terminalEntries.isEmpty)
        XCTAssertNil(proc.exitCode)
    }

    func testProcessTerminalOutput() {
        let proc = ClaudeCodeProcess(
            projectPath: URL(fileURLWithPath: "/tmp")
        )
        XCTAssertEqual(proc.terminalOutput, "")
    }

    // MARK: - JSONLWatcher

    func testProjectHashConversion() {
        let hash = JSONLWatcher.projectHash(for: "/Users/brian/botcrew")
        XCTAssertEqual(hash, "-Users-brian-botcrew")
    }

    func testProjectHashWithSpaces() {
        let hash = JSONLWatcher.projectHash(for: "/Users/brian/my project")
        XCTAssertEqual(hash, "-Users-brian-my project")
    }

    func testClaudeProjectsDir() {
        let dir = JSONLWatcher.claudeProjectsDir
        XCTAssertTrue(dir.hasSuffix("/.claude/projects"))
    }

    // MARK: - AppState Session Management

    func testStartSessionCreatesRootAgent() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp/test"),
            status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        state.startSession(projectId: projectId, prompt: "hello")

        XCTAssertEqual(state.projects[0].agents.count, 1)
        XCTAssertEqual(state.projects[0].agents[0].name, "claude")
        XCTAssertNil(state.projects[0].agents[0].parentId) // root agent
        XCTAssertEqual(state.projects[0].status, .active)
        XCTAssertEqual(state.projects[0].events.count, 1)
        XCTAssertEqual(state.projects[0].events[0].type, .spawn)
    }

    func testStopSessionMarksAgentsIdle() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let agentId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp/test"),
            status: .active, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .typing,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: [], tokenCount: 0, estimatedCost: 0
        )]

        state.stopSession(projectId: projectId)

        XCTAssertEqual(state.projects[0].agents[0].status, .idle)
        XCTAssertEqual(state.projects[0].status, .idle)
    }

    func testStopSessionPreservesErrorStatus() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let agentId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp/test"),
            status: .error, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .error,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: [], tokenCount: 0, estimatedCost: 0
        )]

        state.stopSession(projectId: projectId)

        XCTAssertEqual(state.projects[0].agents[0].status, .error)
    }

    func testTerminalOutputForSelectedProject() {
        let state = AppState(skipPersistence: true)
        XCTAssertEqual(state.terminalOutputForSelectedProject, "")
    }

    func testSelectedProjectHasSession() {
        let state = AppState(skipPersistence: true)
        XCTAssertFalse(state.selectedProjectHasSession)
    }
}

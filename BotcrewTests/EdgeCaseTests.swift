// EdgeCaseTests.swift
// BotcrewTests

import XCTest
import SwiftUI
@testable import Botcrew

final class EdgeCaseTests: XCTestCase {

    // MARK: - Malformed JSONL

    func testMalformedJSONLReturnsNil() {
        XCTAssertNil(AgentStateParser.parseJSONLLine("{broken json"))
        XCTAssertNil(AgentStateParser.parseJSONLLine(""))
        XCTAssertNil(AgentStateParser.parseJSONLLine("   "))
        XCTAssertNil(AgentStateParser.parseJSONLLine("null"))
        XCTAssertNil(AgentStateParser.parseJSONLLine("[]")) // array, not object
    }

    func testPartialJSONLLine() {
        // Valid JSON but missing expected fields
        let line = "{\"type\": \"unknown\"}"
        let event = AgentStateParser.parseJSONLLine(line)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.type, "unknown")
        XCTAssertNil(event?.sessionId)
        XCTAssertNil(event?.timestamp)
        XCTAssertFalse(event?.isAssistant ?? true)
    }

    func testJSONLWithExtraFields() {
        let line = """
        {"type":"assistant","extraField":"ignored","message":{"role":"assistant","content":[]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)
        XCTAssertNotNil(event)
        XCTAssertTrue(event?.isAssistant ?? false)
    }

    func testJSONLWithNestedToolUsesMissingInput() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Write"}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let toolUses = AgentStateParser.extractToolUses(from: event)
        // Should skip tool_use without "input" field
        XCTAssertEqual(toolUses.count, 0)
    }

    func testJSONLWithMixedContentTypes() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"thinking..."},{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"/tmp/x"}}]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let toolUses = AgentStateParser.extractToolUses(from: event)
        XCTAssertEqual(toolUses.count, 1)
        XCTAssertEqual(toolUses[0].name, "Read")
    }

    // MARK: - Rapid State Changes

    func testRapidAgentStatusUpdates() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let agentId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .idle,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        // Rapidly cycle through all statuses
        let statuses: [AgentStatus] = [.typing, .reading, .waiting, .idle, .error, .typing, .idle]
        for status in statuses {
            state.projects[0].agents[0].status = status
        }
        XCTAssertEqual(state.projects[0].agents[0].status, .idle)
    }

    func testManyEventsAppended() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let agentId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .typing,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        state.selectAgent(agentId)

        // Add 500 events rapidly
        for i in 0..<500 {
            state.projects[0].events.append(ActivityEvent(
                id: UUID(), agentId: agentId, timestamp: Date().addingTimeInterval(Double(i)),
                type: i % 2 == 0 ? .write : .read, file: "file\(i).swift", meta: "Event \(i)"
            ))
        }

        XCTAssertEqual(state.projects[0].events.count, 500)
        XCTAssertEqual(state.eventsForSelectedAgent.count, 500)
    }

    // MARK: - Agent Hierarchy Edge Cases

    func testOrphanedSubAgent() {
        // Sub-agent with parentId that doesn't match any root
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let orphanParentId = UUID() // doesn't exist
        let subId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: [
                Agent(id: subId, name: "orphan", parentId: orphanParentId, status: .idle,
                      bodyColor: .green, shirtColor: .green, spawnTime: Date())
            ], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        // No root agents (the orphan has a parentId so it's not a root)
        XCTAssertTrue(state.rootAgents.isEmpty)
        // Sub agents for the non-existent root should include the orphan
        XCTAssertEqual(state.subAgents(for: orphanParentId).count, 1)
    }

    func testDeepAgentHierarchy() {
        // 3 roots with 5 subs each = 18 agents
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        var agents: [Agent] = []
        var rootIds: [UUID] = []

        for i in 0..<3 {
            let rootId = UUID()
            rootIds.append(rootId)
            agents.append(Agent(id: rootId, name: "root-\(i)", parentId: nil, status: .typing,
                                bodyColor: .purple, shirtColor: .purple, spawnTime: Date()))
            for j in 0..<5 {
                agents.append(Agent(id: UUID(), name: "sub-\(i)-\(j)", parentId: rootId, status: .idle,
                                    bodyColor: .green, shirtColor: .green, spawnTime: Date()))
            }
        }

        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: agents, events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        XCTAssertEqual(state.rootAgents.count, 3)
        for rootId in rootIds {
            XCTAssertEqual(state.subAgents(for: rootId).count, 5)
        }
    }

    // MARK: - Project Edge Cases

    func testSelectNonExistentProject() {
        let state = AppState(skipPersistence: true)
        state.projects = []
        state.selectProject(UUID())
        XCTAssertNil(state.selectedProject)
    }

    func testRemoveNonExistentProject() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        state.removeProject(UUID()) // non-existent
        XCTAssertEqual(state.projects.count, 1) // unchanged
        XCTAssertEqual(state.selectedProjectId, projectId) // unchanged
    }

    func testRemoveSelectedProjectSelectsFirst() {
        let state = AppState(skipPersistence: true)
        let p1 = UUID()
        let p2 = UUID()
        state.projects = [
            Project(id: p1, name: "first", path: URL(fileURLWithPath: "/tmp/a"),
                    status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0),
            Project(id: p2, name: "second", path: URL(fileURLWithPath: "/tmp/b"),
                    status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0),
        ]
        state.selectedProjectId = p2
        state.removeProject(p2)
        XCTAssertEqual(state.selectedProjectId, p1) // falls back to first
    }

    func testRemoveLastProject() {
        let state = AppState(skipPersistence: true)
        let p1 = UUID()
        state.projects = [Project(
            id: p1, name: "only", path: URL(fileURLWithPath: "/tmp"),
            status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = p1
        state.removeProject(p1)
        XCTAssertTrue(state.projects.isEmpty)
        XCTAssertNil(state.selectedProjectId)
    }

    // MARK: - Token/Cost Edge Cases

    func testZeroTokenEstimate() {
        let cost = AgentStateParser.estimateCost(inputTokens: 0, outputTokens: 0)
        XCTAssertEqual(cost, 0.0)
    }

    func testLargeTokenCount() {
        let cost = AgentStateParser.estimateCost(inputTokens: 10_000_000, outputTokens: 1_000_000)
        // $150 input + $75 output = $225
        XCTAssertEqual(cost, 225.0, accuracy: 0.01)
    }

    func testUsageWithMissingFields() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[],"usage":{}},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let usage = AgentStateParser.extractUsage(from: event)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.input, 0)
        XCTAssertEqual(usage?.output, 0)
    }

    func testUsageWithNoUsageField() {
        let line = """
        {"type":"assistant","message":{"role":"assistant","content":[]},"timestamp":"2026-03-17T12:00:00.000Z"}
        """
        let event = AgentStateParser.parseJSONLLine(line)!
        let usage = AgentStateParser.extractUsage(from: event)
        XCTAssertNil(usage)
    }

    // MARK: - Color Extension

    func testColorHexBlack() {
        let color = Color(hex: 0x000000)
        // Can't easily inspect Color values, but ensure it doesn't crash
        XCTAssertNotNil(color)
    }

    func testColorHexWhite() {
        let color = Color(hex: 0xFFFFFF)
        XCTAssertNotNil(color)
    }

    func testColorHexSystemBlue() {
        let color = Color(hex: 0x0A84FF)
        XCTAssertNotNil(color)
    }

    // MARK: - ClaudeCodeProcess Edge Cases

    func testProcessDoubleStart() {
        let proc = ClaudeCodeProcess(
            projectPath: URL(fileURLWithPath: "/tmp")
        )
        // Should not crash if process isn't actually running
        XCTAssertFalse(proc.isRunning)
    }

    func testProcessStopWhenNotRunning() {
        let proc = ClaudeCodeProcess(
            projectPath: URL(fileURLWithPath: "/tmp")
        )
        // Stopping when not running should be a no-op
        proc.stop()
        XCTAssertFalse(proc.isRunning)
    }

    // MARK: - JSONLWatcher Edge Cases

    func testWatchNonExistentFile() {
        let watcher = JSONLWatcher()
        watcher.watchFile(at: "/nonexistent/path/file.jsonl")
        XCTAssertFalse(watcher.isWatching) // should not crash, just skip
    }

    func testFindLatestSessionNonExistentProject() {
        let result = JSONLWatcher.findLatestSession(for: "/nonexistent/project/path")
        XCTAssertNil(result)
    }

    func testReadAllEventsNonExistentFile() {
        let events = JSONLWatcher.readAllEvents(from: "/nonexistent/file.jsonl")
        XCTAssertTrue(events.isEmpty)
    }

    func testStopAllWhenNothingWatching() {
        let watcher = JSONLWatcher()
        watcher.stopAll() // should not crash
        XCTAssertFalse(watcher.isWatching)
    }

    // MARK: - SpriteData Edge Cases

    func testAllShapesAre8x10() {
        let shapes: [[[Int]]] = [SpriteData.body, SpriteData.type, SpriteData.shrug, SpriteData.error]
        for shape in shapes {
            XCTAssertEqual(shape.count, SpriteData.gridHeight)
            for row in shape {
                XCTAssertEqual(row.count, SpriteData.gridWidth)
            }
        }
    }

    func testAllShapesUseValidPixelValues() {
        let validValues: Set<Int> = [0, 1, 2, 3, 6]
        let shapes: [[[Int]]] = [SpriteData.body, SpriteData.type, SpriteData.shrug, SpriteData.error]
        for shape in shapes {
            for row in shape {
                for val in row {
                    XCTAssertTrue(validValues.contains(val), "Invalid pixel value: \(val)")
                }
            }
        }
    }

    func testShapeForAllStatuses() {
        for status in AgentStatus.allCases {
            let shape = SpriteData.shape(for: status)
            XCTAssertEqual(shape.count, SpriteData.gridHeight)
            XCTAssertEqual(shape[0].count, SpriteData.gridWidth)
        }
    }

    // MARK: - BobParams Edge Cases

    func testBobParamsAllPositive() {
        for status in AgentStatus.allCases {
            let params = BobParams.forStatus(status)
            XCTAssertGreaterThan(params.frequency, 0)
            XCTAssertGreaterThan(params.amplitude, 0)
        }
    }

    func testReadingBobParamsDistinctFromIdle() {
        let reading = BobParams.forStatus(.reading)
        let idle = BobParams.forStatus(.idle)
        XCTAssertNotEqual(reading.frequency, idle.frequency)
    }
}

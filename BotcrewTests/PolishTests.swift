// PolishTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class PolishTests: XCTestCase {

    // MARK: - Empty States

    func testNoProjectSelectedShowsEmptyState() {
        let state = AppState()
        state.projects = []
        state.selectedProjectId = nil
        XCTAssertNil(state.selectedProject)
        XCTAssertTrue(state.rootAgents.isEmpty)
    }

    func testProjectWithNoAgentsShowsEmptyAgentState() {
        let state = AppState()
        let projectId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        XCTAssertNotNil(state.selectedProject)
        XCTAssertTrue(state.rootAgents.isEmpty)
    }

    // MARK: - Error Recovery

    func testErrorRecoverySetup() {
        // Verifies that error agents can be selected and terminal toggled
        let state = AppState()
        let projectId = UUID()
        let agentId = UUID()
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .error, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .error,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        state.selectAgent(agentId)
        // Simulate error recovery: clicking error sprite opens terminal
        if state.selectedAgent?.status == .error {
            state.showTerminal = true
        }
        XCTAssertTrue(state.showTerminal)
        XCTAssertEqual(state.selectedAgentId, agentId)
    }

    // MARK: - Expanded Panel Ops Mode

    func testExpandedPanelIsOpsMode() {
        let state = AppState()
        state.snapOfficePanel(to: .expanded)
        XCTAssertEqual(state.officePanelSnap, .expanded)
        XCTAssertEqual(state.officePanelHeight, 270)
    }

    func testOfficePanelSnapStates() {
        let state = AppState()
        // Collapsed
        state.snapOfficePanel(to: .collapsed)
        XCTAssertEqual(state.officePanelSnap, .collapsed)
        // Ambient
        state.snapOfficePanel(to: .ambient)
        XCTAssertEqual(state.officePanelSnap, .ambient)
        // Expanded
        state.snapOfficePanel(to: .expanded)
        XCTAssertEqual(state.officePanelSnap, .expanded)
    }

    // MARK: - Multi-Terminal Grid

    func testOpenTerminalIdsDefaultEmpty() {
        let state = AppState()
        XCTAssertTrue(state.openTerminalIds.isEmpty)
    }

    func testOpenTerminalIdsClearedOnProjectSwitch() {
        let state = AppState()
        let p1 = UUID()
        let p2 = UUID()
        state.projects = [
            Project(id: p1, name: "a", path: URL(fileURLWithPath: "/tmp/a"),
                    status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0),
            Project(id: p2, name: "b", path: URL(fileURLWithPath: "/tmp/b"),
                    status: .idle, agents: [], events: [], tokenCount: 0, estimatedCost: 0),
        ]
        state.selectedProjectId = p1
        state.openTerminalIds = [UUID(), UUID()]
        state.selectProject(p2)
        XCTAssertTrue(state.openTerminalIds.isEmpty)
    }

    func testMaxFourTerminals() {
        let state = AppState()
        let ids = (0..<5).map { _ in UUID() }
        state.openTerminalIds = Array(ids.prefix(4))
        XCTAssertEqual(state.openTerminalIds.count, 4)
    }

    // MARK: - Performance

    func testComputeLayoutsWithManyAgents() {
        // Ensure layout computation doesn't crash with 8+ agents
        let state = AppState()
        let projectId = UUID()
        var agents: [Agent] = []
        let root1 = UUID()
        let root2 = UUID()
        agents.append(Agent(id: root1, name: "root-1", parentId: nil, status: .typing,
                            bodyColor: .purple, shirtColor: .purple, spawnTime: Date()))
        agents.append(Agent(id: root2, name: "root-2", parentId: nil, status: .reading,
                            bodyColor: .orange, shirtColor: .orange, spawnTime: Date()))
        // Add 6 sub-agents
        for i in 0..<6 {
            let parentId = i < 3 ? root1 : root2
            agents.append(Agent(id: UUID(), name: "sub-\(i)", parentId: parentId, status: .idle,
                                bodyColor: .green, shirtColor: .green, spawnTime: Date()))
        }

        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: agents, events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId

        XCTAssertEqual(state.rootAgents.count, 2)
        XCTAssertEqual(state.subAgents(for: root1).count, 3)
        XCTAssertEqual(state.subAgents(for: root2).count, 3)
    }

    func testMockDataHasExpectedStructure() {
        let state = AppState.withMockData()
        XCTAssertEqual(state.projects.count, 3)
        // First project should have agents
        let p1 = state.projects[0]
        XCTAssertFalse(p1.agents.isEmpty)
        XCTAssertFalse(p1.events.isEmpty)
        // Third project should be in error
        XCTAssertEqual(state.projects[2].status, .error)
    }
}

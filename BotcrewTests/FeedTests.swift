// FeedTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class FeedTests: XCTestCase {

    private func makeAgent(id: UUID = UUID(), name: String = "agent", parentId: UUID? = nil) -> Agent {
        Agent(id: id, name: name, parentId: parentId, status: .idle,
              bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
    }

    private func makeEvent(agentId: UUID, type: EventType = .write, secondsAgo: Double = 0) -> ActivityEvent {
        ActivityEvent(id: UUID(), agentId: agentId, timestamp: Date().addingTimeInterval(-secondsAgo),
                      type: type, file: "test.swift", meta: "mock")
    }

    // MARK: - eventsForSelectedAgent

    func testEventsFilteredByAgent() {
        let state = AppState()
        let agent1 = makeAgent(id: UUID(), name: "a1")
        let agent2 = makeAgent(id: UUID(), name: "a2")
        let events = [
            makeEvent(agentId: agent1.id, type: .write, secondsAgo: 10),
            makeEvent(agentId: agent1.id, type: .read, secondsAgo: 5),
            makeEvent(agentId: agent2.id, type: .bash, secondsAgo: 3),
        ]
        let project = Project(id: UUID(), name: "Test", path: URL(fileURLWithPath: "/tmp"),
                              status: .active, agents: [agent1, agent2], events: events,
                              tokenCount: 0, estimatedCost: 0)
        state.projects = [project]
        state.selectedProjectId = project.id
        state.selectedAgentId = agent1.id

        let filtered = state.eventsForSelectedAgent
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.agentId == agent1.id })
    }

    func testEventsOrderedNewestFirst() {
        let state = AppState()
        let agentId = UUID()
        let agent = makeAgent(id: agentId)
        let events = [
            makeEvent(agentId: agentId, type: .write, secondsAgo: 30),
            makeEvent(agentId: agentId, type: .read, secondsAgo: 10),
            makeEvent(agentId: agentId, type: .bash, secondsAgo: 20),
        ]
        let project = Project(id: UUID(), name: "Test", path: URL(fileURLWithPath: "/tmp"),
                              status: .active, agents: [agent], events: events,
                              tokenCount: 0, estimatedCost: 0)
        state.projects = [project]
        state.selectedProjectId = project.id
        state.selectedAgentId = agentId

        let sorted = state.eventsForSelectedAgent
        XCTAssertEqual(sorted.count, 3)
        // Newest first: secondsAgo 10, 20, 30
        XCTAssertEqual(sorted[0].type, .read)
        XCTAssertEqual(sorted[1].type, .bash)
        XCTAssertEqual(sorted[2].type, .write)
    }

    func testEventsEmptyWhenNoAgentSelected() {
        let state = AppState()
        let agentId = UUID()
        let events = [makeEvent(agentId: agentId)]
        let project = Project(id: UUID(), name: "Test", path: URL(fileURLWithPath: "/tmp"),
                              status: .active, agents: [makeAgent(id: agentId)], events: events,
                              tokenCount: 0, estimatedCost: 0)
        state.projects = [project]
        state.selectedProjectId = project.id
        state.selectedAgentId = nil

        XCTAssertTrue(state.eventsForSelectedAgent.isEmpty)
    }

    func testEventsEmptyWhenNoProjectSelected() {
        let state = AppState()
        XCTAssertTrue(state.eventsForSelectedAgent.isEmpty)
    }

    // MARK: - showTerminal toggle

    func testShowTerminalDefaultsFalse() {
        let state = AppState()
        XCTAssertFalse(state.showTerminal)
    }

    func testShowTerminalToggles() {
        let state = AppState()
        state.showTerminal = true
        XCTAssertTrue(state.showTerminal)
        state.showTerminal = false
        XCTAssertFalse(state.showTerminal)
    }
}

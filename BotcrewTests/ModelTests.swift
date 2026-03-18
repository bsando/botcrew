// ModelTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class ModelTests: XCTestCase {

    // MARK: - Agent hierarchy

    func testRootAgentHasNilParent() {
        let agent = Agent(
            id: UUID(),
            name: "orchestrator",
            parentId: nil,
            status: .idle,
            bodyColor: .purple,
            shirtColor: .purple,
            spawnTime: Date()
        )
        XCTAssertNil(agent.parentId)
    }

    func testSubAgentHasParentId() {
        let rootId = UUID()
        let sub = Agent(
            id: UUID(),
            name: "writer-1",
            parentId: rootId,
            status: .typing,
            bodyColor: .green,
            shirtColor: .green,
            spawnTime: Date()
        )
        XCTAssertEqual(sub.parentId, rootId)
    }

    // MARK: - Project agents

    func testProjectContainsAgents() {
        let agents = [
            Agent(id: UUID(), name: "root", parentId: nil, status: .idle, bodyColor: .purple, shirtColor: .purple, spawnTime: Date()),
            Agent(id: UUID(), name: "sub", parentId: nil, status: .typing, bodyColor: .green, shirtColor: .green, spawnTime: Date()),
        ]
        let project = Project(
            id: UUID(),
            name: "test",
            path: URL(fileURLWithPath: "/tmp"),
            status: .active,
            agents: agents,
            events: [],
            tokenCount: 1500,
            estimatedCost: 0.03
        )
        XCTAssertEqual(project.agents.count, 2)
        XCTAssertEqual(project.tokenCount, 1500)
    }

    // MARK: - ActivityEvent

    func testActivityEventStoresMetadata() {
        let agentId = UUID()
        let event = ActivityEvent(
            id: UUID(),
            agentId: agentId,
            timestamp: Date(),
            type: .write,
            file: "ContentView.swift",
            meta: "Added new view"
        )
        XCTAssertEqual(event.agentId, agentId)
        XCTAssertEqual(event.type, .write)
        XCTAssertEqual(event.file, "ContentView.swift")
    }

    func testActivityEventOptionalFieldsCanBeNil() {
        let event = ActivityEvent(
            id: UUID(),
            agentId: UUID(),
            timestamp: Date(),
            type: .thinking,
            file: nil,
            meta: nil
        )
        XCTAssertNil(event.file)
        XCTAssertNil(event.meta)
    }

    // MARK: - Enums cover all cases

    func testAgentStatusHasAllExpectedCases() {
        let cases = AgentStatus.allCases
        XCTAssertTrue(cases.contains(.typing))
        XCTAssertTrue(cases.contains(.reading))
        XCTAssertTrue(cases.contains(.waiting))
        XCTAssertTrue(cases.contains(.idle))
        XCTAssertTrue(cases.contains(.error))
        XCTAssertEqual(cases.count, 5)
    }

    func testEventTypeHasAllExpectedCases() {
        let cases = EventType.allCases
        XCTAssertTrue(cases.contains(.spawn))
        XCTAssertTrue(cases.contains(.write))
        XCTAssertTrue(cases.contains(.read))
        XCTAssertTrue(cases.contains(.bash))
        XCTAssertTrue(cases.contains(.thinking))
        XCTAssertTrue(cases.contains(.error))
        XCTAssertEqual(cases.count, 6)
    }

    func testProjectStatusHasAllExpectedCases() {
        let cases = ProjectStatus.allCases
        XCTAssertEqual(cases.count, 3)
    }
}

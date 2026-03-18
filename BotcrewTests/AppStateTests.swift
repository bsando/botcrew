// AppStateTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class AppStateTests: XCTestCase {

    private func makeAgent(
        id: UUID = UUID(),
        name: String = "agent",
        parentId: UUID? = nil,
        status: AgentStatus = .idle
    ) -> Agent {
        Agent(
            id: id,
            name: name,
            parentId: parentId,
            status: status,
            bodyColor: .purple,
            shirtColor: .purple,
            spawnTime: Date()
        )
    }

    private func makeProject(
        id: UUID = UUID(),
        name: String = "TestProject",
        agents: [Agent] = []
    ) -> Project {
        Project(
            id: id,
            name: name,
            path: URL(fileURLWithPath: "/tmp/test"),
            status: .active,
            agents: agents,
            tokenCount: 0,
            estimatedCost: 0
        )
    }

    // MARK: - Selection

    func testSelectedProjectReturnsCorrectProject() {
        let state = AppState()
        let project = makeProject()
        state.projects = [project]
        state.selectedProjectId = project.id
        XCTAssertEqual(state.selectedProject?.id, project.id)
    }

    func testSelectedProjectReturnsNilWhenNoMatch() {
        let state = AppState()
        state.projects = [makeProject()]
        state.selectedProjectId = UUID()
        XCTAssertNil(state.selectedProject)
    }

    func testSelectedProjectReturnsNilWhenNothingSelected() {
        let state = AppState()
        state.projects = [makeProject()]
        state.selectedProjectId = nil
        XCTAssertNil(state.selectedProject)
    }

    func testSelectedAgentReturnsCorrectAgent() {
        let state = AppState()
        let agent = makeAgent(name: "writer-1")
        let project = makeProject(agents: [agent])
        state.projects = [project]
        state.selectedProjectId = project.id
        state.selectedAgentId = agent.id
        XCTAssertEqual(state.selectedAgent?.id, agent.id)
        XCTAssertEqual(state.selectedAgent?.name, "writer-1")
    }

    func testSelectedAgentReturnsNilWhenNoProjectSelected() {
        let state = AppState()
        let agent = makeAgent()
        let project = makeProject(agents: [agent])
        state.projects = [project]
        state.selectedProjectId = nil
        state.selectedAgentId = agent.id
        XCTAssertNil(state.selectedAgent)
    }

    func testSelectedAgentReturnsNilWhenAgentNotInProject() {
        let state = AppState()
        let project = makeProject(agents: [makeAgent()])
        state.projects = [project]
        state.selectedProjectId = project.id
        state.selectedAgentId = UUID()
        XCTAssertNil(state.selectedAgent)
    }

    // MARK: - Defaults

    func testInitialStateIsEmpty() {
        let state = AppState()
        XCTAssertTrue(state.projects.isEmpty)
        XCTAssertNil(state.selectedProjectId)
        XCTAssertNil(state.selectedAgentId)
        XCTAssertNil(state.activeClusterId)
        XCTAssertTrue(state.openTerminalIds.isEmpty)
    }
}

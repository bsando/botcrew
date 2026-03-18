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
        agents: [Agent] = [],
        tokenCount: Int = 0,
        estimatedCost: Double = 0
    ) -> Project {
        Project(
            id: id,
            name: name,
            path: URL(fileURLWithPath: "/tmp/test"),
            status: .active,
            agents: agents,
            events: [],
            tokenCount: tokenCount,
            estimatedCost: estimatedCost
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
        XCTAssertFalse(state.isSidebarCollapsed)
        XCTAssertFalse(state.showAddProjectSheet)
    }

    // MARK: - selectProject

    func testSelectProjectSetsIdAndClearsAgent() {
        let state = AppState()
        let agent = makeAgent()
        let p1 = makeProject(agents: [agent])
        let p2 = makeProject(name: "Other")
        state.projects = [p1, p2]
        state.selectedProjectId = p1.id
        state.selectedAgentId = agent.id
        state.activeClusterId = UUID()
        state.openTerminalIds = [UUID()]

        state.selectProject(p2.id)

        XCTAssertEqual(state.selectedProjectId, p2.id)
        XCTAssertNil(state.selectedAgentId)
        XCTAssertNil(state.activeClusterId)
        XCTAssertTrue(state.openTerminalIds.isEmpty)
    }

    // MARK: - removeProject

    func testRemoveProjectRemovesFromList() {
        let state = AppState()
        let p1 = makeProject(name: "A")
        let p2 = makeProject(name: "B")
        state.projects = [p1, p2]
        state.selectedProjectId = p1.id

        state.removeProject(p1.id)

        XCTAssertEqual(state.projects.count, 1)
        XCTAssertEqual(state.projects.first?.name, "B")
    }

    func testRemoveSelectedProjectSelectsFirst() {
        let state = AppState()
        let p1 = makeProject(name: "A")
        let p2 = makeProject(name: "B")
        state.projects = [p1, p2]
        state.selectedProjectId = p1.id

        state.removeProject(p1.id)

        XCTAssertEqual(state.selectedProjectId, p2.id)
    }

    func testRemoveNonSelectedProjectKeepsSelection() {
        let state = AppState()
        let p1 = makeProject(name: "A")
        let p2 = makeProject(name: "B")
        state.projects = [p1, p2]
        state.selectedProjectId = p1.id

        state.removeProject(p2.id)

        XCTAssertEqual(state.selectedProjectId, p1.id)
        XCTAssertEqual(state.projects.count, 1)
    }

    func testRemoveLastProjectClearsSelection() {
        let state = AppState()
        let p1 = makeProject()
        state.projects = [p1]
        state.selectedProjectId = p1.id

        state.removeProject(p1.id)

        XCTAssertTrue(state.projects.isEmpty)
        XCTAssertNil(state.selectedProjectId)
    }

    // MARK: - addProject

    func testAddProjectAppendsAndSelects() {
        let state = AppState()
        XCTAssertTrue(state.projects.isEmpty)

        state.addProject(name: "NewProject", path: URL(fileURLWithPath: "/tmp/new"))

        XCTAssertEqual(state.projects.count, 1)
        XCTAssertEqual(state.projects.first?.name, "NewProject")
        XCTAssertEqual(state.selectedProjectId, state.projects.first?.id)
    }

    func testAddProjectSetsIdleStatus() {
        let state = AppState()
        state.addProject(name: "Test", path: URL(fileURLWithPath: "/tmp"))
        XCTAssertEqual(state.projects.first?.status, .idle)
        XCTAssertTrue(state.projects.first?.agents.isEmpty ?? false)
    }

    // MARK: - Mock data

    func testMockDataHasThreeProjects() {
        let state = AppState.withMockData()
        XCTAssertEqual(state.projects.count, 3)
        XCTAssertNotNil(state.selectedProjectId)
    }

    func testMockDataFirstProjectHasAgents() {
        let state = AppState.withMockData()
        XCTAssertEqual(state.selectedProject?.agents.count, 6)
    }

    func testMockDataHasErrorProject() {
        let state = AppState.withMockData()
        let errorProjects = state.projects.filter { $0.status == .error }
        XCTAssertEqual(errorProjects.count, 1)
    }
}

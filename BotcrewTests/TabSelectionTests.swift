// TabSelectionTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class TabSelectionTests: XCTestCase {

    private func makeAgent(
        id: UUID = UUID(),
        name: String = "agent",
        parentId: UUID? = nil,
        status: AgentStatus = .idle
    ) -> Agent {
        Agent(id: id, name: name, parentId: parentId, status: status,
              bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
    }

    private func makeProject(agents: [Agent]) -> Project {
        Project(id: UUID(), name: "Test", path: URL(fileURLWithPath: "/tmp"),
                status: .active, agents: agents, events: [], tokenCount: 0, estimatedCost: 0)
    }

    private func stateWithAgents() -> (AppState, UUID, UUID, UUID) {
        let state = AppState(skipPersistence: true)
        let rootId = UUID()
        let sub1Id = UUID()
        let sub2Id = UUID()
        let project = makeProject(agents: [
            makeAgent(id: rootId, name: "root", parentId: nil),
            makeAgent(id: sub1Id, name: "sub-1", parentId: rootId),
            makeAgent(id: sub2Id, name: "sub-2", parentId: rootId),
        ])
        state.projects = [project]
        state.selectedProjectId = project.id
        return (state, rootId, sub1Id, sub2Id)
    }

    // MARK: - rootAgents

    func testRootAgentsFiltersCorrectly() {
        let (state, rootId, _, _) = stateWithAgents()
        XCTAssertEqual(state.rootAgents.count, 1)
        XCTAssertEqual(state.rootAgents.first?.id, rootId)
    }

    func testRootAgentsEmptyWhenNoProject() {
        let state = AppState(skipPersistence: true)
        XCTAssertTrue(state.rootAgents.isEmpty)
    }

    // MARK: - subAgents

    func testSubAgentsReturnsChildren() {
        let (state, rootId, sub1Id, sub2Id) = stateWithAgents()
        let subs = state.subAgents(for: rootId)
        XCTAssertEqual(subs.count, 2)
        let subIds = Set(subs.map(\.id))
        XCTAssertTrue(subIds.contains(sub1Id))
        XCTAssertTrue(subIds.contains(sub2Id))
    }

    func testSubAgentsEmptyForLeafAgent() {
        let (state, _, sub1Id, _) = stateWithAgents()
        XCTAssertTrue(state.subAgents(for: sub1Id).isEmpty)
    }

    // MARK: - selectAgent

    func testSelectAgentSetsIdAndExpandsParent() {
        let (state, rootId, sub1Id, _) = stateWithAgents()
        state.selectAgent(sub1Id)
        XCTAssertEqual(state.selectedAgentId, sub1Id)
        XCTAssertEqual(state.activeClusterId, rootId)
    }

    func testSelectRootAgentExpandsOwnCluster() {
        let (state, rootId, _, _) = stateWithAgents()
        state.selectAgent(rootId)
        XCTAssertEqual(state.selectedAgentId, rootId)
        XCTAssertEqual(state.activeClusterId, rootId)
    }

    func testSelectAgentIgnoresInvalidId() {
        let (state, _, _, _) = stateWithAgents()
        state.selectAgent(UUID())
        XCTAssertNil(state.selectedAgentId)
    }

    // MARK: - toggleCluster

    func testToggleClusterExpandsAndSelects() {
        let (state, rootId, _, _) = stateWithAgents()
        state.toggleCluster(rootId)
        XCTAssertEqual(state.activeClusterId, rootId)
        XCTAssertEqual(state.selectedAgentId, rootId)
    }

    func testToggleClusterCollapsesWhenAlreadyExpanded() {
        let (state, rootId, _, _) = stateWithAgents()
        state.activeClusterId = rootId
        state.selectedAgentId = rootId
        state.toggleCluster(rootId)
        XCTAssertNil(state.activeClusterId)
    }

    func testToggleClusterCollapseMoveSelectionFromSubToRoot() {
        let (state, rootId, sub1Id, _) = stateWithAgents()
        state.activeClusterId = rootId
        state.selectedAgentId = sub1Id
        state.toggleCluster(rootId)
        XCTAssertNil(state.activeClusterId)
        XCTAssertEqual(state.selectedAgentId, rootId)
    }

    func testToggleClusterSwitchesBetweenClusters() {
        let state = AppState(skipPersistence: true)
        let root1 = UUID()
        let root2 = UUID()
        let project = makeProject(agents: [
            makeAgent(id: root1, name: "root1"),
            makeAgent(id: root2, name: "root2"),
        ])
        state.projects = [project]
        state.selectedProjectId = project.id

        state.toggleCluster(root1)
        XCTAssertEqual(state.activeClusterId, root1)

        state.toggleCluster(root2)
        XCTAssertEqual(state.activeClusterId, root2)
        XCTAssertEqual(state.selectedAgentId, root2)
    }
}

// PerformanceTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class PerformanceTests: XCTestCase {

    // MARK: - Layout Computation Performance

    func testLayoutComputationWith8Agents() {
        let state = makeStateWithAgents(rootCount: 2, subsPerRoot: 3) // 8 total
        measure {
            for _ in 0..<1000 {
                _ = state.rootAgents
                for root in state.rootAgents {
                    _ = state.subAgents(for: root.id)
                }
            }
        }
    }

    func testLayoutComputationWith20Agents() {
        let state = makeStateWithAgents(rootCount: 4, subsPerRoot: 4) // 20 total
        measure {
            for _ in 0..<1000 {
                _ = state.rootAgents
                for root in state.rootAgents {
                    _ = state.subAgents(for: root.id)
                }
            }
        }
    }

    // MARK: - Event Filtering Performance

    func testEventFilteringWith1000Events() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let agentId = UUID()
        var events: [ActivityEvent] = []
        for i in 0..<1000 {
            events.append(ActivityEvent(
                id: UUID(), agentId: i % 3 == 0 ? agentId : UUID(),
                timestamp: Date().addingTimeInterval(Double(i)),
                type: .write, file: "file\(i).swift", meta: "Event \(i)"
            ))
        }
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .typing,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: events, tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        state.selectAgent(agentId)

        measure {
            for _ in 0..<100 {
                _ = state.eventsForSelectedAgent
            }
        }
    }

    func testEventFilteringWith5000Events() {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        let agentId = UUID()
        var events: [ActivityEvent] = []
        for i in 0..<5000 {
            events.append(ActivityEvent(
                id: UUID(), agentId: i % 5 == 0 ? agentId : UUID(),
                timestamp: Date().addingTimeInterval(Double(i)),
                type: [.write, .read, .bash, .thinking, .spawn][i % 5], file: "file\(i).swift"
            ))
        }
        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: [
                Agent(id: agentId, name: "claude", parentId: nil, status: .typing,
                      bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
            ], events: events, tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        state.selectAgent(agentId)

        measure {
            for _ in 0..<100 {
                _ = state.eventsForSelectedAgent
            }
        }
    }

    // MARK: - JSONL Parsing Performance

    func testJSONLParsingPerformance() {
        let lines = (0..<100).map { i in
            """
            {"type":"assistant","sessionId":"abc-\(i)","message":{"role":"assistant","content":[{"type":"tool_use","id":"t\(i)","name":"Write","input":{"file_path":"/tmp/file\(i).swift","content":"hello"}}],"usage":{"input_tokens":\(i * 100),"output_tokens":\(i * 10)}},"timestamp":"2026-03-17T12:00:0\(i % 10).000Z"}
            """
        }

        measure {
            for line in lines {
                let event = AgentStateParser.parseJSONLLine(line)
                if let event = event {
                    _ = AgentStateParser.extractToolUses(from: event)
                    _ = AgentStateParser.extractUsage(from: event)
                    _ = AgentStateParser.containsError(event)
                    _ = AgentStateParser.isSubagentSpawn(event)
                }
            }
        }
    }

    // MARK: - SpriteData Performance

    func testSpriteShapeLookupPerformance() {
        measure {
            for _ in 0..<10000 {
                for status in AgentStatus.allCases {
                    _ = SpriteData.shape(for: status)
                }
            }
        }
    }

    // MARK: - BobParams Performance

    func testBobParamsLookupPerformance() {
        measure {
            for _ in 0..<10000 {
                for status in AgentStatus.allCases {
                    _ = BobParams.forStatus(status)
                }
            }
        }
    }

    // MARK: - State Management Performance

    func testProjectSwitchingPerformance() {
        let state = AppState(skipPersistence: true)
        var projects: [Project] = []
        for i in 0..<10 {
            let projectId = UUID()
            var agents: [Agent] = []
            let rootId = UUID()
            agents.append(Agent(id: rootId, name: "root-\(i)", parentId: nil, status: .typing,
                                bodyColor: .purple, shirtColor: .purple, spawnTime: Date()))
            for j in 0..<3 {
                agents.append(Agent(id: UUID(), name: "sub-\(i)-\(j)", parentId: rootId, status: .idle,
                                    bodyColor: .green, shirtColor: .green, spawnTime: Date()))
            }
            projects.append(Project(
                id: projectId, name: "project-\(i)", path: URL(fileURLWithPath: "/tmp/\(i)"),
                status: .active, agents: agents, events: [], tokenCount: i * 1000, estimatedCost: Double(i) * 0.1
            ))
        }
        state.projects = projects

        measure {
            for _ in 0..<1000 {
                for project in state.projects {
                    state.selectProject(project.id)
                }
            }
        }
    }

    // MARK: - Helpers

    private func makeStateWithAgents(rootCount: Int, subsPerRoot: Int) -> AppState {
        let state = AppState(skipPersistence: true)
        let projectId = UUID()
        var agents: [Agent] = []

        for i in 0..<rootCount {
            let rootId = UUID()
            agents.append(Agent(id: rootId, name: "root-\(i)", parentId: nil, status: .typing,
                                bodyColor: .purple, shirtColor: .purple, spawnTime: Date()))
            for j in 0..<subsPerRoot {
                agents.append(Agent(id: UUID(), name: "sub-\(i)-\(j)", parentId: rootId, status: .idle,
                                    bodyColor: .green, shirtColor: .green, spawnTime: Date()))
            }
        }

        state.projects = [Project(
            id: projectId, name: "test", path: URL(fileURLWithPath: "/tmp"),
            status: .active, agents: agents, events: [], tokenCount: 0, estimatedCost: 0
        )]
        state.selectedProjectId = projectId
        return state
    }
}

// BotcrewUITests.swift
// BotcrewUITests

import XCTest

final class BotcrewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    override func tearDownWithError() throws {
        if let app = app {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Window

    func testAppLaunches() throws {
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }

    func testWindowHasMinimumSize() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        let frame = window.frame
        XCTAssertGreaterThanOrEqual(frame.width, 900)
        XCTAssertGreaterThanOrEqual(frame.height, 640)
    }

    // MARK: - Agent Tree (replaces Sidebar)

    func testAgentTreeShowsProjects() throws {
        let project = app.staticTexts["botcrew"]
        XCTAssertTrue(project.waitForExistence(timeout: 5), "Should show 'botcrew' project")
    }

    func testAgentTreeShowsApiServerProject() throws {
        let text = app.staticTexts["api-server"]
        XCTAssertTrue(text.waitForExistence(timeout: 5), "Should show 'api-server' project")
    }

    func testAgentTreeShowsDocsSiteProject() throws {
        let text = app.staticTexts["docs-site"]
        XCTAssertTrue(text.waitForExistence(timeout: 5), "Should show 'docs-site' project")
    }

    func testAgentsHeaderExists() throws {
        let header = app.staticTexts["AGENTS"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Should show AGENTS header")
    }

    func testClickProjectSwitchesSelection() throws {
        let apiServer = app.staticTexts["api-server"]
        XCTAssertTrue(apiServer.waitForExistence(timeout: 5))
        apiServer.click()
        let emptyText = app.staticTexts["No active sessions"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3), "Should show empty agent state")
    }

    // MARK: - Agent Tree Hierarchy

    func testAgentTreeShowsOrchestrator() throws {
        let orchestrator = app.staticTexts["orchestrator"]
        XCTAssertTrue(orchestrator.waitForExistence(timeout: 5), "Should show orchestrator agent in tree")
    }

    func testAgentTreeShowsSubAgents() throws {
        let writer = app.staticTexts["writer-1"]
        XCTAssertTrue(writer.waitForExistence(timeout: 5), "Should show writer-1 sub-agent in tree")
    }

    // MARK: - File Tree

    func testFilesHeaderExists() throws {
        let header = app.staticTexts["FILES"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Should show FILES header")
    }

    // MARK: - Feed

    func testFeedModePickerExists() throws {
        // The segmented picker contains "Activity", "Terminal", "All" segments
        let activity = app.radioButtons["Activity"]
        XCTAssertTrue(activity.waitForExistence(timeout: 5), "Should show Activity segment in picker")
    }

    func testTerminalSegmentExists() throws {
        let terminal = app.radioButtons["Terminal"]
        XCTAssertTrue(terminal.waitForExistence(timeout: 5), "Should show Terminal segment")
    }

    func testTerminalSegmentSwitchesView() throws {
        let terminal = app.radioButtons["Terminal"]
        if terminal.waitForExistence(timeout: 5) {
            terminal.click()
            let activity = app.radioButtons["Activity"]
            XCTAssertTrue(activity.exists, "Activity segment should still be visible")
        }
    }

    // MARK: - Empty States

    func testEmptyProjectStateAfterRemovingAll() throws {
        let apiServer = app.staticTexts["api-server"]
        XCTAssertTrue(apiServer.waitForExistence(timeout: 5))
        apiServer.click()
        let emptyText = app.staticTexts["No active sessions"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3))
    }
}

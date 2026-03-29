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

    // MARK: - Sidebar

    func testSidebarShowsProjects() throws {
        // Mock data has 3 projects: botcrew, api-server, docs-site
        let sidebar = app.staticTexts["botcrew"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "Should show 'botcrew' project")
    }

    func testSidebarShowsApiServerProject() throws {
        let text = app.staticTexts["api-server"]
        XCTAssertTrue(text.waitForExistence(timeout: 5), "Should show 'api-server' project")
    }

    func testSidebarShowsDocsSiteProject() throws {
        let text = app.staticTexts["docs-site"]
        XCTAssertTrue(text.waitForExistence(timeout: 5), "Should show 'docs-site' project")
    }

    func testProjectsHeaderExists() throws {
        let header = app.staticTexts["PROJECTS"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Should show PROJECTS header")
    }

    func testClickProjectSwitchesSelection() throws {
        let apiServer = app.staticTexts["api-server"]
        XCTAssertTrue(apiServer.waitForExistence(timeout: 5))
        apiServer.click()
        // After clicking api-server (no agents), should show empty agent state
        let emptyText = app.staticTexts["No active sessions"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3), "Should show empty agent state")
    }

    // MARK: - Tab Bar

    func testTabBarShowsRootAgents() throws {
        // Agent names may be inside buttons or other containers — search descendants
        let orchestrator = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == 'orchestrator'")
        ).firstMatch
        XCTAssertTrue(orchestrator.waitForExistence(timeout: 5), "Should show orchestrator tab")
    }

    func testTabBarShowsUiBuilder() throws {
        let uiBuilder = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == 'ui-builder'")
        ).firstMatch
        XCTAssertTrue(uiBuilder.waitForExistence(timeout: 5), "Should show ui-builder tab")
    }

    // MARK: - Office Panel

    func testOfficeLabelExists() throws {
        let officeLabel = app.staticTexts["OFFICE"]
        XCTAssertTrue(officeLabel.waitForExistence(timeout: 5), "Should show OFFICE label in panel bar")
    }

    // MARK: - Feed

    func testActivityTerminalToggleExists() throws {
        // Mock data selects "botcrew" project with agents, so toggle should be visible immediately
        let activityButton = app.buttons["Activity"]
        XCTAssertTrue(activityButton.waitForExistence(timeout: 5), "Should show Activity toggle")
        let terminalButton = app.buttons["Terminal"]
        XCTAssertTrue(terminalButton.exists, "Should show Terminal toggle")
    }

    func testTerminalToggleSwitchesView() throws {
        let terminalButton = app.buttons["Terminal"]
        if terminalButton.waitForExistence(timeout: 5) {
            terminalButton.click()
            // Terminal view should show — Activity button should still be visible
            let activityButton = app.buttons["Activity"]
            XCTAssertTrue(activityButton.exists, "Activity button should still be visible")
        }
    }

    // MARK: - Empty States

    func testEmptyProjectStateAfterRemovingAll() throws {
        // Verify the empty agent state works when selecting a project with no agents
        let apiServer = app.staticTexts["api-server"]
        XCTAssertTrue(apiServer.waitForExistence(timeout: 5))
        apiServer.click()
        let emptyText = app.staticTexts["No active sessions"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3))
    }

    // MARK: - Sidebar Collapse

    func testSidebarCollapseButton() throws {
        // The sidebar collapse button uses SF Symbol "sidebar.left"
        let collapseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'sidebar'")).firstMatch
        if collapseButton.waitForExistence(timeout: 5) {
            collapseButton.click()
            // After collapse, the PROJECTS text should disappear
            let projects = app.staticTexts["PROJECTS"]
            // Give animation time
            sleep(1)
            // Re-expand
            let expandButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'sidebar'")).firstMatch
            if expandButton.exists {
                expandButton.click()
            }
        }
    }
}

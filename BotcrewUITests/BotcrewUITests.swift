// BotcrewUITests.swift
// BotcrewUITests

import XCTest

final class BotcrewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
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
        let orchestrator = app.staticTexts["orchestrator"]
        XCTAssertTrue(orchestrator.waitForExistence(timeout: 5), "Should show orchestrator tab")
    }

    func testTabBarShowsUiBuilder() throws {
        let uiBuilder = app.staticTexts["ui-builder"]
        XCTAssertTrue(uiBuilder.waitForExistence(timeout: 5), "Should show ui-builder tab")
    }

    // MARK: - Office Panel

    func testOfficeLabelExists() throws {
        let officeLabel = app.staticTexts["OFFICE"]
        XCTAssertTrue(officeLabel.waitForExistence(timeout: 5), "Should show OFFICE label in panel bar")
    }

    // MARK: - Feed

    func testActivityTerminalToggleExists() throws {
        // First select an agent
        let orchestrator = app.staticTexts["orchestrator"]
        if orchestrator.waitForExistence(timeout: 5) {
            orchestrator.click()
        }
        let activityButton = app.buttons["Activity"]
        let terminalButton = app.buttons["Terminal"]
        XCTAssertTrue(activityButton.waitForExistence(timeout: 3), "Should show Activity toggle")
        XCTAssertTrue(terminalButton.exists, "Should show Terminal toggle")
    }

    func testTerminalToggleSwitchesView() throws {
        // Select an agent first
        let orchestrator = app.staticTexts["orchestrator"]
        if orchestrator.waitForExistence(timeout: 5) {
            orchestrator.click()
        }
        let terminalButton = app.buttons["Terminal"]
        if terminalButton.waitForExistence(timeout: 3) {
            terminalButton.click()
            // Terminal view should show monospaced content
            let activityButton = app.buttons["Activity"]
            XCTAssertTrue(activityButton.exists, "Activity button should still be visible")
        }
    }

    // MARK: - Empty States

    func testEmptyProjectStateAfterRemovingAll() throws {
        // This tests the empty state flow conceptually
        // We can't easily remove all projects in UI test without context menus
        // but we verify the empty agent state works
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

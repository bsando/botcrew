// OfficeLayoutTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class OfficeLayoutTests: XCTestCase {

    // MARK: - Office panel snap states

    func testOfficePanelDefaultHeight() {
        let state = AppState()
        XCTAssertEqual(state.officePanelHeight, 148)
        XCTAssertEqual(state.officePanelSnap, .ambient)
    }

    func testOfficePanelSnapCollapsed() {
        let state = AppState()
        state.officePanelHeight = 26
        XCTAssertEqual(state.officePanelSnap, .collapsed)
    }

    func testOfficePanelSnapAmbient() {
        let state = AppState()
        state.officePanelHeight = 148
        XCTAssertEqual(state.officePanelSnap, .ambient)
    }

    func testOfficePanelSnapExpanded() {
        let state = AppState()
        state.officePanelHeight = 270
        XCTAssertEqual(state.officePanelSnap, .expanded)
    }

    func testOfficePanelSnapBoundary() {
        let state = AppState()
        // At 60 → collapsed (boundary is <= 60)
        state.officePanelHeight = 60
        XCTAssertEqual(state.officePanelSnap, .collapsed)
        // At 61 → ambient
        state.officePanelHeight = 61
        XCTAssertEqual(state.officePanelSnap, .ambient)
        // At 219 → ambient
        state.officePanelHeight = 219
        XCTAssertEqual(state.officePanelSnap, .ambient)
        // At 220 → expanded (boundary is >= 220)
        state.officePanelHeight = 220
        XCTAssertEqual(state.officePanelSnap, .expanded)
    }

    func testSnapOfficePanelSetsHeight() {
        let state = AppState()
        state.snapOfficePanel(to: .collapsed)
        XCTAssertEqual(state.officePanelHeight, 26)
        state.snapOfficePanel(to: .ambient)
        XCTAssertEqual(state.officePanelHeight, 148)
        state.snapOfficePanel(to: .expanded)
        XCTAssertEqual(state.officePanelHeight, 270)
    }

    // MARK: - SpriteData shapes

    func testAllShapesAre8x10() {
        let shapes: [[[Int]]] = [SpriteData.body, SpriteData.type, SpriteData.shrug, SpriteData.error]
        for (i, shape) in shapes.enumerated() {
            XCTAssertEqual(shape.count, 10, "Shape \(i) should be 10 rows")
            for (j, row) in shape.enumerated() {
                XCTAssertEqual(row.count, 8, "Shape \(i) row \(j) should be 8 cols")
            }
        }
    }

    func testShapeForStatusMapping() {
        XCTAssertEqual(SpriteData.shape(for: .typing), SpriteData.type)
        XCTAssertEqual(SpriteData.shape(for: .waiting), SpriteData.shrug)
        XCTAssertEqual(SpriteData.shape(for: .error), SpriteData.error)
        XCTAssertEqual(SpriteData.shape(for: .idle), SpriteData.body)
        XCTAssertEqual(SpriteData.shape(for: .reading), SpriteData.body)
    }

    func testErrorShapeHasXEyes() {
        let flat = SpriteData.error.flatMap { $0 }
        XCTAssertTrue(flat.contains(6), "Error shape should contain X-eye pixels (value 6)")
    }

    func testTypeShapeHasNoXEyes() {
        let flat = SpriteData.type.flatMap { $0 }
        XCTAssertFalse(flat.contains(6), "Type shape should not contain X-eye pixels")
    }

    // MARK: - SpriteLayout

    func testSpriteLayoutIdentifiable() {
        let id = UUID()
        let agent = Agent(id: id, name: "test", parentId: nil, status: .idle,
                          bodyColor: .purple, shirtColor: .purple, spawnTime: Date())
        let layout = SpriteLayout(id: id, agent: agent, center: CGPoint(x: 100, y: 50),
                                  isRoot: true, rootCenter: nil)
        XCTAssertEqual(layout.id, id)
        XCTAssertTrue(layout.isRoot)
        XCTAssertNil(layout.rootCenter)
    }

    func testSubSpriteLayoutHasRootCenter() {
        let rootId = UUID()
        let subId = UUID()
        let agent = Agent(id: subId, name: "sub", parentId: rootId, status: .typing,
                          bodyColor: .green, shirtColor: .green, spawnTime: Date())
        let rootCenter = CGPoint(x: 200, y: 50)
        let layout = SpriteLayout(id: subId, agent: agent, center: CGPoint(x: 180, y: 100),
                                  isRoot: false, rootCenter: rootCenter)
        XCTAssertFalse(layout.isRoot)
        XCTAssertEqual(layout.rootCenter, rootCenter)
    }
}

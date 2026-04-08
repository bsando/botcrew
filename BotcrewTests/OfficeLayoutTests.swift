// OfficeLayoutTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class OfficeLayoutTests: XCTestCase {

    // MARK: - Office panel snap states

    func testOfficePanelDefaultHeight() {
        let state = AppState(skipPersistence: true)
        XCTAssertEqual(state.officePanelHeight, 148)
        XCTAssertEqual(state.officePanelSnap, .ambient)
    }

    func testOfficePanelSnapCollapsed() {
        let state = AppState(skipPersistence: true)
        state.officePanelHeight = 26
        XCTAssertEqual(state.officePanelSnap, .collapsed)
    }

    func testOfficePanelSnapAmbient() {
        let state = AppState(skipPersistence: true)
        state.officePanelHeight = 148
        XCTAssertEqual(state.officePanelSnap, .ambient)
    }

    func testOfficePanelSnapExpanded() {
        let state = AppState(skipPersistence: true)
        state.officePanelHeight = 270
        XCTAssertEqual(state.officePanelSnap, .expanded)
    }

    func testOfficePanelSnapBoundary() {
        let state = AppState(skipPersistence: true)
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
        let state = AppState(skipPersistence: true)
        state.snapOfficePanel(to: .collapsed)
        XCTAssertEqual(state.officePanelHeight, 26)
        state.snapOfficePanel(to: .ambient)
        XCTAssertEqual(state.officePanelHeight, 148)
        state.snapOfficePanel(to: .expanded)
        XCTAssertEqual(state.officePanelHeight, 270)
    }

    // MARK: - SpriteData shapes

    func testAllShapesAre8x10() {
        let blobs = SpriteTheme.blobs.shapes
        let shapes: [[[Int]]] = [blobs.body, blobs.type, blobs.shrug, blobs.error]
        for (i, shape) in shapes.enumerated() {
            XCTAssertEqual(shape.count, 10, "Shape \(i) should be 10 rows")
            for (j, row) in shape.enumerated() {
                XCTAssertEqual(row.count, 8, "Shape \(i) row \(j) should be 8 cols")
            }
        }
    }

    func testShapeForStatusMapping() {
        let blobs = SpriteTheme.blobs.shapes
        XCTAssertEqual(SpriteData.shape(for: .typing), blobs.type)
        XCTAssertEqual(SpriteData.shape(for: .waiting), blobs.shrug)
        XCTAssertEqual(SpriteData.shape(for: .error), blobs.error)
        XCTAssertEqual(SpriteData.shape(for: .idle), blobs.body)
        XCTAssertEqual(SpriteData.shape(for: .reading), blobs.body)
    }

    func testErrorShapeHasXEyes() {
        let flat = SpriteTheme.blobs.shapes.error.flatMap { $0 }
        XCTAssertTrue(flat.contains(6), "Error shape should contain X-eye pixels (value 6)")
    }

    func testTypeShapeHasNoXEyes() {
        let flat = SpriteTheme.blobs.shapes.type.flatMap { $0 }
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

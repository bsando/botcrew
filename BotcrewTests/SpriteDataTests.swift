// SpriteDataTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class SpriteDataTests: XCTestCase {

    func testBodyShapeIs8x10() {
        let body = SpriteTheme.blobs.shapes.body
        XCTAssertEqual(body.count, 10, "Sprite should be 10 rows tall")
        for (i, row) in body.enumerated() {
            XCTAssertEqual(row.count, 8, "Row \(i) should be 8 pixels wide")
        }
    }

    func testBodyShapeUsesValidValues() {
        let validValues: Set<Int> = [0, 1, 2, 3, 6]
        let body = SpriteTheme.blobs.shapes.body
        for (i, row) in body.enumerated() {
            for (j, val) in row.enumerated() {
                XCTAssertTrue(validValues.contains(val), "Invalid pixel value \(val) at (\(i),\(j))")
            }
        }
    }

    func testBodyShapeHasEyes() {
        let hasEyes = SpriteTheme.blobs.shapes.body.flatMap { $0 }.contains(2)
        XCTAssertTrue(hasEyes, "Body shape should contain eye pixels (value 2)")
    }

    func testBodyShapeHasAccent() {
        let hasAccent = SpriteTheme.blobs.shapes.body.flatMap { $0 }.contains(3)
        XCTAssertTrue(hasAccent, "Body shape should contain accent pixels (value 3)")
    }

    // MARK: - All built-in themes

    func testAllThemesHaveValidShapes() {
        let validValues: Set<Int> = [0, 1, 2, 3, 6]
        for theme in SpriteTheme.allBuiltIn {
            let allShapes = [theme.shapes.body, theme.shapes.type, theme.shapes.shrug, theme.shapes.error]
            for (shapeIdx, shape) in allShapes.enumerated() {
                XCTAssertEqual(shape.count, 10, "\(theme.name) shape \(shapeIdx) should be 10 rows")
                for (i, row) in shape.enumerated() {
                    XCTAssertEqual(row.count, 8, "\(theme.name) shape \(shapeIdx) row \(i) should be 8 cols")
                    for (j, val) in row.enumerated() {
                        XCTAssertTrue(validValues.contains(val),
                            "\(theme.name) shape \(shapeIdx) invalid pixel \(val) at (\(i),\(j))")
                    }
                }
            }
        }
    }

    func testAllThemesHaveEyes() {
        for theme in SpriteTheme.allBuiltIn {
            let hasEyes = theme.shapes.body.flatMap { $0 }.contains(2)
            XCTAssertTrue(hasEyes, "\(theme.name) body shape should contain eye pixels")
        }
    }

    func testErrorShapesHaveXEyes() {
        for theme in SpriteTheme.allBuiltIn {
            let hasXEyes = theme.shapes.error.flatMap { $0 }.contains(6)
            XCTAssertTrue(hasXEyes, "\(theme.name) error shape should contain X-eye pixels (value 6)")
        }
    }

    func testShapeResolution() {
        let theme = SpriteTheme.blobs
        XCTAssertEqual(theme.shapes.shape(for: .idle), theme.shapes.body)
        XCTAssertEqual(theme.shapes.shape(for: .reading), theme.shapes.body)
        XCTAssertEqual(theme.shapes.shape(for: .typing), theme.shapes.type)
        XCTAssertEqual(theme.shapes.shape(for: .waiting), theme.shapes.shrug)
        XCTAssertEqual(theme.shapes.shape(for: .error), theme.shapes.error)
    }
}

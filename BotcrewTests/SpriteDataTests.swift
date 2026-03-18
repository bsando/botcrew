// SpriteDataTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class SpriteDataTests: XCTestCase {

    func testBodyShapeIs8x10() {
        XCTAssertEqual(SpriteData.body.count, 10, "Sprite should be 10 rows tall")
        for (i, row) in SpriteData.body.enumerated() {
            XCTAssertEqual(row.count, 8, "Row \(i) should be 8 pixels wide")
        }
    }

    func testBodyShapeUsesValidValues() {
        let validValues: Set<Int> = [0, 1, 2, 3, 6]
        for (i, row) in SpriteData.body.enumerated() {
            for (j, val) in row.enumerated() {
                XCTAssertTrue(validValues.contains(val), "Invalid pixel value \(val) at (\(i),\(j))")
            }
        }
    }

    func testBodyShapeHasEyes() {
        let hasEyes = SpriteData.body.flatMap { $0 }.contains(2)
        XCTAssertTrue(hasEyes, "Body shape should contain eye pixels (value 2)")
    }

    func testBodyShapeHasAccent() {
        let hasAccent = SpriteData.body.flatMap { $0 }.contains(3)
        XCTAssertTrue(hasAccent, "Body shape should contain accent pixels (value 3)")
    }
}

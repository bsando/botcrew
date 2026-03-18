// AnimationTests.swift
// BotcrewTests

import XCTest
@testable import Botcrew

final class AnimationTests: XCTestCase {

    // MARK: - BobParams

    func testTypingBobIsFastest() {
        let typing = BobParams.forStatus(.typing)
        let idle = BobParams.forStatus(.idle)
        let waiting = BobParams.forStatus(.waiting)
        XCTAssertGreaterThan(typing.frequency, idle.frequency)
        XCTAssertGreaterThan(typing.frequency, waiting.frequency)
    }

    func testTypingBobHasLargestAmplitude() {
        let typing = BobParams.forStatus(.typing)
        let idle = BobParams.forStatus(.idle)
        let waiting = BobParams.forStatus(.waiting)
        XCTAssertGreaterThan(typing.amplitude, idle.amplitude)
        XCTAssertGreaterThan(typing.amplitude, waiting.amplitude)
    }

    func testIdleBobIsSlowest() {
        let idle = BobParams.forStatus(.idle)
        let typing = BobParams.forStatus(.typing)
        let reading = BobParams.forStatus(.reading)
        XCTAssertLessThan(idle.frequency, typing.frequency)
        XCTAssertLessThan(idle.frequency, reading.frequency)
    }

    func testErrorBobIsVeryFast() {
        let error = BobParams.forStatus(.error)
        // 12Hz flash rate
        XCTAssertEqual(error.frequency, 12.0)
    }

    func testAllStatusesHaveBobParams() {
        for status in AgentStatus.allCases {
            let params = BobParams.forStatus(status)
            XCTAssertGreaterThan(params.frequency, 0)
            XCTAssertGreaterThan(params.amplitude, 0)
        }
    }

    // MARK: - SpriteData shape selection (animation-relevant)

    func testTypingUsesTypeShape() {
        let shape = SpriteData.shape(for: .typing)
        // Type shape is shifted right (col 0 row 0 should be transparent)
        XCTAssertEqual(shape[0][0], 0)
        XCTAssertNotEqual(shape, SpriteData.body)
    }

    func testWaitingUsesShrug() {
        let shape = SpriteData.shape(for: .waiting)
        // Shrug has accent (3) at far edges of row 5
        XCTAssertEqual(shape[5][0], 3) // left arm extended
        XCTAssertEqual(shape[5][7], 3) // right arm extended
    }

    func testErrorUsesErrorShape() {
        let shape = SpriteData.shape(for: .error)
        // Error has X-eyes (6)
        let flat = shape.flatMap { $0 }
        XCTAssertTrue(flat.contains(6))
    }
}

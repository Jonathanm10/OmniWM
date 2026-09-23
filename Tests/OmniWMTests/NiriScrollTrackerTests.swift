// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

@testable import OmniWM
import XCTest

final class NiriScrollTrackerTests: XCTestCase {
    func testDiscreteWheelNormalizationIgnoresAccelerationAndPreservesDirection() {
        for delta: CGFloat in [1, 10, 120, 1200] {
            XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
                pointDelta: delta, fixedPointDelta: 0, isContinuous: false
            ), 120)
            XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
                pointDelta: -delta, fixedPointDelta: 0, isContinuous: false
            ), -120)
            XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
                pointDelta: delta, fixedPointDelta: -1200, isContinuous: false
            ), 120)
            for signedDelta in [delta, -delta] {
                XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
                    pointDelta: signedDelta, fixedPointDelta: 0, isContinuous: true
                ), signedDelta)
            }
        }
        XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
            pointDelta: 0, fixedPointDelta: -1, isContinuous: false
        ), -120)
        XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
            pointDelta: 0.0005, fixedPointDelta: 1, isContinuous: false
        ), 120)
        XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
            pointDelta: 0, fixedPointDelta: -1, isContinuous: true
        ), -1)
        XCTAssertEqual(MouseEventHandler.resolvedWheelAxisDelta(
            pointDelta: 0, fixedPointDelta: 0, isContinuous: false
        ), 0)
    }

    func testWholeTickSurplusBeyondCapIsDiscarded() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(1500), 127)
        XCTAssertEqual(tracker.accumulate(5), 0)
    }

    func testNegativeWholeTickSurplusBeyondCapIsDiscarded() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(-1500), -127)
        XCTAssertEqual(tracker.accumulate(-5), 0)
    }

    func testRepeatedCappedBurstsRemainIndependent() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(1500), 127)
        XCTAssertEqual(tracker.accumulate(1500), 127)
        XCTAssertEqual(tracker.accumulate(5), 0)
    }

    func testProductionTickDiscardsWholeTickSurplus() {
        var tracker = NiriScrollTracker(tick: 120)

        XCTAssertEqual(tracker.accumulate(30_000), 127)
        XCTAssertEqual(tracker.accumulate(120), 1)
    }

    func testSubTickRemainderCarriesAcrossCalls() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(15), 1)
        XCTAssertEqual(tracker.accumulate(5), 1)
    }

    func testBelowTickThresholdAccumulates() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(5), 0)
        XCTAssertEqual(tracker.accumulate(5), 1)
    }

    func testExactCapLeavesNoRemainder() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(1270), 127)
        XCTAssertEqual(tracker.accumulate(9), 0)
    }

    func testDirectionChangeResetsSubTickRemainder() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(5), 0)
        XCTAssertEqual(tracker.accumulate(-5), 0)
        XCTAssertEqual(tracker.accumulate(-5), -1)
    }

    func testResetClearsAccumulator() {
        var tracker = NiriScrollTracker(tick: 10)

        XCTAssertEqual(tracker.accumulate(15), 1)
        tracker.reset()
        XCTAssertEqual(tracker.accumulate(5), 0)
        XCTAssertEqual(tracker.accumulate(5), 1)
    }

    func testProductionOverflowKeepsOnlySubTickRemainder() {
        var tracker = NiriScrollTracker(tick: 120)

        XCTAssertEqual(tracker.accumulate(20_000), 127)
        XCTAssertEqual(tracker.accumulator, 80, accuracy: 0.001)
    }
}

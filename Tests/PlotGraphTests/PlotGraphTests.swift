import XCTest
import CoreGraphics
@testable import PlotGraph

final class PlotDataTests: XCTestCase {

    func testMinMaxAreComputedFromPoints() {
        let data = PlotData(xs: [3.0, 1.0, 2.0], ys: [30.0, 10.0, 20.0])
        XCTAssertEqual(data.min.x, 1)
        XCTAssertEqual(data.max.x, 3)
        XCTAssertEqual(data.min.y, 10)
        XCTAssertEqual(data.max.y, 30)
    }

    func testPointsAreSortedByX() {
        let data = PlotData(points: [CGPoint(x: 3, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 2, y: 0)])
        XCTAssertEqual(data.x, [1, 2, 3])
    }

    func testFunctionInitializerSamplesOverStride() {
        let data = PlotData(xs: stride(from: 0.0, through: 4.0, by: 1.0), f: { $0 * $0 })
        XCTAssertEqual(data.y, [0, 1, 4, 9, 16])
    }
}

final class PlotRangeTests: XCTestCase {

    func testNiceRoundNumbersForTypicalData() {
        // 0...94 should snap to a "nice" delta rather than an awkward one.
        let range = PlotRange(min: 0, max: 94)
        XCTAssertTrue(range.min <= 0)
        XCTAssertTrue(range.max >= 94)
        XCTAssertTrue([1, 2, 5, 10, 20, 50, 100].contains(range.delta))
    }

    func testConstantDataDoesNotProduceNaN() {
        // All samples equal (zero-width range) previously sent log10(0) to -infinity.
        let range = PlotRange(min: 5, max: 5)
        XCTAssertFalse(range.delta.isNaN)
        XCTAssertFalse(range.min.isNaN)
        XCTAssertFalse(range.max.isNaN)
        XCTAssertTrue(range.max >= range.min)
    }
}

final class CvsReaderTests: XCTestCase {
    
    func testNumericDataRoundTripsThroughDataConversion() {
        let value = 3.14159
        XCTAssertEqual(value.data.double, value, accuracy: 1e-12)
        
        let intValue = 42
        XCTAssertEqual(intValue.data.integer, intValue)
        
        let floatValue: Float = 2.5
        XCTAssertEqual(floatValue.data.float, floatValue)
    }
    
    func testStringDataRoundTrips() {
        let text = "hello,world"
        XCTAssertEqual(text.data.string, text)
    }
    
    func testExtractSubscriptSelectsColumn() {
        let rows: [[Data]] = [
            ["1".data, "a".data],
            ["2".data, "b".data],
        ]
        let extract = Extract(data: rows)
        XCTAssertEqual(extract[0].map { $0.string }, ["1", "2"])
        XCTAssertEqual(extract[1].map { $0.string }, ["a", "b"])
    }
}

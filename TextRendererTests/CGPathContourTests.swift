@testable import TextRenderer
import XCTest

private let kPoint1 = CGPoint(x: 1, y: 2)
private let kPoint2 = CGPoint(x: 3, y: 4)
private let kPoint3 = CGPoint(x: 5, y: 6)
private let kPoint4 = CGPoint(x: 7, y: 8)
private let kPoint5 = CGPoint(x: 9, y: 10)

final class CGPathContourTests: XCTestCase {
    func testFirstCloseSubpathIsEmpty() {
        let path = CGMutablePath()
        path.closeSubpath()
        XCTAssertTrue(path.contours.isEmpty)
    }

    func testFirstMoveToPointAddsContour() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        XCTAssertEqual(path.contours, [[kPoint1]])
    }

    func testFirstAddLineIsEmpty() {
        let path = CGMutablePath()
        path.addLine(to: kPoint1)
        XCTAssertTrue(path.contours.isEmpty)
    }

    func testFirstAddQuadCurveIsEmpty() {
        let path = CGMutablePath()
        path.addQuadCurve(to: kPoint1, control: kPoint2)
        XCTAssertTrue(path.contours.isEmpty)
    }

    func testFirstAddCurveIsEmpty() {
        let path = CGMutablePath()
        path.addCurve(to: kPoint1, control1: kPoint2, control2: kPoint3)
        XCTAssertTrue(path.contours.isEmpty)
    }

    func testLocalFirstCloseSubpathAddsNothing() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        path.closeSubpath()
        path.closeSubpath()
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2]])
    }

    func testLocalFirstMoveToPointAddsContour() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        path.closeSubpath()
        path.move(to: kPoint3)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2], [kPoint3]])
    }

    func testLocalFirstAddLineAddsContourWithPreviousContourFirstPoint() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        path.closeSubpath()
        path.addLine(to: kPoint3)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2], [kPoint1, kPoint3]])
    }

    func testLocalFirstAddQuadCurveAddsContourWithPreviousContourFirstPoint() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        path.closeSubpath()
        path.addQuadCurve(to: kPoint3, control: kPoint4)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2], [kPoint1, kPoint3]])
    }

    func testLocalFirstAddCurveAddsContourWithPreviousContourFirstPoint() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        path.closeSubpath()
        path.addCurve(to: kPoint3, control1: kPoint4, control2: kPoint5)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2], [kPoint1, kPoint3]])
    }

    func testNextCloseSubpathAddsContour() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.closeSubpath()
        XCTAssertEqual(path.contours, [[kPoint1]])
    }

    func testNextMoveToPointAddsContour() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        path.move(to: kPoint3)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2], [kPoint3]])
    }

    func testNextAddLineAddsPoint() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addLine(to: kPoint2)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2]])
    }

    func testNextAddQuadCurveAddsPoint() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addQuadCurve(to: kPoint2, control: kPoint3)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2]])
    }

    func testNextAddCurveAddsPoint() {
        let path = CGMutablePath()
        path.move(to: kPoint1)
        path.addCurve(to: kPoint2, control1: kPoint3, control2: kPoint4)
        XCTAssertEqual(path.contours, [[kPoint1, kPoint2]])
    }
}

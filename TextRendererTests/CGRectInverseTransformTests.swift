import CoreGraphics
@testable import TextRenderer
import XCTest

private let kUnitSquare = CGRect(origin: CGPoint(x: -0.5, y: -0.5), size: CGSize(width: 1, height: 1))
private let kSomeRect = CGRect(origin: CGPoint(x: 1, y: 2), size: CGSize(width: 3, height: 4))
private let kAccuracy: CGFloat = 0.000001

final class CGRectInverseTransformTests: XCTestCase {
    func testInverseTransformInvertsToUnitSquare() {
        let invertedRect = kSomeRect.applying(kSomeRect.inverseTransform)
        XCTAssertEqual(invertedRect.origin.x, kUnitSquare.origin.x, accuracy: kAccuracy)
        XCTAssertEqual(invertedRect.origin.y, kUnitSquare.origin.y, accuracy: kAccuracy)
        XCTAssertEqual(invertedRect.size.width, kUnitSquare.size.width, accuracy: kAccuracy)
        XCTAssertEqual(invertedRect.size.height, kUnitSquare.size.height, accuracy: kAccuracy)
    }
}

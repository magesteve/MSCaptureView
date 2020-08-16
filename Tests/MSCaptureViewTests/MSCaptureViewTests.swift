import XCTest
@testable import MSCaptureView

final class MSCaptureViewTests: XCTestCase {
    func testVesion() {
        let (major, minor, _) = MSCaptureView.version
        XCTAssertEqual(major, 1)
        XCTAssertEqual(minor, 0)
    }

    static var allTests = [
        ("testVesion", testVesion),
    ]
}

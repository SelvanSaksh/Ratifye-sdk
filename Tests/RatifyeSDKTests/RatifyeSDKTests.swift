import XCTest
import RatifyeSDK

final class RatifyeSDKTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(RatifyeSDK.version, "1.0.0")
    }

    func testScanResultEquality() {
        let a = RatifyeScanResult(payload: "123", symbologyRaw: "QR")
        let b = RatifyeScanResult(payload: "123", symbologyRaw: "QR")
        XCTAssertEqual(a, b)
    }
}

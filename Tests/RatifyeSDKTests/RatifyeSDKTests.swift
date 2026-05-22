import XCTest
import RatifyeSDK

final class RatifyeSDKTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(RatifyeSDK.version, "1.1.1")
    }

    func testScanResultEquality() {
        let a = RatifyeScanResult(payload: "123", symbologyRaw: "QR")
        let b = RatifyeScanResult(payload: "123", symbologyRaw: "QR")
        XCTAssertEqual(a, b)
    }

    func testAuthSuccessPayloadShape() {
        let scan = RatifyeScanResult(payload: "abc", symbologyRaw: "QR")
        let success = RatifyeAuthScanSuccess(
            scan: scan,
            httpStatus: 200,
            responseData: #"{"ok":true}"#.data(using: .utf8)!
        )
        let dict = RatifyeScanEventPayload.authSuccess(success).toDictionary(surface: .single)
        XCTAssertEqual(dict["kind"] as? String, "auth_success")
        XCTAssertEqual(dict["payload"] as? String, "abc")
        let auth = dict["auth"] as? [String: Any]
        XCTAssertEqual(auth?["httpStatus"] as? Int, 200)
        XCTAssertEqual(auth?["success"] as? Bool, true)
        XCTAssertNotNil(auth?["responseJSON"])
    }

    func testFeatureConfigurationAuthPriority() {
        let cfg = RatifyeScanFeatureConfiguration(
            singleScanEnabled: true,
            authScanEnabled: true,
            authConfiguration: RatifyeAuthConfiguration(ingestURL: URL(string: "https://example.com")!)
        )
        XCTAssertTrue(cfg.usesAuthFlow)
    }

    func testMultiAuthConfiguration() {
        let cfg = RatifyeMultiScanFeatureConfiguration(
            multiScanEnabled: true,
            authScanEnabled: true,
            authConfiguration: RatifyeAuthConfiguration(ingestURL: URL(string: "https://example.com")!)
        )
        XCTAssertTrue(cfg.usesAuthFlow)
    }

    func testAuthPayloadIncludesSurface() {
        let scan = RatifyeScanResult(payload: "x", symbologyRaw: "QR")
        let success = RatifyeAuthScanSuccess(scan: scan, httpStatus: 201, responseData: Data())
        let dict = RatifyeScanEventPayload.authSuccess(success).toDictionary(surface: .multi)
        XCTAssertEqual(dict["surface"] as? String, "multi")
        XCTAssertEqual(dict["kind"] as? String, "auth_success")
    }
}

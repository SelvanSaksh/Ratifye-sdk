import XCTest
import UIKit
import RatifyeSDK

final class RatifyeSDKTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(RatifyeSDK.version, "1.5.0")
    }

    func testRatifyeBarcodeParsing() {
        let raw =
            "https://dl.ratifye.ai/01/18907001962025?13=260404&15=270404&17=270505(98)CLTPH2PNBRHJUA====(97)48"
        let parsed = RatifyeBarcodeParsing.parse(raw)
        XCTAssertEqual(
            parsed.barcodeData,
            "https://dl.ratifye.ai/01/18907001962025?13=260404&15=270404&17=270505"
        )
        XCTAssertEqual(parsed.encryptedText, "CLTPH2PNBRHJUA====")
        XCTAssertEqual(parsed.companyId, "48")
    }

    func testScanResultEquality() {
        let a = RatifyeScanResult(payload: "123", symbologyRaw: "QR")
        let b = RatifyeScanResult(payload: "123", symbologyRaw: "QR")
        XCTAssertEqual(a, b)
    }

    func testAuthSuccessPayloadShape() {
        let raw =
            "https://dl.ratifye.ai/01/18907001962025?13=260404&15=270404&17=270505(98)CLTPH2PNBRHJUA====(97)48"
        let scan = RatifyeScanResult(payload: raw, symbologyRaw: "QR")
        let success = RatifyeAuthScanSuccess(
            scan: scan,
            httpStatus: 200,
            responseData: #"{"ok":true}"#.data(using: .utf8)!
        )
        let dict = RatifyeScanEventPayload.authSuccess(success).toDictionary(surface: .single)
        XCTAssertEqual(dict["kind"] as? String, "auth_success")
        XCTAssertEqual(dict["barcode_data"] as? String, scan.parsed.barcodeData)
        XCTAssertEqual(dict["encrypted_text"] as? String, "CLTPH2PNBRHJUA====")
        XCTAssertEqual(dict["company_id"] as? String, "48")
        let auth = dict["auth"] as? [String: Any]
        XCTAssertEqual(auth?["httpStatus"] as? Int, 200)
        XCTAssertEqual(auth?["success"] as? Bool, true)
    }

    func testAuthBcRequestBodyShape() throws {
        let raw =
            "https://dl.ratifye.ai/01/18907001962025?13=260404&15=270404&17=270505(98)CLTPH2PNBRHJUA====(97)48"
        let cfg = RatifyeAuthConfiguration.standard
        let client = RatifyeScanIngestClient(configuration: cfg)
        let result = RatifyeScanResult(payload: raw, symbologyRaw: "QR")
        let body = try client.encodedRequestBody(for: result)
        let json = try JSONSerialization.jsonObject(with: body) as? [[String: String]]
        XCTAssertEqual(json?.count, 1)
        XCTAssertEqual(json?.first?["encrypted_text"], "CLTPH2PNBRHJUA====")
        XCTAssertEqual(
            json?.first?["barcode_data"],
            "https://dl.ratifye.ai/01/18907001962025?13=260404&15=270404&17=270505"
        )
        XCTAssertEqual(json?.first?["company_id"], "48")
    }
}

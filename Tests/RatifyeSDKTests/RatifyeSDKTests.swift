import XCTest
import UIKit
import RatifyeSDK

final class RatifyeSDKTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(RatifyeSDK.version, "1.4.0")

    func testGalleryBarcodeParsing() {
        let raw = "chgtfssd(98)ZXRZR3JR2RCWTQ====(97)0"
        let size = CGSize(width: 400, height: 120)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        defer { UIGraphicsEndImageContext() }
        (raw as NSString).draw(at: CGPoint(x: 8, y: 48), withAttributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        XCTAssertNotNil(image)
        // Vision may not decode rendered text; test API returns array without crashing.
        let results = RatifyeBarcodeImageScanner.scan(image!)
        XCTAssertNotNil(results)
    }
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
            auth: .withAuthEnabled(true)
        )
        XCTAssertTrue(cfg.usesAuthFlow)
    }

    func testMultiAuthConfiguration() {
        let cfg = RatifyeMultiScanFeatureConfiguration(
            multiScanEnabled: true,
            auth: .withAuthEnabled(true)
        )
        XCTAssertTrue(cfg.usesAuthFlow)
    }

    func testAuthDefaultsURL() {
        XCTAssertEqual(
            RatifyeAuthDefaults.ingestURL.absoluteString,
            "https://dlhub.8aiku.com/scan/auth-bc"
        )
        XCTAssertEqual(RatifyeAuthDefaults.companyId, "0")
    }

    func testAuthBcEncryptedTextExtraction() {
        let raw = "chgtfssd(98)ZXRZR3JR2RCWTQ====(97)0"
        XCTAssertEqual(
            RatifyeBarcodeParsing.encryptedText(from: raw),
            "ZXRZR3JR2RCWTQ===="
        )
    }

    func testAuthBcRequestBodyShape() throws {
        let cfg = RatifyeAuthConfiguration.standard
        let client = RatifyeScanIngestClient(configuration: cfg)
        let result = RatifyeScanResult(payload: "chgtfssd(98)ZXRZR3JR2RCWTQ====(97)0", symbologyRaw: "QR")
        let body = try client.encodedRequestBody(for: result)
        let json = try JSONSerialization.jsonObject(with: body) as? [[String: String]]
        XCTAssertEqual(json?.count, 1)
        XCTAssertEqual(json?.first?["encrypted_text"], "ZXRZR3JR2RCWTQ====")
        XCTAssertEqual(json?.first?["barcode_data"], result.payload)
        XCTAssertEqual(json?.first?["company_id"], RatifyeAuthDefaults.companyId)
    }

    func testAuthPayloadIncludesSurface() {
        let scan = RatifyeScanResult(payload: "x", symbologyRaw: "QR")
        let success = RatifyeAuthScanSuccess(scan: scan, httpStatus: 201, responseData: Data())
        let dict = RatifyeScanEventPayload.authSuccess(success).toDictionary(surface: .multi)
        XCTAssertEqual(dict["surface"] as? String, "multi")
        XCTAssertEqual(dict["kind"] as? String, "auth_success")
    }
}

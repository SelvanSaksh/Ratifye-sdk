import Foundation

/// Parsed Ratifye / GS1 barcode: `(98)` encrypted payload, `(97)` company id, base URL without those segments.
public struct RatifyeParsedBarcode: Sendable, Equatable {
    /// Raw string from the scanner (unchanged).
    public let rawPayload: String
    /// Base barcode / URL with `(98)…` and `(97)…` segments removed.
    public let barcodeData: String
    /// Value between `(98)` and `(97)`.
    public let encryptedText: String
    /// Value after `(97)`, or SDK default when markers are missing.
    public let companyId: String

    public init(
        rawPayload: String,
        barcodeData: String,
        encryptedText: String,
        companyId: String
    ) {
        self.rawPayload = rawPayload
        self.barcodeData = barcodeData
        self.encryptedText = encryptedText
        self.companyId = companyId
    }

    public func toAuthDictionary() -> [String: String] {
        [
            "barcode_data": barcodeData,
            "encrypted_text": encryptedText,
            "company_id": companyId
        ]
    }
}

public enum RatifyeBarcodeParsing {
    private static let marker98 = "(98)"
    private static let marker97 = "(97)"

    public static func parse(_ rawPayload: String) -> RatifyeParsedBarcode {
        guard let range98 = rawPayload.range(of: marker98) else {
            return RatifyeParsedBarcode(
                rawPayload: rawPayload,
                barcodeData: rawPayload,
                encryptedText: rawPayload,
                companyId: RatifyeAuthDefaults.companyId
            )
        }

        let barcodeData = String(rawPayload[..<range98.lowerBound])
        let after98 = rawPayload[range98.upperBound...]

        guard let range97 = after98.range(of: marker97) else {
            return RatifyeParsedBarcode(
                rawPayload: rawPayload,
                barcodeData: barcodeData.isEmpty ? rawPayload : barcodeData,
                encryptedText: String(after98),
                companyId: RatifyeAuthDefaults.companyId
            )
        }

        let encryptedText = String(after98[..<range97.lowerBound])
        let companyId = String(after98[range97.upperBound...])

        return RatifyeParsedBarcode(
            rawPayload: rawPayload,
            barcodeData: barcodeData,
            encryptedText: encryptedText,
            companyId: companyId.isEmpty ? RatifyeAuthDefaults.companyId : companyId
        )
    }

    /// Backward-compatible helper.
    public static func encryptedText(from barcodeData: String) -> String {
        parse(barcodeData).encryptedText
    }
}

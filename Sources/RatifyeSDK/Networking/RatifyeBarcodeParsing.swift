import Foundation

public enum RatifyeBarcodeParsing {
    /// Extracts value between GS1 application identifiers `(98)` and `(97)`.
    static func encryptedText(from barcodeData: String) -> String {
        let marker98 = "(98)"
        let marker97 = "(97)"
        guard let start = barcodeData.range(of: marker98) else {
            return barcodeData
        }
        let after98 = barcodeData[start.upperBound...]
        guard let end = after98.range(of: marker97) else {
            return String(after98)
        }
        return String(after98[..<end.lowerBound])
    }
}

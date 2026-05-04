import Foundation
import Vision

/// A barcode read from the camera.
public struct RatifyeScanResult: Sendable, Hashable {
    public let payload: String
    public let symbologyRaw: String

    public init(payload: String, symbologyRaw: String) {
        self.payload = payload
        self.symbologyRaw = symbologyRaw
    }
}

extension RatifyeScanResult {
    static func from(_ observation: VNBarcodeObservation) -> RatifyeScanResult? {
        guard let payload = observation.payloadStringValue else { return nil }
        let raw = observation.symbology.rawValue
        return RatifyeScanResult(payload: payload, symbologyRaw: raw)
    }
}

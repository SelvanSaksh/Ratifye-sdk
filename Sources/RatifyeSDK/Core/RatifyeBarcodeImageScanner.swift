import UIKit
import Vision

public enum RatifyeBarcodeImageScanner {
    /// Scans a still image from the photo library (or any `UIImage`).
    public static func scan(
        _ image: UIImage,
        symbologies: [VNBarcodeSymbology] = RatifyeBarcodeCameraEngine.defaultSymbologies
    ) -> [RatifyeScanResult] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNDetectBarcodesRequest()
        request.symbologies = symbologies

        let orientation = cgOrientation(for: image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try? handler.perform([request])

        guard let observations = request.results as? [VNBarcodeObservation] else { return [] }
        return observations.compactMap { RatifyeScanResult.from($0) }
    }

    private static func cgOrientation(for orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

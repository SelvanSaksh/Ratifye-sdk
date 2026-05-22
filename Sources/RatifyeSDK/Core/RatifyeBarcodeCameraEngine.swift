import AVFoundation
import AudioToolbox
import UIKit
import Vision

public enum RatifyeScanMode: Sendable {
    /// First successful decode dismisses/stops (controller decides).
    case single
    /// Every new payload (deduped) reported on main queue.
    case multi
}

public protocol RatifyeBarcodeCameraEngineDelegate: AnyObject {
    func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult)
}

/// Shared AVFoundation + Vision pipeline for barcode scanning.
public final class RatifyeBarcodeCameraEngine: NSObject {
    public weak var delegate: RatifyeBarcodeCameraEngineDelegate?

    public let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.ratifye.sdk.barcode.processing")

    public var scanMode: RatifyeScanMode = .single
    public var symbologies: [VNBarcodeSymbology] = RatifyeBarcodeCameraEngine.defaultSymbologies
    public var vibrateOnDetect: Bool = true
    /// Minimum time between multi-scan callbacks for the same payload (seconds).
    public var multiRescanCooldown: TimeInterval = 0.6

    private var deviceInput: AVCaptureDeviceInput?
    public private(set) var currentPosition: AVCaptureDevice.Position = .back
    public private(set) var isTorchOn: Bool = false
    private var isSingleFinished = false
    private var lastEmittedAt: [String: Date] = [:]
    private var isProcessingFrame = false

    private lazy var barcodeRequest: VNDetectBarcodesRequest = {
        let r = VNDetectBarcodesRequest { [weak self] request, _ in
            self?.handleVisionResults(request)
        }
        r.symbologies = symbologies
        return r
    }()

    public static let defaultSymbologies: [VNBarcodeSymbology] = [
        .qr, .ean8, .ean13, .upce, .code128, .code39, .code93,
        .pdf417, .aztec, .dataMatrix, .itf14
    ]

    public override init() {
        super.init()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: processingQueue)
    }

    public func configureIfNeeded() throws {
        guard deviceInput == nil else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        try attachInput(position: .back)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        barcodeRequest.symbologies = symbologies
    }

    public func startRunning() {
        guard !session.isRunning else { return }
        isSingleFinished = false
        lastEmittedAt.removeAll()
        let captureSession = session
        if Thread.isMainThread {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        } else {
            captureSession.startRunning()
        }
    }

    public func refreshPreviewConnection(for previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.session = session
        guard let connection = previewLayer.connection else { return }
        if #available(iOS 17.0, *) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    /// Call after a failed single-scan decode flow so the camera can scan again (for example authenticated ingest retry).
    public func resetSingleScanLock() {
        isSingleFinished = false
    }

    public func stopRunning() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    public func attachPreview(to layer: AVCaptureVideoPreviewLayer) {
        layer.session = session
        layer.videoGravity = .resizeAspectFill
    }

    public var isTorchAvailable: Bool {
        guard let device = deviceInput?.device else { return false }
        return device.hasTorch && currentPosition == .back
    }

    public func setTorch(on: Bool) {
        guard let device = deviceInput?.device,
              device.hasTorch,
              currentPosition == .back
        else {
            isTorchOn = false
            return
        }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
        isTorchOn = on && device.torchMode == .on
    }

    @discardableResult
    public func toggleTorch() -> Bool {
        guard isTorchAvailable else {
            setTorch(on: false)
            return false
        }
        setTorch(on: !isTorchOn)
        return isTorchOn
    }

    public func toggleCamera() throws {
        let next: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        try switchCamera(to: next)
        if next == .front {
            setTorch(on: false)
        }
    }

    public func setZoom(_ factor: CGFloat) {
        guard let device = deviceInput?.device else { return }
        let maxZ = device.activeFormat.videoMaxZoomFactor
        let z = min(max(factor, 1), maxZ)
        try? device.lockForConfiguration()
        device.videoZoomFactor = z
        device.unlockForConfiguration()
    }

    public func switchCamera(to position: AVCaptureDevice.Position) throws {
        guard position != currentPosition else { return }
        session.beginConfiguration()
        if let input = deviceInput {
            session.removeInput(input)
            deviceInput = nil
        }
        try attachInput(position: position)
        session.commitConfiguration()
    }

    private func attachInput(position: AVCaptureDevice.Position) throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            throw RatifyeCameraError.noCamera
        }
        session.addInput(input)
        deviceInput = input
        currentPosition = position
    }

    private func visionOrientation() -> CGImagePropertyOrientation {
        // Back camera in portrait: match common Vision sample-buffer orientation.
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .portraitUpsideDown: return .left
        case .landscapeLeft: return .up
        case .landscapeRight: return .down
        default: return .right
        }
    }

    private func handleVisionResults(_ request: VNRequest) {
        guard let observations = request.results as? [VNBarcodeObservation] else { return }

        for obs in observations {
            guard let result = RatifyeScanResult.from(obs) else { continue }

            switch scanMode {
            case .single:
                if isSingleFinished { return }
                isSingleFinished = true
                emit(result, stopAfter: true)
                return
            case .multi:
                let now = Date()
                if let last = lastEmittedAt[result.payload], now.timeIntervalSince(last) < multiRescanCooldown {
                    continue
                }
                lastEmittedAt[result.payload] = now
                emit(result, stopAfter: false)
            }
        }
    }

    private func emit(_ result: RatifyeScanResult, stopAfter: Bool) {
        if vibrateOnDetect {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.ratifyeEngine(self, didOutput: result)
            if stopAfter {
                self.stopRunning()
            }
        }
    }
}

public enum RatifyeCameraError: Error {
    case noCamera
}

extension RatifyeBarcodeCameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        switch scanMode {
        case .single:
            if isSingleFinished { return }
        case .multi:
            break
        }

        guard !isProcessingFrame,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        isProcessingFrame = true
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: visionOrientation())
        barcodeRequest.symbologies = symbologies
        defer { isProcessingFrame = false }
        try? handler.perform([barcodeRequest])
    }
}

import UIKit
import AVFoundation

public protocol RatifyeSingleScanCameraViewDelegate: AnyObject {
    func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, didEmit event: RatifyeScanEventPayload)
    func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, cameraDidFail error: Error)
}

/// Embedded single-scan camera (plain and/or authenticated). Does not present sheets or dismiss parent UI.
public final class RatifyeSingleScanCameraView: UIView {
    public weak var delegate: RatifyeSingleScanCameraViewDelegate?

    public var featureConfiguration = RatifyeScanFeatureConfiguration() {
        didSet { applyFeatureConfiguration() }
    }

    public var presentationMode: RatifyeCameraPresentationMode = .embedded
    public var showsCloseButton: Bool = false

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let authCoordinator = RatifyeAuthScanCoordinator()
    private var closeButton: UIButton?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .black
        engine.scanMode = .single
        engine.delegate = self
        previewLayer.videoGravity = .resizeAspectFill
        layer.insertSublayer(previewLayer, at: 0)
        engine.attachPreview(to: previewLayer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startCameraIfEnabled()
        } else {
            engine.stopRunning()
        }
    }

    public func startCameraIfEnabled() {
        guard featureConfiguration.isScanningEnabled else {
            engine.stopRunning()
            return
        }
        do {
            try engine.configureIfNeeded()
            engine.startRunning()
        } catch {
            delegate?.ratifyeSingleScanCameraView(self, cameraDidFail: error)
        }
    }

    public func stopCamera() {
        engine.stopRunning()
    }

    private func applyFeatureConfiguration() {
        Task { @MainActor in
            authCoordinator.update(configuration: featureConfiguration.auth)
        }
        if window != nil {
            startCameraIfEnabled()
        }
    }

    public func configureChrome() {
        closeButton?.removeFromSuperview()
        closeButton = nil
        guard showsCloseButton, presentationMode == .modal else { return }

        let b = UIButton(type: .system)
        b.setTitle("Close", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        addSubview(b)
        NSLayoutConstraint.activate([
            b.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            b.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        closeButton = b
    }

    @objc private func closeTapped() {
        engine.stopRunning()
    }

    private func resumeAfterScan() {
        engine.resetSingleScanLock()
        engine.startRunning()
    }

    private func emit(_ event: RatifyeScanEventPayload) {
        delegate?.ratifyeSingleScanCameraView(self, didEmit: event)
    }

    private func handlePlainSingle(_ result: RatifyeScanResult) {
        emit(.single(result))
        resumeAfterScan()
    }

    @MainActor
    private func handleAuth(_ result: RatifyeScanResult) {
        guard featureConfiguration.usesAuthFlow, authCoordinator.canRunAuth else {
            if featureConfiguration.singleScanEnabled {
                handlePlainSingle(result)
            }
            return
        }
        guard !authCoordinator.isBusy else { return }

        authCoordinator.ingest(result) { [weak self] event in
            guard let self else { return }
            self.emit(event)
            self.resumeAfterScan()
        }
    }
}

extension RatifyeSingleScanCameraView: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        guard !authCoordinator.isBusy else { return }
        guard featureConfiguration.isScanningEnabled else { return }

        if featureConfiguration.usesAuthFlow {
            Task { @MainActor in
                handleAuth(result)
            }
        } else if featureConfiguration.singleScanEnabled {
            handlePlainSingle(result)
        }
    }
}

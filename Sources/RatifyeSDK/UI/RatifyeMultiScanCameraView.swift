import UIKit
import AVFoundation

public protocol RatifyeMultiScanCameraViewDelegate: AnyObject {
    func ratifyeMultiScanCameraView(_ view: RatifyeMultiScanCameraView, didEmit event: RatifyeScanEventPayload)
    func ratifyeMultiScanCameraView(_ view: RatifyeMultiScanCameraView, cameraDidFail error: Error)
    func ratifyeMultiScanCameraViewDidRequestFinish(_ view: RatifyeMultiScanCameraView)
}

/// Embedded continuous multi-scan camera (plain and/or authenticated ingest). Does not present sheets or dismiss parent UI.
public final class RatifyeMultiScanCameraView: UIView {
    public weak var delegate: RatifyeMultiScanCameraViewDelegate?

    public var featureConfiguration = RatifyeMultiScanFeatureConfiguration() {
        didSet { applyFeatureConfiguration() }
    }

    public var presentationMode: RatifyeCameraPresentationMode = .embedded
    public var showsDoneButton: Bool = false

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let authCoordinator = RatifyeAuthScanCoordinator()
    private var doneButton: UIButton?

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
        engine.scanMode = .multi
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
            delegate?.ratifyeMultiScanCameraView(self, cameraDidFail: error)
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
        } else if !featureConfiguration.multiScanEnabled {
            engine.stopRunning()
        }
    }

    public func configureChrome() {
        doneButton?.removeFromSuperview()
        doneButton = nil
        guard showsDoneButton else { return }

        let b = UIButton(type: .system)
        b.setTitle("Done", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        addSubview(b)
        NSLayoutConstraint.activate([
            b.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            b.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        doneButton = b
    }

    @objc private func doneTapped() {
        engine.stopRunning()
        delegate?.ratifyeMultiScanCameraViewDidRequestFinish(self)
    }

    private func emit(_ event: RatifyeScanEventPayload) {
        delegate?.ratifyeMultiScanCameraView(self, didEmit: event)
    }

    @MainActor
    private func handleScan(_ result: RatifyeScanResult) {
        guard featureConfiguration.multiScanEnabled else { return }

        if featureConfiguration.usesAuthFlow {
            guard authCoordinator.canRunAuth, !authCoordinator.isBusy else { return }
            authCoordinator.ingest(result) { [weak self] event in
                self?.emit(event)
            }
        } else {
            emit(.multi(result))
        }
    }
}

extension RatifyeMultiScanCameraView: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        guard featureConfiguration.multiScanEnabled else { return }
        Task { @MainActor in
            handleScan(result)
        }
    }
}

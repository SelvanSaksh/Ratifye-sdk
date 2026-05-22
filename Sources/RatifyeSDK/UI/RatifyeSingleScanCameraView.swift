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
    public var showsCameraControls: Bool = true {
        didSet { controlsView.isHidden = !showsCameraControls }
    }

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let authCoordinator = RatifyeAuthScanCoordinator()
    private let controlsView = RatifyeCameraControlsView()
    private let galleryPicker = RatifyeGalleryPickerPresenter()
    private var scanDispatcher: RatifyeCameraScanDispatcher?
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

        controlsView.delegate = self
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controlsView)
        NSLayoutConstraint.activate([
            controlsView.centerXAnchor.constraint(equalTo: centerXAnchor),
            controlsView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        updateFlashControl()

        galleryPicker.onImagePicked = { [weak self] image in
            self?.handleGalleryImage(image)
        }

        Task { @MainActor in
            self.rebuildDispatcher()
        }
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
            updateFlashControl()
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
            rebuildDispatcher()
        }
        if window != nil {
            startCameraIfEnabled()
        }
    }

    @MainActor
    private func rebuildDispatcher() {
        scanDispatcher = RatifyeCameraScanDispatcher(
            surface: .single,
            authCoordinator: authCoordinator,
            usesAuthFlow: featureConfiguration.usesAuthFlow,
            plainScanEnabled: featureConfiguration.singleScanEnabled,
            emit: { [weak self] event in
                guard let self else { return }
                self.delegate?.ratifyeSingleScanCameraView(self, didEmit: event)
            },
            onAfterSingleScan: { [weak self] in
                self?.resumeAfterScan()
            }
        )
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

    private func updateFlashControl() {
        controlsView.setFlashOn(engine.isTorchOn, available: engine.isTorchAvailable)
    }

    @MainActor
    private func handleGalleryImage(_ image: UIImage) {
        let results = RatifyeBarcodeImageScanner.scan(image)
        guard !results.isEmpty else { return }
        if scanDispatcher == nil { rebuildDispatcher() }
        scanDispatcher?.dispatchGalleryResults(results)
    }
}

extension RatifyeSingleScanCameraView: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        guard !authCoordinator.isBusy else { return }
        guard featureConfiguration.isScanningEnabled else { return }
        Task { @MainActor in
            if scanDispatcher == nil { rebuildDispatcher() }
            scanDispatcher?.dispatch(result)
        }
    }
}

extension RatifyeSingleScanCameraView: RatifyeCameraControlsViewDelegate {
    func cameraControlsDidTapSwitchCamera(_ controls: RatifyeCameraControlsView) {
        do {
            try engine.toggleCamera()
            updateFlashControl()
        } catch {
            delegate?.ratifyeSingleScanCameraView(self, cameraDidFail: error)
        }
    }

    func cameraControlsDidTapFlash(_ controls: RatifyeCameraControlsView) {
        _ = engine.toggleTorch()
        updateFlashControl()
    }

    func cameraControlsDidTapGallery(_ controls: RatifyeCameraControlsView) {
        galleryPicker.present(from: self)
    }
}

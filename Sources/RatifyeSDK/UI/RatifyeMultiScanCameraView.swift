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
    public var showsCameraControls: Bool = true {
        didSet { controlsView.isHidden = !showsCameraControls }
    }

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let authCoordinator = RatifyeAuthScanCoordinator()
    private let controlsView = RatifyeCameraControlsView()
    private let galleryPicker = RatifyeGalleryPickerPresenter()
    private var scanDispatcher: RatifyeCameraScanDispatcher?
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
            delegate?.ratifyeMultiScanCameraView(self, cameraDidFail: error)
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
        } else if !featureConfiguration.multiScanEnabled {
            engine.stopRunning()
        }
    }

    @MainActor
    private func rebuildDispatcher() {
        scanDispatcher = RatifyeCameraScanDispatcher(
            surface: .multi,
            authCoordinator: authCoordinator,
            usesAuthFlow: featureConfiguration.usesAuthFlow,
            plainScanEnabled: featureConfiguration.multiScanEnabled,
            emit: { [weak self] event in
                guard let self else { return }
                self.delegate?.ratifyeMultiScanCameraView(self, didEmit: event)
            }
        )
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

extension RatifyeMultiScanCameraView: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        guard featureConfiguration.multiScanEnabled else { return }
        Task { @MainActor in
            if scanDispatcher == nil { rebuildDispatcher() }
            scanDispatcher?.dispatch(result)
        }
    }
}

extension RatifyeMultiScanCameraView: RatifyeCameraControlsViewDelegate {
    func cameraControlsDidTapSwitchCamera(_ controls: RatifyeCameraControlsView) {
        do {
            try engine.toggleCamera()
            updateFlashControl()
        } catch {
            delegate?.ratifyeMultiScanCameraView(self, cameraDidFail: error)
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

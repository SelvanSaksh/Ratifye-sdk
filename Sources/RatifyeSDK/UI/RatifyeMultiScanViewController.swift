import UIKit
import AVFoundation

public protocol RatifyeMultiScanViewControllerDelegate: AnyObject {
    func ratifyeMultiScan(_ controller: RatifyeMultiScanViewController, didScan result: RatifyeScanResult)
    func ratifyeMultiScanDidFinish(_ controller: RatifyeMultiScanViewController)
}

/// Continuous scanning; duplicate payloads are throttled by the engine cooldown.
open class RatifyeMultiScanViewController: UIViewController {
    public weak var scanDelegate: RatifyeMultiScanViewControllerDelegate?

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()

    public var showsDoneButton: Bool = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        engine.scanMode = .multi
        engine.delegate = self
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        engine.attachPreview(to: previewLayer)

        do {
            try engine.configureIfNeeded()
        } catch {
            dismiss(animated: true)
            return
        }

        if showsDoneButton {
            let b = UIButton(type: .system)
            b.setTitle("Done", for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
            b.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(b)
            NSLayoutConstraint.activate([
                b.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                b.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
            ])
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        engine.startRunning()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine.stopRunning()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    @objc private func doneTapped() {
        engine.stopRunning()
        scanDelegate?.ratifyeMultiScanDidFinish(self)
        dismiss(animated: true)
    }
}

extension RatifyeMultiScanViewController: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        scanDelegate?.ratifyeMultiScan(self, didScan: result)
    }
}

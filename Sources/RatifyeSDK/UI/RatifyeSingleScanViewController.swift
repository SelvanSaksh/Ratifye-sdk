import UIKit
import AVFoundation

public protocol RatifyeSingleScanViewControllerDelegate: AnyObject {
    func ratifyeSingleScan(_ controller: RatifyeSingleScanViewController, didFinishWith result: RatifyeScanResult)
    func ratifyeSingleScanDidCancel(_ controller: RatifyeSingleScanViewController)
}

/// Presents a full-screen camera and returns the first decoded barcode.
open class RatifyeSingleScanViewController: UIViewController {
    public weak var scanDelegate: RatifyeSingleScanViewControllerDelegate?

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()

    public var showsCloseButton: Bool = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        engine.scanMode = .single
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

        if showsCloseButton {
            let b = UIButton(type: .system)
            b.setTitle("Close", for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
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

    @objc private func closeTapped() {
        scanDelegate?.ratifyeSingleScanDidCancel(self)
        dismiss(animated: true)
    }
}

extension RatifyeSingleScanViewController: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        scanDelegate?.ratifyeSingleScan(self, didFinishWith: result)
        dismiss(animated: true)
    }
}

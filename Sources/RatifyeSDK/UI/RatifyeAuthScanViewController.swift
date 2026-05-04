import UIKit
import AVFoundation

public protocol RatifyeAuthScanViewControllerDelegate: AnyObject {
    /// Called after a successful server ingest (2xx).
    func ratifyeAuthScan(_ controller: RatifyeAuthScanViewController, didValidate result: RatifyeScanResult, serverData: Data)
    func ratifyeAuthScan(_ controller: RatifyeAuthScanViewController, didFailIngest error: Error, for result: RatifyeScanResult)
    func ratifyeAuthScanDidCancel(_ controller: RatifyeAuthScanViewController)
}

/// Single scan that POSTs the payload to your API using `RatifyeAuthConfiguration`.
open class RatifyeAuthScanViewController: UIViewController {
    public weak var scanDelegate: RatifyeAuthScanViewControllerDelegate?

    private let engine = RatifyeBarcodeCameraEngine()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let ingestClient: RatifyeScanIngestClient
    private var isAwaitingIngest = false

    public init(configuration: RatifyeAuthConfiguration) {
        self.ingestClient = RatifyeScanIngestClient(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        scanDelegate?.ratifyeAuthScanDidCancel(self)
        dismiss(animated: true)
    }
}

extension RatifyeAuthScanViewController: RatifyeBarcodeCameraEngineDelegate {
    public func ratifyeEngine(_ engine: RatifyeBarcodeCameraEngine, didOutput result: RatifyeScanResult) {
        guard !isAwaitingIngest else { return }
        isAwaitingIngest = true

        Task { @MainActor in
            defer { self.isAwaitingIngest = false }
            do {
                let (_, data) = try await ingestClient.ingest(result)
                self.scanDelegate?.ratifyeAuthScan(self, didValidate: result, serverData: data)
                self.dismiss(animated: true)
            } catch {
                self.engine.resetSingleScanLock()
                self.engine.startRunning()
                self.scanDelegate?.ratifyeAuthScan(self, didFailIngest: error, for: result)
            }
        }
    }
}

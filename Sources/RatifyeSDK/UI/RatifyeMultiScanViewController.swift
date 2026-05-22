import UIKit

public protocol RatifyeMultiScanViewControllerDelegate: AnyObject {
    func ratifyeMultiScan(_ controller: RatifyeMultiScanViewController, didEmit event: RatifyeScanEventPayload)
    func ratifyeMultiScanDidFinish(_ controller: RatifyeMultiScanViewController)
}

/// Full-screen host for `RatifyeMultiScanCameraView`. Use `.embedded` when placing inside your layout (no auto-dismiss).
open class RatifyeMultiScanViewController: UIViewController {
    public weak var scanDelegate: RatifyeMultiScanViewControllerDelegate?

    public let cameraView = RatifyeMultiScanCameraView()

    public var featureConfiguration: RatifyeMultiScanFeatureConfiguration {
        get { cameraView.featureConfiguration }
        set { cameraView.featureConfiguration = newValue }
    }

    public var presentationMode: RatifyeCameraPresentationMode = .modal {
        didSet {
            cameraView.presentationMode = presentationMode
            cameraView.showsDoneButton = presentationMode == .modal
            cameraView.configureChrome()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        cameraView.presentationMode = presentationMode
        cameraView.showsDoneButton = presentationMode == .modal
        cameraView.delegate = self
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraView)
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        cameraView.configureChrome()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraView.startCameraIfEnabled()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.stopCamera()
    }
}

extension RatifyeMultiScanViewController: RatifyeMultiScanCameraViewDelegate {
    public func ratifyeMultiScanCameraView(_ view: RatifyeMultiScanCameraView, didEmit event: RatifyeScanEventPayload) {
        scanDelegate?.ratifyeMultiScan(self, didEmit: event)
    }

    public func ratifyeMultiScanCameraView(_ view: RatifyeMultiScanCameraView, cameraDidFail error: Error) {
        if presentationMode == .modal {
            dismiss(animated: true)
        }
    }

    public func ratifyeMultiScanCameraViewDidRequestFinish(_ view: RatifyeMultiScanCameraView) {
        scanDelegate?.ratifyeMultiScanDidFinish(self)
        if presentationMode == .modal {
            dismiss(animated: true)
        }
    }
}

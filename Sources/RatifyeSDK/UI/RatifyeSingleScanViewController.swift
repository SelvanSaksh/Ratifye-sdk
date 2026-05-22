import UIKit

public protocol RatifyeSingleScanViewControllerDelegate: AnyObject {
    func ratifyeSingleScan(_ controller: RatifyeSingleScanViewController, didEmit event: RatifyeScanEventPayload)
    func ratifyeSingleScanDidCancel(_ controller: RatifyeSingleScanViewController)
}

/// Full-screen host for `RatifyeSingleScanCameraView`. Use `.embedded` when placing inside your layout (no auto-dismiss).
open class RatifyeSingleScanViewController: UIViewController {
    public weak var scanDelegate: RatifyeSingleScanViewControllerDelegate?

    public let cameraView = RatifyeSingleScanCameraView()

    public var featureConfiguration: RatifyeScanFeatureConfiguration {
        get { cameraView.featureConfiguration }
        set { cameraView.featureConfiguration = newValue }
    }

    public var presentationMode: RatifyeCameraPresentationMode = .modal {
        didSet {
            cameraView.presentationMode = presentationMode
            cameraView.showsCloseButton = presentationMode == .modal
            cameraView.configureChrome()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        cameraView.presentationMode = presentationMode
        cameraView.showsCloseButton = presentationMode == .modal
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

extension RatifyeSingleScanViewController: RatifyeSingleScanCameraViewDelegate {
    public func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, didEmit event: RatifyeScanEventPayload) {
        scanDelegate?.ratifyeSingleScan(self, didEmit: event)
        if presentationMode == .modal, case .single = event {
            dismiss(animated: true)
        }
        if presentationMode == .modal, case .authSuccess = event {
            dismiss(animated: true)
        }
    }

    public func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, cameraDidFail error: Error) {
        if presentationMode == .modal {
            dismiss(animated: true)
        }
    }
}

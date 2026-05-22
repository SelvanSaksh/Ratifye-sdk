import UIKit

public protocol RatifyeAuthScanViewControllerDelegate: AnyObject {
    func ratifyeAuthScan(_ controller: RatifyeAuthScanViewController, didEmit event: RatifyeScanEventPayload)
    func ratifyeAuthScanDidCancel(_ controller: RatifyeAuthScanViewController)
}

/// Authenticated single scan host. Prefer `RatifyeSingleScanCameraView` with `authScanEnabled` for page embedding.
open class RatifyeAuthScanViewController: UIViewController {
    public weak var scanDelegate: RatifyeAuthScanViewControllerDelegate?

    public let cameraView = RatifyeSingleScanCameraView()

    public var presentationMode: RatifyeCameraPresentationMode = .modal {
        didSet {
            cameraView.presentationMode = presentationMode
            cameraView.showsCloseButton = presentationMode == .modal
            cameraView.configureChrome()
        }
    }

    public init(configuration: RatifyeAuthConfiguration, presentationMode: RatifyeCameraPresentationMode = .modal) {
        self.presentationMode = presentationMode
        super.init(nibName: nil, bundle: nil)
        cameraView.featureConfiguration = RatifyeScanFeatureConfiguration(
            singleScanEnabled: false,
            authScanEnabled: true,
            authConfiguration: configuration
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

extension RatifyeAuthScanViewController: RatifyeSingleScanCameraViewDelegate {
    public func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, didEmit event: RatifyeScanEventPayload) {
        scanDelegate?.ratifyeAuthScan(self, didEmit: event)
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

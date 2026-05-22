import Foundation
import RatifyeSDK
import React

@objc(RatifyeMultiScanNativeView)
final class RatifyeMultiScanNativeView: UIView, RatifyeMultiScanCameraViewDelegate {
    private let cameraView = RatifyeMultiScanCameraView()

    @objc var multiScanEnabled: Bool = true {
        didSet { applyConfiguration() }
    }

    @objc var authScanEnabled: Bool = false {
        didSet { applyConfiguration() }
    }

    @objc var onScanEvent: RCTDirectEventBlock?

    override init(frame: CGRect) {
        super.init(frame: frame)
        cameraView.presentationMode = .embedded
        cameraView.delegate = self
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cameraView)
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        applyConfiguration()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyConfiguration() {
        cameraView.featureConfiguration = RatifyeMultiScanFeatureConfiguration(
            multiScanEnabled: multiScanEnabled,
            auth: RatifyeRNAuthConfiguration.authFeature(authScanEnabled: authScanEnabled)
        )
        if window != nil {
            setNeedsLayout()
            layoutIfNeeded()
            cameraView.startCameraIfEnabled()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if window != nil, bounds.width > 1, bounds.height > 1 {
            cameraView.startCameraIfEnabled()
        }
    }

    func ratifyeMultiScanCameraView(_ view: RatifyeMultiScanCameraView, didEmit event: RatifyeScanEventPayload) {
        onScanEvent?(event.toDictionary(surface: .multi))
    }

    func ratifyeMultiScanCameraView(_ view: RatifyeMultiScanCameraView, cameraDidFail error: Error) {
        onScanEvent?([
            "kind": "camera_error",
            "surface": RatifyeScanSurface.multi.rawValue,
            "errorCode": "camera_error",
            "errorMessage": error.localizedDescription
        ])
    }

    func ratifyeMultiScanCameraViewDidRequestFinish(_ view: RatifyeMultiScanCameraView) {}
}

@objc(RatifyeMultiScanViewManager)
final class RatifyeMultiScanViewManager: RCTViewManager {
    override static func moduleName() -> String! { "RatifyeMultiScanView" }

    override static func requiresMainQueueSetup() -> Bool { true }

    override func view() -> UIView! {
        RatifyeMultiScanNativeView()
    }
}

import Foundation
import RatifyeSDK
import React

@objc(RatifyeSingleScanNativeView)
final class RatifyeSingleScanNativeView: UIView, RatifyeSingleScanCameraViewDelegate {
    private let cameraView = RatifyeSingleScanCameraView()

    @objc var singleScanEnabled: Bool = true {
        didSet { applyConfiguration() }
    }

    @objc var authScanEnabled: Bool = false {
        didSet { applyConfiguration() }
    }

    @objc var ingestURL: NSString? {
        didSet { applyConfiguration() }
    }

    @objc var bearerToken: NSString? {
        didSet { applyConfiguration() }
    }

    @objc var apiKey: NSString? {
        didSet { applyConfiguration() }
    }

    @objc var companyId: NSString? {
        didSet { applyConfiguration() }
    }

    @objc var ingestFormat: NSString? {
        didSet { applyConfiguration() }
    }

    @objc var extraHTTPHeaders: NSDictionary? {
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
        let auth = RatifyeRNAuthConfiguration.authFeature(
            authScanEnabled: authScanEnabled,
            ingestURL: ingestURL,
            bearerToken: bearerToken,
            apiKey: apiKey,
            companyId: companyId,
            ingestFormat: ingestFormat,
            extraHTTPHeaders: extraHTTPHeaders
        )
        cameraView.featureConfiguration = RatifyeScanFeatureConfiguration(
            singleScanEnabled: singleScanEnabled,
            auth: auth
        )
    }

    func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, didEmit event: RatifyeScanEventPayload) {
        onScanEvent?(event.toDictionary(surface: .single))
    }

    func ratifyeSingleScanCameraView(_ view: RatifyeSingleScanCameraView, cameraDidFail error: Error) {
        onScanEvent?([
            "kind": "camera_error",
            "surface": RatifyeScanSurface.single.rawValue,
            "errorCode": "camera_error",
            "errorMessage": error.localizedDescription
        ])
    }
}

@objc(RatifyeSingleScanViewManager)
final class RatifyeSingleScanViewManager: RCTViewManager {
    override static func moduleName() -> String! { "RatifyeSingleScanView" }

    override static func requiresMainQueueSetup() -> Bool { true }

    override func view() -> UIView! {
        RatifyeSingleScanNativeView()
    }
}

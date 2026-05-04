import Foundation
import RatifyeSDK
import React

/// Copy into your React Native iOS target (alongside the .m bridge file).
/// Ensure the app target links **RatifyeSDK** (Swift Package) and imports **React**.
@objc(RatifyeScan)
final class RatifyeScanModule: NSObject, RCTBridgeModule {

    static func moduleName() -> String! { "RatifyeScan" }

    static func requiresMainQueueSetup() -> Bool { true }

    @objc(scan:rejecter:)
    func scan(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            guard let host = RCTPresentedViewController() else {
                reject("E_NO_HOST", "No presented view controller", nil)
                return
            }
            let vc = RatifyeSingleScanViewController()
            let proxy = SingleScanProxy(resolve: resolve, reject: reject)
            vc.scanDelegate = proxy
            objc_setAssociatedObject(vc, &SingleScanProxy.associatedKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            vc.modalPresentationStyle = .fullScreen
            host.present(vc, animated: true)
        }
    }
}

private final class SingleScanProxy: NSObject, RatifyeSingleScanViewControllerDelegate {
    static var associatedKey: UInt8 = 0

    private let resolve: RCTPromiseResolveBlock
    private let reject: RCTPromiseRejectBlock

    init(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolve
        self.reject = reject
    }

    func ratifyeSingleScan(_ controller: RatifyeSingleScanViewController, didFinishWith result: RatifyeScanResult) {
        resolve(["payload": result.payload, "symbologyRaw": result.symbologyRaw])
        objc_setAssociatedObject(controller, &SingleScanProxy.associatedKey, nil, .OBJC_ASSOCIATION_ASSIGN)
    }

    func ratifyeSingleScanDidCancel(_ controller: RatifyeSingleScanViewController) {
        reject("E_CANCELLED", "User cancelled scan", nil)
        objc_setAssociatedObject(controller, &SingleScanProxy.associatedKey, nil, .OBJC_ASSOCIATION_ASSIGN)
    }
}

import Foundation

@MainActor
final class RatifyeCameraScanDispatcher {
    enum Surface {
        case single
        case multi
    }

    let surface: Surface
    let authCoordinator: RatifyeAuthScanCoordinator
    var usesAuthFlow: Bool
    var plainScanEnabled: Bool
    let emit: (RatifyeScanEventPayload) -> Void
    let onAfterSingleScan: (() -> Void)?

    init(
        surface: Surface,
        authCoordinator: RatifyeAuthScanCoordinator,
        usesAuthFlow: Bool,
        plainScanEnabled: Bool,
        emit: @escaping (RatifyeScanEventPayload) -> Void,
        onAfterSingleScan: (() -> Void)? = nil
    ) {
        self.surface = surface
        self.authCoordinator = authCoordinator
        self.usesAuthFlow = usesAuthFlow
        self.plainScanEnabled = plainScanEnabled
        self.emit = emit
        self.onAfterSingleScan = onAfterSingleScan
    }

    func dispatch(_ result: RatifyeScanResult) {
        guard plainScanEnabled || usesAuthFlow else { return }

        if usesAuthFlow {
            guard authCoordinator.canRunAuth, !authCoordinator.isBusy else { return }
            authCoordinator.ingest(result) { [weak self] event in
                guard let self else { return }
                self.emit(event)
                self.onAfterSingleScan?()
            }
            return
        }

        switch surface {
        case .single:
            emit(.single(result))
            onAfterSingleScan?()
        case .multi:
            emit(.multi(result))
        }
    }

    func dispatchGalleryResults(_ results: [RatifyeScanResult]) {
        guard !results.isEmpty else { return }
        switch surface {
        case .single:
            dispatch(results[0])
        case .multi:
            for result in results {
                dispatch(result)
            }
        }
    }
}

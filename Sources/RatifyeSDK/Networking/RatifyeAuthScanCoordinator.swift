import Foundation

/// Runs authenticated ingest for any scan surface (single or multi).
@MainActor
public final class RatifyeAuthScanCoordinator {
    private var ingestClient: RatifyeScanIngestClient?
    private var isIngestInFlight = false

    public init() {}

    public func update(configuration: RatifyeAuthFeatureConfiguration) {
        if configuration.usesAuthFlow, let cfg = configuration.authConfiguration {
            ingestClient = RatifyeScanIngestClient(configuration: cfg)
        } else {
            ingestClient = nil
        }
    }

    public var canRunAuth: Bool {
        ingestClient != nil
    }

    public var isBusy: Bool { isIngestInFlight }

    public func ingest(
        _ result: RatifyeScanResult,
        completion: @escaping (RatifyeScanEventPayload) -> Void
    ) {
        guard let ingestClient, !isIngestInFlight else { return }
        isIngestInFlight = true

        Task {
            defer { self.isIngestInFlight = false }
            do {
                let (status, data) = try await ingestClient.ingest(result)
                let success = RatifyeAuthScanSuccess(scan: result, httpStatus: status, responseData: data)
                completion(.authSuccess(success))
            } catch {
                let failure = RatifyeAuthScanFailure(
                    scan: result,
                    error: error,
                    httpStatus: RatifyeIngestErrorBridge.httpStatus(from: error),
                    responseData: RatifyeIngestErrorBridge.responseData(from: error)
                )
                completion(.authFailure(failure))
            }
        }
    }
}

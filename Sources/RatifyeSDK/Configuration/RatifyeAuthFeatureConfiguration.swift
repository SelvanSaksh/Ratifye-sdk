import Foundation

/// Auth ingest settings shared by single- and multi-scan camera surfaces.
public struct RatifyeAuthFeatureConfiguration: Sendable {
    public var authScanEnabled: Bool
    public var authConfiguration: RatifyeAuthConfiguration?

    public init(
        authScanEnabled: Bool = false,
        authConfiguration: RatifyeAuthConfiguration? = nil
    ) {
        self.authScanEnabled = authScanEnabled
        self.authConfiguration = authConfiguration
    }

    public var usesAuthFlow: Bool {
        guard authScanEnabled,
              let cfg = authConfiguration,
              cfg.ingestURL != nil
        else { return false }
        return cfg.isAuthBcReady
    }
}

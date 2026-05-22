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
        authScanEnabled && authConfiguration != nil
    }

    /// Auth on/off only — uses SDK default ingest URL and `company_id` `"0"`.
    public static func withAuthEnabled(_ enabled: Bool) -> RatifyeAuthFeatureConfiguration {
        RatifyeAuthFeatureConfiguration(
            authScanEnabled: enabled,
            authConfiguration: enabled ? .standard : nil
        )
    }
}

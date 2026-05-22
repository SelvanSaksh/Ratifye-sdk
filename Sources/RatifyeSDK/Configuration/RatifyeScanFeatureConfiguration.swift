import Foundation

/// Which scan behaviors are active on the single-scan camera surface.
public struct RatifyeScanFeatureConfiguration: Sendable {
    /// Plain single scan: emit barcode locally (no HTTP).
    public var singleScanEnabled: Bool
    public var auth: RatifyeAuthFeatureConfiguration

    public init(
        singleScanEnabled: Bool = true,
        authScanEnabled: Bool = false,
        authConfiguration: RatifyeAuthConfiguration? = nil
    ) {
        self.singleScanEnabled = singleScanEnabled
        self.auth = RatifyeAuthFeatureConfiguration(
            authScanEnabled: authScanEnabled,
            authConfiguration: authConfiguration
        )
    }

    public init(singleScanEnabled: Bool, auth: RatifyeAuthFeatureConfiguration) {
        self.singleScanEnabled = singleScanEnabled
        self.auth = auth
    }

    public var authScanEnabled: Bool {
        get { auth.authScanEnabled }
        set { auth.authScanEnabled = newValue }
    }

    public var authConfiguration: RatifyeAuthConfiguration? {
        get { auth.authConfiguration }
        set { auth.authConfiguration = newValue }
    }

    public var usesAuthFlow: Bool { auth.usesAuthFlow }

    public var isScanningEnabled: Bool {
        usesAuthFlow || singleScanEnabled
    }
}

/// Feature flags for the multi-scan camera surface.
public struct RatifyeMultiScanFeatureConfiguration: Sendable {
    public var multiScanEnabled: Bool
    public var auth: RatifyeAuthFeatureConfiguration

    public init(
        multiScanEnabled: Bool = true,
        authScanEnabled: Bool = false,
        authConfiguration: RatifyeAuthConfiguration? = nil
    ) {
        self.multiScanEnabled = multiScanEnabled
        self.auth = RatifyeAuthFeatureConfiguration(
            authScanEnabled: authScanEnabled,
            authConfiguration: authConfiguration
        )
    }

    public init(multiScanEnabled: Bool, auth: RatifyeAuthFeatureConfiguration) {
        self.multiScanEnabled = multiScanEnabled
        self.auth = auth
    }

    public var authScanEnabled: Bool {
        get { auth.authScanEnabled }
        set { auth.authScanEnabled = newValue }
    }

    public var authConfiguration: RatifyeAuthConfiguration? {
        get { auth.authConfiguration }
        set { auth.authConfiguration = newValue }
    }

    public var usesAuthFlow: Bool { auth.usesAuthFlow }

    public var isScanningEnabled: Bool {
        multiScanEnabled
    }
}

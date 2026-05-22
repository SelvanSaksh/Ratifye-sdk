import Foundation

/// JSON body shape for authenticated ingest.
public enum RatifyeAuthIngestFormat: String, Sendable {
    case authBc = "auth_bc"
    case legacy = "legacy"
}

/// Auth ingest settings. URL and `company_id` use SDK defaults unless overridden internally.
public struct RatifyeAuthConfiguration: Sendable {
    public var bearerToken: String?
    public var apiKey: String?
    public var ingestURL: URL
    public var extraHTTPHeaders: [String: String]
    public var ingestFormat: RatifyeAuthIngestFormat
    public var companyId: String

    public init(
        bearerToken: String? = nil,
        apiKey: String? = nil,
        ingestURL: URL = RatifyeAuthDefaults.ingestURL,
        extraHTTPHeaders: [String: String] = [:],
        ingestFormat: RatifyeAuthIngestFormat = .authBc,
        companyId: String = RatifyeAuthDefaults.companyId
    ) {
        self.bearerToken = bearerToken
        self.apiKey = apiKey
        self.ingestURL = ingestURL
        self.extraHTTPHeaders = extraHTTPHeaders
        self.ingestFormat = ingestFormat
        self.companyId = companyId
    }

    /// Default auth-bc configuration used when `authScanEnabled` is true.
    public static var standard: RatifyeAuthConfiguration {
        RatifyeAuthConfiguration()
    }
}

import Foundation

/// JSON body shape for authenticated ingest.
public enum RatifyeAuthIngestFormat: String, Sendable {
    /// `POST` `[{ "encrypted_text", "barcode_data", "company_id" }]`
    case authBc = "auth_bc"
    /// `POST` `{ "payload", "symbologyRaw" }` (legacy).
    case legacy = "legacy"
}

/// Credentials and backend used for authenticated scan flows. All values are supplied by the host app.
public struct RatifyeAuthConfiguration: Sendable {
    public var bearerToken: String?
    public var apiKey: String?
    /// Full ingest URL from your app config (not hardcoded in the SDK).
    public var ingestURL: URL?
    public var extraHTTPHeaders: [String: String]
    public var ingestFormat: RatifyeAuthIngestFormat
    /// Required for `authBc` when auth ingest runs — set from your app/session.
    public var companyId: String?

    public init(
        bearerToken: String? = nil,
        apiKey: String? = nil,
        ingestURL: URL? = nil,
        extraHTTPHeaders: [String: String] = [:],
        ingestFormat: RatifyeAuthIngestFormat = .authBc,
        companyId: String? = nil
    ) {
        self.bearerToken = bearerToken
        self.apiKey = apiKey
        self.ingestURL = ingestURL
        self.extraHTTPHeaders = extraHTTPHeaders
        self.ingestFormat = ingestFormat
        self.companyId = companyId
    }

    public var isAuthBcReady: Bool {
        guard ingestFormat == .authBc else { return true }
        guard let companyId, !companyId.isEmpty else { return false }
        return true
    }
}

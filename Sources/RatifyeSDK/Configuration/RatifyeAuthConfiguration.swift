import Foundation

/// Credentials and optional backend used for authenticated scan flows.
public struct RatifyeAuthConfiguration: Sendable {
    public var bearerToken: String?
    public var apiKey: String?
    /// If set, `POST` JSON `{ "payload", "symbologyRaw" }` with auth headers.
    public var ingestURL: URL?
    public var extraHTTPHeaders: [String: String]

    public init(
        bearerToken: String? = nil,
        apiKey: String? = nil,
        ingestURL: URL? = nil,
        extraHTTPHeaders: [String: String] = [:]
    ) {
        self.bearerToken = bearerToken
        self.apiKey = apiKey
        self.ingestURL = ingestURL
        self.extraHTTPHeaders = extraHTTPHeaders
    }
}

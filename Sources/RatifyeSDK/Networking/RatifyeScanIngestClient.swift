import Foundation

public enum RatifyeIngestError: Error, Sendable {
    case missingURL
    case invalidResponse
    case httpStatus(Int, Data?)
}

extension RatifyeIngestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Ingest URL is not configured."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let code, _):
            return "Ingest failed with HTTP status \(code)."
        }
    }
}

/// Posts scan results to your API using the auth configuration.
public struct RatifyeScanIngestClient: Sendable {
    public var configuration: RatifyeAuthConfiguration
    public var urlSession: URLSession

    public init(configuration: RatifyeAuthConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    public func ingest(_ result: RatifyeScanResult) async throws -> (status: Int, data: Data) {
        guard let url = configuration.ingestURL else { throw RatifyeIngestError.missingURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = configuration.bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let key = configuration.apiKey {
            request.setValue(key, forHTTPHeaderField: "X-API-Key")
        }
        for (k, v) in configuration.extraHTTPHeaders {
            request.setValue(v, forHTTPHeaderField: k)
        }

        let body: [String: String] = [
            "payload": result.payload,
            "symbologyRaw": result.symbologyRaw
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RatifyeIngestError.invalidResponse }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw RatifyeIngestError.httpStatus(http.statusCode, data)
        }
        return (http.statusCode, data)
    }
}

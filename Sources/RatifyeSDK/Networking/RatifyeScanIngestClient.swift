import Foundation

public enum RatifyeIngestError: Error, Sendable {
    case missingURL
    case invalidResponse
    case httpStatus(Int, Data?)
    case bodyEncodingFailed
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
        case .bodyEncodingFailed:
            return "Failed to encode the ingest request body."
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
        var request = URLRequest(url: configuration.ingestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyDefaultHeaders(to: &request)

        if let token = configuration.bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let key = configuration.apiKey {
            request.setValue(key, forHTTPHeaderField: "X-API-Key")
        }
        for (k, v) in configuration.extraHTTPHeaders {
            request.setValue(v, forHTTPHeaderField: k)
        }

        request.httpBody = try makeRequestBody(for: result)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RatifyeIngestError.invalidResponse }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw RatifyeIngestError.httpStatus(http.statusCode, data)
        }
        return (http.statusCode, data)
    }

    private func applyDefaultHeaders(to request: inout URLRequest) {
        if configuration.ingestFormat == .authBc {
            if request.value(forHTTPHeaderField: "Accept") == nil {
                request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
            }
        }
    }

    /// Encodes the request body for the configured ingest format (for tests and debugging).
    public func encodedRequestBody(for result: RatifyeScanResult) throws -> Data {
        try makeRequestBody(for: result)
    }

    private func makeRequestBody(for result: RatifyeScanResult) throws -> Data {
        switch configuration.ingestFormat {
        case .legacy:
            let body: [String: String] = [
                "payload": result.payload,
                "symbologyRaw": result.symbologyRaw
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: body) else {
                throw RatifyeIngestError.bodyEncodingFailed
            }
            return data

        case .authBc:
            let parsed = RatifyeBarcodeParsing.parse(result.payload)
            let item = parsed.toAuthDictionary()
            guard let data = try? JSONSerialization.data(withJSONObject: [item]) else {
                throw RatifyeIngestError.bodyEncodingFailed
            }
            return data
        }
    }
}

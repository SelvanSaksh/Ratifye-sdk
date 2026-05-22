import Foundation

public struct RatifyeAuthScanSuccess: Sendable {
    public let scan: RatifyeScanResult
    public let httpStatus: Int
    public let responseData: Data

    public init(scan: RatifyeScanResult, httpStatus: Int, responseData: Data) {
        self.scan = scan
        self.httpStatus = httpStatus
        self.responseData = responseData
    }

    public var responseBodyString: String? {
        String(data: responseData, encoding: .utf8)
    }

    public func responseJSONObject() -> [String: Any]? {
        RatifyeJSONBridge.object(from: responseData) as? [String: Any]
    }
}

public struct RatifyeAuthScanFailure: Sendable {
    public let scan: RatifyeScanResult
    public let error: Error
    public let httpStatus: Int?
    public let responseData: Data?

    public init(scan: RatifyeScanResult, error: Error, httpStatus: Int? = nil, responseData: Data? = nil) {
        self.scan = scan
        self.error = error
        self.httpStatus = httpStatus
        self.responseData = responseData
    }

    public var responseBodyString: String? {
        guard let responseData else { return nil }
        return String(data: responseData, encoding: .utf8)
    }

    public func responseJSONObject() -> [String: Any]? {
        guard let responseData else { return nil }
        return RatifyeJSONBridge.object(from: responseData) as? [String: Any]
    }
}

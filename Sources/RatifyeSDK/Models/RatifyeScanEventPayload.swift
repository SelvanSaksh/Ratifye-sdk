import Foundation

public enum RatifyeScanSurface: String, Sendable {
    case single
    case multi
}

public enum RatifyeScanEventKind: String, Sendable {
    case single
    case authSuccess = "auth_success"
    case authFailure = "auth_failure"
    case multi
}

/// Normalized event body for app / React Native layers (sheets, popups, etc.).
public enum RatifyeScanEventPayload: Sendable {
    case single(RatifyeScanResult)
    case authSuccess(RatifyeAuthScanSuccess)
    case authFailure(RatifyeAuthScanFailure)
    case multi(RatifyeScanResult)

    public var kind: RatifyeScanEventKind {
        switch self {
        case .single: return .single
        case .authSuccess: return .authSuccess
        case .authFailure: return .authFailure
        case .multi: return .multi
        }
    }

    public func toDictionary(surface: RatifyeScanSurface) -> [String: Any] {
        switch self {
        case .single(let result):
            return Self.base(kind: .single, surface: surface, scan: result)
        case .multi(let result):
            return Self.base(kind: .multi, surface: surface, scan: result)
        case .authSuccess(let success):
            var d = Self.base(kind: .authSuccess, surface: surface, scan: success.scan)
            d["auth"] = Self.authSuccessDictionary(success)
            return d
        case .authFailure(let failure):
            var d = Self.base(kind: .authFailure, surface: surface, scan: failure.scan)
            d["auth"] = Self.authFailureDictionary(failure)
            return d
        }
    }

    private static func base(
        kind: RatifyeScanEventKind,
        surface: RatifyeScanSurface,
        scan: RatifyeScanResult
    ) -> [String: Any] {
        [
            "kind": kind.rawValue,
            "surface": surface.rawValue,
            "payload": scan.payload,
            "symbologyRaw": scan.symbologyRaw,
            "scan": scan.toDictionary()
        ]
    }

    private static func authSuccessDictionary(_ success: RatifyeAuthScanSuccess) -> [String: Any] {
        var auth: [String: Any] = [
            "httpStatus": success.httpStatus,
            "success": true
        ]
        if let body = success.responseBodyString {
            auth["responseBody"] = body
        }
        if let json = success.responseJSONObject() {
            auth["responseJSON"] = RatifyeJSONBridge.sanitize(json)
        }
        return auth
    }

    private static func authFailureDictionary(_ failure: RatifyeAuthScanFailure) -> [String: Any] {
        var auth: [String: Any] = [
            "success": false,
            "errorCode": RatifyeIngestErrorBridge.code(for: failure.error),
            "errorMessage": failure.error.localizedDescription
        ]
        if let status = failure.httpStatus {
            auth["httpStatus"] = status
        }
        if let body = failure.responseBodyString {
            auth["responseBody"] = body
        }
        if let json = failure.responseJSONObject() {
            auth["responseJSON"] = RatifyeJSONBridge.sanitize(json)
        }
        return auth
    }
}

extension RatifyeScanResult {
    public func toDictionary() -> [String: Any] {
        ["payload": payload, "symbologyRaw": symbologyRaw]
    }
}

enum RatifyeJSONBridge {
    static func object(from data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    static func sanitize(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { sanitize($0) }
        case let dict as NSDictionary:
            var out: [String: Any] = [:]
            for (k, v) in dict {
                if let key = k as? String {
                    out[key] = sanitize(v)
                }
            }
            return out
        case let array as [Any]:
            return array.map { sanitize($0) }
        case let array as NSArray:
            return array.map { sanitize($0) }
        case is String, is NSNumber, is Bool, is Int, is Double, is Float:
            return value
        case is NSNull:
            return NSNull()
        default:
            return String(describing: value)
        }
    }
}

enum RatifyeIngestErrorBridge {
    static func code(for error: Error) -> String {
        if let ingest = error as? RatifyeIngestError {
            switch ingest {
            case .missingURL: return "missing_url"
            case .invalidResponse: return "invalid_response"
            case .httpStatus(let code, _): return "http_\(code)"
            }
        }
        return (error as NSError).domain + "_" + String((error as NSError).code)
    }

    static func httpStatus(from error: Error) -> Int? {
        guard case .httpStatus(let code, _) = error as? RatifyeIngestError else { return nil }
        return code
    }

    static func responseData(from error: Error) -> Data? {
        guard case .httpStatus(_, let data) = error as? RatifyeIngestError else { return nil }
        return data
    }
}

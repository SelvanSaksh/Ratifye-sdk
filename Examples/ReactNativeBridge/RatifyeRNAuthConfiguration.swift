import Foundation
import RatifyeSDK

enum RatifyeRNAuthConfiguration {
    static func authFeature(
        authScanEnabled: Bool,
        ingestURL: NSString?,
        bearerToken: NSString?,
        apiKey: NSString?,
        companyId: NSString?,
        ingestFormat: NSString?,
        extraHTTPHeaders: NSDictionary?
    ) -> RatifyeAuthFeatureConfiguration {
        var headers: [String: String] = [:]
        if let extraHTTPHeaders {
            for (k, v) in extraHTTPHeaders {
                if let key = k as? String, let value = v as? String {
                    headers[key] = value
                }
            }
        }

        let format: RatifyeAuthIngestFormat
        switch (ingestFormat as String?)?.lowercased() {
        case "legacy":
            format = .legacy
        case "authbc", "auth_bc":
            format = .authBc
        default:
            format = .authBc
        }

        var authConfiguration: RatifyeAuthConfiguration?
        if let urlString = ingestURL as String?, !urlString.isEmpty, let url = URL(string: urlString) {
            let cid = (companyId as String?).flatMap { $0.isEmpty ? nil : $0 }
            authConfiguration = RatifyeAuthConfiguration(
                bearerToken: bearerToken as String?,
                apiKey: apiKey as String?,
                ingestURL: url,
                extraHTTPHeaders: headers,
                ingestFormat: format,
                companyId: cid
            )
        }

        return RatifyeAuthFeatureConfiguration(
            authScanEnabled: authScanEnabled,
            authConfiguration: authConfiguration
        )
    }
}

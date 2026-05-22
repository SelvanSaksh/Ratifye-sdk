import Foundation
import RatifyeSDK

enum RatifyeRNAuthConfiguration {
    static func authFeature(
        authScanEnabled: Bool,
        ingestURL: NSString?,
        bearerToken: NSString?,
        apiKey: NSString?,
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

        var authConfiguration: RatifyeAuthConfiguration?
        if let urlString = ingestURL as String?, let url = URL(string: urlString) {
            authConfiguration = RatifyeAuthConfiguration(
                bearerToken: bearerToken as String?,
                apiKey: apiKey as String?,
                ingestURL: url,
                extraHTTPHeaders: headers
            )
        }

        return RatifyeAuthFeatureConfiguration(
            authScanEnabled: authScanEnabled,
            authConfiguration: authConfiguration
        )
    }
}

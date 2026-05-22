import Foundation
import RatifyeSDK

enum RatifyeRNAuthConfiguration {
    static func authFeature(authScanEnabled: Bool) -> RatifyeAuthFeatureConfiguration {
        .withAuthEnabled(authScanEnabled)
    }
}

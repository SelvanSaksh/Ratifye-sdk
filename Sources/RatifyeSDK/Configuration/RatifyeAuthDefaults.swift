import Foundation

/// Built-in auth API endpoint and defaults (not configured by the host app).
public enum RatifyeAuthDefaults {
    public static let ingestURL = URL(string: "https://dlhub.8aiku.com/scan/auth-bc")!
    public static let companyId = "0"
}

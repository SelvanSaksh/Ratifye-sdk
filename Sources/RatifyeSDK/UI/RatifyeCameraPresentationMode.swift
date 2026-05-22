import Foundation

/// Controls whether camera UI dismisses itself (modal) or only reports events (embedded in a page).
public enum RatifyeCameraPresentationMode: Sendable {
    case modal
    case embedded
}

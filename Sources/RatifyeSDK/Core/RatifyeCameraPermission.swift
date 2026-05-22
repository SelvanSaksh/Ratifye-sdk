import AVFoundation

enum RatifyeCameraPermission {
    static func requestVideoAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { completion(true) }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            DispatchQueue.main.async { completion(false) }
        }
    }
}

public enum RatifyeCameraPermissionError: Error, LocalizedError {
    case denied

    public var errorDescription: String? {
        "Camera access was denied. Enable Camera in Settings."
    }
}

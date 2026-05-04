# RatifyeSDK

Swift package for iOS barcode scanning: **single scan**, **multi scan**, and **authenticated single scan** (POST to your backend with bearer token or API key). Use it from pure Swift, SwiftUI, UIKit, or embed the UIKit view controllers in a **React Native** native module.

- **Minimum iOS:** 15.0  
- **Distribution:** Swift Package Manager (public Git repository)

## Add the package (Swift / Xcode)

1. In Xcode: **File → Add Package Dependencies…**
2. Enter your public Git URL, for example: `https://github.com/YOUR_ORG/Ratifye-sdk.git`
3. Choose the `RatifyeSDK` product and add it to your app target.

Or in another `Package.swift`:

```swift
.package(url: "https://github.com/YOUR_ORG/Ratifye-sdk.git", from: "1.0.0")
```

## Info.plist

Add camera usage text:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan barcodes.</string>
```

## Swift (UIKit)

```swift
import RatifyeSDK

final class MyCoordinator: RatifyeSingleScanViewControllerDelegate {
    func presentScan(from host: UIViewController) {
        let vc = RatifyeSingleScanViewController()
        vc.scanDelegate = self
        vc.modalPresentationStyle = .fullScreen
        host.present(vc, animated: true)
    }

    func ratifyeSingleScan(_ controller: RatifyeSingleScanViewController, didFinishWith result: RatifyeScanResult) {
        print(result.payload, result.symbologyRaw)
    }

    func ratifyeSingleScanDidCancel(_ controller: RatifyeSingleScanViewController) {}
}
```

### Multi scan

Use `RatifyeMultiScanViewController` and `RatifyeMultiScanViewControllerDelegate`. Each new payload is reported on the main thread (repeats of the same value are throttled by the engine’s `multiRescanCooldown`).

### Authenticated single scan

Point `ingestURL` at your API. The SDK sends `POST` JSON:

```json
{ "payload": "<string>", "symbologyRaw": "<Vision symbology string>" }
```

Headers:

- `Authorization: Bearer <token>` if `bearerToken` is set  
- `X-API-Key: <key>` if `apiKey` is set  
- Any `extraHTTPHeaders` you provide  

```swift
let cfg = RatifyeAuthConfiguration(
    bearerToken: token,
    ingestURL: URL(string: "https://api.example.com/v1/scans")!
)
let vc = RatifyeAuthScanViewController(configuration: cfg)
vc.scanDelegate = self
```

## Publish for public access

1. Create a **public** GitHub (or GitLab) repository, for example `Ratifye-sdk`.
2. Push this folder as the repo root (include `Package.swift` and `Sources/`).
3. Tag a semantic version that matches `Package.swift` / consumers, for example:

   ```bash
   git tag 1.0.0
   git push origin 1.0.0
   ```

4. In Xcode or SPM, depend on the **tagged revision**, not an unversioned branch, for stable builds.

Optional: add a **Release** on GitHub with release notes for each tag.

## React Native integration

React Native does not consume Swift packages directly. You add the SDK to the **iOS app** that hosts RN, then bridge from JavaScript to native code.

### 1. Add RatifyeSDK to the iOS host

- Open `ios/YourApp.xcworkspace` (or `.xcodeproj`).
- **File → Add Package Dependencies…** → your `Ratifye-sdk` URL.
- Add the `RatifyeSDK` product to the **app** target (the one that builds `YourApp`).

### 2. Expo

If you use Expo: create a **config plugin** or use a **development build** (EAS) so you can edit the native `Podfile` / Xcode project and add the SPM dependency. Managed Expo without custom native code cannot load this SDK until you eject or use a dev client.

### 3. Native module

Copy `Examples/ReactNativeBridge/RatifyeScanModule.swift` and `RatifyeScanModule.m` into your iOS app target. Add both files to the target, ensure **Swift** sees `import React`, and that the bridging header (if any) does not conflict.

The module exposes:

```ts
import { NativeModules } from 'react-native';
const { RatifyeScan } = NativeModules;

const result = await RatifyeScan.scan();
// result: { payload: string; symbologyRaw: string }
```

Use the same pattern for **multi scan** (`RCTEventEmitter` + `RatifyeMultiScanViewController`) or **auth scan** (construct `RatifyeAuthScanViewController` with `RatifyeAuthConfiguration` built from JS arguments).

### 4. Autolinking

After adding files, run `pod install` from `ios/` if your project uses CocoaPods. SPM libraries linked to the app target are built with the app; no extra Pod is required for RatifyeSDK itself.

---

For questions or changes, open an issue on your public repository.

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

## Two camera surfaces (page-embedded)

| Surface | Swift type | Modes |
|--------|------------|--------|
| **Single camera** | `RatifyeSingleScanCameraView` | Plain single scan and/or authenticated ingest (enable via `RatifyeScanFeatureConfiguration`) |
| **Multi camera** | `RatifyeMultiScanCameraView` | Continuous multi scan (`multiScanEnabled`) |

Embedded views **do not** present modals or dismiss your screen. They emit `RatifyeScanEventPayload` so your app can show sheets/popups.

### Feature flags (single camera)

```swift
cameraView.featureConfiguration = RatifyeScanFeatureConfiguration(
    singleScanEnabled: true,
    authScanEnabled: true,
    authConfiguration: RatifyeAuthConfiguration(
        bearerToken: session.accessToken,
        ingestURL: URL(string: appConfig.scanAuthURL)!,
        companyId: session.companyId,
        ingestFormat: .authBc
    )
)
```

Auth ingest runs only when `authScanEnabled`, `ingestURL`, and (for `auth_bc`) `companyId` are all provided by your app. The SDK does not embed API URLs.

### Event payload (auth + parsing)

All flows use `RatifyeScanEventPayload.toDictionary()`:

- `kind`: `single` | `auth_success` | `auth_failure` | `multi`
- `surface`: `single` | `multi` (which camera emitted the event)
- `payload`, `symbologyRaw`, `scan`
- `auth` (authenticated flows): `httpStatus`, `responseBody`, `responseJSON` (parsed when valid JSON), `errorCode`, `errorMessage` on failure

Authenticated ingest (`ingestFormat: auth_bc`) — body built from the scan + app-supplied `companyId`:

```json
[
  {
    "encrypted_text": "<extracted from (98)…(97) in barcode, or full payload>",
    "barcode_data": "<full scanned string>",
    "company_id": "<from app>"
  }
]
```

`ingestURL` must be the full URL from your environment or backend config.

Legacy format (`ingestFormat: legacy`): `{ "payload", "symbologyRaw" }`.

Headers: `Content-Type: application/json`, `Accept: application/json, text/plain, */*`, optional `Authorization` / `X-API-Key`, plus `extraHTTPHeaders`.

### Swift (UIKit page)

```swift
let camera = RatifyeSingleScanCameraView(frame: container.bounds)
camera.presentationMode = .embedded
camera.featureConfiguration = RatifyeScanFeatureConfiguration(singleScanEnabled: true)
camera.delegate = self
container.addSubview(camera)
```

### Swift (modal, optional)

```swift
let vc = RatifyeSingleScanViewController()
vc.presentationMode = .modal
vc.featureConfiguration = ...
vc.scanDelegate = self
host.present(vc, animated: true)
```

### Multi scan

`RatifyeMultiScanCameraView` with `RatifyeMultiScanFeatureConfiguration(multiScanEnabled: true, authScanEnabled: ..., authConfiguration: ...)`. Same auth ingest and `auth_success` / `auth_failure` events as single. Plain multi emits `kind: multi` when auth is off. Duplicate payloads are throttled by `multiRescanCooldown` on the engine.

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

### 3. Native views (page-embedded, not modal scanner)

Copy into your iOS app target:

- `RatifyeSingleScanNativeView.swift` + `RatifyeSingleScanNativeView.m`
- `RatifyeMultiScanNativeView.swift` + `RatifyeMultiScanNativeView.m`
- `RatifyeRNAuthConfiguration.swift`
- `RatifyeScanner.tsx` (into your JS app)

**Single camera props:** `singleScanEnabled`, `authScanEnabled`, `ingestURL`, `companyId`, `ingestFormat`, `bearerToken`, `apiKey`, `extraHTTPHeaders`

**Multi camera props:** `multiScanEnabled`, `authScanEnabled`, `ingestURL`, `companyId`, `ingestFormat`, `bearerToken`, `apiKey`, `extraHTTPHeaders` (same auth API as single)

**Event:** `onScanEvent` → same shape as `RatifyeScanEventPayload` (`kind`, `payload`, `symbologyRaw`, `auth.responseJSON`, etc.)

```tsx
import Config from 'react-native-config'; // or your env / API layer
import { RatifyeSingleScanCamera } from './RatifyeScanner';

<RatifyeSingleScanCamera
  style={{ flex: 1 }}
  singleScanEnabled={!useAuth}
  authScanEnabled={useAuth}
  ingestURL={Config.SCAN_AUTH_URL}
  companyId={session.companyId}
  ingestFormat="auth_bc"
  bearerToken={session.accessToken}
  onScanEvent={(event) => {
    if (event.kind === 'auth_success' || event.kind === 'single') {
      setSheetVisible(true);
    }
  }}
/>
```

Never hardcode production API URLs in the SDK or sample components — pass them from your app at runtime.

Show results in **your** `Modal` / bottom sheet — the SDK camera stays on the page.

### 4. Autolinking

After adding files, run `pod install` from `ios/` if your project uses CocoaPods. SPM libraries linked to the app target are built with the app; no extra Pod is required for RatifyeSDK itself.

---

For questions or changes, open an issue on your public repository.

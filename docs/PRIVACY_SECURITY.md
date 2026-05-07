# Privacy & Security: HereAlready

---

## 1. Location Data

### What is collected
- The device's current GPS coordinates, updated every 20 metres while monitoring is active.

### What is NOT collected
- No location history is stored persistently beyond the current trip session.
- No location data is transmitted to any server.
- No user account or identity is associated with location data.

### Retention
- `LocationManager.lastKnownLocation` is an in-memory `@Published` property. It is discarded when the app is terminated.
- Active trip destination and threshold are written to `UserDefaults` only to survive app restarts mid-trip, and are cleared when the trip is stopped.

---

## 2. Required Permissions

| Permission | When Requested | Why |
|------------|----------------|-----|
| Location (When In Use) | App first launch | To display user position on map and enable foreground monitoring |
| Location (Always) | When user starts a trip | To enable background monitoring so alerts fire when the app is backgrounded |
| Notifications | When user starts their first trip | To deliver the arrival alert |

### Permission Denial Handling
- If "When In Use" is denied: show a prompt explaining the feature is non-functional without location access, with a link to Settings.
- If "Always" is denied: inform the user that background alerts will not work. The app can still alert when foregrounded.
- If Notifications are denied: fall back to an in-app visual/haptic alert. Notify the user that the notification alert is disabled.

---

## 3. API Keys

### Current State (Known Issue)
The Google Maps API key is hardcoded in `AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("AIzaSyBcrU0CMylaErlcxN2bT29GlRVSJePDHhY")
```
**This is a security risk.** The key is embedded in the app binary and visible via static analysis.

### Required Action Before Release
- Restrict the API key in Google Cloud Console to:
  - iOS app bundle ID: `com.curtischang.HereAlready` (verify exact bundle ID)
  - Only the APIs in use: Maps SDK for iOS, Places API
- Move the key to a `.xcconfig` file excluded from version control, injected at build time via a build setting.
- Do not commit the key to git.

---

## 4. Data Minimisation

- The app does not log coordinates to persistent storage or analytics.
- No crash reporting SDK (e.g. Firebase Crashlytics) is currently included. If added in future, ensure it is configured to not capture location data in crash reports.

---

## 5. App Transport Security

- All network calls (Google Places API) must use HTTPS. ATS is enabled by default on iOS and should not be weakened.

---

## 6. Third-Party SDKs

| SDK | Data Access | Privacy Policy |
|-----|-------------|----------------|
| Google Maps iOS SDK | Map tiles fetched from Google servers; user IP visible to Google | Google Privacy Policy |
| Google Places API | Search queries sent to Google | Google Privacy Policy |

Users should be informed of Google's data practices via the app's Privacy Policy before using the search feature.

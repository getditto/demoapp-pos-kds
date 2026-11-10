# Testing and native previews

## Running tests

Run the native test commands from the repository root. Platform build/setup
instructions remain in [iOS](../iOS/README.md) and [Android](../Android/README.md).

```sh
xcodebuild test -project iOS/DittoPOS.xcodeproj -scheme DittoPOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath build/tests CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
  DITTO_ENV_FILE="$PWD/.ci/build.env"

DITTO_ENV_FILE="$PWD/.ci/build.env" Android/gradlew -p Android \
  :app:testDebugUnitTest

# With an Android emulator already running; replace the serial with yours.
ANDROID_SERIAL=emulator-5554 DITTO_ENV_FILE="$PWD/.ci/build.env" \
  Android/gradlew -p Android :app:connectedDebugAndroidTest
```

iOS needs Xcode with an installed arm64 iOS Simulator; adjust the destination
to match your machine. Android needs JDK 17 and Android SDK Platform 37.

Tests that exercise storage and observers use the real Ditto SDK with isolated,
disposable offline stores, following [Ditto's testing guidance](https://docs.ditto.live/sdk/latest/deployment/testing).
These stores use no encryption/private key or license token and never start sync.
Simulate peer-originated changes with sequenced DQL writes to the local test store.
Real peer convergence and file transfer have separate manual acceptance checks.

The iOS `DittoPOSTests` bundle compiles production logic directly and uses the
small `AppUIHost` for native SwiftUI lifecycle checks, without the demo app or
its `.env`. `AppUIPresentationTests` uses XCUITest with the same host to exercise
the real theme, shell and Settings presentation. The host's startup has no Ditto
SDK, repositories or demo startup; offline stores are opened only by tests.
Android uses JVM logic
tests and emulator-based repository/UI tests whose runner substitutes a plain
`Application`, bypassing the demo's Hilt startup, seeding and sync. Both platforms
load the same independently authored order JSON from `Tests/Fixtures` for store
tests. `.ci/build.env` supplies unusable compiler constants for native app builds;
it never initializes a test store. The automated test commands above never launch the real demo apps and need no Ditto
authentication or app-store signing credentials. Add production logic to the
standalone target's Sources phase when extending its coverage; do not copy it.

Local and CI check builds use build number **9999**. Actual release builds
can supply `CURRENT_PROJECT_VERSION=<number>` to `xcodebuild` or
`-PdittoBuildNumber=<number>` to Gradle. These inputs do not change the
marketing version or allocate a shipping number.

## Native UI libraries

`iOS/AppUI` is a local Swift package; `Android/app-ui` is a Compose library.
They own semantic styling, shared presentation components and bundled brand
resources, with no Ditto, navigation or app-state dependencies. App code supplies
values, bindings, callbacks and content. Package publication is separate work.

Open `ComponentCatalog.swift` in Xcode Canvas or `ComponentCatalog.kt` in Android
Studio Preview to inspect the actual shared controls in light/dark and large text.
The app-owned `SettingsContent` / `SettingsScreen` compose these foundations;
previews and the isolated UI hosts are developer resources, not app destinations.

The component catalogs also preview shared photo containers and placeholders.
The app-owned `ProductPhotoView` / `ProductPhoto` load optional Ditto attachments,
cancel loading when hidden and reuse a bounded decoded-image cache. Offline tests
cover photo replacement, removal, delayed file availability and crop/export logic,
including shared cases from `Tests/Fixtures/photo-crops.json`.

## Manual DQL scripts

Scripts in [`Scripts/`](../Scripts) exercise insert/observer paths for metric testing. Each
script's header documents its purpose and inputs.

To run a script you'll need:

1. A [Cloud URL endpoint](https://docs.ditto.live/cloud/http-api/getting-started#cloud-url-endpoint).
2. An [HTTP API key](https://docs.ditto.live/cloud/http-api/auth-and-params#api-key).

Available:

- `INSERT_Orders` — inserts generic orders on a configurable interval.

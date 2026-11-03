#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
output="$repo_root/build/ci/ios"
mkdir -p "$output"
run=$(mktemp -d "$output/run-XXXXXX")
derived_data="$repo_root/build/ci/DerivedData"

xcodebuild -version
xcodebuild test \
  -project "$repo_root/iOS/DittoPOS.xcodeproj" \
  -scheme DittoPOS \
  -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}" \
  -derivedDataPath "$derived_data" \
  -resultBundlePath "$run/Tests.xcresult" \
  -disableAutomaticPackageResolution \
  -onlyUsePackageVersionsFromResolvedFile \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
  DITTO_ENV_FILE="$repo_root/.ci/test.env" \
  2>&1 | tee "$run/xcodebuild.log"

xcrun xcresulttool get test-results summary --path "$run/Tests.xcresult" > "$run/test-summary.json"
python3 "$repo_root/Scripts/ci/verify-test-results.py" ios "$run/test-summary.json"

cp "$derived_data/Build/Products/Debug-iphonesimulator/DittoPOS.app/Info.plist" "$run/app-info.plist"
python3 - "$run/app-info.plist" <<'PY'
import plistlib
import sys

with open(sys.argv[1], "rb") as file:
    info = plistlib.load(file)
if info["CFBundleVersion"] != "9999":
    sys.exit(f"Expected test build 9999, got {info['CFBundleVersion']}")
print(f"iOS app: {info['CFBundleShortVersionString']} ({info['CFBundleVersion']})")
PY

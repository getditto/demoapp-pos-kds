#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
output="$repo_root/build/ci/android"
mkdir -p "$output"
run=$(mktemp -d "$output/run-XXXXXX")
cd "$repo_root/Android"
export DITTO_ENV_FILE="$repo_root/.ci/test.env"

./gradlew --version
./gradlew --no-daemon --console=plain \
  :app:cleanTestDebugUnitTest :ditto-wrapper:cleanTestDebugUnitTest \
  :app:assembleDebug :app:testDebugUnitTest :ditto-wrapper:testDebugUnitTest \
  -PdittoBuildNumber=9999 2>&1 | tee "$run/gradle.log"

python3 "$repo_root/Scripts/ci/verify-test-results.py" android "$repo_root/Android"
cp app/build/outputs/apk/debug/output-metadata.json "$run/app-metadata.json"
python3 - "$run/app-metadata.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as file:
    elements = json.load(file)["elements"]
if not elements or any(item["versionCode"] != 9999 for item in elements):
    sys.exit("Expected test build 9999 in every debug APK")
for item in elements:
    print(f"Android APK: {item['versionName']} ({item['versionCode']})")
PY

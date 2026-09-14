#!/bin/zsh

set -euo pipefail

for dependency in xcodebuild xcrun grep sed head mktemp rm cat; do
  command -v "$dependency" >/dev/null || {
    print -u2 "Brak wymaganego narzędzia: $dependency"
    exit 1
  }
done

repo_root="${0:A:h:h}"
derived_data="$(mktemp -d /private/tmp/cipherpath-tests.XXXXXX)"
test_log="$derived_data/xcodebuild-test.log"
trap 'rm -rf -- "$derived_data"' EXIT

preferred_name="CipherPath — iPhone 17"
devices="$(xcrun simctl list devices available)"

preferred_line="$(print -r -- "$devices" | grep -F "$preferred_name (" | head -n 1 || true)"
booted_line="$(print -r -- "$devices" | grep -E 'iPhone.*\([0-9A-Fa-f-]{36}\) \(Booted\)' | head -n 1 || true)"
first_iphone_line="$(print -r -- "$devices" | grep -E 'iPhone.*\([0-9A-Fa-f-]{36}\)' | head -n 1 || true)"

extract_udid() {
  print -r -- "$1" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/'
}

if [[ -n "$preferred_line" ]]; then
  destination="platform=iOS Simulator,id=$(extract_udid "$preferred_line")"
elif [[ -n "$booted_line" ]]; then
  destination="platform=iOS Simulator,id=$(extract_udid "$booted_line")"
elif [[ -n "$first_iphone_line" ]]; then
  destination="platform=iOS Simulator,id=$(extract_udid "$first_iphone_line")"
else
  print -u2 "Brak dostępnego iPhone Simulatora. Sprawdź: xcrun simctl list devices available"
  exit 1
fi

print "Test destination: $destination"

run_tests() {
  xcodebuild \
    -project "$repo_root/CipherPath.xcodeproj" \
    -scheme "CipherPath Dev" \
    -configuration Debug \
    -destination "$destination" \
    -derivedDataPath "$derived_data" \
    "$@" \
    test
}

if run_tests >"$test_log" 2>&1; then
  grep -E '\*\* TEST SUCCEEDED \*\*' "$test_log" || {
    cat "$test_log"
    print -u2 "xcodebuild zakończył się bez błędu, ale brak potwierdzenia TEST SUCCEEDED"
    exit 1
  }
elif grep -q "swift-plugin-server.*produced malformed response" "$test_log"; then
  cat "$test_log"
  print -u2 "Uwaga: ponawiam testy z -disable-sandbox z powodu błędu Xcode beta."
  run_tests OTHER_SWIFT_FLAGS=-disable-sandbox >"$test_log" 2>&1
  grep -E '\*\* TEST SUCCEEDED \*\*' "$test_log" || {
    cat "$test_log"
    exit 1
  }
else
  cat "$test_log"
  exit 1
fi

print "Testy jednostkowe: OK"

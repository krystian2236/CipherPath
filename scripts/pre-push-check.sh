#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h:h}"
cd "$repo_root"

unit_log="$(mktemp /private/tmp/cipherpath-unit.XXXXXX)"
check_log="$(mktemp /private/tmp/cipherpath-pre-push.XXXXXX)"
trap 'rm -f -- "$unit_log" "$check_log"' EXIT

for dependency in git zsh mktemp grep sed rm cat; do
  command -v "$dependency" >/dev/null || {
    print -u2 "Brak wymaganego narzędzia: $dependency"
    exit 1
  }
done

[[ "$(git rev-parse --show-toplevel)" == "$repo_root" ]] || {
  print -u2 "Skrypt uruchomiono poza repozytorium CipherPath"
  exit 1
}

print "=== Stan Git ==="
git status --short --branch

print "\n=== Poprawność diffu ==="
git diff --check
git diff --cached --check
print "Diff: OK"

print "\n=== Kontrola nazw plików w Git ==="
suspicious_pattern='(^|/)(\.env($|\.)|id_(rsa|dsa|ecdsa|ed25519)(\.|$)|.*\.(pem|p12|pfx|key)$)'
if git ls-files | grep -E "$suspicious_pattern" >/dev/null; then
  print -u2 "Wykryto potencjalny sekret lub klucz w śledzonych plikach:"
  git ls-files | grep -E "$suspicious_pattern" | sed 's/^/  - /'
  exit 1
fi
print "Nazwy plików: OK"

print "\n=== Testy jednostkowe ==="
if zsh "$repo_root/scripts/test-unit.sh" >"$unit_log" 2>&1; then
  grep -E 'Test destination:|\*\* TEST SUCCEEDED \*\*|Testy jednostkowe: OK' "$unit_log"
else
  cat "$unit_log"
  exit 1
fi

print "\n=== Integralność projektu ==="
if "$repo_root/scripts/test-project-integrity.sh" >"$check_log" 2>&1; then
  grep -E '\*\* BUILD SUCCEEDED \*\*|Wersja bundle:|Integralność bundle: OK' "$check_log"
else
  cat "$check_log"
  exit 1
fi

print "\nKontrola przed push: OK"

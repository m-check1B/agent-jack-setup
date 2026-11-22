#!/bin/bash
# agent-jack-setup DOCTOR (macOS): retired (KRA-10893). The Agent Jack doctor in the public onboarding repo checks,
# installs and repairs a Mac in one run; `--check` there changes nothing. This file keeps only the maintainers'
# versions.env selftest (bin/doctor.sh --selftest: every line parses, checksums and commits are well-formed,
# every pinned URL, asset and tag answers). Windows: bin/doctor.ps1.
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$HERE/versions.env"
selftest() {
  local f=0 line k v url want got
  ok() { echo "PASS selftest $*"; }
  bad() { echo "FAIL selftest $*"; f=$((f+1)); }
  answers() { curl -fsIL --proto '=https' --max-time 30 -o /dev/null "$1"; }
  tagsha() { git ls-remote "$1.git" "refs/tags/$2" "refs/tags/$2^{}" 2>/dev/null | awk '{print $1}' | tail -1; }
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    if [[ "$line" =~ ^[A-Z0-9_]+=[^[:space:]]+$ || "$line" =~ ^[A-Z0-9_]+=\"[^\"]+\"$ ]]; then :; else bad "parse: $line"; fi
  done < "$HERE/versions.env"
  for k in $(grep -oE '^[A-Z0-9_]*SHA256[A-Z0-9_]*' "$HERE/versions.env"); do
    v="${!k}"; [ "$v" = TBD ] || [[ "$v" =~ ^[0-9a-f]{64}$ ]] && ok "checksum $k" || bad "checksum $k is not 64 lowercase hex or TBD"
    a="${k/SHA256/ASSET}"   # T3 asset/checksum pairs agree on TBD; Node has no asset key
    case "$k" in T3_*) { [ "${!a:-TBD}" = TBD ] && [ "$v" = TBD ]; } || { [ "${!a:-TBD}" != TBD ] && [ "$v" != TBD ]; } || bad "checksum $k and $a disagree on TBD" ;; esac
  done
  [[ "$TENTACLES_COMMIT" =~ ^[0-9a-f]{40}$ ]] && ok "commit TENTACLES_COMMIT" || bad "commit TENTACLES_COMMIT is not 40 hex"
  [[ "$GUARDIAN_COMMIT" =~ ^[0-9a-f]{40}$ ]] && ok "commit GUARDIAN_COMMIT" || bad "commit GUARDIAN_COMMIT is not 40 hex"
  # the Node pin is one unit: version and both Mac checksums together, or the doctor cannot install Node (P2-2)
  [[ "${NODE_VERSION:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && ok "node NODE_VERSION" || bad "node NODE_VERSION missing or not x.y.z (AJ-PIN-01)"
  for k in NODE_SHA256_MAC_ARM64 NODE_SHA256_MAC_X64; do [[ "${!k:-}" =~ ^[0-9a-f]{64}$ ]] && ok "node $k" || bad "node $k missing or not 64 hex (AJ-PIN-01)"; done
  for url in "https://nodejs.org/dist/v${NODE_VERSION:-}/node-v${NODE_VERSION:-}-darwin-arm64.tar.gz" "https://nodejs.org/dist/v${NODE_VERSION:-}/node-v${NODE_VERSION:-}-darwin-x64.tar.gz" "$SETUP_REPO" "$T3_REPO" "$TENTACLES_REPO" "$GUARDIAN_REPO" \
    "https://registry.npmjs.org/@openai/codex/$CODEX_CLI_MIN" "https://registry.npmjs.org/@anthropic-ai/claude-code/$CLAUDE_CLI_MIN" \
    "https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/$(printf '%s' "${CLAUDE_WINGET_ID:0:1}" | tr '[:upper:]' '[:lower:]')/${CLAUDE_WINGET_ID//.//}/$CLAUDE_CLI_MIN/$CLAUDE_WINGET_ID.yaml"; do
    answers "$url" && ok "url $url" || bad "url $url does not answer"
  done
  for k in $(grep -oE '^T3_ASSET_[A-Z0-9_]+' "$HERE/versions.env"); do
    [ "${!k}" = TBD ] && { echo "SKIP selftest asset $k not published yet (AJ-PIN-00)"; continue; }
    url="$T3_REPO/releases/download/$T3_TAG/${!k}"; answers "$url" && ok "asset $url" || bad "asset $url does not answer"
  done
  [ -n "$(tagsha "$T3_REPO" "$T3_TAG")" ] && ok "tag $T3_TAG on $T3_REPO" || bad "tag $T3_TAG missing on $T3_REPO"
  got="$(tagsha "$TENTACLES_REPO" "$TENTACLES_TAG")"; [ "$got" = "$TENTACLES_COMMIT" ] && ok "tag $TENTACLES_TAG = $TENTACLES_COMMIT" || bad "tag $TENTACLES_TAG = ${got:-missing}, want $TENTACLES_COMMIT"
  got="$(tagsha "$GUARDIAN_REPO" "$GUARDIAN_TAG")"; want="$GUARDIAN_COMMIT"; [ -n "$got" ] && [ "${got:0:${#want}}" = "$want" ] && ok "tag $GUARDIAN_TAG = $want" || bad "tag $GUARDIAN_TAG = ${got:-missing}, want $want"
  echo "selftest fails: $f"
  [ $f -eq 0 ]
}
[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }
echo "bin/doctor.sh is retired on macOS. Run the Agent Jack doctor instead (add --check to change nothing):"
echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)"'
exit 3

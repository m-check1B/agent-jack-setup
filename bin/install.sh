#!/bin/bash
# agent-jack-setup INSTALL (macOS). Idempotent: brings each component to the exact pin in versions.env.
# Usage: bin/install.sh <claude|codex|t3|tentacles|classify|guardian|all>   (all = claude codex t3 tentacles classify; guardian = optional 5-min guard checkout)
# Functions are do_<component> so they never shadow the real commands (v1.0.0 recursed on `tentacles`).
# Never uses sudo; never touches secrets; downloads only from the public URLs in versions.env.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$HERE/versions.env"
DEV="$HOME/Developer"
die() { echo "FAIL $1: $2" >&2; exit 1; }
need_pin() { [ "$1" != TBD ] || die AJ-PIN-00 "pin $2 not published yet (versions.env)"; }
ver() { "$@" 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[-A-Za-z0-9.]*' | head -1; }

do_claude() {
  command -v npm >/dev/null || die AJ-NODE-01 "node/npm missing (brew install node)"
  cur="$(ver claude --version || true)"
  if [ -n "$cur" ] && [ "$(printf '%s\n%s\n' "$CLAUDE_CLI_MIN" "$cur" | sort -V | head -1)" = "$CLAUDE_CLI_MIN" ]; then echo "ok claude-cli $cur (>= $CLAUDE_CLI_MIN)"; return; fi
  npm install -g "@anthropic-ai/claude-code@$CLAUDE_CLI_MIN" || die AJ-CLAUDE-01 "npm install failed (EACCES: see REPAIR.md AJ-NPM-01)"
  echo "ok claude-cli $CLAUDE_CLI_MIN (sign in yourself: claude auth login)"
}

do_codex() {
  command -v npm >/dev/null || die AJ-NODE-01 "node/npm missing (brew install node)"
  cur="$(ver codex --version || true)"
  if [ -n "$cur" ] && [ "$(printf '%s\n%s\n' "$CODEX_CLI_MIN" "$cur" | sort -V | head -1)" = "$CODEX_CLI_MIN" ]; then echo "ok codex-cli $cur (>= $CODEX_CLI_MIN)"; return; fi
  npm install -g "@openai/codex@$CODEX_CLI_MIN" || die AJ-CODEX-01 "npm install failed (EACCES: see REPAIR.md AJ-NPM-01)"
  echo "ok codex-cli $CODEX_CLI_MIN (sign in yourself: codex login)"
}

do_t3() {
  need_pin "$T3_TAG" T3_TAG
  local app dest cur arch asset sum   # tmp + mnt stay global so the EXIT trap can clean them up
  # same order as doctor: an existing copy in /Applications wins, then ~/Applications, then /Applications if writable
  dest=/Applications
  [ ! -d "/Applications/$T3_APP_NAME.app" ] && [ -d "$HOME/Applications/$T3_APP_NAME.app" ] && dest="$HOME/Applications"
  [ -w "$dest" ] || { mkdir -p "$HOME/Applications"; dest="$HOME/Applications"; }
  app="$dest/$T3_APP_NAME.app"
  cur="$(defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || true)"
  if [ "$cur" = "$T3_VERSION" ]; then echo "ok t3code $T3_VERSION"; return; fi
  arch="$(uname -m)"
  if [ "$arch" = arm64 ]; then asset="$T3_ASSET_MAC_ARM64"; sum="$T3_SHA256_MAC_ARM64"; else asset="$T3_ASSET_MAC_X64"; sum="$T3_SHA256_MAC_X64"; fi
  tmp="$(mktemp -d)"; mnt=""
  trap '[ -n "$mnt" ] && hdiutil detach -quiet "$mnt" 2>/dev/null; rm -rf "$tmp"' EXIT
  curl -fL --proto '=https' -o "$tmp/$asset" "$T3_REPO/releases/download/$T3_TAG/$asset" || die AJ-T3-03 "download failed"
  [ "$(shasum -a 256 "$tmp/$asset" | cut -d' ' -f1)" = "$sum" ] || die AJ-T3-04 "checksum mismatch, not installing"
  mnt="$(hdiutil attach -nobrowse -readonly "$tmp/$asset" 2>/dev/null | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
  [ -n "$mnt" ] && [ -d "$mnt/$T3_APP_NAME.app" ] || die AJ-T3-03 "could not open the downloaded dmg"
  osascript -e "quit app \"$T3_APP_NAME\"" >/dev/null 2>&1 || true
  cp -R "$mnt/$T3_APP_NAME.app" "$tmp/new.app" || die AJ-T3-03 "copy from the dmg failed"
  rm -rf "$app" && mv "$tmp/new.app" "$app" || die AJ-T3-03 "could not write $dest"
  echo "ok t3code $T3_VERSION in ${dest/#$HOME/~} (auto-update is off in this build; upgrades come only via agent-jack-setup)"
}

do_tentacles() {
  need_pin "$TENTACLES_TAG" TENTACLES_TAG
  mkdir -p "$DEV"
  [ -d "$DEV/t3-code-tentacles/.git" ] || git clone -q "$TENTACLES_REPO.git" "$DEV/t3-code-tentacles"
  git -C "$DEV/t3-code-tentacles" fetch -q --tags origin
  git -C "$DEV/t3-code-tentacles" -c advice.detachedHead=false checkout -q "$TENTACLES_TAG"
  echo "tentacles: npm install + link (can take several minutes)…"
  (cd "$DEV/t3-code-tentacles" && npm install --no-audit --no-fund --loglevel=error && npm link --loglevel=error) || die AJ-TENT-01 "npm install/link failed (EACCES: REPAIR.md AJ-NPM-01)"
  echo "ok tentacles $(ver command tentacles --version || echo '?') @ $TENTACLES_TAG"
}

do_classify() {
  need_pin "$GUARDIAN_TAG" GUARDIAN_TAG
  local py; py="$(command -v python3.12 || command -v python3.13 || command -v python3 || true)"
  [ -n "$py" ] && "$py" -c "import sys; mj,mn=map(int,'$PYTHON_MIN'.split('.')); sys.exit(0 if sys.version_info >= (mj,mn) else 1)" || die AJ-PY-01 "Python >= $PYTHON_MIN needed (brew install python@3.12)"
  [ -x "$CLASSIFY_VENV/bin/python" ] || "$py" -m venv "$CLASSIFY_VENV"
  "$CLASSIFY_VENV/bin/python" -m pip install -q --upgrade --force-reinstall "git+$GUARDIAN_REPO.git@$GUARDIAN_TAG" || die AJ-EC-01 "pip install of estate-classify failed"
  echo "ok estate-classify @ $GUARDIAN_TAG in ~/.agent-jack/venv"
}

do_guardian() {
  need_pin "$GUARDIAN_TAG" GUARDIAN_TAG
  mkdir -p "$DEV"
  [ -d "$DEV/estate-guardian/.git" ] || git clone -q "$GUARDIAN_REPO.git" "$DEV/estate-guardian"
  git -C "$DEV/estate-guardian" fetch -q --tags origin
  git -C "$DEV/estate-guardian" -c advice.detachedHead=false checkout -q "$GUARDIAN_TAG"
  echo "ok estate-guardian guard checkout @ $GUARDIAN_TAG (optional; its install.sh/launchd is NOT run; it needs your own estate config)"
}

free_gb=$(( $(df -k "$HOME" | awk 'NR==2{print $4}') / 1048576 ))
[ "$free_gb" -ge "$DISK_FAIL_GB" ] || die AJ-DISK-02 "only ${free_gb} GB free; need at least $DISK_FAIL_GB GB (recommended $DISK_WARN_GB GB). See REPAIR.md AJ-DISK-02"
case "${1:-}" in
  claude) do_claude ;; codex) do_codex ;; t3) do_t3 ;; tentacles) do_tentacles ;; classify) do_classify ;; guardian) do_guardian ;;
  all) do_claude; do_codex; do_t3; do_tentacles; do_classify ;;
  *) echo "usage: bin/install.sh <claude|codex|t3|tentacles|classify|guardian|all>"; exit 2 ;;
esac
echo "next: bin/doctor.sh"

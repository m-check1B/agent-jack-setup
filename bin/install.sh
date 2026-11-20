#!/bin/bash
# agent-jack-setup INSTALL (macOS). Idempotent: brings each component to the exact pin in versions.env.
# Usage: bin/install.sh <claude|codex|t3|tentacles|t3-token|classify|guardian|all>   (all = claude codex t3 tentacles classify [t3-token if T3 runs, non-fatal]; guardian = optional 5-min guard checkout)
# Functions are do_<component> so they never shadow the real commands (v1.0.0 recursed on `tentacles`).
# Never uses sudo; never touches secrets; downloads only from the public URLs in versions.env.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$HERE/versions.env"
DEV="$HOME/Developer"
TILDE='~'   # for "${path/#"$HOME"/$TILDE}": a literal ~ there is expanded by bash >= 4.3 and kept as \~ by 3.2
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

# a >= b in version order (sort -V)
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

# Older T3 Code apps (T3_LEGACY_APP_NAMES) share the data folder ~/.t3: once T3 Code (Beta) is in place,
# quit them and move them aside, never delete. A failed download or checksum leaves them working.
t3_move_older() {
  local name d older=()
  IFS='|' read -r -a older <<< "${T3_LEGACY_APP_NAMES:-}"
  for name in ${older[@]+"${older[@]}"}; do
    [ -n "$name" ] || continue
    for d in /Applications "$HOME/Applications"; do
      [ -d "$d/$name.app" ] || continue
      osascript -e "quit app \"$name\"" >/dev/null 2>&1 || true
      mkdir -p "$HOME/.agent-jack/replaced-apps"
      mv "$d/$name.app" "$HOME/.agent-jack/replaced-apps/$name-$(date +%Y%m%d%H%M%S).app" || die AJ-T3-07 "could not move the older T3 Code app $d/$name.app aside"
      echo "moved the older T3 Code app $name.app to ~/.agent-jack/replaced-apps (your threads in ~/.t3 are kept)"
    done
  done
}

do_t3() {
  need_pin "$T3_TAG" T3_TAG
  local app dest cur arch asset sum id   # tmp + mnt stay global so the EXIT trap can clean them up
  # same order as doctor: an existing copy in /Applications wins, then ~/Applications, then /Applications if writable
  dest=/Applications
  [ ! -d "/Applications/$T3_APP_NAME.app" ] && [ -d "$HOME/Applications/$T3_APP_NAME.app" ] && dest="$HOME/Applications"
  [ -w "$dest" ] || { mkdir -p "$HOME/Applications"; dest="$HOME/Applications"; }
  app="$dest/$T3_APP_NAME.app"
  cur="$(defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || true)"
  # T3 Code updates itself: the pinned release or anything newer is kept, never downgraded.
  if [ -n "$cur" ] && ver_ge "$cur" "$T3_VERSION"; then echo "ok t3code $cur (>= $T3_VERSION)"; t3_move_older; return; fi
  arch="$(uname -m)"
  if [ "$arch" = arm64 ]; then asset="$T3_ASSET_MAC_ARM64"; sum="$T3_SHA256_MAC_ARM64"; else asset="$T3_ASSET_MAC_X64"; sum="$T3_SHA256_MAC_X64"; fi
  tmp="$(mktemp -d)"; mnt=""
  trap '[ -n "$mnt" ] && hdiutil detach -quiet "$mnt" 2>/dev/null; rm -rf "$tmp"' EXIT
  curl -fL --proto '=https' -o "$tmp/$asset" "$T3_REPO/releases/download/$T3_TAG/$asset" || die AJ-T3-03 "download failed"
  [ "$(shasum -a 256 "$tmp/$asset" | cut -d' ' -f1)" = "$sum" ] || die AJ-T3-04 "checksum mismatch, not installing"
  mnt="$(hdiutil attach -nobrowse -readonly "$tmp/$asset" 2>/dev/null | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
  [ -n "$mnt" ] && [ -d "$mnt/$T3_APP_NAME.app" ] || die AJ-T3-03 "could not open the downloaded dmg"
  id="$(defaults read "$mnt/$T3_APP_NAME.app/Contents/Info" CFBundleIdentifier 2>/dev/null || true)"
  [ "$id" = "$T3_BUNDLE_ID" ] || die AJ-T3-08 "unexpected bundle id '$id' (want $T3_BUNDLE_ID), not installing"
  osascript -e "quit app \"$T3_APP_NAME\"" >/dev/null 2>&1 || true
  cp -R "$mnt/$T3_APP_NAME.app" "$tmp/new.app" || die AJ-T3-03 "copy from the dmg failed"
  rm -rf "$app" && mv "$tmp/new.app" "$app" || die AJ-T3-03 "could not write $dest"
  echo "ok t3code $T3_VERSION in ${dest/#"$HOME"/$TILDE} (official T3 Code (Beta); it updates itself, doctor checks the supported range)"
  t3_move_older
}

do_tentacles() {
  need_pin "$TENTACLES_TAG" TENTACLES_TAG
  mkdir -p "$DEV"
  [ -d "$DEV/t3-code-tentacles/.git" ] || git clone -q "$TENTACLES_REPO.git" "$DEV/t3-code-tentacles"
  git -C "$DEV/t3-code-tentacles" fetch -q --tags origin
  git -C "$DEV/t3-code-tentacles" -c advice.detachedHead=false checkout -q "$TENTACLES_TAG"
  [ "$(git -C "$DEV/t3-code-tentacles" rev-parse HEAD)" = "$TENTACLES_COMMIT" ] || die AJ-TENT-02 "checkout is not the pinned commit $TENTACLES_COMMIT"
  echo "tentacles: npm install + link (can take several minutes)…"
  (cd "$DEV/t3-code-tentacles" && npm install --no-audit --no-fund --loglevel=error && npm link --loglevel=error) || die AJ-TENT-01 "npm install/link failed (EACCES: REPAIR.md AJ-NPM-01)"
  local have onpath
  have="$(node -p 'require(process.argv[1]).version' "$DEV/t3-code-tentacles/package.json" 2>/dev/null || echo '?')"
  echo "ok tentacles $have @ $TENTACLES_TAG (checkout ~/Developer/t3-code-tentacles)"
  onpath="$(ver command tentacles --version || true)"
  if [ "$onpath" != "$have" ]; then echo "note: \`tentacles\` on PATH is ${onpath:-missing} at $(command -v tentacles | sed "s#^$HOME#~#"), not this checkout (REPAIR.md AJ-TENT-02)"; fi
}

# Stock T3 Code (Beta) writes its CLI to ~/.t3/bin/t3 when it first opens; Tentacles 0.5.0-jack.17 does not
# look there, so issue Tentacles' T3 session token with it. Idempotent; the token is never printed.
T3_CLI="$HOME/.t3/bin/t3"; T3_HOME_DIR="$HOME/.t3"
# "T3 is running": match the app's own executable path as a fixed string. pgrep reads the ( ) in the name as a pattern and never matches.
t3_proc_match() { grep -F -- "/$T3_APP_NAME.app/Contents/MacOS/$T3_APP_NAME" >/dev/null; }  # stdin: ps -A -o comm= (no -q: grep must read all of ps under pipefail)
t3_running() { ps -A -o comm= 2>/dev/null | t3_proc_match; }
TOKEN_FILE="${T3_HERMES_TOKEN_FILE:-$HOME/.local/state/t3-hermes-bridge/t3.token}"
t3_auth_state() { # valid | invalid | unknown, from `tentacles doctor --json` (it exits non-zero when not ready)
  { tentacles doctor --json 2>/dev/null || true; } | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let a;try{a=JSON.parse(s).t3.auth.status}catch{}process.stdout.write(a==="valid"||a==="invalid"?a:"unknown")})' 2>/dev/null || echo unknown
}
do_t3_token() {
  command -v tentacles >/dev/null || die AJ-TENT-01 "tentacles missing: run bin/install.sh tentacles first"
  [ -x "$T3_CLI" ] || die AJ-TENT-05 "~/.t3/bin/t3 missing: open $T3_APP_NAME once (it writes that command), then re-run bin/install.sh t3-token"
  t3_running || die AJ-TENT-05 "$T3_APP_NAME is not running: open it, then re-run bin/install.sh t3-token"
  if [ -s "$TOKEN_FILE" ] && [ "$(t3_auth_state)" = valid ]; then echo "ok t3-token (Tentacles is signed in to $T3_APP_NAME)"; return; fi
  local out
  out="$(tentacles reauth --t3-bin "$T3_CLI" --t3-home "$T3_HOME_DIR" 2>/dev/null)" || die AJ-TENT-05 "tentacles reauth failed; is $T3_APP_NAME open and finished starting? Re-run bin/install.sh t3-token"
  printf '%s' "$out" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);process.exit(r.authenticated&&r.tokenStored?0:1)})' 2>/dev/null || die AJ-TENT-05 "tentacles reauth did not store a token"
  [ "$(t3_auth_state)" = valid ] || die AJ-TENT-05 "token stored; tentacles doctor did not confirm the T3 auth (run tentacles doctor)"
  echo "ok t3-token (issued a Tentacles session for $T3_APP_NAME; stored in ${TOKEN_FILE/#"$HOME"/$TILDE})"
}

do_classify() {
  need_pin "$GUARDIAN_TAG" GUARDIAN_TAG
  # Keep a venv whose pip works; otherwise try each Python >= min in turn. A failed
  # `venv` (e.g. a uv-managed python without ensurepip) leaves a half-made venv; remove it.
  local py ok=""
  for py in $(command -v python3.12 python3.13 python3 2>/dev/null); do
    "$py" -c "import sys; mj,mn=map(int,'$PYTHON_MIN'.split('.')); sys.exit(0 if sys.version_info >= (mj,mn) else 1)" 2>/dev/null || continue
    "$CLASSIFY_VENV/bin/python" -m pip --version >/dev/null 2>&1 && { ok=1; break; }
    rm -rf "${CLASSIFY_VENV:?}"
    "$py" -m venv "$CLASSIFY_VENV" >/dev/null 2>&1 && "$CLASSIFY_VENV/bin/python" -m pip --version >/dev/null 2>&1 && { ok=1; break; }
  done
  [ -n "$ok" ] || { rm -rf "${CLASSIFY_VENV:?}"; die AJ-PY-01 "Python >= $PYTHON_MIN with a working venv needed (brew install python@3.12)"; }
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
  claude) do_claude ;; codex) do_codex ;; t3) do_t3 ;; tentacles) do_tentacles ;; t3-token) do_t3_token ;; classify) do_classify ;; guardian) do_guardian ;;
  all) do_claude; do_codex; do_t3; do_tentacles; do_classify
    # last and non-fatal: a token failure only prints its next step (REPAIR.md AJ-TENT-05)
    if t3_running; then ( do_t3_token ) || echo "next: bin/install.sh t3-token once $T3_APP_NAME has finished starting (REPAIR.md AJ-TENT-05)"
    else echo "next: open $T3_APP_NAME once, then bin/install.sh t3-token"; fi ;;
  *) echo "usage: bin/install.sh <claude|codex|t3|tentacles|t3-token|classify|guardian|all>"; exit 2 ;;
esac
echo "next: bin/doctor.sh"

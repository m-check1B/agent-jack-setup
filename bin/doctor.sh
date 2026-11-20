#!/bin/bash
# agent-jack-setup DOCTOR (macOS). Read-only: it changes nothing.
# Prints one line per component: PASS|FAIL|SKIP <code> <component> <found> <expected> <source>.
# Exit 0 = all PASS/SKIP/WARN, 1 = at least one FAIL. WARN never fails the run. --json for machine output.
# No secrets, e-mails or home paths are printed (home is shown as ~).
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$HERE/versions.env"
JSON=0; [ "${1:-}" = "--json" ] && JSON=1

# --selftest: dry check of versions.env on any OS (macOS, Linux; installs and changes nothing):
# every line parses, every checksum/commit field is well-formed, every pinned URL and tag answers.
t3_auth_state() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let a;try{a=JSON.parse(s).t3.auth.status}catch{}process.stdout.write(a==="valid"||a==="invalid"?a:"unknown")})' 2>/dev/null || echo unknown; }  # stdin: tentacles doctor --json
# "T3 is running": match the app's own executable path as a fixed string. pgrep reads the ( ) in the name as a pattern and never matches.
t3_proc_match() { grep -F -- "/$T3_APP_NAME.app/Contents/MacOS/$T3_APP_NAME" >/dev/null; }  # stdin: ps -A -o comm= (no -q: grep must read all of ps under pipefail)
t3_running() { ps -A -o comm= 2>/dev/null | t3_proc_match; }
# Why AJ-TENT-03. Tentacles at the pin prints JSON only when T3 answered; with no token file or T3 not
# running it prints nothing, so fall back to the local facts.
tent03_why() { # $1 = t3_auth_state
  if [ "$1" = invalid ] || [ ! -s "${T3_HERMES_TOKEN_FILE:-$HOME/.local/state/t3-hermes-bridge/t3.token}" ]; then echo "T3 token missing or rejected: bin/install.sh t3-token"
  elif ! t3_running; then echo "$T3_APP_NAME not running"
  else echo "see tentacles doctor"; fi
}
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
    a="${k/SHA256/ASSET}"; { [ "${!a:-TBD}" = TBD ] && [ "$v" = TBD ]; } || { [ "${!a:-TBD}" != TBD ] && [ "$v" != TBD ]; } || bad "checksum $k and $a disagree on TBD"
  done
  [[ "$TENTACLES_COMMIT" =~ ^[0-9a-f]{40}$ ]] && ok "commit TENTACLES_COMMIT" || bad "commit TENTACLES_COMMIT is not 40 hex"
  [[ "$GUARDIAN_COMMIT" =~ ^[0-9a-f]{7,40}$ ]] && ok "commit GUARDIAN_COMMIT" || bad "commit GUARDIAN_COMMIT is not hex"
  for url in "$SETUP_REPO" "$T3_REPO" "$TENTACLES_REPO" "$GUARDIAN_REPO" \
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
  for c in '{"t3":{"reachable":true,"auth":{"status":"valid"}}}=valid' '{"t3":{"reachable":true,"auth":{"status":"invalid","code":"t3_reauth_required"}}}=invalid' '=unknown' 'not-json=unknown'; do
    in="${c%=*}"; got="$(printf '%s' "$in" | t3_auth_state)"; [ "$got" = "${c##*=}" ] && ok "t3 auth state ${c##*=} from a ${#in}-byte stdout" || bad "t3 auth state: '$in' gave $got, want ${c##*=}"
  done
  tf="$(mktemp)"; got="$(T3_HERMES_TOKEN_FILE="$tf" tent03_why unknown)"   # empty token file, no JSON (new Mac)
  [ "$got" = "T3 token missing or rejected: bin/install.sh t3-token" ] && ok "AJ-TENT-03 no JSON + no token = token text" || bad "AJ-TENT-03 no JSON + no token gave: $got"
  echo x > "$tf"; got="$(T3_HERMES_TOKEN_FILE="$tf" T3_APP_NAME="aj-selftest-no-such-app" tent03_why unknown)"; rm -f "$tf"
  [ "$got" = "aj-selftest-no-such-app not running" ] && ok "AJ-TENT-03 no JSON + token + T3 down = not running" || bad "AJ-TENT-03 no JSON + token + T3 down gave: $got"
  # process-list lines: the app itself counts as running; its helper alone and a name without ( ) do not
  for c in "/Applications/$T3_APP_NAME.app/Contents/MacOS/$T3_APP_NAME=0" "/Applications/$T3_APP_NAME.app/Contents/Frameworks/$T3_APP_NAME Helper.app/Contents/MacOS/$T3_APP_NAME Helper=1" "/Applications/T3 Code Beta.app/Contents/MacOS/T3 Code Beta=1"; do
    if printf '%s\n' "${c%=*}" | t3_proc_match; then got=0; else got=1; fi
    [ "$got" = "${c##*=}" ] && ok "t3 running match=${c##*=} for ${c%=*}" || bad "t3 running match gave $got for ${c%=*}, want ${c##*=}"
  done
  [ "$(grep '^t3_proc_match() ' "$HERE/bin/install.sh")" = "$(grep '^t3_proc_match() ' "$HERE/bin/doctor.sh")" ] && ! grep -q 'pgre[p] -x' "$HERE/bin/install.sh" "$HERE/bin/doctor.sh" && ok "t3 running match: installer and doctor share one fixed-string rule, no pgrep" || bad "t3 running match differs between installer and doctor, or pgrep is back"
  want='tentacles reauth --t3-bin "$HOME/.t3/bin/t3" --t3-home "$HOME/.t3"'
  grep -qF -- "$want" "$HERE/REPAIR.md" && grep -q '^T3_CLI="\$HOME/.t3/bin/t3"; T3_HOME_DIR="\$HOME/.t3"$' "$HERE/bin/install.sh" && grep -q 't3-token) do_t3_token' "$HERE/bin/install.sh" \
    && ok "t3-token step: install.sh target and REPAIR AJ-TENT-03/05 name the same ~/.t3/bin/t3 reauth" || bad "t3-token step: install.sh and REPAIR.md disagree on the reauth command"
  echo "selftest fails: $f"
  [ $f -eq 0 ]
}
[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }
FAILS=0; OUT=()
rec() { # status code component found expected source
  [ "$1" = FAIL ] && FAILS=$((FAILS+1))
  OUT+=("$1|$2|$3|$4|$5|$6")
}
ver() { "$@" 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[-A-Za-z0-9.]*' | head -1; }
plist_ver() { defaults read "$1/Contents/Info" CFBundleShortVersionString 2>/dev/null; }
app_path() { for d in /Applications "$HOME/Applications"; do [ -d "$d/$1.app" ] && { echo "$d/$1.app"; return; }; done; }
ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }  # $1 >= $2
pin() { [ "$1" = TBD ] && { rec FAIL AJ-PIN-00 "$2" - "pin not published yet" VERSIONS.md; return 1; }; return 0; }

# 1 system
OSV="$(sw_vers -productVersion 2>/dev/null)"; ARCH="$(uname -m)"
if [ "${OSV%%.*}" -ge "$MACOS_MIN_MAJOR" ] 2>/dev/null; then rec PASS AJ-SYS-00 macos "$OSV $ARCH" ">=$MACOS_MIN_MAJOR" apple
else rec FAIL AJ-SYS-01 macos "${OSV:-?} $ARCH" ">=$MACOS_MIN_MAJOR" apple; fi
# 0 backup (Time Machine, read-only check; WARN only, never FAIL)
TMOUT_="$(tmutil latestbackup 2>/dev/null | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}' | tail -1)"
if [ -z "$TMOUT_" ]; then rec WARN AJ-BAK-01 backup "no-recent-time-machine" "backup <= 7 days" "Time Machine or another backup (REPAIR.md AJ-BAK-01)"
else BD="${TMOUT_%-*}"; AGE=$(( ( $(date +%s) - $(date -j -f %Y-%m-%d "$BD" +%s) ) / 86400 ))
  if [ "$AGE" -le 7 ]; then rec PASS AJ-BAK-00 backup "time-machine $BD" "backup <= 7 days" "Time Machine"
  else rec WARN AJ-BAK-01 backup "time-machine $BD (${AGE}d old)" "backup <= 7 days" "Time Machine (REPAIR.md AJ-BAK-01)"; fi
fi
# 0a recommended hardware (WARN only): Apple M3 or later, 16 GB RAM, 512 GB disk
CHIP="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"; MEM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))
DISK_GB=$(( $(df -k / | awk 'NR==2{print $2}') * 1024 / 1000000000 ))
MGEN="$(printf '%s' "$CHIP" | sed -nE 's/^Apple M([0-9]+).*/\1/p')"
HWLOW=""; { [ -z "$MGEN" ] || [ "$MGEN" -lt 3 ]; } && HWLOW="$HWLOW chip"
[ "$MEM_GB" -lt 16 ] && HWLOW="$HWLOW ram"; [ "$DISK_GB" -lt 460 ] && HWLOW="$HWLOW disk"   # a 512 GB drive reports ~494-500 GB
if [ -z "$HWLOW" ]; then rec PASS AJ-HW-00 hardware "${CHIP:-?}, ${MEM_GB} GB RAM, ${DISK_GB} GB disk" "M3+ 16GB 512GB" "README: Recommended hardware"
else rec WARN AJ-HW-01 hardware "${CHIP:-?}, ${MEM_GB} GB RAM, ${DISK_GB} GB disk (below:${HWLOW})" "M3+ 16GB 512GB" "REPAIR.md AJ-HW-01"; fi
# 0b free disk space (home volume)
FREE_GB=$(( $(df -k "$HOME" | awk 'NR==2{print $4}') / 1048576 ))
if [ "$FREE_GB" -lt "$DISK_FAIL_GB" ]; then rec FAIL AJ-DISK-02 disk "${FREE_GB} GB free" ">=$DISK_WARN_GB GB (min $DISK_FAIL_GB)" "REPAIR.md AJ-DISK-02"
elif [ "$FREE_GB" -lt "$DISK_WARN_GB" ]; then rec WARN AJ-DISK-01 disk "${FREE_GB} GB free" ">=$DISK_WARN_GB GB" "REPAIR.md AJ-DISK-01"
else rec PASS AJ-DISK-00 disk "${FREE_GB} GB free" ">=$DISK_WARN_GB GB" df; fi
# 2 prerequisites
if command -v brew >/dev/null; then rec PASS AJ-BREW-00 homebrew "$(ver brew --version)" any brew.sh; else rec FAIL AJ-BREW-01 homebrew missing any brew.sh; fi
NV="$(ver node -v)"
if [ -z "$NV" ]; then rec FAIL AJ-NODE-01 node missing ">=$NODE_MIN_MAJOR" homebrew
elif [ "${NV%%.*}" -ge "$NODE_MIN_MAJOR" ]; then rec PASS AJ-NODE-00 node "$NV" ">=$NODE_MIN_MAJOR" homebrew
else rec FAIL AJ-NODE-02 node "$NV" ">=$NODE_MIN_MAJOR" homebrew; fi
if command -v git >/dev/null; then rec PASS AJ-GIT-00 git "$(ver git --version)" any apple-clt; else rec FAIL AJ-GIT-01 git missing any apple-clt; fi
# 3 local drivers: Codex CLI and Claude Code CLI are both required (installed, at the minimum version).
# Sign in to both is recommended: both signed in → PASS; only one → WARN for the other; neither → FAIL for both.
CV="$(ver claude --version)"; XV2="$(ver codex --version)"
CS=0; [ -n "$CV" ] && ge "$CV" "$CLAUDE_CLI_MIN" && claude auth status >/dev/null 2>&1 && CS=1
XS=0; [ -n "$XV2" ] && ge "$XV2" "$CODEX_CLI_MIN" && codex login status >/dev/null 2>&1 && XS=1
CF=FAIL; CNOTE=""; [ $XS = 1 ] && { CF=WARN; CNOTE=" (recommended: sign in too)"; }
XF=FAIL; XNOTE=""; [ $CS = 1 ] && { XF=WARN; XNOTE=" (recommended: sign in too)"; }
# 3a Claude Code CLI (minimum version; it updates itself)
if [ -z "$CV" ]; then rec FAIL AJ-CLAUDE-01 claude-cli missing ">=$CLAUDE_CLI_MIN" npm:@anthropic-ai/claude-code
elif ! ge "$CV" "$CLAUDE_CLI_MIN"; then rec FAIL AJ-CLAUDE-02 claude-cli "$CV" ">=$CLAUDE_CLI_MIN" npm:@anthropic-ai/claude-code
elif [ $CS = 1 ]; then rec PASS AJ-CLAUDE-00 claude-cli "$CV signed-in" ">=$CLAUDE_CLI_MIN" npm:@anthropic-ai/claude-code
else rec $CF AJ-CLAUDE-03 claude-cli "$CV signed-out$CNOTE" ">=$CLAUDE_CLI_MIN" npm:@anthropic-ai/claude-code; fi
# 3a' Codex CLI (minimum version; always installed; the "Local · Codex" lab; signed in locally with the user's own ChatGPT plan)
if [ -z "$XV2" ]; then rec FAIL AJ-CODEX-01 codex-cli missing ">=$CODEX_CLI_MIN" npm:@openai/codex
elif ! ge "$XV2" "$CODEX_CLI_MIN"; then rec FAIL AJ-CODEX-02 codex-cli "$XV2" ">=$CODEX_CLI_MIN" npm:@openai/codex
elif [ $XS = 1 ]; then rec PASS AJ-CODEX-00 codex-cli "$XV2 signed-in" ">=$CODEX_CLI_MIN" npm:@openai/codex
else rec $XF AJ-CODEX-03 codex-cli "$XV2 signed-out$XNOTE" ">=$CODEX_CLI_MIN" npm:@openai/codex; fi
# 3b stray API overrides (they silently replace your Claude sign-in; names only, values never printed)
STRAY=""
for v in ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY; do
  # inside Claude Code the parent process may set these itself, so only a plain terminal's env counts
  if [ -z "${CLAUDECODE:-}" ] && [ -n "$(printenv "$v" 2>/dev/null)" ]; then STRAY="$STRAY $v(env)"; fi
  for f in "$HOME/.zshenv" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    [ -f "$f" ] && grep -Eq "^[[:space:]]*(export[[:space:]]+)?$v=" "$f" && STRAY="$STRAY $v(~/${f##*/})"
  done
done
if [ -n "$STRAY" ]; then rec $CF AJ-ENV-01 claude-env "${STRAY# }" "no ANTHROPIC_* override" "REPAIR.md AJ-ENV-01"
else rec PASS AJ-ENV-00 claude-env clean "no ANTHROPIC_* override" shell; fi
# 3b' doctor started inside the Codex app sandbox (no network): the reply checks can't work there
SANDBOXED=0
if [ -n "${CODEX_SANDBOX:-}" ] && [ -n "${CODEX_SANDBOX_NETWORK_DISABLED:-}" ]; then SANDBOXED=1
  rec FAIL AJ-DOC-01 doctor "inside Codex sandbox (no network)" "run with approval, outside the sandbox" "REPAIR.md AJ-DOC-01"; fi
# 3c Claude answers headless (60 s limit; one tiny request)
if [ $CS = 1 ] && [ -z "$STRAY" ] && [ $SANDBOXED = 0 ]; then
  if [ "$(perl -e 'alarm 60; exec @ARGV' claude -p "Reply with exactly: OK" </dev/null 2>/dev/null | tr -d '[:space:]')" = OK ]; then rec PASS AJ-CLAUDE-05 claude-reply OK OK claude
  else rec $CF AJ-CLAUDE-04 claude-reply "no-OK-in-60s" OK "REPAIR.md AJ-CLAUDE-04"; fi
fi
# 3d Codex answers headless (90 s limit; one tiny request, read-only sandbox, run from an empty temp folder)
if [ $XS = 1 ] && [ $SANDBOXED = 0 ]; then
  XT="$(mktemp -d)"
  if [ "$(cd "$XT" && perl -e 'alarm 90; exec @ARGV' codex exec --skip-git-repo-check --sandbox read-only "Reply with exactly: OK" </dev/null 2>/dev/null | tail -1 | tr -d '[:space:]')" = OK ]; then rec PASS AJ-CODEX-05 codex-reply OK OK codex
  else rec $XF AJ-CODEX-04 codex-reply "no-OK-in-90s" OK "REPAIR.md AJ-CODEX-04"; fi
  rmdir "$XT" 2>/dev/null
fi
# 4 T3 Code: the official upstream app. It updates itself, so any release from T3_MIN up passes;
#   newer than the tested T3_VERSION is a WARN (the Tentacles doctor below still decides Local Talk).
T3="$(app_path "$T3_APP_NAME")"
if [ -z "$T3" ]; then rec FAIL AJ-T3-01 t3code missing "$T3_VERSION" "$T3_REPO@$T3_TAG"
elif pin "$T3_VERSION" t3code; then TV="$(plist_ver "$T3")"; TID="$(defaults read "$T3/Contents/Info" CFBundleIdentifier 2>/dev/null)"
  if [ "$TID" != "$T3_BUNDLE_ID" ]; then rec FAIL AJ-T3-08 t3code "bundle ${TID:-unknown}" "$T3_BUNDLE_ID" "REPAIR.md AJ-T3-08"
  elif ! ge "$TV" "$T3_MIN"; then rec FAIL AJ-T3-02 t3code "$TV" ">=$T3_MIN (tested $T3_VERSION)" "$T3_REPO@$T3_TAG"
  elif [ "$TV" != "$T3_VERSION" ] && ge "$TV" "$T3_VERSION"; then rec WARN AJ-T3-09 t3code "$TV newer than tested" "$T3_VERSION" "REPAIR.md AJ-T3-09"
  else rec PASS AJ-T3-00 t3code "$TV" "$T3_MIN..$T3_VERSION" "$T3_REPO@$T3_TAG"; fi
fi
LEGACY_FOUND=""
IFS='|' read -r -a LEGACY_NAMES <<< "${T3_LEGACY_APP_NAMES:-}"
for name in ${LEGACY_NAMES[@]+"${LEGACY_NAMES[@]}"}; do [ -n "$(app_path "$name")" ] && LEGACY_FOUND="${LEGACY_FOUND:+$LEGACY_FOUND, }$name.app"; done
[ -n "$LEGACY_FOUND" ] && rec WARN AJ-T3-10 t3code-older "older T3 Code app: $LEGACY_FOUND" "only $T3_APP_NAME" "REPAIR.md AJ-T3-10"
# 5 Tentacles: version pin, then its doctor must report the Local Talk turn-result capability on this T3
if ! command -v tentacles >/dev/null; then rec FAIL AJ-TENT-01 tentacles missing "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"
else XV="$(ver tentacles --version)"
  if pin "$TENTACLES_VERSION" tentacles && [ "$XV" != "$TENTACLES_VERSION" ]; then rec FAIL AJ-TENT-02 tentacles "$XV" "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"
  elif [ "$TENTACLES_VERSION" != TBD ]; then
    if TJ="$(tentacles doctor --json 2>/dev/null)"; then
      TALK="$(printf '%s' "$TJ" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).capabilities?.talkTurnResult??"none"))}catch{process.stdout.write("unreadable")}})' 2>/dev/null)"
      if [ "$TALK" = v1 ]; then rec PASS AJ-TENT-00 tentacles "$XV doctor-ok talkTurnResult=v1" "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"
      else rec FAIL AJ-TENT-04 tentacles "$XV talkTurnResult=${TALK:-none}" "talkTurnResult v1" "REPAIR.md AJ-TENT-04"; fi
    else TWHY="$(tent03_why "$(printf '%s' "$TJ" | t3_auth_state)")"
      rec FAIL AJ-TENT-03 tentacles "$XV doctor-not-ready: $TWHY" "$TENTACLES_VERSION" "REPAIR.md AJ-TENT-03"; fi
  fi
fi
# 6 estate-guardian: the classifier + router for Tentacles (standard), the guard checkout (optional)
VPY="$CLASSIFY_VENV/bin/python"
if [ ! -x "$VPY" ]; then rec FAIL AJ-EC-01 estate-classify not-installed "$CLASSIFY_VERSION" "$GUARDIAN_REPO@$GUARDIAN_TAG"
else EV="$("$VPY" -c 'import importlib.metadata as m; print(m.version("estate-classify"))' 2>/dev/null)"
  if [ -z "$EV" ]; then rec FAIL AJ-EC-01 estate-classify not-installed "$CLASSIFY_VERSION" "$GUARDIAN_REPO@$GUARDIAN_TAG"
  elif pin "$CLASSIFY_VERSION" estate-classify && [ "$EV" != "$CLASSIFY_VERSION" ]; then rec FAIL AJ-EC-02 estate-classify "$EV" "$CLASSIFY_VERSION" "$GUARDIAN_REPO@$GUARDIAN_TAG"
  elif [ -n "${GUARDIAN_COMMIT:-}" ] && [ "$("$VPY" -c 'import json,importlib.metadata as m; print((json.loads(m.distribution("estate-classify").read_text("direct_url.json") or "{}").get("vcs_info") or {}).get("commit_id","")[:7])' 2>/dev/null)" != "${GUARDIAN_COMMIT:0:7}" ]; then rec FAIL AJ-EC-02 estate-classify "$EV other-commit" "$GUARDIAN_TAG" "$GUARDIAN_REPO@$GUARDIAN_TAG"
  elif [ "$CLASSIFY_VERSION" != TBD ]; then
    # offline smoke: import both modules, classify against an empty in-memory taxonomy (no key, no network, no writes)
    if "$VPY" - <<'PY' >/dev/null 2>&1
import json, tempfile, os, classify, worker_route
d = tempfile.mkdtemp()
p = os.path.join(d, "smoke.json")
json.dump({"name": "smoke", "taxonomy": {"classes": {}}, "question": "smoke?", "min_conf": 0.6,
           "paths": {"judge_queue": os.path.join(d, "q.jsonl"), "answers": os.path.join(d, "a.jsonl")},
           "key": {"source": "env", "env": "AJ_SMOKE_NO_KEY"}, "questions": {}}, open(p, "w"))
r = classify.Classifier(p).classify("smoke test", key="smoke")
assert r["class"] == "unclassified"
PY
    then rec PASS AJ-EC-00 estate-classify "$EV smoke-ok" "$CLASSIFY_VERSION" "$GUARDIAN_REPO@$GUARDIAN_TAG"
    else rec FAIL AJ-EC-03 estate-classify "$EV smoke-fail" "$CLASSIFY_VERSION" "$GUARDIAN_REPO@$GUARDIAN_TAG"; fi
  fi
fi
EG="$HOME/Developer/estate-guardian"
if [ ! -d "$EG/.git" ]; then rec SKIP AJ-EG-00 guard-checkout not-installed "$GUARDIAN_TAG" "$GUARDIAN_REPO (optional)"
else GV="$(git -C "$EG" describe --tags --exact-match 2>/dev/null || echo untagged)"
  if [ "$GUARDIAN_TAG" != TBD ] && [ "$GV" != "$GUARDIAN_TAG" ]; then rec FAIL AJ-EG-02 guard-checkout "$GV" "$GUARDIAN_TAG" "$GUARDIAN_REPO (optional)"
  else rec PASS AJ-EG-00 guard-checkout "$GV" "$GUARDIAN_TAG" "$GUARDIAN_REPO (optional)"; fi
fi
# 7 Agent Jack desktop
AJ="$(app_path 'Agent Jack')"
if [ -z "$AJ" ]; then rec FAIL AJ-JACK-01 agent-jack-app missing ">=$JACK_DESKTOP_MIN" "agentjack.kraliki.com/downloads (signed in)"
else JV="$(plist_ver "$AJ")"
  if ge "$JV" "$JACK_DESKTOP_MIN"; then rec PASS AJ-JACK-00 agent-jack-app "$JV" ">=$JACK_DESKTOP_MIN" "agentjack.kraliki.com/downloads (signed in)"
  else rec FAIL AJ-JACK-02 agent-jack-app "$JV" ">=$JACK_DESKTOP_MIN" "agentjack.kraliki.com/downloads (signed in)"; fi
fi
# 7b Google Chrome (required: the browser the agents' extensions run in; it updates itself, so no pin)
GC="$(app_path 'Google Chrome')"
if [ -z "$GC" ]; then rec FAIL AJ-CHROME-01 google-chrome missing any "google.com/chrome (REPAIR.md AJ-CHROME-01)"
else rec PASS AJ-CHROME-00 google-chrome "$(plist_ver "$GC")" any google.com/chrome; fi
# 8 manual checks (inside the Agent Jack app; doctor cannot see them)
rec SKIP AJ-PAIR-00 pairing manual "Paired · ready" "Settings → Computers & labs"
rec SKIP AJ-LOCAL-00 local-bot manual "Local reply OK" "Bot gear → Engine → Select (Advanced) → Lab Local · Codex or Local · Claude Code → Apply"
rec SKIP AJ-BROWSER-00 browser "manual (optional)" "extension Connected" "BROWSER.md: Codex → ChatGPT extension (OpenAI); Claude → Claude in Chrome (Anthropic)"

if [ $JSON = 1 ]; then
  printf '{"doctor":"agent-jack-setup","setup_tag":"%s","fails":%d,"checks":[' "$SETUP_TAG" "$FAILS"
  i=0; for l in "${OUT[@]}"; do IFS='|' read -r s c n f e src <<<"$l"; [ $i -gt 0 ] && printf ','; printf '{"status":"%s","code":"%s","component":"%s","found":"%s","expected":"%s","source":"%s"}' "$s" "$c" "$n" "$f" "$e" "$src"; i=1; done
  printf ']}\n'
else
  echo "AGENT JACK DOCTOR v1 · setup $SETUP_TAG · $(date +%Y-%m-%d)"
  for l in "${OUT[@]}"; do IFS='|' read -r s c n f e src <<<"$l"; printf '%-4s %-12s %-16s found=%-22s expected=%-16s source=%s\n' "$s" "$c" "$n" "$f" "$e" "$src"; done
  echo "fails: $FAILS  (fix each FAIL code with REPAIR.md, then run bin/doctor.sh again)"
fi
[ $FAILS -eq 0 ]

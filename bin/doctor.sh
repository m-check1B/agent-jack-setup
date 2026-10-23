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
# 4 T3 Code (our pinned fork)
T3="$(app_path "$T3_APP_NAME")"
if [ -z "$T3" ]; then rec FAIL AJ-T3-01 t3code missing "$T3_VERSION" "$T3_REPO@$T3_TAG"
else TV="$(plist_ver "$T3")"
  if pin "$T3_VERSION" t3code && [ "$TV" != "$T3_VERSION" ]; then rec FAIL AJ-T3-02 t3code "$TV" "$T3_VERSION" "$T3_REPO@$T3_TAG"
  elif [ "$T3_VERSION" != TBD ]; then rec PASS AJ-T3-00 t3code "$TV" "$T3_VERSION" "$T3_REPO@$T3_TAG"; fi
fi
# 5 Tentacles
if ! command -v tentacles >/dev/null; then rec FAIL AJ-TENT-01 tentacles missing "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"
else XV="$(ver tentacles --version)"
  if pin "$TENTACLES_VERSION" tentacles && [ "$XV" != "$TENTACLES_VERSION" ]; then rec FAIL AJ-TENT-02 tentacles "$XV" "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"
  elif [ "$TENTACLES_VERSION" != TBD ]; then
    if tentacles doctor --json >/dev/null 2>&1; then rec PASS AJ-TENT-00 tentacles "$XV doctor-ok" "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"
    else rec FAIL AJ-TENT-03 tentacles "$XV doctor-not-ready" "$TENTACLES_VERSION" "$TENTACLES_REPO@$TENTACLES_TAG"; fi
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
rec SKIP AJ-LOCAL-00 local-bot manual "Local reply OK" "Bot → Provider → Local → Codex or Claude Code"
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

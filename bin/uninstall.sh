#!/bin/bash
# Remove what the Agent Jack doctor and earlier versions of this setup installed. Lists everything first;
# changes only with --yes. An app goes to the Trash only when the doctor's record (~/.agent-jack/installed-apps)
# says the doctor installed it; any other copy is left whole and reported (audit 3, P3-7).
# Keeps your sign-ins, the Agent Jack app, ~/.t3 and your own checkouts.
set -u
NL='
'
# refused before anything is read or touched (B3 P3-1): every path below starts with $HOME
refuse() { echo "Refused: $1, so nothing was removed. Run it again from a normal Terminal window." >&2; exit 2; }
case "${HOME:-}" in /*) ;; *) refuse "HOME is unset, empty or not an absolute path" ;; esac
case "$HOME" in *"$NL"*) refuse "HOME holds a newline" ;; esac   # newline guard
case "$(cd "$HOME" 2>/dev/null && pwd -P)" in *[!/]*|"") ;; *) refuse "HOME is the root folder" ;; esac   # / and // alike
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$HERE/versions.env"
DEV="$HOME/Developer"; AJ="$HOME/.agent-jack"; TILDE="~"; REC="$AJ/installed-apps"
{ [ -L "$AJ" ] || [ -L "$DEV" ]; } && refuse "~/.agent-jack or ~/Developer is a link to somewhere else"
short() { printf '%s' "${1/#"$HOME"/$TILDE}"; }
shq() { case "$1" in "$HOME"/*) printf '~/"%s"' "${1#"$HOME"/}" ;; *) printf '"%s"' "$1" ;; esac; }   # a path to paste into Terminal
ours() { [ -d "$1/.git" ] && [ -z "$(git -C "$1" status --porcelain 2>/dev/null)" ] && [ "$(git -C "$1" remote get-url origin 2>/dev/null)" = "$2.git" ]; }
# the only paths this script may remove; every path is checked against this list again right before rm
fixed() { case "$1" in "$DEV/t3-code-tentacles"|"$DEV/estate-guardian"|"$CLASSIFY_VENV"|"$AJ/tentacles"|"$AJ/node") [ "$1" != "$HOME" ] && [ "$1" != / ] ;; *) return 1 ;; esac; }
DIRS=""
ours "$DEV/t3-code-tentacles" "$TENTACLES_REPO" && DIRS="$DIRS$DEV/t3-code-tentacles$NL"
ours "$DEV/estate-guardian" "$GUARDIAN_REPO" && DIRS="$DIRS$DEV/estate-guardian$NL"
for d in "$CLASSIFY_VENV" "$AJ/tentacles" "$AJ/node"; do [ -e "$d" ] && DIRS="$DIRS$d$NL"; done
# apps: recorded ones go to the Trash; unrecorded ones stay
APPS=""; THEIRS=""
for d in /Applications "$HOME/Applications"; do
  a="$d/$T3_APP_NAME.app"; [ -d "$a" ] || continue
  if awk -F'|' -v n="$T3_APP_NAME" -v w="${d/#"$HOME"/$TILDE}" '$1==n && $4==w {f=1} END {exit !f}' "$REC" 2>/dev/null; then APPS="$APPS$a$NL"; else THEIRS="$THEIRS$a$NL"; fi
done
echo "Would remove: the tentacles npm link, the marked PATH line in ~/.zprofile / ~/.bash_profile, and:"
printf '%s' "$DIRS" | while IFS= read -r d; do echo "  $(short "$d")"; done
echo "  (~/.agent-jack/node also holds the Codex CLI and Claude Code CLI the doctor installed there)"
printf '%s' "$APPS" | while IFS= read -r a; do echo "Would move to the Trash (the doctor installed it): $(short "$a")"; done
printf '%s' "$THEIRS" | while IFS= read -r a; do echo "Left whole (not installed by the doctor): $(short "$a"). To remove it yourself: mv $(shq "$a") ~/.Trash/"; done
echo "(checkouts with local changes or another origin are kept)"
[ "${1:-}" = "--yes" ] || { echo "Run again with --yes to remove."; exit 0; }
command -v npm >/dev/null 2>&1 && npm rm -g tentacles >/dev/null 2>&1
while IFS= read -r d; do
  [ -n "$d" ] || continue
  if fixed "$d"; then rm -rf -- "$d"; else echo "kept: $(short "$d") (not on the fixed list)"; fi
done <<EOF
$DIRS
EOF
[ -z "$APPS" ] || osascript -e "quit app \"$T3_APP_NAME\"" >/dev/null 2>&1 || true
KEPT=0; MOVED=0
while IFS= read -r a; do
  [ -n "$a" ] || continue
  case "$a" in "/Applications/$T3_APP_NAME.app"|"$HOME/Applications/$T3_APP_NAME.app") ;; *) KEPT=1; echo "kept: $(short "$a") (not one of the app paths this script may move)"; continue ;; esac
  mkdir -p "$HOME/.Trash" && mv -- "$a" "$HOME/.Trash/$T3_APP_NAME-$(date +%Y%m%d%H%M%S).app" && MOVED=1 || { KEPT=1; echo "kept: $(short "$a") (could not move it)"; }
done <<EOF
$APPS
EOF
[ $KEPT = 1 ] || rm -f -- "$REC"
for f in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  [ -f "$f" ] && grep -q '# Agent Jack doctor$' "$f" && { { grep -v '# Agent Jack doctor$' "$f" || true; } > "$f.aj-tmp" && cat "$f.aj-tmp" > "$f"; rm -f -- "$f.aj-tmp"; }
done
echo "done. Claude Code or Codex installed some other way stay."
[ $MOVED = 0 ] || echo "The T3 Code (Beta) the doctor installed is in the Trash if you want it back."

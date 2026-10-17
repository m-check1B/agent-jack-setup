#!/bin/bash
# Remove what agent-jack-setup installed. Lists everything first; deletes only with --yes.
# Keeps your Claude sign-in, your Agent Jack app and your data.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
. "$HERE/versions.env"
DEV="$HOME/Developer"
ours() { [ -d "$1/.git" ] && [ -z "$(git -C "$1" status --porcelain 2>/dev/null)" ] && [ "$(git -C "$1" remote get-url origin 2>/dev/null)" = "$2.git" ]; }
LIST=""
ours "$DEV/t3-code-tentacles" "$TENTACLES_REPO" && LIST="$LIST ~/Developer/t3-code-tentacles"
ours "$DEV/estate-guardian" "$GUARDIAN_REPO" && LIST="$LIST ~/Developer/estate-guardian"
echo "Would remove: tentacles npm link,${LIST:- (no clean checkouts of ours)}, ~/.agent-jack/venv, /Applications (or ~/Applications)/$T3_APP_NAME.app"
echo "(checkouts with local changes or another origin are kept)"
[ "${1:-}" = "--yes" ] || { echo "Run again with --yes to remove."; exit 0; }
ours "$DEV/t3-code-tentacles" "$TENTACLES_REPO" && { (cd "$DEV/t3-code-tentacles" && npm unlink -g >/dev/null 2>&1) || true; }
ours "$DEV/t3-code-tentacles" "$TENTACLES_REPO" && rm -rf "$DEV/t3-code-tentacles"
ours "$DEV/estate-guardian" "$GUARDIAN_REPO" && rm -rf "$DEV/estate-guardian"
rm -rf "$CLASSIFY_VENV"
osascript -e "quit app \"$T3_APP_NAME\"" >/dev/null 2>&1 || true
rm -rf "/Applications/$T3_APP_NAME.app" "$HOME/Applications/$T3_APP_NAME.app"
echo "removed. Claude Code CLI stays (npm uninstall -g @anthropic-ai/claude-code if you want it gone)."

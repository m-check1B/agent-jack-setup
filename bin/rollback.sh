#!/bin/bash
# Roll back to an earlier tested combination: bin/rollback.sh <setup-tag>   (tags listed in VERSIONS.md)
# macOS (KRA-10893): from DOCTOR_TAG on, the doctor of that tag does the work; v1.1.1-v1.1.3 are refused, because
# their installer removes the app before the new one is in place (KRA-10943). Older tags install the T3 fork.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DOCTOR_TAG=v1.1.4   # the first tag with the one doctor; never printed, so no public text names it before it exists
DOCTOR_LINE='  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)"'
TAG="${1:?usage: bin/rollback.sh <setup-tag>}"
# only a plain release tag; git revision syntax (^ ~ : @ paths, leading dash) never reaches git
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "$TAG is not a setup tag of the form vX.Y.Z" >&2; exit 2; }
older() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }
older "$TAG" v1.1.1 && { printf '%s\n%s\n' "$TAG installs the T3 Code TPLUS fork, which must not be on the Mac. Run the Agent Jack doctor instead:" "$DOCTOR_LINE" >&2; exit 2; }
older "$TAG" "$DOCTOR_TAG" && { printf '%s\n%s\n' "$TAG cannot be rolled back to on a Mac: its installer removes the app before the new one is in place (KRA-10943). Run the Agent Jack doctor instead:" "$DOCTOR_LINE" >&2; exit 2; }
# the tag must be origin's tag, at origin's commit (B3 P3-3): never a local-only or re-pointed tag
remote="$(git -C "$HERE" ls-remote origin "refs/tags/$TAG" "refs/tags/$TAG^{}" 2>/dev/null)" || { echo "Could not reach origin to check $TAG; connect to the internet, then run this again." >&2; exit 2; }
# only the exact tag ref and its peeled line: ls-remote matches pattern tails, so refs/heads/refs/tags/<tag> would match too
remote="$(printf '%s\n' "$remote" | awk -v r="refs/tags/$TAG" '$2==r || $2==r"^{}" {c=$1} END {print c}')"
[ -n "$remote" ] || { echo "$TAG is not a tag on origin (it exists only here, or not at all); pick a tag from VERSIONS.md." >&2; exit 2; }
git -C "$HERE" rev-parse -q --verify "refs/tags/$TAG^{commit}" >/dev/null || git -C "$HERE" fetch -q origin "refs/tags/$TAG:refs/tags/$TAG" 2>/dev/null \
  || { echo "Could not fetch $TAG from origin; connect to the internet, then run this again." >&2; exit 2; }
[ "$(git -C "$HERE" rev-parse "refs/tags/$TAG^{commit}")" = "$remote" ] || { echo "Your local tag $TAG points elsewhere than origin's; remove it with: git -C \"$HERE\" tag -d $TAG, then run this again." >&2; exit 2; }
# the folder goes back to where it was on every exit, also when the doctor of $TAG fails (P3-6)
WAS="$(git -C "$HERE" symbolic-ref -q --short HEAD || git -C "$HERE" rev-parse HEAD)"
trap 'git -C "$HERE" -c advice.detachedHead=false checkout -q "$WAS"' EXIT
git -C "$HERE" -c advice.detachedHead=false checkout -q "refs/tags/$TAG"
"$HERE/bin/doctor.sh"   # from DOCTOR_TAG on, the tag's doctor names the one Agent Jack doctor run

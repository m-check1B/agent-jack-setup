#!/bin/bash
# Roll back to an earlier tested combination: bin/rollback.sh <setup-tag>   (tags listed in VERSIONS.md)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:?usage: bin/rollback.sh <setup-tag>}"
[ "$TAG" = v1.0.0 ] && { echo "v1.0.0 has a known install bug; roll back to v1.0.1 or later" >&2; exit 2; }
git -C "$HERE" fetch -q --tags origin
git -C "$HERE" -c advice.detachedHead=false checkout -q "$TAG"
"$HERE/bin/install.sh" all
echo "rolled back to $TAG; run bin/doctor.sh"

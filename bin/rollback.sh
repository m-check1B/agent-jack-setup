#!/bin/bash
# Roll back to an earlier tested combination: bin/rollback.sh <setup-tag>   (tags listed in VERSIONS.md)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:?usage: bin/rollback.sh <setup-tag>}"
git -C "$HERE" fetch -q --tags origin
git -C "$HERE" -c advice.detachedHead=false checkout -q "$TAG"
"$HERE/bin/install.sh" all
echo "rolled back to $TAG; run bin/doctor.sh"

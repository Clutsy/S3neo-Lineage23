#!/bin/bash
# Prepares a synced LineageOS 23.2 tree for the Galaxy S3 Neo: blobs, vndk v29 libs, patches.
# Run from the tree root. On Crave this repo is cloned to .repo/local_manifests, so:
#   bash .repo/local_manifests/scripts/prepare.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$HERE/scripts/fetch_blobs.sh"
bash "$HERE/scripts/vendor_vndk29.sh"
bash "$HERE/scripts/apply_patches.sh" "$HERE/patches"
echo "prepare.sh OK"

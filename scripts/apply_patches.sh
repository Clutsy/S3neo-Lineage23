#!/bin/bash
# Applies patches to the synced tree. Run from the tree root: apply_patches.sh <patches dir>
# Layout: <patches dir>/<repo path with "/" replaced by "_">/NNNN-title.patch  (git format-patch / git am)
set -euo pipefail
P="$(cd "${1:?patches dir}" && pwd)"
git config --global user.email "ci@local"; git config --global user.name "ci"
shopt -s nullglob
for d in "$P"/*/; do
    repo="$(basename "$d" | tr '_' '/')"
    [ -d "$repo/.git" ] || [ -e "$repo/.git" ] || { echo "SKIP $repo (not in tree)"; continue; }
    for f in "$d"*.patch; do
        echo "== $repo <- $(basename "$f")"
        git -C "$repo" am --3way "$f"
    done
done

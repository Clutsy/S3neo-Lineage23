#!/bin/bash
# Applies patches to the synced tree. Run from the tree root: apply_patches.sh <patches dir>
# Layout: <patches dir>/<repo path with "/" replaced by "_">/NNNN-title.patch  (git format-patch / git am)
# Idempotent: a patch that is already applied is skipped, so re-runs on a persistent tree are safe.
set -euo pipefail
P="$(cd "${1:?patches dir}" && pwd)"
git config --global user.email "ci@local"; git config --global user.name "ci"
shopt -s nullglob
for d in "$P"/*/; do
    repo="$(basename "$d" | tr '_' '/')"
    [ -e "$repo/.git" ] || { echo "SKIP $repo (not in tree)"; continue; }
    for f in "$d"*.patch; do
        if git -C "$repo" apply --reverse --check "$f" >/dev/null 2>&1; then
            echo "== $repo <- $(basename "$f") (already applied, skipped)"; continue
        fi
        echo "== $repo <- $(basename "$f")"
        git -C "$repo" am --3way "$f" || { git -C "$repo" am --abort || true; echo "PATCH FAILED: $repo $(basename "$f")"; exit 1; }
    done
done

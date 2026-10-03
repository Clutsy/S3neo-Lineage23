Patches are applied by scripts/apply_patches.sh after repo sync (git am). Folder = repo path with / replaced by _
`device_samsung_s3ve3g-common/0001-drop-ld-shim.patch`. `scripts/apply_patches.sh` applies them with `git am`
after `repo sync` and before the build. Empty on purpose: nothing here has been validated yet.

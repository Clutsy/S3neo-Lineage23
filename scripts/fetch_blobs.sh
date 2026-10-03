#!/bin/bash
# Fetches the s3ve3g vendor blobs into a LineageOS tree. Run from the tree root.
# Source: TheMuppets/proprietary_vendor_samsung, branch lineage-18.1 (tip 9508b39, May 2022).
# Checked 2026-10-03: every entry in html6405's proprietary-files lists (msm8226-common,
# s3ve3g-common, s3ve3gxx, s3ve3gjv) exists here and its SHA1 matches the list (190/190 hashed
# entries; 32 more entries carry no hash). They are Android 11-era blobs, the same ones the
# 21.0 builds use. Not tested on a device.
set -euo pipefail
git clone -q --depth 1 --filter=blob:none --sparse -b lineage-18.1 \
    https://github.com/TheMuppets/proprietary_vendor_samsung .blobs_tmp
git -C .blobs_tmp sparse-checkout set msm8226-common s3ve3g-common s3ve3gds s3ve3gjv s3ve3gxx
mkdir -p vendor/samsung
for d in msm8226-common s3ve3g-common s3ve3gds s3ve3gjv s3ve3gxx; do
    rm -rf "vendor/samsung/$d"; cp -r ".blobs_tmp/$d" "vendor/samsung/$d"
done
rm -rf .blobs_tmp
# TARGET_LD_SHIM_LIBS is gone from the 22.x+ linker: give libperipheral_client.so the shim as DT_NEEDED instead.
# Tested on the real blob: patchelf 0.18.0 adds libshim_binder.so as the first NEEDED entry.
patchelf --add-needed libshim_binder.so vendor/samsung/s3ve3g-common/proprietary/vendor/lib/libperipheral_client.so
echo "Blobs in vendor/samsung/. Build the xx (Sony IMX175) or jv (Samsung S5K4H5YB) variant that matches your phone."

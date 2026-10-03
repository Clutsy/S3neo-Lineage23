#!/bin/bash
# prebuilts/vndk/v29 is not in the LOS 23.2 manifest (only v31-v34 are). msm8226.mk copies two files from it
# (libprotobuf-cpp-lite.so and libcutils.so as libcutils-v29) into /vendor/lib. This fetches them from AOSP at
# the tag LOS 21.0 used (android-14.0.0_r67) and puts them where patches/device_samsung_msm8226-common expects.
set -euo pipefail
T=$(mktemp -d)
git clone -q --depth 1 --branch android-14.0.0_r67 https://android.googlesource.com/platform/prebuilts/vndk/v29 "$T/v29"
D=device/samsung/msm8226-common/vndk29
mkdir -p "$D"
cp "$T/v29/arm/arch-arm-armv7-a-neon/shared/vndk-core/libprotobuf-cpp-lite.so" "$D/"
cp "$T/v29/arm/arch-arm-armv7-a-neon/shared/vndk-sp/libcutils.so" "$D/"
rm -rf "$T"; ls -la "$D"

#!/bin/bash
# Reproduces the kernel build done in the sandbox (Ubuntu 24.04, 1 CPU, ~12 min with -j2).
# Kernel: html6405/android_kernel_samsung_msm8226, branch lineage-21.0-BPF (Linux 3.4.113)
# Toolchain: LineageOS GCC 4.9 prebuilt (GCC 13 from Ubuntu is not used).
set -euo pipefail
git clone --depth 1 -b lineage-21.0-BPF https://github.com/html6405/android_kernel_samsung_msm8226 kernel
git clone --depth 1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 gcc49
export ARCH=arm CROSS_COMPILE="$PWD/gcc49/bin/arm-linux-androideabi-"
cd kernel
make O=../kout lineage_s3ve3gxx_defconfig   # or lineage_s3ve3gjv_defconfig / lineage_s3ve3gds_defconfig
make O=../kout -j"$(nproc)" zImage dtbs

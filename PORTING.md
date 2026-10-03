# Galaxy S3 Neo (s3ve3g*) on LineageOS 23.2 (Android 16 QPR2)

Status: **sources and a plan only. Nothing here has been built or booted.**
I could not build it: the sandbox I work in has 1 CPU, 3 GB RAM and ~10 GB of disk,
there are no public vendor blobs for this device, and I cannot flash or test a phone.

## What I checked (verified by reading the repos on 2026-10-03)

Base: html6405's `lineage-21.0` trees (Android 14), the newest ones that exist publicly
for s3ve3g-common and msm8226-common. Kernel: `android_kernel_samsung_msm8226`,
branches `lineage-21.0` and `lineage-21.0-BPF` (3.4 kernel).

1. **`TARGET_LD_SHIM_LIBS` is gone upstream.** LOS 21.0 bionic has `LD_SHIM_LIBS`
   support in `linker.cpp`; LOS 22.0, 22.1, 22.2, 23.0, 23.1 and 23.2 have none, and
   `vendor/lineage` 23.2 no longer defines the soong variable.
   The board config of s3ve3g-common sets it for `libperipheral_client.so` -> `libshim_binder.so`.
   Replacement: add the shim as a `DT_NEEDED` entry on the blob (patchelf, in `blob_fixups`).
2. **html6405 patched `vendor/lineage` for 21.0.** His fork re-adds soong config vars that
   upstream dropped: `target_process_sdk_version_overrides`, `disable_postrender_cleanup`,
   `needs_netd_direct_connect_rule`, `needs_camera_boottime`, `no_cameraserver` and others.
   In upstream 23.2 none of these exist. His board config relies on
   `TARGET_PROCESS_SDK_VERSION_OVERRIDE` (mediaserver, mm-qcamera-daemon, rild),
   `TARGET_NEEDS_NETD_DIRECT_CONNECT_RULE` and `TARGET_DISABLE_POSTRENDER_CLEANUP`.
   Each one needs its consumer code rebased onto 23.2 (frameworks/av, frameworks/native,
   system/netd, bionic or init). I did **not** locate every consumer; they are not
   in any public branch I could see.
3. **Camera.** The board config uses `TARGET_HAS_LEGACY_CAMERA_HAL1`,
   `TARGET_NEEDS_LEGACY_CAMERA_HAL1_DYN_NATIVE_HANDLE`, `TARGET_USES_NON_TREBLE_CAMERA`
   and a `CameraWrapper.cpp` (`msm8226-common/camera`). `frameworks/av` 23.2 has no
   `device1/` directory (nor does 21.0), and the build system repos I grepped
   (`android_build`, `build_soong`, `system_core`, `vendor_lineage`) contain none of these flags
   in either 21.0 or 23.2. So the HAL1 path lives in patches I cannot see.
   Until those patches are found or rewritten, the camera cannot work on 23.2.
4. **Blob extraction.** LOS 23.2 `tools/extract-utils` has no `extract_utils.sh` any more
   (only the Python `extract_utils/`). Both `extract-files.sh` and `setup-makefiles.sh`
   in the s3ve3g trees must become `extract-files.py` / `setup-makefiles.py`.
5. **Vendor blobs: found.** `TheMuppets/proprietary_vendor_samsung`, branch `lineage-18.1`,
   has `msm8226-common`, `s3ve3g-common`, `s3ve3gds`, `s3ve3gjv`, `s3ve3gxx` (~73 MB, 272 files).
   I cross-checked html6405's four proprietary-files lists: all 222 entries are present and
   all 190 entries that carry a SHA1 match byte for byte (`fetch_blobs.sh` pins it).
   The camera blobs differ per variant: Sony (xx) uses `B08QT_*` / `libmmcamera_imx175.so`,
   Samsung (jv) uses `E08QL_*` / `libmmcamera_s5k4h5yb.so`, and `liboemcamera.so` and the ISP
   modules also differ. A ROM built for the wrong variant loads the wrong camera libraries.
   Branches 19.1 and later of that repo no longer carry these devices.

## Order of work (on a real build machine)

1. Run `setup_tree.sh`. It syncs LOS 23.2 and forks the 21.0 trees to local `lineage-23.2` branches.
2. Run `fetch_blobs.sh` (no phone extraction needed for the blobs). Port `extract-files` / `setup-makefiles` to Python only if you want to re-extract.
3. Get the **kernel** compiling and booting first (3.4 + BPF branch, SELinux permissive).
   The Galaxy S2 Android 16 build on XDA does exactly this and boots, with lag and random crashes.
4. Rebase the `vendor/lineage` additions from item 2 onto 23.2, one flag at a time.
5. Replace the LD shim (item 1). Fix the HIDL/AIDL manifests (`manifest.xml`, `compatibility_matrix.xml`).
6. First boot: Wi-Fi, touch, display. Then audio, RIL, sensors, then camera (item 3).
7. SELinux: permissive first, then write the missing policy from `audit2allow` logs.

## What I need from you to continue

- A build machine (the LineageOS wiki asks for 64 GB RAM for lineage-21 and up, plus a lot of free disk).
- `adb logcat -b all` and `dmesg` after each boot attempt.
- Your exact variant (Sony or Samsung camera sensor, single or dual SIM).

## Findings from the dependency pass (verified against GitHub on 2026-10-03)

- LOS 23.2 `default.xml` keeps only `hardware/qcom/wlan` from the legacy qcom set; LOS 21.0 also carried
  `hardware/qcom/{audio,bt,camera,display,gps,media,...}`. The manifest therefore pins them explicitly at the newest
  plain branch that exists: audio 23.2, display 22.2, media 22.2, gps 23.0, camera 22.2, bt 23.0.
  Whether the 22.2-era display/media/camera code still compiles on Android 16 is unknown.
- `android_device_samsung_qcom-common` has no 23.x branch (last: lineage-22.2). Pinned to 22.2.
- `msm8226-common` includes `device/qcom/sepolicy-legacy/sepolicy.mk`; the only "-legacy" (non-um) policy branch left
  upstream is `lineage-18.1-legacy`. Pinned to it. Expect SELinux work (SELinux is permissive in the S2 Android 16 port).
- GCC 4.9 is not in the 23.2 default manifest (only host gcc). The kernel-3.4 toolchain prebuilt is added to the
  manifest; the kernel compiled in the sandbox with exactly that branch (lineage-19.1).
- Build host: free runner for a public repo = 4 vCPU / 16 GB / 14 GB disk, 6 h per job, 10 GB cache per repo.
  `analyze` mode (`m nothing`) is the fast loop; a cold full build may not fit in one 6 h job.

## Static pass 2: boot image, shim, vndk (verified in sources 2026-10-03, patches tested to apply on pristine repos)

Fixed by `patches/` (each patch applies cleanly with `git am` on the upstream branch; none has been compiled):
1. **Boot image / device tree.** s3ve3g-common sets `BOARD_CUSTOM_BOOTIMG_MK := hardware/samsung/mkbootimg.mk`; that file
   exists up to lineage-23.0 and is gone in 23.2, so the include would fail. LOS 21.0 `core/Makefile` also added
   `--dt dt.img` to the boot/recovery mkbootimg args for `BOARD_KERNEL_SEPARATED_DT`; 23.2 does not.
   -> `patches/build_make` restores those lines, `patches/device_samsung_s3ve3g-common` drops the custom-bootimg lines.
   The manifest adds `system/tools/dtbtool` (builds `dtbToolLineage`, newest branch lineage-18.1) and pins LineageOS'
   `system/tools/mkbootimg` fork at lineage-21.0 (23.2 uses plain AOSP mkbootimg, which has no `--dt`).
2. **LD shim.** `TARGET_LD_SHIM_LIBS` (libperipheral_client.so -> libshim_binder.so) is removed from the board config;
   `scripts/fetch_blobs.sh` runs `patchelf --add-needed libshim_binder.so` on the blob (tested on the real blob with patchelf 0.18.0).
3. **VNDK v29.** `msm8226.mk` copies two libs from `prebuilts/vndk/v29`; LOS 23.2 keeps only v31-v34.
   `scripts/vendor_vndk29.sh` fetches the two files from AOSP tag android-14.0.0_r67 (the tag LOS 21.0 used) and the patch
   points `msm8226.mk` at them. Not run here: android.googlesource.com is not reachable from my sandbox.
4. **hardware/samsung** added to the manifest (not in the 23.2 default.xml; `qcom-common` depends on it).

## NOT solved (these will need log-driven iteration, or may not be solvable)

- **Camera.** Legacy HAL1 path (`CameraWrapper.cpp`, `TARGET_HAS_LEGACY_CAMERA_HAL1`): no consumer found in upstream 21.0 or 23.2.
  Without it the camera will not work on Android 16. This is the part the original request cares most about.
- **Process SDK overrides** (`mediaserver=22`, `mm-qcamera-daemon=22`, `rild=27`): `TARGET_PROCESS_SDK_VERSION_OVERRIDE` has no
  consumer in upstream 23.2 (and none in upstream 21.0 either; html6405's own vendor/lineage fork provides it).
- **mkbootimg 21.0 fork vs Android 16 releasetools**: compatibility unknown.
- **SELinux**: `device/qcom/sepolicy-legacy` pinned to the old `lineage-18.1-legacy` branch; Android 16 neverallow rules will likely reject it.
- **Kernel in the Android 16 build**: compiles standalone with GCC 4.9 (done in the sandbox); how LOS 23.2's kernel build step
  picks the toolchain for this tree is untested.
- **Memory/time**: 16 GB runner vs the 64 GB the wiki asks for.

## Static pass 3: camera HAL1, LED, NFC (verified in sources 2026-10-03; nothing compiled)

**Camera HAL1 on Android 16.** Upstream LOS 23.2 `frameworks/av` has no HAL1 client (`device1/`, `api1/CameraClient`): the
html6405 Android 14 build carried its own patches. A HAL1 restoration for Android 15 exists in a third-party fork
(`Oichkatzelesfrettschen/android_frameworks_av` and `_base`, branch `lineage-22.2-m8`, merged Sep 2026; it builds on the
LineageOS-UL work). Its `lineage-23.2` branches are identical to upstream, so I ported the camera-only part myself:
- `patches/frameworks_av`: 23 files. Applies cleanly to upstream 23.2 (`b6b36c1`). `rotationOverride` was replaced by
  `CameraCompatibilityInfo` (the 23.2 API) in `Camera::connect`, `CameraService::makeClient`, `CameraClient`, `HidlDeviceInfo1::getCameraInfo`.
- `patches/frameworks_base`: 29 files (camera2 LEGACY shim + JNI), 4 conflicts resolved by hand, same API change. The fork's
  unrelated edits (EdgeEffect, RippleDrawable, ProcessList, Zygote, Gnss, BatterySaver) are deliberately NOT included.
- `patches/device_samsung_msm8226-common/0002`: `soong_config_set,camera,legacy_hal1,true`; `CameraWrapper` now reports module
  API 2.4 and implements `set_callbacks()` + `set_torch_mode()` (writes `/sys/class/leds/torch-light/brightness`, from the
  `msm_led_torch` kernel driver) because the HIDL legacy provider only forwards torch to modules >= 2.4.
- Properties used by the ported code: `ro.camera.legacy_camera2_shim` (camera2 apps on a HAL1-only camera), `ro.camera.record_force_yuv`,
  `debug.camera.legacy_record_stream`. None is set in the device tree yet; set `ro.camera.legacy_camera2_shim=true` in `system.prop`
  if camera2-only apps must work.
- Unknown: whether any of this compiles against all of 23.2; whether it works on the Sony IMX175 / Samsung S5K4H5YB / front S5K6A3YX blobs.
- Trust: this replaces core framework code with a third party's work (Apache-2.0 derivative). It is in `patches/` as plain diffs: read it before you flash.

**Charging/notification LED.** 23.x removed `TargetSpecificHeaderPath` from build/make and build/soong (present in 21.0), so
`hardware/samsung/aidl/light` (`android.hardware.light-service.samsung`) could not find `samsung_lights.h`.
`patches/device_samsung_s3ve3g-common/0002` sets `SOONG_CONFIG_samsungVars_target_specific_header_path`. The LED node
`/sys/class/sec/led/led_blink` is exposed by `leds-an30259a`, which the S3 Neo defconfig enables.

**NFC.** `nfc_nci.msm8226` and `android.hardware.nfc@1.0-impl/-service` no longer exist; `hardware/nxp/nfc` 23.2 builds
`android.hardware.nfc@1.2-service` (pn8x; PN547C2 supported, `NXP_FW_NAME=libpn547_fw.so`). Same patch switches the device to it,
declares 1.2 in `nfc/manifest.xml`, drops `NfcNci` (23.2 `base_system.mk` adds the NFC stack itself) and also installs
`libnfc-nxp.conf` in `/vendor/etc`. Unknown: that the old pn547 conf keys are accepted by the pn8x HAL and that `/dev/pn547` exists (the kernel registers a misc device in `drivers/nfc/pn544.c`).

**Still open:** process SDK overrides (mediaserver/mm-qcamera-daemon/rild), legacy SELinux policy, `device_perms.h` (property perms via init),
mkbootimg fork vs Android 16 releasetools, kernel toolchain wiring in the 23.2 build.

# Porting notes — Alch3myOS 17 untuk lynx

Dibuat 2026-11-22, dari komparasi langsung `device_google_lynx` branch `16`
vs `device_google_grizzly` branch `17`.

## Komparasi lynx vs grizzly

- **lynx = Pixel 7a**, Tensor G2 (`gs201`), kernel **6.1**, Android **16**,
  branch cuma `16`, commit terakhir 2026-06-07
- **grizzly = Pixel 11 Pro**, keluarga `malibu`, kernel **6.12**,
  Android **17**, branch cuma `17`, commit terakhir 2026-11-18

## Yang disamakan dengan grizzly (struktur produk)

- Product file baru `alch3my_lynx.mk`, inherit
  `vendor/alch3my/config/common_full_phone.mk` (dulu `vendor/lineage/...`)
- Flag: `WITH_GMS=true`, `IS_PIXEL`, `TARGET_HAS_UDFPS`,
  `TARGET_SUPPORTS_QUICK_TAP`, `TARGET_FACE_UNLOCK_SUPPORTED`,
  `TARGET_SUPPORTS_GFU` — UDFPS terkonfirmasi dari `lynx/vendor.prop`
  (`persist.vendor.udfps.*`)
- `PRODUCT_NAME=alch3my_lynx`, `PRODUCT_SYSTEM_BRAND=google`,
  `PRODUCT_SYSTEM_NAME=generic_system_google`
- `AndroidProducts.mk`: `aosp_lynx` + `alch3my_lynx` (bukan `lineage_lynx`)
- `aosp_lynx.mk`: model `Pixel 7a`, brand `google`, + field
  `*_FOR_ATTESTATION`
- `ALCH3MY_BUILD_TYPE := UNOFFICIAL` di draft (grizzly `OFFICIAL` —
  jangan ubah ke OFFICIAL tanpa pengesahan Pyrtle / Alch3myOS)
- Lunch target baru: `alch3my_lynx-bp4a-user`

## Yang WAJIB tetap lynx

- Keluarga SoC `gs201`, **bukan** `malibu`
- Kernel 6.1 (`device/google/lynx-kernels/6.1`, prebuilt `Image.lz4`),
  **bukan** 6.12. CATATAN 2026-11-23 (koreksi user): ZIP PenguinOS
  Obscura **belum pernah di-flash** — yang sudah terbukti jalan itu
  **Infinity-X 4.2**. Kernel prebuilt 6.1.162 yang dipakai Penguin
  (langkah 11) aslinya disalin dari tree Infinity-X yang sudah
  terbukti boot; salinannya masih ada di
  `/root/penguin/device/google/lynx-kernels/6.1/` (`boot.img` +
  `dtbo.img` + `.ko`), dan itu yang dipakai buat Alch3my. Jadi
  kernelnya terbukti (dari Infinity-X), ZIP Penguinnya yang belum.
- `BoardConfig.mk`: density **420** (grizzly 480), include
  `gs201/BoardConfig-common.mk`, kernel modules, sepolicy vibrator, wifi QCOM
- `device-lynx.mk`: inherit `gs201/common.mk`, SCUDO, recovery, overlay
  `*Lynx` / `*Gs201`, VINTF `manifest.xml` +
  `device_framework_matrix_product.xml`
- Layar **1080 x 2400**
- Overlay About phone sudah benar: `Alch3mySettingsLynx` —
  "Google Pixel 7a / Tensor G2 | Titan M2 / 4350 mAh / 6.1\" OLED 90Hz"

## PR yang tersisa (jangan di-skip)

1. **Fingerprint Android 17 lynx — SELESAI 2026-11-22, lalu DIUBAH.**
   Awalnya `CP3A.261005.002.A1 16269273` dari LOS `lineage-24.0` (commit
   `2621fad`), tapi Pyrtle93 bilang Alch3myOS 17 masih di CP2A — jadi
   di-revert ke **`CP2A.260705.006 15641320`**
   (`google/lynx/lynx:17/CP2A.260705.006/15641320:user/release-keys`,
   plus `BuildSystemDesc` / `BuildSystemFingerprint` dari fix LOS
   `e578eca` dengan nilai CP2A), commit `2b5a720`. SPL ikut turun ke
   `2026-07-05`, vendor svn `82`.
2. **Vendor blob lynx 17 — SELESAI 2026-11-22.** `vendor/google/lynx/lynx-vendor.mk`
   wajib ada. Di org Alch3myOS-Devices tidak ada `vendor_google_lynx`.
   Pyrtle93 (09:23 WIB): "update vendor as well". Fork
   `hiemzalhuda/proprietary_vendor_google_lynx` branch `17`, commit
   `29435f5`: base TheMuppets `bc235c1` (CP2A, Agu 2026) + commit
   22 Okt `google_build.xml` dan rust pin CP2A; update CP3A 15 Okt
   TIDAK ikut. `lynx.xml` sudah diarahkan ke fork ini.
3. **gs-common — SELESAI, TIDAK DIPERLUKAN (dicek 2026-11-23, jangan
   tunggu gagal).** Tidak ada branch `lineage-24.0` di mana pun, tapi
   ternyata memang tidak dibutuhkan: manifest Lineage 24.0 sendiri
   tidak include gs-common, manifest Alch3my juga tidak, dan semua
   file device bersih dari referensi gs-common (`common.mk`,
   `device-lynx.mk`, `BoardConfig-common.mk`, `lynx/BoardConfig.mk`
   — grep 23 Nov 2026, nol hasil). Satu-satunya hit cuma nama blob
   `android.hardware.power.stats-impl.gs-common.so` di
   `proprietary-files-vendor.txt`, dan blob itu ADA di vendor fork
   kita (cek API 200). Jadi item ini DITUTUP — tidak perlu port/pin.
   Fallback kalau ternyata nanti tetap butuh: branch `lineage-23.2`
   masih ada di `LineageOS/android_device_google_gs-common`.
4. **gs201 / lynx-kernels di org Alch3my.** Cuma branch `16`, jadi
   `lynx.xml` memakai LineageOS `lineage-24.0` (terverifikasi ada).
5. **Maintainer.** Grizzly set `ro.alch3my.maintainer=Pyrtle93` di
   `device-grizzly.mk`. Lynx belum punya baris ini — jangan tempel nama
   Pyrtle ke lynx.
6. **Sepolicy & VINTF gaya 17.** Grizzly pakai `sepolicy/private` +
   `sepolicy/vendor` dan `vintf/qfp_framework_matrix_system_ext.xml`;
   lynx 16 masih `sepolicy/vendor` saja + `vintf/manifest.xml`.
   Biarkan error build yang menunjukkan apa yang kurang.
7. **Face Unlock / GFU.** Pixel 7a mendukung face unlock di stock, flag
   ikut grizzly di draft. Kalau di boot pertama bermasalah, hapus
   `TARGET_SUPPORTS_GFU := true` dulu.

## Audit persiapan vs repo yang sudah terbukti build (23 Nov 2026)

User minta dicek ulang semua hal yang bisa bikin gagal, dengan patokan
`penguin-lynx-build` (penguin-setup.sh langkah 1–23) dan
`infinity-lynx-build` (Infinity-X 4.2, sudah di-flash dan jalan).
Hasilnya — yang AMAN, yang DIPERBAIKI, yang masih WASPADA:

### Aman — tidak perlu diapa-apakan
- **QCOM hide/guard (Penguin 8–10):** tidak berlaku. Manifest Alch3my
  tidak punya `vendor/qcom` sama sekali (cuma `hardware/qcom/wlan` yang
  memang dibutuhkan + display/gps SoC lain + `device/qcom/sepolicy`),
  jadi `kernel_definitions.mk` yang bikin dtb.img duplikat tidak ada.
- **Rust graft (Penguin 3, 12):** Lineage sudah punya case
  `prebuiltBinaryDecorator` di `getSymbolInfo()`/`IsPrebuilt()` —
  Infinity-X membuktikannya. Tidak ada patch Soong yang dibutuhkan.
- **Sepolicy pixel (Penguin 13, 15, 16):** tidak berlaku.
  `hardware/google/pixel-sepolicy` ADA di manifest Alch3my
  (`snippets/lineage.xml:59`) — `alch3my-setup.sh` memverifikasi
  direktori ini benar-benar ke-sync.
- **libsepol block (Penguin 14):** khusus AOSPA, Lineage tidak punya.
- **Radio sha1 (Penguin 17):** fungsi `add-radio-file-sha1-checked`
  ADA di `vendor/alch3my/build/core/utils.mk:102`.
- **VINTF AIDL (Penguin 18):** tidak berlaku. Matrix fork
  (`vintf/device_framework_matrix_product.xml`, 6 HAL) sama persis
  dengan LOS 24.0 — bedanya cuma versi HAL (6-7 vs 7-8, 2 vs 2-3),
  itu efek CP2A vs CP3A yang memang disengaja. IGloveMode /
  ISupplicantVendor tidak ada di matrix produk maupun LOS 24.0 —
  mereka dicocokkan lewat framework matrix, dan Lineage lynx lolos
  VINTF dengan matrix ini.
- **AndroidProducts (Penguin 20):** fork sudah mendaftarkan
  `alch3my_lynx.mk` ✓.
- **gs-common:** DITUTUP 23 Nov — manifest Lineage 24.0 sendiri tidak
  include gs-common, semua file device bersih, satu-satunya hit cuma
  nama blob yang ada di vendor fork.

### Diperbaiki di audit ini (23 Nov 2026)
- **Kernel prebuilt (Penguin 11) — DIPERBAIKI.** Repo `lynx-kernels`
  24.0 terverifikasi hanya 9 file config (tanpa `.ko`/`boot.img`/
  `dtbo.img`). `alch3my-setup.sh` lama malah ngecek `Image.lz4` yang
  tidak pernah ada — diperbaiki: cek `boot.img` + `dtbo.img`, dan bila
  hilang salin dari `/root/penguin/device/google/lynx-kernels/6.1/`
  (kernel 6.1.162 dari Infinity-X 4.2 yang sudah terbukti boot).
  Catatan koreksi user: yang terbukti itu Infinity-X, ZIP Penguin
  belum pernah di-flash — kernelnya terbukti, ZIP-nya belum.
- **Lunch target — DIPERBAIKI (belum terverifikasi).** `alch3my_lynx-bp4a-user`
  di README/skrip lama TIDAK punya dasar: repo yang terbukti build
  pakai tanpa `-bp4a-` (`infinity_lynx-user`, `aospa_lynx-userdebug`).
  `scripts/build-alch3my-lynx.sh` sekarang coba kandidat berurutan
  (`-user`, `-userdebug`, `-bp4a-user`, `-bp4a-userdebug`) dan pakai
  yang lolos; `alch3my-setup.sh` tidak lagi mengklaim satu target.
- **Duplikat GMS (Penguin 21–23) — WASPADA, dicek otomatis.**
  `vendor/gms` ADA di manifest Alch3my (`Alch3myOS/vendor_gms`) jadi
  risiko yang sama ada. `alch3my-setup.sh` sekarang: sembunyikan
  overlay GMS duplikat (`.find-ignore`), hapus prebuilt duplikat dari
  `vendor/google/lynx/Android.bp`, dan ingatkan bila 5 aplikasi GMS
  belum `product_specific`.
- **gen_mterp.py Python 3.10 (Penguin 19) — DIPERBAIKI.**
  `alch3my-setup.sh` sekarang menambal f-string Python 3.12 di
  `art/runtime/interpreter/mterp/gen_mterp.py` bila ditemukan (logika
  persis `patches/gen_mterp_py310.py` Penguin).
- **Manifest duplikat (23 Nov):** `lynx.xml` sempat menambahkan
  `hardware/google/pixel` yang sudah ada di manifest bawaan —
  sync gagal "duplicate path". Dihapus dari `lynx.xml`.

### Masih waspada (tidak bisa dicek sebelum build)
- JDK: Infinity-X jalan dengan JDK bawaan tree; bila `guice_munge`
  gagal `UnsupportedClassVersionError`, pakai prebuilt JDK 21
  (`prebuilts/jdk/jdk21/...`) di PATH seperti Penguin langkah 17
  (versi JDK di sana).
- Heap KSP: bila KSP SystemUI-core OOM, jangan naikkan heap lewat
  `rom-build.sh`/siso (tidak sampai ke KSP) — pakai direct ninja
  dengan `JAVA_TOOL_OPTIONS` ter-export, seperti Penguin.

## Riwayat

- 2026-11-22 06:44 WIB: user tanya Pyrtle93 di grup Alch3myOS Discussion
  "is source build able sar?" — dijawab "hold on, pushing bug fixes and
  additions/improvements to UI customizations".
- 2026-11-22 07:46 WIB: Pyrtle sarankan bandingkan lynx dengan grizzly.
- 2026-11-22 08:20 WIB: draft di-push ke fork `hiemzalhuda/device_google_lynx`
  branch `17`, commit `e745851`.
- 2026-11-22: repo persiapan build ini dibuat (`alch3my-lynx-build`).
- 2026-11-22 08:29 WIB: Pyrtle93 balas di DM: "You forgot to add changes
  from los updating trees to 17". Diperbaiki di commit `2621fad` (41 file):
  20 commit LOS `lineage-23.2` → `lineage-24.0` diterapkan — fingerprint
  CP3A, SPL 2026-10-05, vintf, overlay, properties, proprietary files,
  sysconfig, `sepolicy/system_ext`, BoardConfig. File LOS diambil verbatim
  kecuali yang sengaja dipertahankan Alch3my: `device-lynx.mk` (tambah
  `Alch3mySettingsLynx`), `aosp_lynx.mk` (tambah attestation), dan sepolicy
  yang namanya di-rename Alch3my (`hal_face.te` dst — perubahan LOS
  di-port ke file rename itu, bukan di-overwrite; tipe sepolicy Alch3my
  didefinisikan di `file.te`, jadi file LOS24 yang mendefinisikan ulang
  tipe yang sama tidak diambil mentah-mentah). `lineage.dependencies`
  tetap dihapus seperti di Alch3my 16.
- 2026-11-22 08:41 WIB: Pyrtle93: "drop the cp3a stuff haha still on
  cp2a". Diperbaiki commit `2b5a720`: fingerprint/SPL/svn/proprietary
  files/vintf/sysconfig di-revert ke state LOS CP2A (`a9af2a0`, Agu 2026).
  Yang sengaja dipertahankan: rust pin ke CP2A.260705.006, entri
  `google_build.xml`, dan config face-unlock di overlay (bukan blob CP3A).

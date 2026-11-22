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
- Kernel **6.1** (`device/google/lynx-kernels/6.1`, prebuilt `Image.lz4`),
  **bukan** 6.12
- `BoardConfig.mk`: density **420** (grizzly 480), include
  `gs201/BoardConfig-common.mk`, kernel modules, sepolicy vibrator, wifi QCOM
- `device-lynx.mk`: inherit `gs201/common.mk`, SCUDO, recovery, overlay
  `*Lynx` / `*Gs201`, VINTF `manifest.xml` +
  `device_framework_matrix_product.xml`
- Layar **1080 x 2400**
- Overlay About phone sudah benar: `Alch3mySettingsLynx` —
  "Google Pixel 7a / Tensor G2 | Titan M2 / 4350 mAh / 6.1\" OLED 90Hz"

## PR yang tersisa (jangan di-skip)

1. **Fingerprint Android 17 lynx — BELUM ADA.** Di `alch3my_lynx.mk`
   masih `TODO_17_BUILD_ID` / `TODO_17_BUILD_NUMBER`. Isi dari stock
   Android 17 factory image / vendor blob lynx yang dipakai.
2. **Vendor blob lynx 17.** `vendor/google/lynx/lynx-vendor.mk` wajib ada.
   Di org Alch3myOS-Devices tidak ada `vendor_google_lynx`;
   `lynx.xml` memakai TheMuppets `proprietary_vendor_google_lynx`
   branch `lineage-24.0` (terverifikasi ada).
3. **gs-common.** Tidak ada branch `lineage-24.0` di mana pun
   (LineageOS dan Alch3myOS-Devices mentok `lineage-23.2`).
   `lynx.xml` sengaja tidak memasukkannya; bila build gagal karena file
   gs-common hilang, port atau pin `23.2` dan uji.
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

## Riwayat

- 2026-11-22 06:44 WIB: user tanya Pyrtle93 di grup Alch3myOS Discussion
  "is source build able sar?" — dijawab "hold on, pushing bug fixes and
  additions/improvements to UI customizations".
- 2026-11-22 07:46 WIB: Pyrtle sarankan bandingkan lynx dengan grizzly.
- 2026-11-22 08:20 WIB: draft di-push ke fork `hiemzalhuda/device_google_lynx`
  branch `17`, commit `e745851`.
- 2026-11-22: repo persiapan build ini dibuat (`alch3my-lynx-build`).

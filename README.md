# alch3my-lynx-build

Porting **Alch3myOS** (Android 17, branch `17`) ke **Pixel 7a (`lynx`)** —
unofficial, bukan build resmi Alch3myOS.

Repo ini adalah lapisan persiapan build, meniru pola `penguin-lynx-build`
dan `infinity-lynx-build`: semua yang spesifik buat `lynx` ada di sini,
tree upstream tetap di-sync dari sumber aslinya tiap rebuild. Tidak ada
kunci signing, tidak ada blob proprietary, dan tidak ada file ZIP di repo ini.

## Status

- **Repo dibuat:** 22 Nov 2026, publik, `hiemzalhuda/alch3my-lynx-build`
- **Target:** Pixel 7a (`lynx`), Tensor G2 (`gs201`), Android 17
- **Basis:** Alch3myOS `17` (`android-17.0.0_r1` + `lineage-24.0`), fork dari Lunaris-AOSP / LineageOS
- **Build pertama:** belum jalan. Draft device tree sudah di-push ke fork
  `hiemzalhuda/device_google_lynx` branch `17`, commit `e745851`.
- **Server:** jangan sync/build sekarang — server UpCloud lagi rebuild
  PenguinOS (Obscura) dan disk tinggal ~19 GB (22 Nov 2026 pagi).

## Kenapa ini porting, bukan build resmi

Upstream Alch3myOS tidak menyediakan `lynx` buat Android 17:
`Alch3myOS-Devices/device_google_lynx` cuma punya branch `16`
(Android 16, commit terakhir 7 Jun 2026), dan semua device Tensor lain
juga mentok di `16`. Yang punya branch `17` cuma device generasi baru,
misalnya `grizzly` (Pixel 11 Pro). Maintainer Alch3myOS, Pyrtle93,
menyarankan di grup Alch3myOS Discussion (22 Nov 2026): bandingkan `lynx`
dengan `grizzly` dan buat keduanya "pretty much identical" — yang
disamakan adalah struktur file produk, bukan isi hardware.

## Isi repo

| File | Fungsi |
| --- | --- |
| `lynx.xml` | Local manifest: device tree (fork branch 17), gs201, kernel prebuilt, vendor blob `lynx`, hardware/google/pixel — semua di-pin ke `lineage-24.0`, kecuali device tree |
| `device/alch3my_lynx.mk` | Product makefile baru `alch3my_lynx`, pola `alch3my_grizzly.mk`. Sudah ada di fork device tree; file di sini salinan referensi |
| `device/AndroidProducts.mk` | Registrasi product makefile (`aosp_lynx`, `alch3my_lynx`) |
| `device/aosp_lynx.mk` | Identitas produk `Pixel 7a` / brand `google`, hardware tetap `gs201` |
| `alch3my-setup.sh` | Cek pasca-sync buat `lynx` (fingerprint, vendor, branch) — jalankan sebelum build |
| `scripts/build-alch3my-lynx.sh` | Perintah build low-RAM: `alch3my_lynx-bp4a-user`, `m bacon`, `-j2` |
| `docs/01-porting-notes.md` | Catatan porting: komparasi lynx vs grizzly, apa yang disamakan, apa yang tetap lynx, dan PR yang tersisa |

## Cara build (ringkas)

```
repo init -u https://github.com/Alch3myOS/android -b 17 --git-lfs
cp lynx.xml .repo/local_manifests/lynx.xml
repo sync -c --force-sync -j$(nproc --all)
./alch3my-setup.sh
source build/envsetup.sh
lunch alch3my_lynx-bp4a-user
m bacon
```

Detail lengkap (termasuk PR fingerprint, vendor, gs-common, dan gerbang
sebelum flash) ada di `docs/01-porting-notes.md`.

Aturan build yang berlaku di sini, sama seperti Infinity-X / PenguinOS:

- Build pertama vanilla dulu, `userdebug` bila tersedia, `-j2` — memisahkan
  kegagalan porting dari konflik GMS.
- Bila OOM, ulang `-j1`, tanpa `make clean`, tanpa hapus tree.
- Signing pertama pakai testkeys. Kunci privat hanya bila build ini
  diputuskan layak jadi daily driver, dengan gerbang yang sama seperti
  Infinity-X: sertifikat OTA kunci privat, release-keys, fingerprint
  stock, plus backup data + stock factory image siap sebelum flash apa pun.
- Jangan push GitHub tanpa perintah eksplisit user.

## Kredit

- [Alch3myOS](https://github.com/Alch3myOS/android) — Alch3myOS (Apache-2.0)
- [Pyrtle93](https://github.com/Pyrtle93) — maintainer Alch3myOS seri Pixel, saran porting lynx-vs-grizzly
- [Lunaris-AOSP](https://github.com/Lunaris-AOSP/android) — basis upstream Alch3myOS
- LineageOS — device tree `lynx` + `gs201`, kernel prebuilt
- TheMuppets — vendor blob `lynx`

## Lisensi

Kode Alch3myOS / LineageOS memakai Apache License 2.0. File adaptasi di
repo ini mengikuti lisensi yang sama.

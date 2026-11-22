#!/bin/bash
# alch3my-setup.sh — cek pasca-sync buat lynx (Alch3myOS 17).
# Jalankan dari source root setelah `repo sync`, sebelum lunch.
# Skrip ini hanya MEMERIKSA, tidak mengubah tree (kecuali bila
# device tree fork belum dipakai — lihat pesan di bawah).
# Keluar 1 bila ada cek yang gagal, supaya build tidak jalan buta.
set -u
fail=0
say() { echo "[alch3my-setup] $*"; }
bad() { echo "[alch3my-setup] GAGAL: $*"; fail=1; }
ok()  { echo "[alch3my-setup] OK: $*"; }

[ -f device/google/lynx/alch3my_lynx.mk ] && ok "device/google/lynx/alch3my_lynx.mk ada" || bad "device/google/lynx/alch3my_lynx.mk tidak ada — cek lynx.xml, device tree harus fork hiemzalhuda branch 17"
[ -f device/google/lynx/lineage_lynx.mk ] && bad "lineage_lynx.mk masih ada — harusnya sudah diganti alch3my_lynx.mk" || ok "lineage_lynx.mk sudah tidak ada"
[ -f device/google/gs201/aosp_common.mk ] && ok "device/google/gs201 ada" || bad "device/google/gs201 tidak ada — cek lynx.xml"
[ -f device/google/lynx-kernels/6.1/Image.lz4 ] && ok "kernel prebuilt 6.1 ada" || bad "kernel prebuilt 6.1 tidak ada — cek lynx.xml / device/google/lynx-kernels"
[ -f vendor/google/lynx/lynx-vendor.mk ] && ok "vendor/google/lynx ada" || bad "vendor/google/lynx tidak ada — cek lynx.xml (TheMuppets lineage-24.0)"
grep -q "TODO_17_BUILD" device/google/lynx/alch3my_lynx.mk 2>/dev/null && bad "fingerprint masih TODO_17_BUILD_ID — isi dulu BuildDesc/BuildFingerprint Android 17 lynx yang asli, jangan build dengan TODO" || ok "fingerprint sudah bukan TODO"
grep -q "vendor/alch3my/config/common_full_phone.mk" device/google/lynx/alch3my_lynx.mk 2>/dev/null && ok "inherit vendor/alch3my benar" || bad "alch3my_lynx.mk tidak inherit vendor/alch3my"
[ -d vendor/alch3my ] && ok "vendor/alch3my ada (manifest branch 17)" || bad "vendor/alch3my tidak ada — repo init harus -b 17 dari Alch3myOS/android"

if [ "$fail" -ne 0 ]; then
  say "Ada cek yang gagal. Perbaiki dulu, lihat docs/01-porting-notes.md."
  exit 1
fi
say "Semua cek lolos. Lanjut: source build/envsetup.sh && lunch alch3my_lynx-bp4a-user && m bacon"

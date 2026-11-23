#!/bin/bash
# build-alch3my-lynx.sh — build Alch3myOS 17 untuk lynx, mode hemat resource.
# Jalankan dari source root, setelah ./alch3my-setup.sh lolos.
# -j2, tanpa Soong ulang bila restart (pakai direct ninja bila perlu,
#  lihat pola infinity-lynx-build). Jangan make clean bila OOM — ulang -j1.
#
# Lunch target TIDAK di-hardcode: repo Infinity-X/Penguin yang sudah
# terbukti build pakai TANPA -bp4a- (infinity_lynx-user,
# aospa_lynx-userdebug), sementara Lineage pakai lineage_lynx-bp4a-*.
# Skrip ini coba kandidat yang masuk akal berurutan dan pakai yang lolos.
set -e
[ -f build/envsetup.sh ] || { echo "Jalankan dari source root Alch3myOS (build/envsetup.sh tidak ketemu)"; exit 1; }

# --- METODE HEMAT RAM (pelajaran PenguinOS, server 8 GB — JANGAN DIHAPUS) ---
# 1. zram 4G (zstd, prioritas 100) WAJIB aktif sebelum build. Di server
#    UpCloud ini zram sudah aktif sejak 14 Nov 2026; cek di sini supaya
#    kalau server pernah reboot/replace, build tidak jalan tanpa zram.
# 2. Heap KSP: JAVA_TOOL_OPTIONS -Xmx8192m. Heap naik SAJA tidak cukup —
#    di Penguin, siso/rom-build.sh tidak meneruskan heap ke JVM KSP
#    (tidak ada baris 'Picked up JAVA_TOOL_OPTIONS' di log); heap hanya
#    sampai lewat direct ninja. Jadi: m bacon dulu (jalur Lineage biasa
#    plain ninja); bila gagal OOM di KSP SystemUI, JANGAN make clean —
#    lanjut direct ninja -j1 dengan OUT_DIR ter-export (lihat bawah).
# 3. -j2; bila OOM, ulang -j1 tanpa make clean dan tanpa hapus tree.
if ! swapon --show 2>/dev/null | grep -q '^/dev/zram'; then
  if [ "$(id -u)" = 0 ] && modprobe zram 2>/dev/null; then
    echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || true
    echo 4294967296 > /sys/block/zram0/disksize
    mkswap /dev/zram0 >/dev/null 2>&1
    swapon -p 100 /dev/zram0
    echo "zram 4G diaktifkan (prioritas 100)"
  else
    echo "PERINGATAN: zram belum aktif dan tidak bisa diaktifkan otomatis — aktifkan manual sebelum build!" >&2
  fi
else
  echo "zram aktif: $(swapon --show 2>/dev/null | grep '^/dev/zram' | awk '{print $3" (prio "$5")"}')"
fi
export JAVA_TOOL_OPTIONS="-Xmx8192m"
export OUT_DIR="$PWD/out"
# shellcheck disable=SC1091
source build/envsetup.sh
LUNCHED=""
for t in alch3my_lynx-user alch3my_lynx-userdebug alch3my_lynx-bp4a-user alch3my_lynx-bp4a-userdebug; do
  if lunch "$t" >/tmp/lunch-alch3my.log 2>&1; then
    LUNCHED="$t"
    echo "lunch OK: $t"
    break
  fi
done
[ -n "$LUNCHED" ] || { echo "Semua kandidat lunch gagal — jalankan 'lunch' manual dan lihat daftar combo. Log terakhir:"; tail -5 /tmp/lunch-alch3my.log; exit 1; }
# Bila build ini gagal OOM (khususnya KSP SystemUI-core), JANGAN make clean:
# lanjut direct ninja dari titik gagal (heap sudah ter-export di atas):
#   ninja -j1 -C "$OUT_DIR" bacon
# atau target OTA: ninja -j1 -C "$OUT_DIR" otapackage
m bacon -j2

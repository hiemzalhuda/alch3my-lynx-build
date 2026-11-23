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
m bacon -j2

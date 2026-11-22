#!/bin/bash
# build-alch3my-lynx.sh — build Alch3myOS 17 untuk lynx, mode hemat resource.
# Jalankan dari source root, setelah ./alch3my-setup.sh lolos.
# -j2, tanpa Soong ulang bila restart (pakai direct ninja bila perlu,
#  lihat pola infinity-lynx-build). Jangan make clean bila OOM — ulang -j1.
set -e
cd "$(dirname "$0")/.." 2>/dev/null || true
# Skrip ini diasumsikan dijalankan dari source root; bila tidak, berhenti.
[ -f build/envsetup.sh ] || { echo "Jalankan dari source root Alch3myOS (build/envsetup.sh tidak ketemu)"; exit 1; }
# shellcheck disable=SC1091
source build/envsetup.sh
lunch alch3my_lynx-bp4a-user
m bacon -j2

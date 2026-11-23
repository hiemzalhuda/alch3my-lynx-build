#!/bin/bash
# alch3my-setup.sh — cek + perbaikan pasca-sync buat lynx (Alch3myOS 17).
# Jalankan dari source root setelah `repo sync`, sebelum lunch.
# Skrip ini MEMERIKSA, dan untuk tiga masalah yang sudah terbukti
# membunuh build PenguinOS/Infinity-X (kernel prebuilt, gen_mterp.py
# Python 3.10, duplikat GMS) ia MEMPERBAIKI langsung bila ditemukan —
# idempotent, aman dijalankan ulang. Keluar 1 bila ada cek yang gagal.
set -u
fail=0
say() { echo "[alch3my-setup] $*"; }
bad() { echo "[alch3my-setup] GAGAL: $*"; fail=1; }
ok()  { echo "[alch3my-setup] OK: $*"; }

[ -f device/google/lynx/alch3my_lynx.mk ] && ok "device/google/lynx/alch3my_lynx.mk ada" || bad "device/google/lynx/alch3my_lynx.mk tidak ada — cek lynx.xml, device tree harus fork hiemzalhuda branch 17"
[ -f device/google/lynx/lineage_lynx.mk ] && bad "lineage_lynx.mk masih ada — harusnya sudah diganti alch3my_lynx.mk" || ok "lineage_lynx.mk sudah tidak ada"
[ -f device/google/gs201/aosp_common.mk ] && ok "device/google/gs201 ada" || bad "device/google/gs201 tidak ada — cek lynx.xml"
[ -f vendor/google/lynx/lynx-vendor.mk ] && ok "vendor/google/lynx ada" || bad "vendor/google/lynx tidak ada — cek lynx.xml (fork branch 17, CP2A)"
grep -q "TODO_17_BUILD" device/google/lynx/alch3my_lynx.mk 2>/dev/null && bad "fingerprint masih TODO_17_BUILD_ID — isi dulu BuildDesc/BuildFingerprint Android 17 lynx yang asli, jangan build dengan TODO" || ok "fingerprint sudah bukan TODO (CP2A.260705.006)"
grep -q "vendor/alch3my/config/common_full_phone.mk" device/google/lynx/alch3my_lynx.mk 2>/dev/null && ok "inherit vendor/alch3my benar" || bad "alch3my_lynx.mk tidak inherit vendor/alch3my"
[ -d vendor/alch3my ] && ok "vendor/alch3my ada (manifest branch 17)" || bad "vendor/alch3my tidak ada — repo init harus -b 17 dari Alch3myOS/android"

# --- Kernel prebuilt (pelajaran Penguin build #21) ---
# Repo Lineage lynx-kernels HANYA berisi file config (.load/.cfg) — .ko /
# boot.img / dtbo TIDAK PERNAH ada di git (.gitignore mengabaikan
# *.img/*.ko). Tanpa boot.img, BOARD_PREBUILT_BOOTIMAGE kosong →
# INSTALLED_BOOTIMAGE_TARGET kosong → target otapackage tidak ada.
# JANGAN cek Image.lz4 — file itu tidak dipakai di sini (kernel prebuilt
# ada di dalam boot.img, TARGET_NO_KERNEL=true).
KDIR="device/google/lynx-kernels/6.1"
if [ ! -f "$KDIR/boot.img" ] || [ ! -f "$KDIR/dtbo.img" ]; then
  if [ -f /root/penguin/device/google/lynx-kernels/6.1/boot.img ]; then
    cp -a /root/penguin/device/google/lynx-kernels/6.1/. "$KDIR"/
    say "kernel prebuilt 6.1.162 disalin dari tree Penguin (salinan kernel Infinity-X 4.2 yang sudah terbukti boot)"
  else
    bad "kernel prebuilt hilang (boot.img/dtbo.img tidak ada) dan salinan di /root/penguin tidak ditemukan — build akan gagal 'unknown target otapackage'. Bangun kernel dari source (manifest android_kernel_google_gs-6.1_manifest, build_lynx.sh) lalu salin ke $KDIR/"
  fi
fi
[ -f "$KDIR/boot.img" ] && [ -f "$KDIR/dtbo.img" ] && ok "kernel prebuilt 6.1 ada (boot.img + dtbo.img + .ko)"

# --- pixel-sepolicy (pelajaran Penguin build #15-16) ---
# BoardConfig lynx merujuk hardware/google/pixel-sepolicy/vibrator/*.
# Di AOSPA repo ini TIDAK ADA di manifest dan build gagal sepolicy;
# di Alch3my repo ini ADA di manifest (snippets/lineage.xml) — verifikasi
# benar-benar ke-sync.
[ -d hardware/google/pixel-sepolicy ] && ok "hardware/google/pixel-sepolicy ada" || bad "hardware/google/pixel-sepolicy tidak ada — cek manifest (snippets/lineage.xml), build akan gagal sepolicy"

# --- gen_mterp.py Python 3.10 (pelajaran Penguin build #19) ---
# art/runtime/interpreter/mterp/gen_mterp.py memakai f-string Python 3.12
# sementara server masih Python 3.10.12 — build gagal di sini. Perbaiki
# bila barisnya ada (logika persis patches/gen_mterp_py310.py Penguin).
GENMTERP="art/runtime/interpreter/mterp/gen_mterp.py"
if [ -f "$GENMTERP" ]; then
  python3 - "$GENMTERP" <<'PYEOF' || bad "gen_mterp.py gagal diperbaiki — cek manual"
import sys
p = sys.argv[1]
old = '''        print(f"{">>" if j == i else "  "}{n:6}: {c}", file=sys.stderr)'''
new = '''        print(f"{'>>' if j == i else '  '}{n:6}: {c}", file=sys.stderr)'''
s = open(p).read()
if new in s:
    print("gen_mterp.py: sudah diperbaiki sebelumnya")
elif old in s:
    assert s.count(old) == 1
    open(p, 'w').write(s.replace(old, new))
    print("gen_mterp.py: f-string Python 3.12 diperbaiki buat Python 3.10")
else:
    sys.exit("neither pattern found — upstream changed gen_mterp.py")
PYEOF
fi

# --- Duplikat GMS (pelajaran Penguin rebuild #21-23) ---
# vendor/gms ADA di manifest Alch3my (Alch3myOS/vendor_gms). Bila update
# GMS menambahkan overlay/prebuilt yang sudah ada di gs201/lynx, Soong
# gagal "found in multiple namespaces". Cek + perbaiki bila ada.
if [ -d vendor/gms/common ]; then
  for ov in GoogleConfigOverlay PixelConfigOverlay2019 PixelConfigOverlay2021 PixelConfigOverlayCommon; do
    if [ -d "vendor/gms/common/$ov" ] && { [ -d "device/google/gs201/overlay/$ov" ] || [ -d "device/google/lynx/overlay/$ov" ]; }; then
      touch "vendor/gms/common/$ov/.find-ignore"
      say "overlay GMS duplikat $ov disembunyikan (.find-ignore), pakai versi gs201/lynx"
    fi
  done
  for mod in DeviceIntelligenceNetworkPrebuiltAstrea TetheringEntitlement; do
    if grep -q "$mod" vendor/gms/common/Android.bp 2>/dev/null && grep -q "$mod" vendor/google/lynx/Android.bp 2>/dev/null; then
      python3 - "$mod" <<'PYEOF'
import re, sys
mod = sys.argv[1]
p = 'vendor/google/lynx/Android.bp'
s = open(p).read()
s2 = re.sub(r'android_app_import\s*\{[^}]*name:\s*"' + re.escape(mod) + r'"[^}]*\}', '', s, flags=re.S)
open(p, 'w').write(s2)
print("removed" if s2 != s else "not-found")
PYEOF
      say "prebuilt duplikat $mod dihapus dari vendor/google/lynx/Android.bp (pakai versi GMS)"
    fi
  done
  for app in GoogleExtShared GooglePrintRecommendationService DocumentsUIGoogle GooglePackageInstaller TagGoogle; do
    python3 - "$app" <<'PYEOF' 2>/dev/null || say "PERHATIAN: $app di vendor/gms/common belum product_specific — bila Soong gagal artifact path, tambahkan product_specific: true ke modul itu (lihat Penguin langkah 23)"
import re, sys
app = sys.argv[1]
s = open('vendor/gms/common/Android.bp').read()
m = re.search(r'android_app_import\s*\{[^}]*name:\s*"' + re.escape(app) + r'"[^}]*\}', s, flags=re.S)
sys.exit(0 if (m and 'product_specific' in m.group(0)) else 1)
PYEOF
  done
  ok "cek duplikat GMS selesai"
fi

if [ "$fail" -ne 0 ]; then
  say "Ada cek yang gagal. Perbaiki dulu, lihat docs/01-porting-notes.md."
  exit 1
fi
say "Semua cek lolos."
say "Lanjut: source build/envsetup.sh && lunch — PILIH variant alch3my_lynx dari daftar (jangan tebak -bp4a-; repo Infinity-X/Penguin yang sudah terbukti build pakai tanpa -bp4a-: infinity_lynx-user, aospa_lynx-userdebug) — lalu m bacon"

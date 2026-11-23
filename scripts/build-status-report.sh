#!/bin/bash
# build-status-report.sh — lapor fase build + estimasi % ke Telegram (ReportBot).
# Dibuat 2026-11-23 buat Alch3my lynx; bisa dipakai build lain via argumen.
#
# Cara pakai:
#   build-status-report.sh [NAMA] [TREE] [SYNC_LOG] [BUILD_LOG]
#   contoh: build-status-report.sh "Alch3my lynx" /root/alch3my /root/alch3my-sync.log
#
# Fase yang dideteksi (berurutan):
#   SELESAI — ZIP ada di out/target/product/lynx/
#   BUILD   — log build ada angka ninja [N/M] → % = N/M
#   GAGAL   — log berisi FAILED / error fatal dan prosesnya mati
#   SOONG   — log build ada tapi belum ada angka ninja
#   SYNC    — proses `repo sync` jalan → % = project ke-sync / total project
#             (estimasi; user bilang estimasi saja tidak apa-apa)
#   IDLE    — tidak ada proses dan tidak ada ZIP (sync belum mulai / berhenti)
#
# Kirim hanya bila: fase berubah, atau % naik >= 5 sejak laporan terakhir,
# atau SELESAI/GAGAL. Jadi tidak spam tiap 30 menit bila tidak ada perubahan.
# Token dibaca dari /root/.telegram-bot-token (mode 600, isi token mentah
# satu baris — JANGAN commit file itu ke mana pun, JANGAN tulis nilainya
# di chat/log). Bila token belum ada, skrip hanya mencetak pesan (dry-run).
# Chat: DM user (ID 438776716, dari @getmyid_bot 20 Nov 2026) — ATAS
# PERINTAH user 23 Nov 2026: jangan ke grup Test Grup.
set -u
NAME="${1:-Alch3my lynx}"
TREE="${2:-/root/alch3my}"
SYNC_LOG="${3:-/root/alch3my-sync.log}"
BUILD_LOG="${4:-}"
STATE="/root/.build-report-state"
TOKEN_FILE="/root/.telegram-bot-token"
CHAT_ID="438776716"
NOW="$(TZ=Asia/Jakarta date '+%H:%M WIB')"

# --- deteksi fase + persen ---
PHASE="IDLE"; PCT=""; DETAIL=""
ZIP="$(ls "$TREE"/out/target/product/lynx/*.zip 2>/dev/null | head -1)"
if [ -n "$ZIP" ]; then
  PHASE="SELESAI"; PCT="100"
  DETAIL="$(du -h "$ZIP" 2>/dev/null | cut -f1) ZIP"
elif [ -n "$BUILD_LOG" ] && [ -f "$BUILD_LOG" ]; then
  LAST="$(grep -o '\[[0-9]*/[0-9]*\]' "$BUILD_LOG" 2>/dev/null | tail -1)"
  if [ -n "$LAST" ]; then
    N="$(echo "$LAST" | tr -d '[]' | cut -d/ -f1)"
    M="$(echo "$LAST" | tr -d '[]' | cut -d/ -f2)"
    PHASE="BUILD"; PCT="$((N * 100 / M))"
    DETAIL="$LAST aksi"
  elif grep -qi "FAILED\|^ninja: error\|FAILED:" "$BUILD_LOG" 2>/dev/null && ! pgrep -f "ninja|mka|bacon" >/dev/null 2>&1; then
    PHASE="GAGAL"; PCT=""
    DETAIL="$(grep -i -m1 'FAILED' "$BUILD_LOG" | cut -c1-120)"
  else
    PHASE="SOONG"; PCT=""
    DETAIL="Soong/Kati, belum ada angka ninja"
  fi
elif pgrep -f "repo/main.py" >/dev/null 2>&1; then
  PHASE="SYNC"
  # % sync = project yang direktori kerjanya sudah ada / total project di
  # manifest (default + snippets + local). .repo/project.list belum ada
  # sebelum sync selesai, jadi daftar path diambil dari file manifest.
  PATHS_TMP="$(mktemp)"
  grep -h -o 'path="[^"]*"' "$TREE/.repo/manifests/default.xml" "$TREE/.repo/manifests/snippets/"*.xml "$TREE/.repo/local_manifests/"*.xml 2>/dev/null | sed 's/path="//;s/"//' | sort -u > "$PATHS_TMP"
  TOTAL="$(wc -l < "$PATHS_TMP")"
  DONE=0
  while IFS= read -r p; do [ -d "$TREE/$p" ] && DONE=$((DONE + 1)); done < "$PATHS_TMP"
  rm -f "$PATHS_TMP"
  if [ "$TOTAL" -gt 0 ]; then
    PCT="$((DONE * 100 / TOTAL))"
    DETAIL="$DONE/$TOTAL project"
  else
    PCT=""
    DETAIL="$(du -sh "$TREE" 2>/dev/null | cut -f1)"
  fi
elif [ -f "$SYNC_LOG" ] && grep -qi "fatal\|^error\|UpdateManifestError" "$SYNC_LOG" 2>/dev/null; then
  PHASE="GAGAL"; PCT=""
  DETAIL="sync: $(grep -i -m1 'fatal\|error' "$SYNC_LOG" | cut -c1-120)"
fi

SIZE="$(du -sh "$TREE" 2>/dev/null | cut -f1)"
FREE="$(df -h / 2>/dev/null | tail -1 | awk '{print $4}')"
[ -n "$PCT" ] && PCT_TXT=" ${PCT}%" || PCT_TXT=""
MSG="$NAME — $PHASE$PCT_TXT
$DETAIL
Tree: $SIZE · Disk sisa: $FREE · $NOW"

# --- kirim hanya bila ada perubahan berarti ---
LAST_PHASE=""; LAST_PCT=""; LAST_SENT=0
[ -f "$STATE" ] && . "$STATE" 2>/dev/null
NOW_EPOCH="$(date +%s)"
SEND=0
[ "$PHASE" != "$LAST_PHASE" ] && SEND=1
if [ -n "$PCT" ] && [ -n "$LAST_PCT" ] && [ "$((PCT - LAST_PCT))" -ge 5 ]; then SEND=1; fi
[ "$PHASE" = "SELESAI" ] || [ "$PHASE" = "GAGAL" ] && SEND=1
[ "$SEND" -eq 0 ] && { echo "skip (tidak ada perubahan): $PHASE$PCT_TXT"; exit 0; }

if [ -f "$TOKEN_FILE" ]; then
  TOKEN="$(head -1 "$TOKEN_FILE" | tr -d '[:space:]')"
  RESP="$(curl -s --max-time 20 -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" --data-urlencode "text=${MSG}" 2>&1)"
  echo "$RESP" | grep -q '"ok":true' && echo "terkirim: $PHASE$PCT_TXT" || { echo "GAGAL kirim Telegram: $RESP"; exit 1; }
else
  echo "DRY-RUN (token belum ada di $TOKEN_FILE) — pesan yang akan dikirim:"
  echo "$MSG"
fi
printf 'LAST_PHASE="%s"\nLAST_PCT="%s"\nLAST_SENT=%s\n' "$PHASE" "$PCT" "$NOW_EPOCH" > "$STATE"

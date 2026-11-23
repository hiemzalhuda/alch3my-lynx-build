#!/usr/bin/env python3
"""bot-status-listener.py — jawab /status di Telegram (long polling getUpdates).

Dibuat 2026-11-23 atas permintaan user: ketik /status di bot, dibalas
laporan build terbaru (paksa kirim via build-status-report.sh + FORCE=1).
Hanya melayani chat DM user (ID 438776716) — perintah dari chat lain
diabaikan. Token dibaca dari /root/.telegram-bot-token (mode 600).

Jalan sebagai systemd service bot-status-listener.service:
  systemctl enable --now bot-status-listener
  journal: /root/bot-listener.log
"""
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

TOKEN_FILE = "/root/.telegram-bot-token"
OFFSET_FILE = "/root/.bot-offset"
REPORT = "/root/build-status-report.sh"
ALLOWED_CHAT = 438776716
API = None


def api(method, **params):
    data = urllib.parse.urlencode(params).encode()
    req = urllib.request.Request(f"{API}/{method}", data=data, method="POST")
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.load(r)


def send(chat_id, text):
    try:
        api("sendMessage", chat_id=chat_id, text=text, parse_mode="HTML")
    except Exception as e:
        print(f"send gagal: {e}", flush=True)


def run_report():
    env = dict(os.environ, FORCE="1")
    try:
        p = subprocess.run(
            [REPORT, "Alch3my lynx", "/root/alch3my", "/root/alch3my-sync.log"],
            env=env, capture_output=True, text=True, timeout=300,
        )
        print(f"report: {p.stdout.strip()} {p.stderr.strip()}", flush=True)
    except Exception as e:
        print(f"report gagal: {e}", flush=True)


def main():
    global API
    with open(TOKEN_FILE) as f:
        token = f.read().strip().splitlines()[0]
    API = f"https://api.telegram.org/bot{token}"
    offset = 0
    if os.path.exists(OFFSET_FILE):
        try:
            offset = int(open(OFFSET_FILE).read().strip() or 0)
        except ValueError:
            offset = 0
    print(f"listener mulai, offset {offset}", flush=True)
    while True:
        try:
            data = api("getUpdates", offset=offset, timeout=25)
        except Exception as e:
            print(f"getUpdates gagal: {e}", flush=True)
            time.sleep(5)
            continue
        for u in data.get("result", []):
            offset = u["update_id"] + 1
            with open(OFFSET_FILE, "w") as f:
                f.write(str(offset))
            msg = u.get("message", {})
            chat = msg.get("chat", {}).get("id")
            text = (msg.get("text") or "").strip()
            if chat != ALLOWED_CHAT or not text:
                continue
            cmd = text.split()[0].lower().split("@")[0]
            if cmd == "/status":
                print(f"/status dari {chat}", flush=True)
                run_report()
            elif cmd == "/start":
                send(chat, "Halo hiemz \U0001f44b\nKetik <b>/status</b> buat cek progres build Alch3my lynx terbaru.")


if __name__ == "__main__":
    main()

#!/usr/bin/env bash
set -Eeuo pipefail

command -v firefox >/dev/null 2>&1 || {
    echo "[ERROR] Firefox no está instalado." >&2
    exit 1
}

command -v ffmpeg >/dev/null 2>&1 || {
    echo "[ERROR] FFmpeg no está instalado." >&2
    exit 1
}

firefox --version
ffmpeg -hide_banner -version | head -n 1

POLITICAS="/usr/lib/firefox/distribution/policies.json"

[[ -s "$POLITICAS" ]] || {
    echo "[ERROR] No existen políticas de Firefox." >&2
    exit 1
}

python3 -m json.tool "$POLITICAS" >/dev/null

echo "[OK] Firefox, HTML5 y códecs multimedia disponibles."
echo "[AVISO] noVNC no transmite audio remoto."
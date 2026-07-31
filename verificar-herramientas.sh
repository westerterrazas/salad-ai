#!/usr/bin/env bash
set -Eeuo pipefail

for comando in croc rclone file-roller unzip zip unar rsync ssh; do
    command -v "$comando" >/dev/null 2>&1 || {
        echo "[ERROR] Falta ${comando}." >&2
        exit 1
    }
done

command -v 7z >/dev/null 2>&1 ||
command -v 7zz >/dev/null 2>&1 || {
    echo "[ERROR] Falta 7-Zip." >&2
    exit 1
}

find /usr/lib     -path '*thunarx-3*'     -name 'thunar-archive-plugin.so'     -print -quit | grep -q . || {
        echo "[ERROR] Falta thunar-archive-plugin." >&2
        exit 1
    }

visudo -cf /etc/sudoers.d/ia >/dev/null
croc --version
rclone version | head -n 2

echo "[OK] Herramientas disponibles."

#!/usr/bin/env bash
set -Eeuo pipefail

COMANDOS=(
    croc rclone file-roller unzip zip unar rsync ssh
    codium clang clangd gdb lldb cmake ninja ccache
    node npm go rustc cargo git-lfs jq rg fd bat
    shellcheck sqlite3 psql redis-cli tmux htop btop ncdu
    dnscrypt-proxy dig
)

for comando in "${COMANDOS[@]}"; do
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

find /usr/lib \
    -path '*thunarx-3*' \
    -name 'thunar-archive-plugin.so' \
    -print -quit | grep -q . || {
        echo "[ERROR] Falta thunar-archive-plugin." >&2
        exit 1
    }

visudo -cf /etc/sudoers.d/ia >/dev/null
croc --version
rclone version | head -n 2
dpkg-query -W -f='${Version}\n' codium

echo "[OK] Herramientas de IA, desarrollo, archivos y privacidad disponibles."

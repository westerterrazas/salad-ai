#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USUARIO="ia"

error() {
    local codigo=$?
    echo "[ERROR] Falló el arranque. Código: ${codigo}" >&2
    exit "$codigo"
}

trap error ERR

if [[ "${ENABLE_SUDO:-true}" == "true" ]]; then
    if [[ -z "${IA_PASSWORD:-}" ]]; then
        echo "[ERROR] IA_PASSWORD es obligatoria." >&2
        exit 1
    fi

    if ((${#IA_PASSWORD} < 12)); then
        echo "[ERROR] IA_PASSWORD requiere 12 caracteres." >&2
        exit 1
    fi

    printf '%s:%s\n' "$USUARIO" "$IA_PASSWORD" | chpasswd
    passwd -u "$USUARIO" >/dev/null 2>&1 || true
    unset IA_PASSWORD

    echo "[OK] sudo configurado."
else
    passwd -l "$USUARIO" >/dev/null 2>&1 || true
fi

"${DIR}/setup.sh"
exec "${DIR}/start-vnc.sh"

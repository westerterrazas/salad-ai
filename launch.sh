#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

manejar_error() {
    local codigo=$?
    echo "[ERROR] Falló el arranque. Código: ${codigo}" >&2
    exit "$codigo"
}

trap manejar_error ERR

echo "================================="
echo " Salad AI — XFCE/noVNC"
echo "================================="

echo "[1/2] Verificando entorno..."
"${DIR}/setup.sh"

echo "[2/2] Desplegando servicios..."
exec "${DIR}/start-vnc.sh"
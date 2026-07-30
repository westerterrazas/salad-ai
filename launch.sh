#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

manejar_error() {
    codigo=$?
    echo "[ERROR] Falló el arranque del contenedor. Código: $codigo" >&2
    exit "$codigo"
}

trap manejar_error ERR

echo "================================="
echo " Salad AI Container"
echo "================================="

echo
echo "[1/2] Verificando entorno..."

if [[ -f "$DIR/setup.sh" ]]; then
    bash "$DIR/setup.sh"
else
    echo "[AVISO] No existe $DIR/setup.sh"
fi

if [[ ! -x "$DIR/start-vnc.sh" ]]; then
    echo "[ERROR] start-vnc.sh no existe o no es ejecutable." >&2
    exit 1
fi

echo
echo "[2/2] Desplegando servicios..."

# Reemplaza el proceso principal del contenedor.
# start-vnc.sh debe finalizar con:
# exec websockify --web /usr/share/novnc "[::]:6080" 127.0.0.1:5901
exec "$DIR/start-vnc.sh"
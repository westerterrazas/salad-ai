#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================="
echo " Salad AI Container"
echo "================================="


echo ""
echo "[1/2] Preparando entorno..."
bash "$DIR/setup.sh"


echo ""
echo "[2/2] Iniciando escritorio VNC..."
bash "$DIR/start-vnc.sh"


echo ""
echo "================================="
echo " Salad AI LISTO"
echo "================================="


# Mantener vivo el contenedor
exec tail -f /dev/null
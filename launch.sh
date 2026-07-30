#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================="
echo " Salad AI Container - High Security"
echo "================================="

echo ""
echo "[1/2] Verificando Entorno..."
bash "$DIR/setup.sh"

echo ""
echo "[2/2] Desplegando Servicios..."
bash "$DIR/start-vnc.sh"

echo ""
echo "================================="
echo " Salad AI LISTO Y EN ESPERA"
echo "================================="

# Pre-crear archivos de log para prevenir fallos en tail
touch /tmp/code-server.log /home/ia/.vnc/container.log
chown ia:ia /tmp/code-server.log /home/ia/.vnc/container.log 2>/dev/null || true

# Mantener vivo el contenedor monitoreando logs
exec tail -f /tmp/code-server.log /home/ia/.vnc/*.log
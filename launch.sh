#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================="
echo " Salad AI Container - High Security"
echo "================================="

echo ""
echo "[1/2] Verificando Entorno..."
if [ -f "$DIR/setup.sh" ]; then
    bash "$DIR/setup.sh"
fi

echo ""
echo "[2/2] Desplegando Servicios..."
bash "$DIR/start-vnc.sh"

echo ""
echo "================================="
echo " Salad AI LISTO Y EN ESPERA"
echo "================================="

# Redirección de logs a /dev/null para cero huella de datos/historial
# Mantiene el contenedor en ejecución de forma pasiva y limpia
exec tail -f /dev/null
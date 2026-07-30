#!/bin/bash
set -e

export PATH="/opt/TurboVNC/bin:$PATH"

echo "=============================="
echo " Preparando Salad AI"
echo "=============================="

mkdir -p /data /models /home/ia/.vnc

echo ""
echo "[GPU Test]:"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=gpu_name,driver_version,memory.total --format=csv,noheader || echo "Error al consultar GPU."
else
    echo "[ADVERTENCIA] nvidia-smi no está accesible en este contenedor."
fi

echo ""
echo "[CUDA Test]:"
nvcc --version 2>/dev/null || echo "nvcc no disponible (usando CUDA Runtime)"

echo ""
echo "[Python Test]:"
python3 --version

echo ""
echo "[TurboVNC Test]:"
if command -v vncserver >/dev/null 2>&1; then
    echo "TurboVNC detectado en: $(which vncserver)"
else
    echo "[ERROR] TurboVNC no fue encontrado en /opt/TurboVNC/bin ni en PATH"
fi

echo ""
echo "[Verificación de Directorios]:"
ls -ld /data /models /workspace

echo ""
echo "Configuración terminada exitosamente."

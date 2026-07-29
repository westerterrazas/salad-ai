#!/bin/bash
set -e

echo "=============================="
echo " Preparando Salad AI"
echo "=============================="


mkdir -p /data
mkdir -p /models


echo ""
echo "GPU:"
nvidia-smi


echo ""
echo "CUDA:"
nvcc --version || echo "nvcc no disponible (runtime CUDA)"


echo ""
echo "Python:"
python3 --version


echo ""
echo "TurboVNC:"
if command -v vncserver >/dev/null 2>&1; then
    vncserver --version || true
else
    echo "TurboVNC no encontrado"
fi


echo ""
echo "Directorios:"
ls -ld /data /models


echo ""
echo "Configuración terminada"
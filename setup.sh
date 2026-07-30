#!/bin/bash
set -e

echo "=============================="
echo " Diagnóstico del Sistema"
echo "=============================="

mkdir -p /data /models

echo "GPU:"
nvidia-smi || echo "Atención: GPU no detectada en este instante."

echo ""
echo "Python:"
python3 --version

echo ""
echo "Directorios /data /models /workspace:"
ls -ld /data /models /workspace

echo ""
echo "Diagnóstico completado."
#!/bin/bash
set -e

echo "=============================="
echo " Preparando Salad AI"
echo "=============================="


mkdir -p /data
mkdir -p /models


echo "GPU:"
nvidia-smi


echo "Python:"
python3 --version


echo "Configuración terminada"
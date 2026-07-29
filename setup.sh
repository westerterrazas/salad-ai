#!/bin/bash
set -e

echo "================================="
echo "Preparando entorno Salad"
echo "================================="


mkdir -p /models
mkdir -p /data


echo "GPU disponible:"
nvidia-smi


echo "Python:"
python3 --version


echo "Entorno listo"
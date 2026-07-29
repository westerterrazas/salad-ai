#!/bin/bash
set -e


echo "================================="
echo " Salad AI Container"
echo "================================="


bash /workspace/setup.sh


echo ""
echo "Verificando modelos..."


if [ ! -d "/models/modelo" ]; then

    echo "Modelo no encontrado"

    # ejemplo:
    # wget URL_MODELO -O /tmp/modelo.zip
    # unzip /tmp/modelo.zip -d /models/modelo

else

    echo "Modelo encontrado"

fi


echo ""
echo "Estado GPU:"
nvidia-smi


echo ""
echo "Iniciando aplicación..."


cd /workspace


# CAMBIA ESTA LINEA
# python3 app.py


echo "Container listo"


# evita que Salad cierre el contenedor
tail -f /dev/null
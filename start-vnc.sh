#!/bin/bash
set -e

USER=ia

echo "=============================="
echo " Iniciando TurboVNC"
echo "=============================="

mkdir -p /home/$USER/.vnc

if [ ! -f /home/$USER/.vnc/passwd ]; then
    echo "Creando password VNC"

    echo "salad123" | /opt/TurboVNC/bin/vncpasswd -f \
    > /home/$USER/.vnc/passwd

    chmod 600 /home/$USER/.vnc/passwd
    chown -R $USER:$USER /home/$USER/.vnc
fi


su - $USER -c "
/opt/TurboVNC/bin/vncserver :1 \
-geometry 1920x1080
"


echo "VNC activo puerto 5901"

ss -ltnp | grep 5901 || true

tail -f /dev/null

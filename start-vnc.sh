#!/bin/bash
set -e

USER=ia

echo "=============================="
echo " Iniciando TurboVNC"
echo "=============================="


# limpiar sesión anterior si existe
su - $USER -c "
/opt/TurboVNC/bin/vncserver -kill :1 >/dev/null 2>&1 || true
"


rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -f /home/$USER/.vnc/*:1.pid
rm -f /home/$USER/.vnc/*:1.log


mkdir -p /home/$USER/.vnc


if [ ! -f /home/$USER/.vnc/passwd ]; then

    echo "Creando password VNC"

    echo "salad123" | \
    /opt/TurboVNC/bin/vncpasswd -f \
    > /home/$USER/.vnc/passwd

    chmod 600 /home/$USER/.vnc/passwd
    chown -R $USER:$USER /home/$USER/.vnc

fi


echo "Arrancando servidor..."


su - $USER -c "
/opt/TurboVNC/bin/vncserver :1 \
-geometry 1920x1080
"


echo ""
echo "=============================="
echo " VNC activo puerto 5901"
echo "=============================="


ss -ltnp | grep 5901 || true
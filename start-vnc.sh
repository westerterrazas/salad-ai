#!/bin/bash
set -e

USER=ia

echo "=============================="
echo " Iniciando TurboVNC"
echo "=============================="


# limpiar sesión anterior
su - $USER -c "
/opt/TurboVNC/bin/vncserver -kill :1 >/dev/null 2>&1 || true
"


rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -f /home/$USER/.vnc/*:1.pid
rm -f /home/$USER/.vnc/*:1.log


mkdir -p /home/$USER/.vnc


# crear password VNC
if [ ! -f /home/$USER/.vnc/passwd ]; then

    echo "Creando password VNC"

    echo "salad123" | \
    /opt/TurboVNC/bin/vncpasswd -f \
    > /home/$USER/.vnc/passwd

fi


chmod 600 /home/$USER/.vnc/passwd
chown -R $USER:$USER /home/$USER/.vnc


echo "Configurando XFCE..."


cat > /home/$USER/.vnc/xstartup.turbovnc <<'EOF'
#!/bin/bash

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

startxfce4 &
EOF


chmod +x /home/$USER/.vnc/xstartup.turbovnc
chown $USER:$USER /home/$USER/.vnc/xstartup.turbovnc


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
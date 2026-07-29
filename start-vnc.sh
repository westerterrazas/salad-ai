#!/bin/bash
set -e

USER=ia
TURBOVNC=/opt/TurboVNC/bin

echo "=============================="
echo " Iniciando TurboVNC"
echo "=============================="


# comprobar instalación
if [ ! -f "$TURBOVNC/vncserver" ]; then
    echo "ERROR: TurboVNC no encontrado"
    ls -lah /opt
    exit 1
fi


# localizar vncpasswd
if [ -f "$TURBOVNC/vncpasswd" ]; then
    VNCPASS="$TURBOVNC/vncpasswd"
elif command -v vncpasswd >/dev/null 2>&1; then
    VNCPASS="$(command -v vncpasswd)"
else
    echo "ERROR: vncpasswd no encontrado"
    exit 1
fi


echo "Limpiando sesión anterior..."

su - $USER -c "
$TURBOVNC/vncserver -kill :1 >/dev/null 2>&1 || true
"


rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -f /home/$USER/.vnc/*:1.pid
rm -f /home/$USER/.vnc/*:1.log


mkdir -p /home/$USER/.vnc


# password VNC
if [ ! -f /home/$USER/.vnc/passwd ]; then

    echo "Creando password VNC"

    echo "salad123" | \
    $VNCPASS -f \
    > /home/$USER/.vnc/passwd

fi


chmod 600 /home/$USER/.vnc/passwd
chown -R $USER:$USER /home/$USER/.vnc


echo "Configurando XFCE..."


cat > /home/$USER/.vnc/xstartup.turbovnc <<'EOF'
#!/bin/bash

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

exec startxfce4
EOF


chmod +x /home/$USER/.vnc/xstartup.turbovnc
chown $USER:$USER /home/$USER/.vnc/xstartup.turbovvnc 2>/dev/null || true


echo "Arrancando servidor..."


su - $USER -c "
$TURBOVNC/vncserver :1 \
-geometry 1920x1080 \
-rfbport 5901
"


echo ""
echo "=============================="
echo " VNC activo puerto 5901"
echo "=============================="


ss -ltnp | grep 5901 || true
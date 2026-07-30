#!/bin/bash
set -e

TURBOVNC=/opt/TurboVNC/bin

echo "=============================="
echo " Iniciando TurboVNC + noVNC"
echo "=============================="

if [ ! -f "$TURBOVNC/vncserver" ]; then
    echo "ERROR: TurboVNC no fue encontrado en $TURBOVNC"
    exit 1
fi

echo "Limpiando sesiones anteriores..."
$TURBOVNC/vncserver -kill :1 2>/dev/null || true

rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -f "$HOME/.vnc/*:1.pid"
rm -f "$HOME/.vnc/*:1.log"

mkdir -p "$HOME/.vnc"

echo "Configurando entorno gráfico XFCE..."
cat > "$HOME/.vnc/xstartup.turbovnc" <<'XEOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
XEOF

chmod +x "$HOME/.vnc/xstartup.turbovnc"

echo "Arrancando servidor TurboVNC en puerto 5901..."
$TURBOVNC/vncserver :1 \
    -geometry 1920x1080 \
    -rfbport 5901 \
    -securitytypes none

echo "Configurando noVNC..."
if [ -f /usr/share/novnc/vnc.html ] && [ ! -f /usr/share/novnc/index.html ]; then
    cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html
fi

echo "Arrancando puente HTTP websockify (noVNC) en puerto 6080..."
websockify --web=/usr/share/novnc/ 6080 localhost:5901 > "$HOME/.vnc/novnc.log" 2>&1 &

sleep 2

echo ""
echo "=============================="
echo " Servidores de Escritorio Listos"
echo " Puerto VNC Local: 5901"
echo " Puerto Web Salad (noVNC): 6080"
echo "=============================="

ss -ltnp | grep -E '5901|6080' || true

#!/bin/bash
set -e

USER=ia
HOME=/home/$USER
TURBOVNC=/opt/TurboVNC/bin

echo "=============================="
echo " Configurando Seguridad y Servicios"
echo "=============================="

# 1. Gestionar Contraseña VNC / Code-Server
IF_PASS="${VNC_PASSWORD:-}"
if [ -z "$IF_PASS" ]; then
    IF_PASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)
    echo "⚠️ ADVERTENCIA: VNC_PASSWORD no definida en Salad Cloud."
    echo "🔑 Contraseña autogenerada: $IF_PASS"
else
    echo "🔒 Usando VNC_PASSWORD configurada en Salad Cloud."
fi

# 2. Asegurar permisos requeridos por TurboVNC (700)
mkdir -p "$HOME/.vnc"
chmod 700 "$HOME/.vnc"

echo "$IF_PASS" | $TURBOVNC/vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
chown -R $USER:$USER "$HOME/.vnc"

# 3. Limpieza de procesos y sockets huérfanos
su - $USER -c "$TURBOVNC/vncserver -kill :1 >/dev/null 2>&1 || true"
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 "$HOME/.vnc/*:1.pid" "$HOME/.vnc/*:1.log"

# 4. Configurar arranque XFCE
cat > "$HOME/.vnc/xstartup.turbovnc" <<'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF

chmod +x "$HOME/.vnc/xstartup.turbovnc"
chown $USER:$USER "$HOME/.vnc/xstartup.turbovnc"

# 5. Iniciar TurboVNC (Puerto local 5901)
echo "Iniciando TurboVNC en puerto 5901..."
su - $USER -c "$TURBOVNC/vncserver :1 -geometry 1920x1080 -rfbport 5901"

# 6. Iniciar noVNC Gateway (Puerto Web 6080)
if [ -d /usr/share/novnc ]; then
    cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html 2>/dev/null || true
    echo "Iniciando noVNC Web Gateway en puerto 6080..."
    pkill websockify || true
    websockify --web /usr/share/novnc 6080 localhost:5901 &
fi

# 7. Iniciar VS Code Web (Puerto Web 8080)
echo "Iniciando VS Code Web (code-server) en puerto 8080..."
touch /tmp/code-server.log
chown $USER:$USER /tmp/code-server.log
su - $USER -c "PASSWORD='$IF_PASS' code-server --bind-addr 0.0.0.0:8080 --auth password /workspace >/tmp/code-server.log 2>&1 &"

echo ""
echo "=========================================="
echo " SERVICIOS LISTOS Y AUDITADOS"
echo "  - Escritorio noVNC (Web): Puerto 6080"
echo "  - VS Code Browser: Puerto 8080"
echo "  - Estado de Seguridad: Protegido por clave"
echo "=========================================="
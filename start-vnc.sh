#!/bin/bash
set -e

USER=ia
HOME=/home/$USER
TURBOVNC=/opt/TurboVNC/bin

echo "=================================================="
echo " ⚡ Starting Hardened AI Environment (No Tor)"
echo "=================================================="

# 1. Regenerar Machine-ID Único por Instancia (Elimina Huella Digital)
if [ -f /etc/machine-id ]; then
    tr -dc 'a-f0-9' < /dev/urandom | head -c 32 > /etc/machine-id 2>/dev/null || true
fi

# 2. Configurar DNS Privados (Cloudflare / Quad9) si resolv.conf es escribible
if [ -w /etc/resolv.conf ]; then
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 9.9.9.9" >> /etc/resolv.conf
fi

# 3. Configurar Seguridad y Contraseñas (Sudo protegido con VNC_PASSWORD)
IF_PASS="${VNC_PASSWORD:-}"
if [ -z "$IF_PASS" ]; then
    IF_PASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
    echo "⚠️ ADVERTENCIA: VNC_PASSWORD no definida en Salad Cloud."
    echo "🔑 Contraseña autogenerada: $IF_PASS"
else
    echo "🔒 Usando VNC_PASSWORD configurada en Salad Cloud."
fi

echo "$USER:$IF_PASS" | chpasswd
echo "$USER ALL=(ALL:ALL) ALL" > /etc/sudoers.d/ia-security
chmod 0440 /etc/sudoers.d/ia-security

# 4. Anular Historiales de Consola
ln -sf /dev/null "$HOME/.bash_history" 2>/dev/null || true
ln -sf /dev/null "$HOME/.python_history" 2>/dev/null || true

# 5. Limpieza Inicial de Temporales
rm -rf /tmp/* /tmp/.* 2>/dev/null || true
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 6. Configurar TurboVNC
mkdir -p "$HOME/.vnc"
chmod 700 "$HOME/.vnc"
echo "$IF_PASS" | $TURBOVNC/vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
chown -R $USER:$USER "$HOME/.vnc"

# 7. Configurar XFCE
cat > "$HOME/.vnc/xstartup.turbovnc" <<'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xset s off
xset -dpms
xfconf-query -c xfce4-session -p /general/SaveOnExit -s false 2>/dev/null || true
exec startxfce4
EOF

chmod +x "$HOME/.vnc/xstartup.turbovnc"
chown $USER:$USER "$HOME/.vnc/xstartup.turbovnc"

# 8. Iniciar TurboVNC local
echo "Iniciando TurboVNC..."
su - $USER -c "$TURBOVNC/vncserver :1 -geometry 1920x1080 -rfbport 5901 -localhost"

# 9. Iniciar noVNC Gateway en IPv6/IPv4 [::]:6080 para Ingress de Salad Cloud
if [ -d /usr/share/novnc ]; then
    cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html 2>/dev/null || true
    echo "Iniciando noVNC Web Gateway en [::]:6080..."
    websockify --web /usr/share/novnc [::]:6080 127.0.0.1:5901 &
fi

# 10. Configurar VS Code Web Cero-Telemetría
mkdir -p "$HOME/.local/share/code-server/User"
cat <<'EOF' > "$HOME/.local/share/code-server/User/settings.json"
{
  "telemetry.telemetryLevel": "off",
  "workbench.enableExperiments": false,
  "update.mode": "off",
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false
}
EOF
chown -R $USER:$USER "$HOME/.local"

su - $USER -c "DISABLE_TELEMETRY=true PASSWORD='$IF_PASS' code-server --bind-addr [::]:8080 --disable-telemetry --auth password /workspace >/dev/null 2>&1 &"

echo ""
echo "=================================================="
echo " 🚀 ENTORNO LISTO Y RENDIMIENTO MÁXIMO"
echo "  - Escritorio noVNC: Puerto 6080"
echo "  - VS Code Web: Puerto 8080"
echo "  - Conexión: Directa a velocidad nativa Gbps"
echo "=================================================="
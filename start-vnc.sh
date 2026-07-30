```bash
#!/usr/bin/env bash
set -Eeuo pipefail

USUARIO="ia"
HOME_USUARIO="/home/${USUARIO}"
TURBOVNC="/opt/TurboVNC/bin"
PUERTO_VNC=5901
PUERTO_NOVNC=6080
PUERTO_CODE=8080

CODE_PID=""
NOVNC_PID=""

limpiar() {
    echo "[INFO] Deteniendo servicios..."

    [[ -n "$NOVNC_PID" ]] && kill "$NOVNC_PID" 2>/dev/null || true
    [[ -n "$CODE_PID" ]] && kill "$CODE_PID" 2>/dev/null || true

    sudo -u "$USUARIO" \
        "$TURBOVNC/vncserver" -kill :1 \
        >/dev/null 2>&1 || true
}

trap limpiar EXIT INT TERM

echo "=================================================="
echo " Salad AI — entorno gráfico"
echo "=================================================="

if [[ -z "${VNC_PASSWORD:-}" ]]; then
    echo "[ERROR] VNC_PASSWORD no está definida." >&2
    exit 1
fi

CONTRASENA="$VNC_PASSWORD"

for comando in sudo nc websockify code-server; do
    command -v "$comando" >/dev/null 2>&1 || {
        echo "[ERROR] Comando no disponible: $comando" >&2
        exit 1
    }
done

[[ -x "$TURBOVNC/vncserver" ]] || {
    echo "[ERROR] TurboVNC no está instalado." >&2
    exit 1
}

install -d -m 0700 -o "$USUARIO" -g "$USUARIO" \
    "$HOME_USUARIO/.vnc" \
    "$HOME_USUARIO/.tor"

install -d -m 0755 -o "$USUARIO" -g "$USUARIO" \
    "$HOME_USUARIO/.local/share/code-server/User"

install -d -m 1777 /tmp/.X11-unix

echo "$USUARIO:$CONTRASENA" | chpasswd

printf '%s\n' "$USUARIO ALL=(ALL:ALL) ALL" \
    > /etc/sudoers.d/ia-security
chmod 0440 /etc/sudoers.d/ia-security

ln -sf /dev/null "$HOME_USUARIO/.bash_history"
ln -sf /dev/null "$HOME_USUARIO/.python_history"

printf '%s\n' "$CONTRASENA" |
    "$TURBOVNC/vncpasswd" -f \
    > "$HOME_USUARIO/.vnc/passwd"

chmod 0600 "$HOME_USUARIO/.vnc/passwd"

cat > "$HOME_USUARIO/.vnc/xstartup.turbovnc" <<'EOF'
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true

xfconf-query \
    -c xfce4-session \
    -p /general/SaveOnExit \
    -s false 2>/dev/null || true

exec dbus-launch --exit-with-session startxfce4
EOF

chmod 0755 "$HOME_USUARIO/.vnc/xstartup.turbovnc"
chown -R "$USUARIO:$USUARIO" \
    "$HOME_USUARIO/.vnc" \
    "$HOME_USUARIO/.local" \
    "$HOME_USUARIO/.tor"

if command -v tor >/dev/null 2>&1; then
    echo "[INFO] Iniciando Tor..."

    sudo -u "$USUARIO" -H tor \
        --DataDirectory "$HOME_USUARIO/.tor" \
        --SocksPort "127.0.0.1:9050" \
        --RunAsDaemon 1
fi

echo "[INFO] Iniciando TurboVNC..."

sudo -u "$USUARIO" \
    "$TURBOVNC/vncserver" -kill :1 \
    >/dev/null 2>&1 || true

sudo -u "$USUARIO" -H \
    "$TURBOVNC/vncserver" :1 \
    -geometry 1920x1080 \
    -depth 24 \
    -rfbport "$PUERTO_VNC" \
    -localhost

for intento in {1..30}; do
    if nc -z 127.0.0.1 "$PUERTO_VNC" 2>/dev/null; then
        echo "[OK] TurboVNC disponible."
        break
    fi

    if [[ "$intento" -eq 30 ]]; then
        echo "[ERROR] TurboVNC no abrió el puerto $PUERTO_VNC." >&2
        exit 1
    fi

    sleep 1
done

cat > "$HOME_USUARIO/.local/share/code-server/User/settings.json" <<'EOF'
{
  "telemetry.telemetryLevel": "off",
  "workbench.enableExperiments": false,
  "update.mode": "none",
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false
}
EOF

chown -R "$USUARIO:$USUARIO" "$HOME_USUARIO/.local"

echo "[INFO] Iniciando code-server..."

sudo -u "$USUARIO" -H env \
    HOME="$HOME_USUARIO" \
    DISABLE_TELEMETRY=true \
    PASSWORD="$CONTRASENA" \
    code-server \
        --bind-addr "[::]:${PUERTO_CODE}" \
        --disable-telemetry \
        --auth password \
        /workspace &

CODE_PID=$!

sleep 2

kill -0 "$CODE_PID" 2>/dev/null || {
    echo "[ERROR] code-server terminó durante el arranque." >&2
    exit 1
}

[[ -d /usr/share/novnc ]] || {
    echo "[ERROR] No existe /usr/share/novnc." >&2
    exit 1
}

cp -f /usr/share/novnc/vnc.html \
    /usr/share/novnc/index.html

echo "[INFO] Iniciando noVNC en [::]:${PUERTO_NOVNC}..."

websockify \
    --web /usr/share/novnc \
    "[::]:${PUERTO_NOVNC}" \
    "127.0.0.1:${PUERTO_VNC}" &

NOVNC_PID=$!

echo "=================================================="
echo " noVNC:       puerto ${PUERTO_NOVNC}"
echo " code-server: puerto ${PUERTO_CODE}"
echo " TurboVNC:    127.0.0.1:${PUERTO_VNC}"
echo "=================================================="

# Si noVNC o code-server muere, termina el contenedor.
set +e
wait -n "$CODE_PID" "$NOVNC_PID"
ESTADO=$?
set -e

echo "[ERROR] Un servicio principal terminó. Código: $ESTADO" >&2
exit "$ESTADO"
```

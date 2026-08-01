#!/usr/bin/env bash
set -Eeuo pipefail

USUARIO="ia"
HOME_USUARIO="/home/${USUARIO}"
TURBOVNC="/opt/TurboVNC/bin"
PUERTO_VNC=5901
PUERTO_NOVNC=6080

PIDS=()

if [[ -s /run/dnscrypt-proxy.pid ]]; then
    DNSCRYPT_PID="$(cat /run/dnscrypt-proxy.pid)"
    if kill -0 "$DNSCRYPT_PID" 2>/dev/null; then
        PIDS+=("$DNSCRYPT_PID")
    elif [[ "${SECURE_DNS_REQUIRED:-true}" == "true" ]]; then
        echo "[ERROR] dnscrypt-proxy no está activo." >&2
        exit 1
    fi
fi

limpiar() {
    local codigo=$?
    trap - EXIT INT TERM
    echo "[INFO] Deteniendo servicios..."

    if ((${#PIDS[@]} > 0)); then
        kill "${PIDS[@]}" 2>/dev/null || true
        wait "${PIDS[@]}" 2>/dev/null || true
    fi

    sudo -u "$USUARIO" "$TURBOVNC/vncserver" -kill :1 \
        >/dev/null 2>&1 || true

    exit "$codigo"
}

trap limpiar EXIT INT TERM

echo "=================================================="
echo " Salad AI — entorno gráfico privado"
echo "=================================================="

if [[ -z "${VNC_PASSWORD:-}" ]]; then
    echo "[ERROR] VNC_PASSWORD no está definida." >&2
    exit 1
fi

if ((${#VNC_PASSWORD} < 8)); then
    echo "[ERROR] VNC_PASSWORD debe tener al menos 8 caracteres." >&2
    exit 1
fi

for comando in sudo nc curl websockify dig; do
    command -v "$comando" >/dev/null 2>&1 || {
        echo "[ERROR] Comando no disponible: ${comando}" >&2
        exit 1
    }
done

[[ -x "$TURBOVNC/vncserver" ]] || {
    echo "[ERROR] TurboVNC no está instalado." >&2
    exit 1
}

install -d -m 0700 -o "$USUARIO" -g "$USUARIO" \
    "$HOME_USUARIO/.vnc" \
    "$HOME_USUARIO/.cache" \
    "$HOME_USUARIO/.cache/mozilla" \
    "$HOME_USUARIO/.cache/matplotlib" \
    "$HOME_USUARIO/.mozilla" \
    "$HOME_USUARIO/.keras" \
    /tmp/runtime-ia

install -d -m 0755 -o "$USUARIO" -g "$USUARIO" \
    "$HOME_USUARIO/.config/autostart" \
    "$HOME_USUARIO/.config/VSCodium/User" \
    "$HOME_USUARIO/.config/xfce4/xfconf/xfce-perchannel-xml" \
    "$HOME_USUARIO/.local/share/code-server/User" \
    "$HOME_USUARIO/.local/state"

install -d -m 1777 /tmp/.X11-unix

AJUSTES_XFCE="$HOME_USUARIO/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"

if [[ ! -s "$AJUSTES_XFCE" ]]; then
    cat > "$AJUSTES_XFCE" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita"/>
    <property name="IconThemeName" type="string" value="elementary-xfce"/>
  </property>
</channel>
XML
fi

rm -f "$HOME_USUARIO/.bash_history" "$HOME_USUARIO/.python_history"

chown -hR "$USUARIO:$USUARIO" "$HOME_USUARIO"

ln -s /dev/null "$HOME_USUARIO/.bash_history"
ln -s /dev/null "$HOME_USUARIO/.python_history"

chown -h "$USUARIO:$USUARIO" \
    "$HOME_USUARIO/.bash_history" \
    "$HOME_USUARIO/.python_history"
printf '%s\n' "$VNC_PASSWORD" \
    | "$TURBOVNC/vncpasswd" -f \
    > "$HOME_USUARIO/.vnc/passwd"

chmod 0600 "$HOME_USUARIO/.vnc/passwd"
unset VNC_PASSWORD

cat > "$HOME_USUARIO/.vnc/xstartup.turbovnc" <<'XSTARTUP'
#!/usr/bin/env bash
export HOME=/home/ia
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR=/tmp/runtime-ia
export KERAS_HOME="$HOME/.keras"
export MPLCONFIGDIR="$HOME/.cache/matplotlib"

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

xdg-user-dirs-update 2>/dev/null || true

xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true

xfconf-query \
    -c xfce4-session \
    -p /general/SaveOnExit \
    -s false 2>/dev/null || true

exec dbus-launch --exit-with-session startxfce4
XSTARTUP

chmod 0755 "$HOME_USUARIO/.vnc/xstartup.turbovnc"

chown -R "$USUARIO:$USUARIO" \
    "$HOME_USUARIO/.vnc" \
    "$HOME_USUARIO/.local"

echo "[INFO] Iniciando TurboVNC..."

sudo -u "$USUARIO" "$TURBOVNC/vncserver" -kill :1 \
    >/dev/null 2>&1 || true

sudo -u "$USUARIO" -H "$TURBOVNC/vncserver" :1 \
    -geometry "${VNC_GEOMETRY:-1920x1080}" \
    -depth 24 \
    -rfbport "$PUERTO_VNC" \
    -localhost

for intento in {1..45}; do
    if nc -z 127.0.0.1 "$PUERTO_VNC" 2>/dev/null; then
        echo "[OK] TurboVNC disponible en 127.0.0.1:${PUERTO_VNC}."
        break
    fi

    if [[ "$intento" -eq 45 ]]; then
        echo "[ERROR] TurboVNC no abrió el puerto ${PUERTO_VNC}." >&2
        exit 1
    fi

    sleep 1
done

VSCODIUM_SETTINGS="$HOME_USUARIO/.config/VSCodium/User/settings.json"
cat > "$VSCODIUM_SETTINGS" <<'JSON'
{
  "telemetry.telemetryLevel": "off",
  "workbench.enableExperiments": false,
  "update.mode": "none",
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false,
  "security.workspace.trust.enabled": true,
  "files.autoSave": "afterDelay",
  "terminal.integrated.enablePersistentSessions": false
}
JSON
chown "$USUARIO:$USUARIO" "$VSCODIUM_SETTINGS"

if [[ "${ENABLE_CODE_SERVER:-true}" == "true" ]]; then
    if [[ -z "${CODE_PASSWORD:-}" ]]; then
        echo "[ERROR] CODE_PASSWORD es obligatoria." >&2
        exit 1
    fi

    cat > "$HOME_USUARIO/.local/share/code-server/User/settings.json" <<'JSON'
{
  "telemetry.telemetryLevel": "off",
  "workbench.enableExperiments": false,
  "update.mode": "none",
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false
}
JSON

    chown -R "$USUARIO:$USUARIO" "$HOME_USUARIO/.local"

    echo "[INFO] Iniciando code-server..."

    sudo -u "$USUARIO" -H env \
        HOME="$HOME_USUARIO" \
        DISABLE_TELEMETRY=true \
        PASSWORD="$CODE_PASSWORD" \
        code-server \
            --bind-addr "${CODE_SERVER_BIND:-127.0.0.1:8080}" \
            --disable-telemetry \
            --auth password \
            /workspace &

    PIDS+=("$!")
    unset CODE_PASSWORD
fi

WEBSOCKIFY_ARGS=(
    --web /usr/share/novnc
    --heartbeat 30
    "[::]:${PUERTO_NOVNC}"
    "127.0.0.1:${PUERTO_VNC}"
)

echo "[INFO] Iniciando noVNC en [::]:${PUERTO_NOVNC}..."

sudo -u "$USUARIO" -H \
    websockify "${WEBSOCKIFY_ARGS[@]}" &

PIDS+=("$!")

supervisar() {
    while sleep 5; do
        nc -z 127.0.0.1 "$PUERTO_VNC" 2>/dev/null || {
            echo "[ERROR] TurboVNC dejó de responder." >&2
            return 1
        }

        curl -gfsS \
            --max-time 3 \
            --noproxy '*' \
            http://[::1]:6080/ >/dev/null || {
                echo "[ERROR] noVNC dejó de responder." >&2
                return 1
            }
    done
}

supervisar &
PIDS+=("$!")

echo "=================================================="
echo " noVNC:       [::]:${PUERTO_NOVNC}"
echo " TurboVNC:    127.0.0.1:${PUERTO_VNC}"

if [[ "${ENABLE_CODE_SERVER:-true}" == "true" ]]; then
    echo " code-server: ${CODE_SERVER_BIND:-127.0.0.1:8080}"
fi

echo "=================================================="

set +e
wait -n "${PIDS[@]}"
ESTADO=$?
set -e

echo "[ERROR] Un servicio principal terminó. Código: ${ESTADO}" >&2
exit "$ESTADO"
#!/usr/bin/env bash
set -Eeuo pipefail

USUARIO="ia"
HOME_USUARIO="/home/${USUARIO}"
VENV_USUARIO="/data/venvs/default"
RUTA_USUARIO="${VENV_USUARIO}/bin:/opt/venv/bin:${HOME_USUARIO}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

DIRECTORIOS=(
    /data
    /data/descargas
    /data/recibidos
    /data/salidas
    /data/venvs
    /models
    /workspace
)

echo "=============================="
echo " Diagnóstico del sistema"
echo "=============================="

id "$USUARIO" >/dev/null 2>&1 || {
    echo "[ERROR] No existe el usuario ${USUARIO}." >&2
    exit 1
}

for directorio in "${DIRECTORIOS[@]}"; do
    mkdir -p "$directorio"
    chown "$USUARIO:$USUARIO" "$directorio"

    sudo -u "$USUARIO" test -r "$directorio" \
        && sudo -u "$USUARIO" test -w "$directorio" \
        && sudo -u "$USUARIO" test -x "$directorio" || {
            echo "[ERROR] ${USUARIO} no puede usar ${directorio}." >&2
            ls -ld "$directorio" >&2
            exit 1
        }
done

[[ -x /usr/bin/python3 ]] || {
    echo "[ERROR] Python 3 del sistema no está disponible." >&2
    exit 1
}

[[ -x /opt/venv/bin/python && -x /opt/venv/bin/pip ]] || {
    echo "[ERROR] El entorno IA base /opt/venv está incompleto." >&2
    exit 1
}

VERSION_SISTEMA="$(/usr/bin/python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
VERSION_VENV=""

if [[ -x "${VENV_USUARIO}/bin/python" ]]; then
    VERSION_VENV="$("${VENV_USUARIO}/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
fi

if [[ "$VERSION_VENV" != "$VERSION_SISTEMA" ]]; then
    echo "[INFO] Creando entorno Python persistente para ${USUARIO}..."
    rm -rf "$VENV_USUARIO"
    sudo -u "$USUARIO" -H /usr/bin/python3 -m venv "$VENV_USUARIO"
fi

BASE_SITE="$(/opt/venv/bin/python -c 'import site; print(site.getsitepackages()[0])')"
USUARIO_SITE="$(sudo -u "$USUARIO" -H "${VENV_USUARIO}/bin/python" -c 'import site; print(site.getsitepackages()[0])')"

printf '%s\n' "$BASE_SITE" > "${USUARIO_SITE}/salad-ai-base.pth"
chown "$USUARIO:$USUARIO" "${USUARIO_SITE}/salad-ai-base.pth"

LINEA_PATH='export PATH="/data/venvs/default/bin:/opt/venv/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"'
touch "${HOME_USUARIO}/.bashrc"
grep -qxF "$LINEA_PATH" "${HOME_USUARIO}/.bashrc" \
    || printf '\n%s\n' "$LINEA_PATH" >> "${HOME_USUARIO}/.bashrc"
chown "$USUARIO:$USUARIO" "${HOME_USUARIO}/.bashrc"

sudo -u "$USUARIO" -H env PATH="$RUTA_USUARIO" python --version
sudo -u "$USUARIO" -H env PATH="$RUTA_USUARIO" pip --version
sudo -u "$USUARIO" -H env PATH="$RUTA_USUARIO" \
    python -c 'import numpy; print("[OK] NumPy base accesible:", numpy.__version__)'

if command -v nvidia-smi >/dev/null 2>&1 \
    && nvidia-smi >/dev/null 2>&1; then
    echo "[OK] GPU NVIDIA accesible."
elif [[ "${REQUIRE_GPU:-false}" == "true" ]]; then
    echo "[ERROR] REQUIRE_GPU=true, pero no hay GPU accesible." >&2
    exit 1
else
    echo "[AVISO] GPU no disponible; válido para prueba sin GPU."
fi

if [[ "${SECURE_DNS_ENABLED:-true}" == "true" ]]; then
    /workspace/verificar-dns-seguro.sh
fi

free -h || true
df -h "${DIRECTORIOS[@]}" || true

echo "[OK] Python del usuario: ${VENV_USUARIO}"
echo "[OK] Python IA protegido: /opt/venv (python-ai / pip-ai)"
echo "[OK] Diagnóstico completado."

#!/usr/bin/env bash
set -Eeuo pipefail

USUARIO="ia"
DIRECTORIOS=(/data /models /workspace)

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

command -v python3 >/dev/null 2>&1 || {
    echo "[ERROR] Python 3 no está disponible." >&2
    exit 1
}

if command -v nvidia-smi >/dev/null 2>&1 \
    && nvidia-smi >/dev/null 2>&1; then
    echo "[OK] GPU NVIDIA accesible."
elif [[ "${REQUIRE_GPU:-false}" == "true" ]]; then
    echo "[ERROR] REQUIRE_GPU=true, pero no hay GPU accesible." >&2
    exit 1
else
    echo "[AVISO] GPU no disponible; válido para prueba sin GPU."
fi

python3 --version
free -h || true
df -h "${DIRECTORIOS[@]}" || true

echo "[OK] Diagnóstico completado."
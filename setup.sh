```bash
#!/usr/bin/env bash
set -Eeuo pipefail

USUARIO="ia"
DIRECTORIOS=(/data /models /workspace)

echo "=============================="
echo " Diagnóstico del Sistema"
echo "=============================="

for directorio in "${DIRECTORIOS[@]}"; do
    mkdir -p "$directorio"

    # Cambia únicamente el directorio raíz, sin recorrer modelos o datos.
    chown "$USUARIO:$USUARIO" "$directorio"
done

echo
echo "GPU NVIDIA:"

if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi; then
        echo "[OK] GPU NVIDIA accesible."
    else
        echo "[AVISO] nvidia-smi existe, pero Salad no expuso la GPU." >&2
    fi
else
    echo "[AVISO] nvidia-smi no está disponible." >&2
fi

echo
echo "Python:"

if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python 3 no está disponible." >&2
    exit 1
fi

python3 --version

echo
echo "Acceso del usuario $USUARIO:"

for directorio in "${DIRECTORIOS[@]}"; do
    if sudo -u "$USUARIO" test -r "$directorio" \
       && sudo -u "$USUARIO" test -w "$directorio" \
       && sudo -u "$USUARIO" test -x "$directorio"; then
        echo "[OK] $directorio"
    else
        echo "[ERROR] $USUARIO no puede usar $directorio." >&2
        ls -ld "$directorio" >&2
        exit 1
    fi
done

echo
echo "Memoria:"
free -h || true

echo
echo "Almacenamiento:"
df -h "${DIRECTORIOS[@]}" || true

echo
echo "Diagnóstico completado correctamente."
```

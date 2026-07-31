#!/usr/bin/env bash
set -Eeuo pipefail

IMAGEN="${IMAGEN:-salad-ai:local}"
CONTENEDOR="${CONTENEDOR:-salad-ai-local}"
VNC_PASSWORD="${VNC_PASSWORD:-CambiaEstaClaveVNC}"
CODE_PASSWORD="${CODE_PASSWORD:-CambiaEstaClaveCode}"
IA_PASSWORD="${IA_PASSWORD:-CambiaEstaClaveSudo123}"
USE_GPU="${USE_GPU:-false}"

ARGS_GPU=()

if [[ "$USE_GPU" == "true" ]]; then
    ARGS_GPU=(--gpus all -e REQUIRE_GPU=true)
fi

echo "[1/5] Validando sintaxis..."
bash -n \
    launch.sh \
    setup.sh \
    start-vnc.sh \
    healthcheck.sh \
    verificar-navegador.sh

echo "[2/5] Construyendo ${IMAGEN}..."

docker buildx build \
    --platform linux/amd64 \
    --provenance=false \
    --sbom=false \
    --load \
    --tag "$IMAGEN" \
    .

echo "[3/5] Iniciando contenedor..."

docker rm -f "$CONTENEDOR" >/dev/null 2>&1 || true

docker run -d \
    --name "$CONTENEDOR" \
    --shm-size=2g \
    "${ARGS_GPU[@]}" \
    -e VNC_PASSWORD="$VNC_PASSWORD" \
    -e CODE_PASSWORD="$CODE_PASSWORD" \
    -e IA_PASSWORD="$IA_PASSWORD" \
    -e ENABLE_SUDO=true \
    -e ENABLE_CODE_SERVER=true \
    -e CODE_SERVER_BIND=127.0.0.1:8080 \
    -p 6080:6080 \
    "$IMAGEN" >/dev/null

echo "[4/5] Esperando estado healthy..."

for intento in {1..90}; do
    estado="$(docker inspect \
        -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}sin-healthcheck{{end}}' \
        "$CONTENEDOR")"

    if [[ "$estado" == "healthy" ]]; then
        break
    fi

    if [[ "$estado" == "unhealthy" ]] \
        || ! docker inspect -f '{{.State.Running}}' "$CONTENEDOR" \
            | grep -q true; then
        docker logs "$CONTENEDOR"
        exit 1
    fi

    if [[ "$intento" -eq 90 ]]; then
        docker logs "$CONTENEDOR"
        echo "[ERROR] El contenedor no quedó healthy." >&2
        exit 1
    fi

    sleep 2
done

echo "[5/5] Comprobando HTTP, IPv6 y WebSocket..."

curl -fsS http://127.0.0.1:6080/ >/dev/null

docker exec "$CONTENEDOR" \
    curl -gfsS --noproxy '*' http://[::1]:6080/ >/dev/null

docker exec "$CONTENEDOR" /workspace/healthcheck.sh
docker exec "$CONTENEDOR" /workspace/verificar-navegador.sh
docker exec "$CONTENEDOR" /workspace/verificar-herramientas.sh

RESPUESTA_WS="$(curl \
    --http1.1 \
    -isS \
    --max-time 3 \
    -H 'Connection: Upgrade' \
    -H 'Upgrade: websocket' \
    -H 'Sec-WebSocket-Version: 13' \
    -H 'Sec-WebSocket-Protocol: binary' \
    -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
    http://127.0.0.1:6080/websockify 2>/dev/null || true)"

grep -q '101 Switching Protocols' <<<"$RESPUESTA_WS" || {
    echo "$RESPUESTA_WS"
    echo "[ERROR] No se confirmó WebSocket." >&2
    exit 1
}

echo "[OK] Pruebas superadas."
echo "URL local: http://127.0.0.1:6080/"
echo "Logs: docker logs -f ${CONTENEDOR}"
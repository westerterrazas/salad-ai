#!/usr/bin/env bash
set -Eeuo pipefail

nc -z 127.0.0.1 5901

curl -gfsS \
    --max-time 3 \
    --noproxy '*' \
    http://[::1]:6080/ >/dev/null

pgrep -f 'websockify.*6080' >/dev/null

if [[ "${ENABLE_CODE_SERVER:-true}" == "true" ]]; then
    host="${CODE_SERVER_BIND%:*}"
    puerto="${CODE_SERVER_BIND##*:}"

    if [[ "$host" == "[::]" || "$host" == "::" ]]; then
        curl -gfsS \
            --max-time 3 \
            --noproxy '*' \
            "http://[::1]:${puerto}/healthz" >/dev/null
    else
        curl -fsS \
            --max-time 3 \
            --noproxy '*' \
            "http://127.0.0.1:${puerto}/healthz" >/dev/null
    fi
fi
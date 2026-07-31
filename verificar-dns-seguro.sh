#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${SECURE_DNS_ENABLED:-true}" != "true" ]]; then
    exit 0
fi

[[ -s /run/dnscrypt-proxy.pid ]] || {
    echo "[ERROR] Falta /run/dnscrypt-proxy.pid." >&2
    exit 1
}

PID="$(cat /run/dnscrypt-proxy.pid)"
kill -0 "$PID" 2>/dev/null || {
    echo "[ERROR] dnscrypt-proxy no está activo." >&2
    exit 1
}

grep -Eq '^nameserver[[:space:]]+127\.0\.0\.1$' /etc/resolv.conf || {
    echo "[ERROR] /etc/resolv.conf no usa el resolver local." >&2
    exit 1
}

dig @127.0.0.1 example.com A \
    +short +time=2 +tries=1 | grep -q . || {
        echo "[ERROR] El DNS cifrado no respondió." >&2
        exit 1
    }

echo "[OK] DNS cifrado operativo."

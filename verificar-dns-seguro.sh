#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${SECURE_DNS_ENABLED:-true}" != "true" ]]; then
    exit 0
fi

CONFIG="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
PIDFILE="/run/dnscrypt-proxy.pid"

[[ -s "$PIDFILE" ]] || {
    echo "[ERROR] Falta ${PIDFILE}." >&2
    exit 1
}

PID="$(cat "$PIDFILE")"
kill -0 "$PID" 2>/dev/null || {
    echo "[ERROR] dnscrypt-proxy no está activo." >&2
    exit 1
}

grep -Eq '^nameserver[[:space:]]+127\.0\.0\.1$' /etc/resolv.conf || {
    echo "[ERROR] /etc/resolv.conf no usa 127.0.0.1." >&2
    exit 1
}

/usr/sbin/dnscrypt-proxy -config "$CONFIG" -check >/dev/null

dig @127.0.0.1 example.com A +short +time=3 +tries=1 |
    grep -q . || {
        echo "[ERROR] El resolver local no respondió." >&2
        exit 1
    }

dig example.com A +short +time=3 +tries=1 |
    grep -q . || {
        echo "[ERROR] El sistema no resuelve mediante dnscrypt-proxy." >&2
        exit 1
    }

echo "[OK] DNS sobre HTTPS cifrado operativo."

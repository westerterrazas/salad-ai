#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ORIGEN="${1:-/data}"
DESTINO="${2:-}"

if [[ ! -e "$ORIGEN" ]]; then
    echo "[ERROR] No existe ${ORIGEN}." >&2
    exit 1
fi

if [[ "$DESTINO" != *:* ]]; then
    echo "Uso: $0 ORIGEN remoto_crypt:ruta" >&2
    exit 1
fi

exec rclone copy     "$ORIGEN"     "$DESTINO"     --progress     --transfers 4     --checkers 8     --retries 5     --low-level-retries 10     --create-empty-src-dirs

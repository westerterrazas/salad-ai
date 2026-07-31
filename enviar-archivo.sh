#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

RUTA="${1:-}"

if [[ -z "$RUTA" || ! -e "$RUTA" ]]; then
    echo "Uso: $0 ARCHIVO_O_DIRECTORIO" >&2
    exit 1
fi

ARGS=(--disable-clipboard)

if [[ -n "${CROC_RELAY:-}" ]]; then
    ARGS+=(--relay "$CROC_RELAY")
fi

croc "${ARGS[@]}" send "$RUTA"

#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

DESTINO="${1:-/data/recibidos}"
mkdir -p "$DESTINO"
cd "$DESTINO"

if [[ -z "${CROC_SECRET:-}" ]]; then
    read -rsp "Código secreto croc: " CROC_SECRET
    echo
    export CROC_SECRET
fi

ARGS=()

if [[ -n "${CROC_RELAY:-}" ]]; then
    ARGS+=(--relay "$CROC_RELAY")
fi

croc "${ARGS[@]}"
unset CROC_SECRET

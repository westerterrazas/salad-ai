#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rclone"

mkdir -p "$CONFIG"
chmod 0700 "$CONFIG"

exec rclone config

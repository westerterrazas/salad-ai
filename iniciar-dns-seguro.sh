#!/usr/bin/env bash

iniciar_dns_seguro() {
    if [[ "${SECURE_DNS_ENABLED:-true}" != "true" ]]; then
        echo "[AVISO] DNS cifrado deshabilitado."
        return 0
    fi

    if [[ "$EUID" -ne 0 ]]; then
        echo "[ERROR] El DNS seguro debe iniciarse como root." >&2
        return 1
    fi

    local config="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
    local log="/var/log/dnscrypt-proxy/dnscrypt-proxy.log"
    local pidfile="/run/dnscrypt-proxy.pid"
    local respaldo="/run/resolv.conf.salad-original"

    for comando in dnscrypt-proxy dig; do
        command -v "$comando" >/dev/null 2>&1 || {
            echo "[ERROR] Falta ${comando}." >&2
            return 1
        }
    done

    /usr/sbin/dnscrypt-proxy -config "$config" -check >/dev/null

    install -d -m 0755 /run
    install -d -m 0750 -o nobody -g nogroup /var/log/dnscrypt-proxy

    if [[ ! -s "$respaldo" ]]; then
        cp -L /etc/resolv.conf "$respaldo"
        chmod 0600 "$respaldo"
    fi

    rm -f "$pidfile"
    : > "$log"
    chown nobody:nogroup "$log"

    /usr/sbin/dnscrypt-proxy -config "$config" >>"$log" 2>&1 &
    local pid=$!
    printf '%s\n' "$pid" > "$pidfile"

    local listo=false
    for _ in {1..45}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi

        if dig @127.0.0.1 example.com A +short +time=2 +tries=1 |
            grep -q .; then
            listo=true
            break
        fi
        sleep 1
    done

    if [[ "$listo" != "true" ]]; then
        echo "[ERROR] dnscrypt-proxy no respondió." >&2
        tail -n 100 "$log" >&2 || true
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rm -f "$pidfile"

        if [[ "${SECURE_DNS_REQUIRED:-true}" == "true" ]]; then
            return 1
        fi

        cat "$respaldo" > /etc/resolv.conf
        echo "[AVISO] Se restauró el DNS original."
        return 0
    fi

    if [[ ! -w /etc/resolv.conf ]]; then
        echo "[ERROR] /etc/resolv.conf no es escribible." >&2
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        return 1
    fi

    printf '%s\n'         'nameserver 127.0.0.1'         'options edns0 trust-ad timeout:2 attempts:2'         > /etc/resolv.conf

    if ! dig example.com A +short +time=2 +tries=1 | grep -q .; then
        echo "[ERROR] El sistema no usa el resolver DNS cifrado." >&2
        cat "$respaldo" > /etc/resolv.conf
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rm -f "$pidfile"
        return 1
    fi

    echo "[OK] DNS sobre HTTPS cifrado activo en 127.0.0.1:53."
}

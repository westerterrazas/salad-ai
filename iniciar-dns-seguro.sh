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

    for comando in dnscrypt-proxy dig; do
        command -v "$comando" >/dev/null 2>&1 || {
            echo "[ERROR] Falta ${comando}." >&2
            return 1
        }
    done

    install -d -m 0755 /run
    install -d -m 0750 -o nobody -g nogroup \
        /var/cache/dnscrypt-proxy \
        /var/log/dnscrypt-proxy

    if [[ ! -s /run/resolv.conf.salad-original ]]; then
        cp -L /etc/resolv.conf /run/resolv.conf.salad-original
    fi

    rm -f /run/dnscrypt-proxy.pid
    : > /var/log/dnscrypt-proxy/dnscrypt-proxy.log
    chown nobody:nogroup /var/log/dnscrypt-proxy/dnscrypt-proxy.log

    /usr/sbin/dnscrypt-proxy \
        -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml \
        >> /var/log/dnscrypt-proxy/dnscrypt-proxy.log 2>&1 &

    local pid=$!
    printf '%s\n' "$pid" > /run/dnscrypt-proxy.pid

    local listo=false
    for _ in {1..45}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi

        if dig @127.0.0.1 example.com A \
            +short +time=2 +tries=1 | grep -q .; then
            listo=true
            break
        fi
        sleep 1
    done

    if [[ "$listo" != "true" ]]; then
        echo "[ERROR] dnscrypt-proxy no respondió." >&2
        tail -n 100 /var/log/dnscrypt-proxy/dnscrypt-proxy.log >&2 || true
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rm -f /run/dnscrypt-proxy.pid

        if [[ "${SECURE_DNS_REQUIRED:-true}" == "true" ]]; then
            return 1
        fi

        cp /run/resolv.conf.salad-original /etc/resolv.conf
        echo "[AVISO] Se restauró el DNS original."
        return 0
    fi

    if ! printf '%s\n' \
        'nameserver 127.0.0.1' \
        'options edns0 trust-ad timeout:2 attempts:2' \
        > /etc/resolv.conf; then
        echo "[ERROR] No se pudo modificar /etc/resolv.conf." >&2
        return 1
    fi

    if ! dig example.com A +short +time=2 +tries=1 | grep -q .; then
        echo "[ERROR] El sistema no está resolviendo mediante dnscrypt-proxy." >&2
        return 1
    fi

    echo "[OK] DNSCrypt cifrado y anonimizado activo en 127.0.0.1:53."
}

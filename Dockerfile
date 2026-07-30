# syntax=docker/dockerfile:1

FROM nvidia/cuda:13.1.0-runtime-ubuntu24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DISABLE_TELEMETRY=true \
    DO_NOT_TRACK=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    HF_HUB_DISABLE_TELEMETRY=1 \
    ANONYMIZED_TELEMETRY=false \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    HISTFILE=/dev/null \
    PYTHONHISTFILE=/dev/null

# Dependencias base, escritorio, VNC, Tor y herramientas.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus-x11 \
        dnsutils \
        git \
        gnupg \
        iproute2 \
        locales \
        mesa-utils \
        nano \
        net-tools \
        netcat-openbsd \
        novnc \
        openssh-client \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        sudo \
        tini \
        tor \
        websockify \
        wget \
        x11-xserver-utils \
        xauth \
        xfce4 \
        xfce4-goodies \
        xterm \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Firefox DEB oficial de Mozilla, evitando el paquete Snap de Ubuntu.
RUN install -d -m 0755 /etc/apt/keyrings \
    && wget -q \
        https://packages.mozilla.org/apt/repo-signing-key.gpg \
        -O /etc/apt/keyrings/packages.mozilla.org.asc \
    && HUELLA="$(gpg --batch --quiet --show-keys --with-colons \
        /etc/apt/keyrings/packages.mozilla.org.asc \
        | awk -F: '$1=="fpr"{print $10; exit}')" \
    && test "${HUELLA}" = "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
        > /etc/apt/sources.list.d/mozilla.list \
    && printf '%s\n' \
        'Package: *' \
        'Pin: origin packages.mozilla.org' \
        'Pin-Priority: 1000' \
        > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox \
    && rm -rf /var/lib/apt/lists/*

# Políticas de privacidad y proxy SOCKS5 mediante Tor.
RUN install -d -m 0755 /etc/firefox/policies \
    && cat > /etc/firefox/policies/policies.json <<'EOF'
{
  "policies": {
    "Proxy": {
      "Mode": "manual",
      "SOCKSProxy": "127.0.0.1:9050",
      "SOCKSVersion": 5,
      "UseDNS": true,
      "Locked": true
    },
    "DisableTelemetry": true,
    "DisableFormHistory": true,
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false
  }
}
EOF

# TurboVNC.
ARG TURBOVNC_VERSION=3.3

RUN wget -q \
        "https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb" \
        -O /tmp/turbovnc.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends /tmp/turbovnc.deb \
    && rm -f /tmp/turbovnc.deb \
    && rm -rf /var/lib/apt/lists/*

# VS Code Web.
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Usuario sin privilegios y directorios de trabajo.
RUN useradd --create-home --shell /bin/bash ia \
    && install -d -m 0700 -o ia -g ia /home/ia/.vnc \
    && install -d -m 0755 -o ia -g ia \
        /home/ia/.config \
        /workspace \
        /data \
        /models \
    && install -d -m 1777 /tmp/.X11-unix \
    && printf '%s\n' \
        'export HISTFILE=/dev/null' \
        'export PYTHONHISTFILE=/dev/null' \
        >> /etc/bash.bashrc

ENV USER=ia \
    HOME=/home/ia

ENV USER=ia \
    HOME=/home/ia

COPY --chown=ia:ia --chmod=0755 \
    setup.sh \
    start-vnc.sh \
    launch.sh \
    /workspace/

WORKDIR /workspace

EXPOSE 6080 8080

HEALTHCHECK \
    --interval=10s \
    --timeout=5s \
    --start-period=30s \
    --retries=3 \
    CMD ["curl", "-gfsS", "--noproxy", "*", "http://[::1]:6080/"]

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/workspace/launch.sh"]
FROM nvidia/cuda:13.1.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=ia
ENV HOME=/home/ia
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Bloque Estricto Anti-Telemetría y Privacidad
ENV DISABLE_TELEMETRY=true \
    DO_NOT_TRACK=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    HF_HUB_DISABLE_TELEMETRY=1 \
    ANONYMIZED_TELEMETRY=false \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    HISTFILE=/dev/null \
    PYTHONHISTFILE=/dev/null

# 1. Paquetes base + XFCE + noVNC + utilidades
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    nano \
    sudo \
    iproute2 \
    net-tools \
    procps \
    openssh-client \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    xauth \
    x11-xserver-utils \
    mesa-utils \
    xterm \
    locales \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    novnc \
    websockify \
    dnsutils \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalar TurboVNC
RUN wget -q \
    https://github.com/TurboVNC/turbovnc/releases/download/3.3/turbovnc_3.3_amd64.deb \
    -O /tmp/turbovnc.deb \
    && apt-get update \
    && apt-get install -y /tmp/turbovnc.deb \
    && rm -f /tmp/turbovnc.deb \
    && rm -rf /var/lib/apt/lists/*

# 3. Instalar VS Code Web (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 4. Crear Usuario y Estructura de Directorios Aislada
RUN useradd -m -s /bin/bash ia \
    && mkdir -p /home/ia/.vnc /home/ia/.config /tmp/.X11-unix /workspace /data /models \
    && chmod 700 /home/ia/.vnc \
    && chmod 1777 /tmp/.X11-unix \
    && chown -R ia:ia /home/ia /workspace /data /models

# 5. Desactivar historial persistentemente
RUN echo "export HISTFILE=/dev/null" >> /etc/bash.bashrc \
    && echo "export PYTHONHISTFILE=/dev/null" >> /etc/bash.bashrc

# 6. Copiar Scripts
COPY setup.sh /workspace/setup.sh
COPY start-vnc.sh /workspace/start-vnc.sh
COPY launch.sh /workspace/launch.sh

RUN chmod +x /workspace/*.sh && chown -R ia:ia /workspace

WORKDIR /workspace

EXPOSE 6080 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:6080/ || exit 1

ENTRYPOINT ["/workspace/launch.sh"]
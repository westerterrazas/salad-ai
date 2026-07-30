FROM nvidia/cuda:13.1.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=ia
ENV HOME=/home/ia
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 1. Paquetes base + XFCE + noVNC + utilidades
RUN apt-get update && apt-get install -y \
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

# 4. Crear Usuario y Estructura de Directorios con Permisos Exactos
RUN useradd -m -s /bin/bash ia \
    && echo "ia ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/ia/.vnc /home/ia/.config /tmp/.X11-unix /workspace /data /models \
    && chmod 700 /home/ia/.vnc \
    && chmod 1777 /tmp/.X11-unix \
    && chown -R ia:ia /home/ia /workspace /data /models

# 5. Copiar Scripts
COPY setup.sh /workspace/setup.sh
COPY start-vnc.sh /workspace/start-vnc.sh
COPY launch.sh /workspace/launch.sh

RUN chmod +x /workspace/*.sh && chown -R ia:ia /workspace

WORKDIR /workspace

ENTRYPOINT ["/workspace/launch.sh"]
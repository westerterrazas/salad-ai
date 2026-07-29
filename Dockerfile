FROM nvidia/cuda:13.1.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
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
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


# TurboVNC
RUN wget -q \
    https://github.com/TurboVNC/turbovnc/releases/download/3.3/turbovnc_3.3_amd64.deb \
    -O /tmp/turbovnc.deb \
    && apt update \
    && apt install -y /tmp/turbovnc.deb \
    && rm /tmp/turbovnc.deb


# Usuario IA
RUN useradd -m -s /bin/bash ia \
    && echo "ia ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# Directorios
RUN mkdir -p /home/ia/.vnc \
    && chown -R ia:ia /home/ia


COPY setup.sh /workspace/setup.sh
COPY start-vnc.sh /workspace/start-vnc.sh
COPY launch.sh /workspace/launch.sh


RUN chmod +x /workspace/*.sh


WORKDIR /workspace


CMD ["/workspace/launch.sh"]
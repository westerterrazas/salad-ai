# syntax=docker/dockerfile:1

FROM golang:1.25.12-alpine AS croc-builder
ARG CROC_VERSION=v10.4.4
RUN CGO_ENABLED=0 GOBIN=/out     go install github.com/schollz/croc/v10@${CROC_VERSION}

FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=croc-builder /out/croc /usr/local/bin/croc

ARG DEBIAN_FRONTEND=noninteractive
ARG TURBOVNC_VERSION=3.3
ARG TURBOVNC_SHA256=3a9eaccd19bf6bb8e02df15734103c0388eec9db23b5e1654842628084ccb4b2
ARG CODE_SERVER_VERSION=4.121.0
ARG CODE_SERVER_SHA256=3860893f15376e5f984492c5c92e87c51975d67e3902410f422823d9f60e06af

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
    PYTHONHISTFILE=/dev/null \
    VIRTUAL_ENV=/opt/venv \
    OPENNSFW2_HOME=/models/opennsfw2 \
    TF_CPP_MIN_LOG_LEVEL=2 \
    GH_TELEMETRY_DISABLED=1 \
    VSCODE_TELEMETRY_LEVEL=off \
    QT_X11_NO_MITSHM=1 \
    QT_QPA_PLATFORM=xcb
ENV PATH="/data/venvs/default/bin:/opt/venv/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        dbus-x11 \
        adwaita-icon-theme \
        desktop-file-utils \
        elementary-xfce-icon-theme \
        gvfs \
        gvfs-backends \
        hicolor-icon-theme \
        libgtk-3-bin \
        policykit-1-gnome \
        shared-mime-info \
        tumbler \
        xdg-user-dirs \
        bzip2 \
        cabextract \
        file-roller \
        gzip \
        lz4 \
        openssh-client \
        p7zip-full \
        rclone \
        rsync \
        tar \
        thunar-archive-plugin \
        unar \
        unzip \
        xz-utils \
        zip \
        zstd \
        bat \
        btop \
        cargo \
        ccache \
        clang \
        clangd \
        dnscrypt-proxy \
        dnsutils \
        fd-find \
        fzf \
        gdb \
        git-lfs \
        golang-go \
        htop \
        jq \
        lldb \
        ncdu \
        ninja-build \
        nodejs \
        npm \
        postgresql-client \
        redis-tools \
        ripgrep \
        rustc \
        shellcheck \
        sqlite3 \
        tmux \
        ffmpeg \
        fonts-liberation \
        fonts-noto-color-emoji \
        git \
        gnupg \
        libavcodec-extra \
        libegl1 \
        libdbus-1-3 \
        libdrm2 \
        libfontconfig1 \
        libfreetype6 \
        libgbm1 \
        libgles2 \
        libopengl0 \
        libvulkan1 \
        libwayland-client0 \
        libwayland-cursor0 \
        libwayland-egl1 \
        libx11-xcb1 \
        libxcb1 \
        libxcb-glx0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-shm0 \
        libxcb-sync1 \
        libxcb-util1 \
        libxcb-xfixes0 \
        libxcb-xkb1 \
        libxkbcommon0 \
        mesa-vulkan-drivers \
        qt6-base-dev \
        qt6-base-dev-tools \
        qt6-qpa-plugins \
        qt6-tools-dev-tools \
        qt6-wayland \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxkbcommon-x11-0 \
        libxcb-cursor0 \
        libxcb-xinerama0 \
        libxcb-xinput0 \
        libxrender1 \
        pkg-config \
        locales \
        mesa-utils \
        nano \
        net-tools \
        netcat-openbsd \
        novnc \
        procps \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python-is-python3 \
        sudo \
        tini \
        websockify \
        wget \
        x11-xserver-utils \
        xauth \
        xfce4 \
        xfce4-goodies \
        xterm \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*


# VSCodium: editor gráfico libre, repositorio recomendado por el proyecto.
RUN wget -qO- \
        https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
        | gpg --dearmor \
        > /usr/share/keyrings/vscodium-archive-keyring.gpg \
    && printf '%s\n' \
        'Types: deb' \
        'URIs: https://download.vscodium.com/debs' \
        'Suites: vscodium' \
        'Components: main' \
        'Architectures: amd64' \
        'Signed-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' \
        > /etc/apt/sources.list.d/vscodium.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends codium \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt constraints.txt /tmp/

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --upgrade \
        pip wheel "setuptools==75.8.2" "Cython==3.0.12" \
    && PIP_CONSTRAINT=/tmp/constraints.txt \
        /opt/venv/bin/python -m pip install --no-cache-dir \
        -r /tmp/requirements.txt \
    && /opt/venv/bin/python -m pip check \
    && ln -sf /opt/venv/bin/python /usr/local/bin/python-ai \
    && ln -sf /opt/venv/bin/pip /usr/local/bin/pip-ai \
    && rm -rf /root/.cache

# Firefox oficial Mozilla en formato DEB, no Snap.
RUN install -d -m 0755 /etc/apt/keyrings \
    && install -d -m 0700 /tmp/gnupg \
    && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg \
        -O /etc/apt/keyrings/packages.mozilla.org.asc \
    && HUELLA="$(GNUPGHOME=/tmp/gnupg gpg --batch --quiet \
        --show-keys --with-colons \
        /etc/apt/keyrings/packages.mozilla.org.asc \
        | awk -F: '$1=="fpr"{print $10; exit}')" \
    && test "$HUELLA" = "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
        > /etc/apt/sources.list.d/mozilla.list \
    && printf '%s\n' \
        'Package: *' \
        'Pin: origin packages.mozilla.org' \
        'Pin-Priority: 1000' \
        > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox \
    && install -d -m 0755 /usr/lib/firefox/distribution \
    && rm -rf /tmp/gnupg /var/lib/apt/lists/*

# Políticas administradas de privacidad.
RUN cat > /usr/lib/firefox/distribution/policies.json <<'EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisableFirefoxAccounts": true,
    "DisablePocket": true,
    "DisableFormHistory": true,
    "DisableAppUpdate": true,
    "BackgroundAppUpdate": false,
    "DisableSystemAddonUpdate": true,
    "DontCheckDefaultBrowser": true,
    "NetworkPrediction": false,
    "CaptivePortal": false,
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "NoDefaultBookmarks": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "EncryptedMediaExtensions": {
      "Enabled": false,
      "Locked": true
    },
    "Preferences": {
      "browser.newtabpage.activity-stream.showSponsored": {
        "Value": false,
        "Status": "locked"
      },
      "browser.newtabpage.activity-stream.showSponsoredTopSites": {
        "Value": false,
        "Status": "locked"
      },
      "browser.urlbar.suggest.quicksuggest.sponsored": {
        "Value": false,
        "Status": "locked"
      },
      "browser.urlbar.suggest.quicksuggest.nonsponsored": {
        "Value": false,
        "Status": "locked"
      },
      "datareporting.healthreport.uploadEnabled": {
        "Value": false,
        "Status": "locked"
      },
      "toolkit.telemetry.enabled": {
        "Value": false,
        "Status": "locked"
      },
      "media.autoplay.default": {
        "Value": 0,
        "Status": "default"
      },
      "privacy.trackingprotection.enabled": {
        "Value": true,
        "Status": "locked"
      },
      "privacy.trackingprotection.pbmode.enabled": {
        "Value": true,
        "Status": "locked"
      },
      "privacy.trackingprotection.socialtracking.enabled": {
        "Value": true,
        "Status": "locked"
      },
      "network.cookie.cookieBehavior": {
        "Value": 5,
        "Status": "locked"
      },
      "network.prefetch-next": {
        "Value": false,
        "Status": "locked"
      },
      "network.dns.disablePrefetch": {
        "Value": true,
        "Status": "locked"
      },
      "browser.urlbar.speculativeConnect.enabled": {
        "Value": false,
        "Status": "locked"
      },
      "network.http.speculative-parallel-limit": {
        "Value": 0,
        "Status": "locked"
      }
    },
    "HttpsOnlyMode": "enabled",
    "DNSOverHTTPS": {
      "Enabled": false,
      "Locked": true,
      "Fallback": false
    },
    "DownloadDirectory": "/data/descargas",
    "GenerativeAI": {
      "Enabled": false,
      "Chatbot": false,
      "LinkPreviews": false,
      "TabGroups": false,
      "Locked": true
    },
    "ExtensionSettings": {
      "uBlock0@raymondhill.net": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
      }
    }
  }
}
EOF

# TurboVNC verificado.
RUN wget -q \
        "https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb" \
        -O /tmp/turbovnc.deb \
    && echo "${TURBOVNC_SHA256}  /tmp/turbovnc.deb" | sha256sum -c - \
    && apt-get update \
    && apt-get install -y --no-install-recommends /tmp/turbovnc.deb \
    && rm -f /tmp/turbovnc.deb \
    && rm -rf /var/lib/apt/lists/*

# code-server verificado.
RUN wget -q \
        "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" \
        -O /tmp/code-server.tar.gz \
    && echo "${CODE_SERVER_SHA256}  /tmp/code-server.tar.gz" | sha256sum -c - \
    && install -d -m 0755 /opt/code-server \
    && tar -xzf /tmp/code-server.tar.gz \
        --strip-components=1 \
        -C /opt/code-server \
    && ln -s /opt/code-server/bin/code-server /usr/local/bin/code-server \
    && rm -f /tmp/code-server.tar.gz

RUN useradd --create-home --shell /bin/bash ia \
    && usermod -aG sudo ia \
    && printf '%s\n' \
        'ia ALL=(ALL:ALL) ALL' \
        'Defaults:ia timestamp_timeout=5' \
        > /etc/sudoers.d/ia \
    && chmod 0440 /etc/sudoers.d/ia \
    && visudo -cf /etc/sudoers.d/ia \
    && passwd -l ia \
    && install -d -m 0700 -o ia -g ia /home/ia/.vnc \
    && install -d -m 0755 -o ia -g ia \
        /home/ia/.config \
        /home/ia/.local \
        /workspace \
        /data \
        /models \
    && install -d -m 0700 -o ia -g ia \
        /home/ia/.config/croc \
        /home/ia/.config/rclone \
    && install -d -m 0755 -o ia -g ia \
        /data/descargas \
        /data/recibidos \
        /data/salidas \
    && install -d -m 1777 /tmp/.X11-unix \
    && printf '%s\n' \
        'export HISTFILE=/dev/null' \
        'export PYTHONHISTFILE=/dev/null' \
        >> /etc/bash.bashrc \
    && cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html

ENV USER=ia \
    HOME=/home/ia \
    XDG_CACHE_HOME=/home/ia/.cache \
    XDG_CONFIG_HOME=/home/ia/.config \
    XDG_DATA_HOME=/home/ia/.local/share \
    XDG_STATE_HOME=/home/ia/.local/state \
    XDG_RUNTIME_DIR=/tmp/runtime-ia \
    KERAS_HOME=/home/ia/.keras \
    MPLCONFIGDIR=/home/ia/.cache/matplotlib \
    SECURE_DNS_ENABLED=true \
    SECURE_DNS_REQUIRED=true \
    ENABLE_SUDO=true \
    ENABLE_CODE_SERVER=true \
    CODE_SERVER_BIND=127.0.0.1:8080 \
    REQUIRE_GPU=false

COPY --chmod=0644 dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml

RUN /usr/sbin/dnscrypt-proxy \
        -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml \
        -check

COPY --chown=ia:ia --chmod=0755 \
    setup.sh \
    start-vnc.sh \
    launch.sh \
    healthcheck.sh \
    verificar-navegador.sh \
    verificar-ia.sh \
    verificar-herramientas.sh \
    enviar-archivo.sh \
    recibir-archivo.sh \
    configurar-rclone.sh \
    respaldar-cifrado.sh \
    verificar-dns-seguro.sh \
    iniciar-dns-seguro.sh \
    /workspace/

RUN /workspace/verificar-herramientas.sh

RUN install -d -m 0700 -o ia -g ia /tmp/verificacion-ia \
    && sudo -u ia -H env \
       HOME=/tmp/verificacion-ia \
       XDG_CACHE_HOME=/tmp/verificacion-ia/.cache \
       XDG_CONFIG_HOME=/tmp/verificacion-ia/.config \
       XDG_DATA_HOME=/tmp/verificacion-ia/.local/share \
       XDG_STATE_HOME=/tmp/verificacion-ia/.local/state \
       KERAS_HOME=/tmp/verificacion-ia/.keras \
       MPLCONFIGDIR=/tmp/verificacion-ia/matplotlib \
       /workspace/verificar-ia.sh \
    && rm -rf /tmp/verificacion-ia \
    && install -d -m 0700 -o ia -g ia \
       /home/ia/.cache \
       /home/ia/.cache/mozilla \
       /home/ia/.cache/matplotlib \
       /home/ia/.mozilla \
       /home/ia/.keras \
       /tmp/runtime-ia \
    && install -d -m 0755 -o ia -g ia \
       /home/ia/.config \
       /home/ia/.local/share \
       /home/ia/.local/state \
    && chown -hR ia:ia /home/ia

WORKDIR /workspace

EXPOSE 6080

HEALTHCHECK \
    --interval=10s \
    --timeout=5s \
    --start-period=45s \
    --retries=3 \
    CMD ["/workspace/healthcheck.sh"]

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/workspace/launch.sh"]

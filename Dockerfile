# syntax=docker/dockerfile:1

FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
    QT_X11_NO_MITSHM=1

ENV PATH="/opt/venv/bin:${PATH}"

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
        ffmpeg \
        fonts-liberation \
        fonts-noto-color-emoji \
        git \
        gnupg \
        libavcodec-extra \
        libegl1 \
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

COPY requirements.txt constraints.txt /tmp/

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --upgrade \
        pip wheel "setuptools==75.8.2" "Cython==3.0.12" \
    && PIP_CONSTRAINT=/tmp/constraints.txt \
        /opt/venv/bin/python -m pip install --no-cache-dir \
        -r /tmp/requirements.txt \
    && /opt/venv/bin/python -m pip check \
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
    && passwd -l ia \
    && install -d -m 0700 -o ia -g ia /home/ia/.vnc \
    && install -d -m 0755 -o ia -g ia \
        /home/ia/.config \
        /home/ia/.local \
        /workspace \
        /data \
        /models \
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
    ENABLE_CODE_SERVER=true \
    CODE_SERVER_BIND=127.0.0.1:8080 \
    REQUIRE_GPU=false

COPY --chown=ia:ia --chmod=0755 \
    setup.sh \
    start-vnc.sh \
    launch.sh \
    healthcheck.sh \
    verificar-navegador.sh \
    verificar-ia.sh \
    /workspace/

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

FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt update && apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    unzip \
    ffmpeg \
    nano \
    tmux \
    htop \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /workspace

COPY requirements.txt .

RUN pip install --break-system-packages \
    -r requirements.txt


COPY launch.sh .
COPY setup.sh .

RUN chmod +x \
    launch.sh \
    setup.sh


RUN mkdir -p /models /data


ENTRYPOINT ["/workspace/launch.sh"]
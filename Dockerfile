# ベースイメージの設定（Debianベース）
FROM debian:bookworm

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    jq \
    build-essential \
    gcc-12 g++-12 \
    clangd \
    clang \
    clang-format \
    clang-tidy \
    python3.11 python3.11-venv python3-pip \
    curl git vim\
    nodejs npm \
    expect \
    time \
    tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# GCCのバージョン設定
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 12 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 12

# # clangd のインストール（C++の言語サーバー）

# Python仮想環境の作成と有効化
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 仮想環境内で online-judge-tools をインストール
RUN pip install --upgrade pip \
    && pip install online-judge-tools \
    && pip install selenium \
    && pip install black flake8 pylint

# atcoder-cli のインストール（npmを使用）
RUN npm install -g atcoder-cli \
    && acc config-dir /root/.atcoder-cli

# 作業ディレクトリを作成
WORKDIR /workspace
RUN mkdir env

# Bashの起動
CMD ["/bin/bash"]
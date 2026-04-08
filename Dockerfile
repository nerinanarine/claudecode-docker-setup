# Claude Code 用 Ubuntu コンテナ
FROM ubuntu:24.04

# タイムゾーン設定（対話プロンプトを抑制）
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS をインストール
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Claude Code をグローバルインストール
RUN npm install -g @anthropic-ai/claude-code

# 作業ディレクトリを設定
WORKDIR /workspace

# デフォルトシェルを bash に設定
CMD ["bash"]

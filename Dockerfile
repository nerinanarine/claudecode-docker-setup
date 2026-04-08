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

# WS_BEARER_TOKEN_BEDROCK が指定された場合、Claude Code が参照する
# AWS_BEARER_TOKEN_BEDROCK に自動マッピングする。
RUN cat > /usr/local/bin/docker-entrypoint.sh <<'EOF'
#!/usr/bin/env bash
set -e

if [ -n "${WS_BEARER_TOKEN_BEDROCK:-}" ] && [ -z "${AWS_BEARER_TOKEN_BEDROCK:-}" ]; then
    export AWS_BEARER_TOKEN_BEDROCK="${WS_BEARER_TOKEN_BEDROCK}"
fi

exec "$@"
EOF
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 作業ディレクトリを設定
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# デフォルトシェルを bash に設定
CMD ["bash"]

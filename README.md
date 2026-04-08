# claudecode-docker-setup

Windows 11 の Docker Desktop 上で **Claude Code** を動かすための Docker 環境一式です。

Ubuntu 24.04 コンテナに Node.js 22 と Claude Code をインストール済みのイメージをビルドし、**AWS Bedrock** または **Azure AI Foundry** 経由で Claude Code を利用できます。

---

## ファイル構成

```
claudecode-docker-setup/
├── Dockerfile                                    # Ubuntu + Node.js 22 + Claude Code
├── docker-compose.yml                            # コンテナ起動設定
├── .env.example                                  # 認証情報テンプレート
└── ClaudeCode_DockerDesktop_Windows11_手順書.md  # 詳細セットアップ手順書
```

---

## クイックスタート

### 1. リポジトリをクローン

```powershell
git clone https://github.com/nerinanarine/claudecode-docker-setup.git
cd claudecode-docker-setup
```

### 2. `.env` ファイルを作成して認証情報を設定

```powershell
Copy-Item .env.example .env
notepad .env
```

**AWS Bedrock を使う場合:**

```env
CLAUDE_CODE_USE_BEDROCK=1
WS_BEARER_TOKEN_BEDROCK=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

**Azure AI Foundry を使う場合:**

```env
CLAUDE_CODE_USE_AZURE=1
ANTHROPIC_BASE_URL=https://<リソース名>.services.ai.azure.com/models
ANTHROPIC_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> ⚠️ `.env` は認証情報を含むため、Git にコミットしないでください。

### 3. イメージをビルド

```powershell
docker compose build
```

### 4. コンテナを起動して Claude Code を使う

```powershell
docker compose run --rm claude-code
```

コンテナ内で:

```bash
# バージョン確認
claude --version

# 対話モードで起動
claude

# 一問一答
claude "Pythonでfizzbuzzを書いて"
```

---

## 対応プラットフォーム

| プラットフォーム | 環境変数 |
|----------------|---------|
| AWS Bedrock | `CLAUDE_CODE_USE_BEDROCK=1` + `WS_BEARER_TOKEN_BEDROCK` |
| Azure AI Foundry | `CLAUDE_CODE_USE_AZURE=1` + Azure エンドポイント・APIキー |

---

## 詳細手順

初めての方や詳しい設定方法は [ClaudeCode_DockerDesktop_Windows11_手順書.md](./ClaudeCode_DockerDesktop_Windows11_手順書.md) をご覧ください。

- Docker Desktop のセットアップ
- AWS Bedrock / Azure AI Foundry の認証設定手順
- よくあるエラーと対処法
- コスト管理のポイント

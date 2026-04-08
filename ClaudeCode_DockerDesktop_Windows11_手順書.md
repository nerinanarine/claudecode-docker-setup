# Claude Code を Docker Desktop の仮想コンテナで使う手順書（Windows 11 初心者向け）

最終更新日: 2026-04-08

---

## 1. この手順書でできること

この手順書では、**Windows 11 + Docker Desktop** 環境で、Ubuntu コンテナ内から **Claude Code（`claude`）** を使えるようにします。

- Windows 側で Docker Desktop を準備
- Dockerfile を使って Claude Code 入り Ubuntu コンテナをビルド
- **AWS Bedrock** または **Azure AI Foundry** の認証情報を設定
- Claude Code を対話モード・コマンドモードで利用

> この手順書では Anthropic API（claude.ai）は使用しません。社内や企業環境でよく利用される **AWS Bedrock** または **Azure AI Foundry** 経由で Claude Code を使います。

---

## 2. 事前準備（必須）

### 必要なもの

1. **Windows 11**（管理者権限があるアカウント推奨）
2. **Docker Desktop**（起動済み）
3. 以下のいずれか（どちらか一方で OK）：
   - **AWS アカウント** と Bedrock で Claude モデルへのアクセス許可
   - **Azure サブスクリプション** と Azure AI Foundry デプロイ済みの Claude モデル
4. インターネット接続

> 重要: 会社 PC の場合、プロキシやファイアウォール設定で失敗することがあります。うまくいかない場合は社内 IT 管理者に確認してください。

> Anthropic への直接サインアップや Anthropic API キーは不要です。

---

## 3. 認証情報の準備

使用するプラットフォームに応じて、**A（AWS Bedrock）** または **B（Azure AI Foundry）** のいずれかを準備します。

---

### 方法 A: AWS Bedrock を使う場合

#### A-1. AWS コンソールで Bedrock の Claude モデルを有効化する

1. AWS コンソール（[https://console.aws.amazon.com](https://console.aws.amazon.com)）にログイン
2. リージョンを **「us-east-1（米国東部）」** などに設定（Bedrock が利用可能なリージョン）
3. 検索バーで **「Amazon Bedrock」** を開く
4. 左メニューの **「Model access（モデルアクセス）」** をクリック
5. **「Anthropic」** の Claude モデル（例: `Claude 3.5 Sonnet`）の **「Request access」** をクリックして有効化
6. 承認されるまで少し待つ（即時承認されることが多い）

#### A-2. Bedrock 用 Bearer トークンを取得する

1. Bedrock 接続に使用する **Bearer トークン** を取得します（社内発行ポータル、または運用管理者から払い出された値）。
2. トークン文字列を安全な場所に保存します。
3. この手順書では、その値を `WS_BEARER_TOKEN_BEDROCK` に設定して利用します。

> 重要: Bearer トークンは機密情報です。チャットやメール本文に貼り付けず、シークレット管理ツールで保管してください。

#### A-3. IAM ポリシーを確認する

対象 IAM ユーザーに以下のポリシーが付与されていることを確認してください。

```json
{
  "Effect": "Allow",
  "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
  "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.*"
}
```

社内の AWS 環境の場合は、クラウド管理者に上記権限の付与を依頼してください。

---

### 方法 B: Azure AI Foundry を使う場合

#### B-1. Azure AI Foundry で Claude モデルをデプロイする

1. Azure ポータル（[https://portal.azure.com](https://portal.azure.com)）にログイン
2. **「Azure AI Foundry」** を開く（または [https://ai.azure.com](https://ai.azure.com)）
3. プロジェクトを選択または新規作成
4. **「デプロイ」** → **「モデルのデプロイ」** から **「Anthropic Claude」** を選択してデプロイ
5. デプロイ完了後、**「エンドポイント URL」** と **「API キー」** を取得してメモする

> エンドポイント URL の形式:  
> `https://<リソース名>.services.ai.azure.com/models`

#### B-2. 取得する情報

| 情報 | 確認場所 |
|------|----------|
| エンドポイント URL | デプロイ画面 → 「エンドポイント」 |
| API キー（Key 1 または Key 2） | デプロイ画面 → 「キー」 |

社内の Azure 環境の場合は、クラウド管理者にエンドポイントとキーを確認してください。

---

## 4. Docker Desktop の確認

1. Windows で Docker Desktop を起動
2. 右下のステータスが **Running** になっていることを確認
3. PowerShell を開いて次を実行

```powershell
docker version
docker run --rm hello-world
```

`hello-world` が成功すれば Docker は正常です。

---

## 5. この手順書のファイル構成

この手順書と同じフォルダに以下のファイルを用意します（後述の手順で作成済みです）。

```
claudecode-docker-setup/
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── ClaudeCode_DockerDesktop_Windows11_手順書.md  ← この手順書
```

---

## 6. コンテナをビルドする

PowerShell でこのフォルダに移動し、イメージをビルドします。

```powershell
cd C:\Users\<ユーザー名>\Downloads\claudecode-docker-setup
docker compose build
```

> 初回ビルドは Node.js と Claude Code のダウンロードがあるため数分かかります。

> **次のセクション（セクション 8）で `.env` ファイルを作成してから、コンテナを起動してください。**

---

## 7. Claude Code のバージョン確認

コンテナ内で確認します。

### 手順

1. Windows PowerShell でコンテナを起動

```powershell
docker compose run --rm claude-code
```

2. プロンプトが `root@...:/workspace#` のように表示されたら、次を実行

```bash
claude --version
```

### 正常時の例

```bash
1.2.3
```

上記のようにバージョン番号が表示されれば正常です。

### うまくいかない場合

- `claude: command not found`
  - イメージが古い可能性があります。Windows 側で再ビルドしてください。

```powershell
docker compose build --no-cache
```

- `Cannot connect to the Docker daemon`
  - Docker Desktop が起動していません。Docker Desktop を起動してから再実行してください。

---

## 8. 認証情報をコンテナに設定する

使用するプラットフォームに応じて **A（AWS Bedrock）** または **B（Azure AI Foundry）** の手順を実施してください。

### 手順 1: `.env` ファイルを作成する（Windows PowerShell）

```powershell
# このフォルダに移動
cd C:\Users\<ユーザー名>\Downloads\claudecode-docker-setup

# .env.example をコピーして .env を作成
Copy-Item .env.example .env

# メモ帳で開いて認証情報を記入
notepad .env
```

> `.env` ファイルは **Git にコミットしないこと**（認証情報が外部に漏れます）。

---

### 方法 A: AWS Bedrock の場合

メモ帳で `.env` を開き、以下の内容を設定します（セクション 3-A で取得した値を記入）。

```env
# AWS Bedrock 設定
CLAUDE_CODE_USE_BEDROCK=1
WS_BEARER_TOKEN_BEDROCK=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

> `AWS_REGION` は Bedrock で Claude が利用可能なリージョンを指定します（例: `us-east-1`、`us-west-2`）。

#### 動作確認（コンテナ内）

```powershell
docker compose run --rm claude-code
```

```bash
# 環境変数が読み込まれているか確認
echo $WS_BEARER_TOKEN_BEDROCK

# Claude Code を Bedrock モードで起動
claude --bedrock
```

---

### 方法 B: Azure AI Foundry の場合

メモ帳で `.env` を開き、以下の内容を設定します（セクション 3-B で取得した値を記入）。

```env
# Azure AI Foundry 設定
CLAUDE_CODE_USE_AZURE=1
ANTHROPIC_BASE_URL=https://<リソース名>.services.ai.azure.com/models
ANTHROPIC_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> `ANTHROPIC_BASE_URL` は Azure AI Foundry のエンドポイント URL です。  
> `ANTHROPIC_API_KEY` は Azure のキー（Anthropic のキーではありません）です。

#### 動作確認（コンテナ内）

```powershell
docker compose run --rm claude-code
```

```bash
# 環境変数が読み込まれているか確認
echo $ANTHROPIC_BASE_URL

# Claude Code を Azure モードで起動
claude --azure
```

---

### 手順 4: 動作確認

どちらのモードでも、起動後に以下で動作を確認できます。

```bash
claude --version
claude "こんにちは。今日の日付を教えてください。"
```

レスポンスが返ってくれば認証は成功です。

---

## 9. Claude Code を試す

### 対話型（チャット）で使う

```bash
claude
```

起動後にそのまま日本語で質問できます。

```
> このディレクトリのファイル構成を確認したい
> bashスクリプトを書いてdiskの使用量を確認して
```

終了は `/exit` または `Ctrl + C`。

### 一問一答で使う

```bash
claude "現在のディレクトリを確認するコマンドを教えて"
```

### ファイルを渡して説明してもらう

```bash
claude "このスクリプトの意味を説明してください" < /path/to/script.sh
```

### コードを書いてもらいファイルに保存する

```bash
claude "Pythonでfizzbuzzを書いて" > fizzbuzz.py
```

### コマンドを説明してもらう

```bash
claude "次のコマンドの意味を説明してください: find . -type f -name '*.log' -mtime -7"
```

---

## 10. 便利なスラッシュコマンド（対話モード内）

| コマンド | 内容 |
|---------|------|
| `/help` | ヘルプを表示 |
| `/clear` | 会話履歴をリセット |
| `/exit` | Claude Code を終了 |
| `/model` | 使用するモデルを確認・変更 |
| `/cost` | 今のセッションのトークン消費を確認 |

---

## 11. コンテナを終了・再開する

### 終了（コンテナ内）

```bash
exit
```

### 再開（Windows PowerShell）

`docker compose run` は毎回新しいコンテナを起動します（`--rm` を付けているため自動削除されます）。  
作業ファイルを保持したい場合は、ボリュームマウントを使った名前付きコンテナで運用します。

```powershell
# 毎回クリーンな環境で起動（推奨）
docker compose run --rm claude-code

# または名前付きコンテナで永続利用（Bedrock の場合）
docker run -it --name claude-code-lab `
  -e CLAUDE_CODE_USE_BEDROCK=1 `
  -e WS_BEARER_TOKEN_BEDROCK=$env:WS_BEARER_TOKEN_BEDROCK `
  -e AWS_REGION=$env:AWS_REGION `
  claudecode-docker-setup-claude-code bash

# または名前付きコンテナで永続利用（Azure の場合）
docker run -it --name claude-code-lab `
  -e CLAUDE_CODE_USE_AZURE=1 `
  -e ANTHROPIC_BASE_URL=$env:ANTHROPIC_BASE_URL `
  -e ANTHROPIC_API_KEY=$env:ANTHROPIC_API_KEY `
  claudecode-docker-setup-claude-code bash
```

名前付きコンテナの再開：

```powershell
docker start -ai claude-code-lab
```

---

## 12. よくあるエラーと対処

### 1) `claude: command not found`
- ビルドに失敗している可能性があります。
- `docker compose build --no-cache` で再ビルドしてください。

### 2) `Authentication failed` / 認証エラー
- 環境変数が正しく設定されているか確認：

```bash
# Bedrock の場合
echo $WS_BEARER_TOKEN_BEDROCK
echo $AWS_REGION

# Azure の場合
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_API_KEY
```

- `.env` ファイルの設定値にコピーミスやスペースが含まれていないか確認してください。
- `CLAUDE_CODE_USE_BEDROCK=1` または `CLAUDE_CODE_USE_AZURE=1` が設定されているか確認してください。

### 3) AWS Bedrock: `AccessDeniedException`
- IAM ユーザーに Bedrock の `InvokeModel` 権限が付与されていません。
- AWS コンソールの IAM で権限を確認し、社内クラウド管理者に権限付与を依頼してください。
- Bedrock のモデルアクセス（Model access）でそのリージョンの Claude モデルが有効化されているか確認してください。

### 4) Azure AI Foundry: `401 Unauthorized`
- Azure のエンドポイント URL またはキーが間違っています。
- Azure AI Foundry のデプロイ画面で正しいエンドポイントとキーを再確認してください。

### 4) ビルドが途中で失敗する
- インターネット接続・プロキシ設定を確認してください。
- Docker Desktop の Resources（メモリ・CPU）を増やしてみてください（推奨: メモリ 4GB 以上）。

### 5) 会社ネットワークで接続できない
- プロキシ設定が必要な可能性があります。
- `docker compose build` の `--build-arg` や `ENV` でプロキシを設定してください。

```dockerfile
# Dockerfile に追加する例
ENV HTTP_PROXY=http://proxy.example.com:8080
ENV HTTPS_PROXY=http://proxy.example.com:8080
```

---

## 13. 初心者向けの運用ポイント

- はじめは `claude "このコマンドの意味を教えて: <command>"` を多めに使うと安全です。
- 提案されたコマンドは、実行前に必ず意図を理解しましょう。
- 認証情報は `.env` ファイルに記入し、**Git リポジトリにはコミットしない** ようにしてください。`.env` は `.gitignore` に追加することを推奨します。
- `/cost` コマンドでトークン消費量を定期的に確認し、使いすぎに注意してください。
- AWS Bedrock の場合は AWS CloudWatch でコスト・使用量を監視できます。
- Azure AI Foundry の場合は Azure Cost Management でコストを監視できます。

---

## 14. 片付け（不要になった場合）

### コンテナ削除（Windows PowerShell）

```powershell
docker rm -f claude-code-lab
```

### イメージ削除（任意）

```powershell
docker rmi claudecode-docker-setup-claude-code
docker rmi ubuntu:24.04
```

### すべてまとめて削除

```powershell
docker compose down --rmi all --volumes --remove-orphans
```

---

## 15. まとめ

この手順で、Windows 11 の Docker Desktop 上の Ubuntu コンテナから Claude Code を使えるようになります。  
コンテナを使うことで、ホスト PC を汚さずに Claude Code の環境を試せます。慣れてきたら、プロジェクトのコードをボリュームマウントして、実際の開発作業に活用してみてください。

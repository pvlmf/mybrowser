# mybrowser

Chromium（`chromium/chromium`）のフォーク `pvlmf/mybrowser` を、学習しながら少しずつ改造していくプロジェクトです。

## クイックスタート

```bash
# ビルド（差分・自動リトライ付き）
./scripts/build-chrome.sh

# 起動（プロファイル分離）
./scripts/run-chrome.sh
```

## ドキュメント

| ファイル | 内容 |
|---|---|
| [todo.txt](todo.txt) | いま取り組むタスク（作業中はここを見る） |
| [docs/overview.md](docs/overview.md) | プロジェクトの現状・環境・制約 |
| [docs/learning-plan.md](docs/learning-plan.md) | 学習ロードマップ（段階と進捗） |
| [docs/build.md](docs/build.md) | ビルド・実行・トラブルシューティング |
| [docs/log.md](docs/log.md) | 作業ログ（日付ごとの記録） |
| [docs/notes/](docs/notes/) | 個別の学びメモ（日付ごと） |
| [archive/gtp-advice.txt](archive/gtp-advice.txt) | 方針の元になった外部アドバイス |

`AGENTS.md` はリポジトリ外（プロジェクトルート）にあります。

## ディレクトリ構成

```
src/                  # Chromium 本体（このリポジトリ、dev ブランチ）
├── chrome/           # ブラウザ実装
├── docs/             # upstream のドキュメント + mybrowser のメモ
│   ├── overview.md
│   ├── learning-plan.md
│   ├── build.md
│   ├── log.md
│   └── notes/
├── scripts/          # ビルド・起動・監視スクリプト
├── archive/          # 参考資料の保管
├── todo.txt          # 現在のタスク
└── README.md         # これ
```

ビルドログと `AGENTS.md` はプロジェクトルート（リポジトリ外）にあります。

## 現在の状態

- ブランチ: `dev`（`origin/dev` に push 済み）
- ビルド: Chromium 158.0.8113.0（Release / component build）
- 直近の変更: 新しいタブページの背景色（コミット `8421ee2fb9`）

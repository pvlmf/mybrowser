# mybrowser

Chromium（`chromium/chromium`）のフォーク `pvlmf/mybrowser` を、学習しながら少しずつ改造していくプロジェクトです。

## クイックスタート

```bash
# ビルドして起動（開発中はこれ）
./scripts/dev.sh

# ビルドだけ（差分・自動リトライ付き）
./scripts/build-chrome.sh

# 起動だけ（プロファイル分離）
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
| [AGENTS.md](AGENTS.md) | エージェント向けのルール |

## ディレクトリ構成

```
mybrowser/src/        # プロジェクトルート兼リポジトリ（dev ブランチ）
├── chrome/           # ブラウザ実装
├── docs/             # upstream のドキュメント + mybrowser のメモ
│   ├── overview.md
│   ├── learning-plan.md
│   ├── build.md
│   ├── log.md
│   └── notes/
├── scripts/          # ビルド・起動・監視スクリプト
├── archive/          # 参考資料の保管
├── build-logs/       # ビルドログ（gitignore 済み）
├── todo.txt          # 現在のタスク
├── AGENTS.md         # エージェント向けルール
└── README.md         # これ
```

gclient のメタデータ（`.gclient`, `.cipd` など）だけが親の `mybrowser/` にあります。

## 現在の状態

- ブランチ: `dev`（`origin/dev` に push 済み）
- ビルド: Chromium 158.0.8113.0（Release / component build）
- 直近の変更: ドキュメント・スクリプト・AGENTS.md をリポジトリ内に統合

# プロジェクト概要

## 目的

`pvlmf/mybrowser`（Chromium のフォーク）を土台に、小さな改造を繰り返しながらブラウザの構造を学ぶ。
独自エンジンを作るのではなく、既存の Chromium に手を入れて理解を深めることが目的。

## リポジトリ

| 項目 | 内容 |
|---|---|
| origin | `git@github.com:pvlmf/mybrowser.git` |
| 親リポジトリ | `chromium/chromium` |
| ブランチ | `dev`（作業用）／`main`（フォークの追従用） |
| 棚卸し開始時の HEAD | `8a67b25c13e1`（2026-10-24、開始時点での `dev`） |
| `main` との差 | 棚卸し開始時に `dev` が 42 コミット先行、0 コミット後退（確認: 2026-10-24） |
| 履歴 | shallow（depth 1） |

### ブランチの役割と shallow clone の制約

- 過去コミットの参照・rebase はできない
- 履歴が必要なら `git fetch --deepen=100` などで段階的に取得
- upstream 追従は `git remote add upstream https://github.com/chromium/chromium.git` して
  必要なコミットだけ depth 1 で取るのが軽い

## ビルド環境

| 項目 | 内容 |
|---|---|
| ソース | `/home/pvlmf/Projects/mybrowser/src` |
| 依存取得 | `gclient sync --no-history`（約23GB） |
| ツール | `~/depot_tools`（gn / ninja / siso / autoninja） |
| コンパイラ | Chromium 同梱 clang、sysroot（Debian bullseye） |
| 出力 | `src/out/Release/`（約7.8GB、共有ライブラリ551個） |
| バイナリ | `src/out/Release/chrome`（200MB） |
| バージョン | Chromium 158.0.8113.0 |

### GN 引数（`src/out/Release/args.gn`）

```gn
is_debug = false
is_component_build = true
symbol_level = 0
blink_symbol_level = 0
v8_symbol_level = 0
```

- `is_component_build = true`: 差分ビルドが速く、リンク時のメモリも少ない
- 配布用の正式ビルドではない（`is_official_build` は未使用）

## マシンリソース

| 項目 | 値 |
|---|---|
| CPU | 16コア |
| RAM | 15GB（zram スワップ 30GB） |
| ディスク | 475GB（空き約390GB） |
| 初回ビルド実績 | 2時間25分 / 6並列 / メモリピーク 6GB |

メモリが厳しいため、ビルドは `-j 6〜8` を目安にする。

## UI の2層構造

| 層 | 技術 | 例 |
|---|---|---|
| ブラウザの枠 | C++ / Views | タブ、ツールバー、ウィンドウ枠 |
| ページ内 UI | WebUI（HTML/CSS/TS + Lit） | 新しいタブページ、設定画面 |

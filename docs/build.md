# ビルドと実行

## コマンド

```bash
cd /home/pvlmf/Projects/mybrowser/src

# ビルド（監督スクリプト: 失敗時に分類して自動再試行）
./scripts/build-chrome.sh

# 起動（プロファイル分離）
./scripts/run-chrome.sh

# 手動でビルド
cd src
export PATH=/home/pvlmf/depot_tools:$PATH
autoninja -C out/Release -j 6 chrome
```

## ビルドの仕組み

- GN が `out/Release` にビルドグラフを生成（`gn gen`）
- Ninja 互換の **siso** が実際のコンパイルを実行
- WebUI の CSS/HTML/TS はビルド時に JS へ変換され、`resources.pak` に梱包される
- そのため **CSS だけの変更でも再ビルドが必要**

差分ビルドの目安:

| 変更内容 | 時間 |
|---|---|
| CSS / HTML のみ | 10秒〜1分 |
| C++ 1ファイル | 数分 |
| 初回フルビルド | 約2時間25分（6並列） |

## ログ

- `build-logs/supervisor.log` — 試行回数・失敗分類の履歴
- `build-logs/build-YYYYMMDD-HHMMSS.log` — 各試行の詳細

## トラブルシューティング

### 変更が画面に反映されない

1. 再ビルドしたか確認（`resources.pak` の更新時刻を見る）
   ```bash
   stat -c '%y %n' src/out/Release/resources.pak
   ```
2. 生成物に入っているか確認
   ```bash
   grep -o "background:blue" src/out/Release/gen/chrome/browser/resources/new_tab_page/tsc/app.css.js
   ```

### `:host` に背景色を指定しても表示されない

カスタム要素は既定で `display: inline`。背景を塗る領域がないため、`:host` に
`display: block;` を追加する。

### ビルドが OOM で落ちる

`scripts/build-chrome.sh` は自動で並列度を下げる。手動なら `-j 4` などにする。

### クローンが `invalid eof` で失敗する

Chromium のフルクローンは約62GB。`--depth 1 --single-branch` の shallow clone を使う。

### ビルドが `interrupt by signal` で止まる

スリープやセッション終了が原因になりやすい。`systemd-run --user` で実行すると強い。

### ディレクトリ名を変更すると全再ビルドになる

siso はビルドディレクトリの絶対パスをキャッシュキーに含むため、`chromium/` を
`mybrowser/` にリネームすると、既存の `.o` がすべて無効になりフルビルド（約2時間）になる。
ソースや依存の再ダウンロードは不要。

- リネームは**初回ビルド前**に行うのが安全
- ビルド後に名前を変えたい場合は、再ビルドの時間を覚悟する

## 環境メモ

- `out/Release/args.gn` は Release + component build + シンボル無し
- 配布用ビルドにする場合は `is_official_build = true` など別途設定が必要

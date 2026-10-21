# 作業ログ

日付ごとに「やったこと / 学び / コミット」を残す。詳細な解説は `docs/notes/` へ。

## 2026-10-20

- `pvlmf/mybrowser` を shallow clone（`--depth 1`）で取得
  - フルクローンは約62GBで `invalid eof` になるため
- `gclient sync --no-history` で依存を取得（約28GB）
- `gclient runhooks` で clang / gn / sysroot を準備
- `gn gen out/Release` でビルド構成を作成
- 初回ビルド開始

## 2026-10-21

- 初回ビルド成功（10:02、Chromium 158.0.8113.0、6並列・2時間25分）
- ヘッドレス起動で動作確認
- ビルド監督スクリプト（自動リトライ）を整備
- `dev` ブランチを作成
- NTP の背景色を変更（`:host` に `display: block` + `background`）
  - 学び: カスタム要素は既定で inline
  - 学び: CSS は `resources.pak` に梱包されるため再ビルド必須
  - コミット: `721ec0cee3`
- 背景色を CSS 変数化し、背景画像があるときは `transparent` に
- ドキュメント構成を整備（README / docs / scripts / archive）
- ルートディレクトリを `chromium/` → `mybrowser/` に変更
  - 学び: siso は絶対パスをキャッシュキーにするため、リネームで全再ビルドになる
  - 再ダウンロードは不要（ソース・依存はそのまま）
- リネーム後のフルビルド成功（17:18、3時間58分、8並列）
- 背景画像をアップロードし、緑が消えて画像が表示されることを確認
- プロジェクトルートを `src` に統合
  - docs / scripts / AGENTS.md をリポジトリ内へ
  - build-logs も `src/build-logs` へ移動（gitignore 済み）
  - コミット: `bec03c9512`, `7fbcaa24c6`, `bb62b2f2cb`

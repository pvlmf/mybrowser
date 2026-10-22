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
- 検索ボックスの幅を変更（広い画面で 1520px）
- NTP に「thisismybrowser」ラベルを追加（HTML + CSS）
- NTP の action chips を無効化（AI / Google 連携方針の最初の実装）
  - `AreActionChipsEnabled()` を false 固定
  - 確認: NTP 表示、`thisismybrowser` ラベルあり、`ntp-action-chips` なし、`isActionChipsVisible_` false
  - 学び: C++ → `loadTimeData` → Lit の流れ。shadow DOM は `ntp-app.shadowRoot` から確認
- NTP の composebox を無効化
  - `searchboxShowComposeEntrypoint` / `searchboxShowComposebox` を false
  - 確認: compose ボタンなし、composebox なし、検索ボックスは残る
  - 学び: `loadTimeData` のキー名とプロパティ名は一致しないことがある
- NTP の Lens と音声検索を無効化
  - `enable_lens_search` / `enable_voice_search` を false
  - 確認: `#lensSearchButton` / `#voiceSearchButton` なし、検索ボックスは残る
  - 学び: 共有コンポーネントはオプションで切り替えると他画面に影響しにくい
- NTP の realbox next（AI Mode）を無効化
  - `kNtpRealboxNext` を `FEATURE_DISABLED_BY_DEFAULT` に
  - 確認: `ntpRealboxNextEnabled_` false、AI Mode ボタンなし、プレースホルダーが通常検索に戻る
  - 学び: 機能フラグのデフォルトを変えると派生する値もまとめて false になる
- NTP の OneGoogleBar を無効化
  - `oneGoogleBarEnabled` を false
  - 確認: `oneGoogleBarEnabled_` false、`#oneGoogleBar` なし、ショートカットは残る
  - 学び: app.html の条件分岐で iframe 自体が作られない
- NTP のモジュールを明示的に無効化
  - `NewTabPageUI::OnLoad()` の `modulesEnabled` を false
  - 確認: `modulesEnabled_` false、`#modules` なし、ショートカットは残る
  - 学び: `loadTimeData.getBoolean()` はキーの存在を前提にするため、値だけ変えてキーは残す
- NTP モジュールの削除計画を作成（コード変更なし）
  - `docs/notes/2026-10-22-modules-removal-plan.md`
  - WebUI / Mojo / C++ / prefs / フラグ / テストの依存を整理
  - 最初は Phase 1a + 1b（WebUI の削除）を推奨
  - ビルド・実ブラウザ確認はコード変更時に行うため、今回はなし

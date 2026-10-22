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
- NTP モジュール削除 Phase 1a-1: `app.html` / `app.css` からモジュール DOM を削除
  - `<ntp-modules>`、Microsoft Auth iframe、`#modules` 用 CSS、`ntp-customize-buttons` の modules バインディングを削除
  - `app.ts` のモジュール処理は次の 1a-2 で削除するため、今回は残した
  - `app_test.ts` からモジュール専用テストを削除し、undo toast のテストを shortcuts ベースに変更
  - 確認: `autoninja -C out/Release chrome/test/data/webui/new_tab_page:build_ts` 成功
  - 確認: `./scripts/build-chrome.sh` 成功（18:02）
  - 確認: 新規プロファイル + `--no-first-run` で `chrome://new-tab-page/` を開き、CDP で `ntp-app` の shadow root を検査
    - `#modules`: なし
    - `ntp-modules`: なし
    - `iframe#microsoftAuth`: なし
    - `cr-most-visited`: あり
    - `ntp-customize-buttons`: あり
    - `#mybrowserLabel`: `thisismybrowser`
    - `ntp-searchbox`: あり
    - `modulesEnabled_`: false、`modulesLoaded_`: true、`showBrowserPromo_`: true
  - 確認: ブラウザログに `CONSOLE` / `Uncaught` / `TypeError` / `ReferenceError` / `SyntaxError` なし
  - 学び: `chrome` ビルドだけでは WebUI テストの TypeScript は検証されない。テスト変更時は `...:build_ts` も実行する
  - 学び: `app.html` から要素を外すだけなら `app.ts` は未使用コードとして残せる。ただし `app.ts` 内の `$$(this, '#modules')` は null を返すだけで安全
  - 新規プロファイルではショートカットが「ウェブストア」になる。初回起動時は `chrome://intro/welcome` が出るが、`--no-first-run` で回避でき、今回の変更とは無関係
  - コミット: `3a094f68ce`

## 2026-10-22

- NTP モジュール削除 Phase 1a-2: `app.ts` からモジュール用ロジックを削除
  - `modulesEnabled_` / `modulesLoaded_` / `modulesLoadedStatus_` / `modulesShownToUser` を削除
  - Microsoft Auth 用の `ParentTrustedDocumentProxy` import、`MSAL_IFRAME_ORIGIN`、`connectToParentDocument` リスナーを削除
  - `computeModulesLoaded_` / `onModulesLoadedChange_` / `onModulesLoaded_` / `computeShowBrowserPromo_` / `onCustomizeModule_` / `onModulesShownToUserChanged_` / `onModulesAutoRemoved_` を削除
  - `app.html` のプロモ表示条件を `showBrowserPromo_ && browserPromoType_ === 'simple'` から `browserPromoType_ === 'simple'` に変更
  - `recordBrowserPromoMetrics_()` は `firstUpdated()` で常に呼ぶようにし、`showBrowserPromo_` による早期 return を削除
  - `NtpElement.MODULE = 7` と `NtpCustomizeChromeEntryPoint.MODULE = 1` は履歴値なので残した
  - `CustomizeDialogPage.MODULES` は `new_tab_footer/app.ts` が参照しているため残し、`app.ts` 内の case のみ削除した
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release chrome/browser/resources/new_tab_page:build_ts` 成功
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release chrome/test/data/webui/new_tab_page:build_ts` 成功
  - 確認: `./scripts/build-chrome.sh` 成功（18:45）
  - 確認: 新規プロファイル + `--no-first-run` + `--headless=new` で `chrome://new-tab-page/` を開き、CDP で `ntp-app.shadowRoot` を検査
    - `#modules`、`ntp-modules`、`iframe#microsoftAuth`: なし
    - `cr-most-visited`、`ntp-customize-buttons`、`#mybrowserLabel`、`ntp-searchbox`: あり
    - `#mybrowserLabel` のテキスト: `thisismybrowser`
    - `'showBrowserPromo_' in app`: false（プロパティ自体が消えている）
    - `'modulesEnabled_' in app` / `'modulesLoaded_' in app` / `'microsoftModuleEnabled_' in app`: false
    - `browserPromoType_`: `disabled`、`individual-promos`: なし
  - 確認: ブラウザログに `CONSOLE` / `Uncaught` / `TypeError` / `ReferenceError` / `SyntaxError` なし
  - 補足: 表示条件の直接確認のため `app.browserPromoType_ = 'simple'` を一時代入したところ、`individual-promos` が呼ぶ `NtpPromoHandler::RequestPromos()` の CHECK でブラウザが abort した。これはプロモを強制表示した場合の既存 C++ 経路で、通常設定（`disabled`）では発生しない。プロモを有効化する場合は別途調査する
  - 学び: `showBrowserPromo_` は「モジュールが読み込み中か」を考慮するためだけの値だった。モジュールを消したので、テンプレートは `browserPromoType_` だけで判定できる
  - 学び: enum の値を消すと `enums.xml` の履歴とずれる。未使用になっても、記録済みの値は残す
  - 次の作業: Phase 1a-3/1b（`modules/` の WebUI リソース、`lazy_load.ts`、GN の参照削除）

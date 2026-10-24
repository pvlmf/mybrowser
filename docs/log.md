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

## 2026-10-23

- 引き継ぎ時点の実測（コード変更なし）
  - `git status -sb`: `## dev`（クリーン）
  - `git log -1 --oneline`: `e7978632cc docs: link local agent handoff from todo`
  - `git ls-remote origin refs/heads/dev`: `e7978632cc43cf48efa117802e1e4f744c13f285`（ローカルと同じ）
  - `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/browser/resources/new_tab_page:build_ts`: 成功（no work to do）
  - `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/test/data/webui/new_tab_page:build_ts`: 失敗（66 errors / 24 files）
    - モジュール系 13 ファイル: `modules/authentication`、`modules/calendar`、`modules/file_suggestion`、`module_descriptor`、`module_header`、`module_registry`、`module_wrapper`、`modules_test`、`most_relevant_tab_resumption`
    - モジュール以外 11 ファイル: `app_focus_test.ts`、`app_test.ts`、composebox 6、lens 2、voice_search 1
    - 主なエラー: `TS2305`（`chrome://new-tab-page/lazy_load.js` に export がない）、`TS7006`（calendar テストの暗黙 `any`）
    - 原因: `cd41dcc` がモジュールテストをビルドに残したまま `lazy_load.ts` の export を削除し、Composebox / Lens / Voice search の export も一緒に消した
  - `./scripts/build-chrome.sh`: この日は未実行。最後の `chrome` ビルドは 13:52 に成功しているが、`cd41dcc` のコミット後の検証記録はない
  - 実ブラウザ確認: この日は未実施
  - 次の作業: `todo.txt` の Phase 1b Step 1（テスト側の切り離しと通常 export の復元）から

## 2026-10-24

- NTP モジュール削除 Phase 1b Step 1: テスト側の切り離しと通常 export の復元
  - `lazy_load.ts` に Composebox / Lens / Voice search / NTP composebox の通常 export を戻した
  - `chrome/test/data/webui/new_tab_page/BUILD.gn` から `modules.gni` の import と `modules_test_files` を削除
  - `app_focus_test.ts` からモジュール import / `ModuleRegistry` / `PromiseResolver` / モジュール mock を削除
  - `new_tab_page_browsertest.cc` からモジュール suite、`V2Modules`、`CounterfactualModules`、`MicrosoftAuth`、Most Relevant suite を削除
  - `chrome/test/data/webui/new_tab_page/modules/` を削除
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/browser/resources/new_tab_page:build_ts` 成功
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/test/data/webui/new_tab_page:build_ts` 成功（TS エラー 0）
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/test/data/webui:browser_tests` 成功
    - 補足: `chrome/test/data/webui/new_tab_page:build` というビルドターゲットは存在しない。C++ の確認は `chrome/test/data/webui:browser_tests` を使う
  - 確認: `./scripts/build-chrome.sh` 成功（15:20:57）。`chrome` バイナリ自体は再リンクされなかったが、`out/Release/resources.pak` は更新された
  - 確認: 新規プロファイル + `--headless=new` + CDP で `chrome://new-tab-page/` の `ntp-app.shadowRoot` を検査
    - `cr-most-visited`: あり（`lazyRender_` 後に出現）
    - `ntp-customize-buttons`: あり
    - `ntp-searchbox`: あり
    - `#mybrowserLabel`: `thisismybrowser`
    - `#modules` / `ntp-modules` / `iframe#microsoftAuth`: なし
    - モジュール関連プロパティ: なし
    - `browserPromoType_`: `disabled`
    - console error: なし
  - 学び: NTP のショートカットとカスタマイズボタンは `lazyRender_` が true になった後に描画される。CDP 確認では shadow root の存在だけでなく、対象要素の出現まで待つ
  - 学び: `chrome` バイナリのタイムスタンプが古くても、WebUI リソースは `resources.pak` 経由で更新されることがある
  - 学び: テスト C++ のビルドターゲットは `chrome/test/data/webui/new_tab_page:build` ではなく `chrome/test/data/webui:browser_tests`

- NTP モジュール削除 Phase 1b Step 2: 製品 WebUI からモジュール資産を削除
  - `lazy_load.ts` からモジュールの import / export を削除
  - `new_tab_page.gni` から `modules.gni` の import と `modules_ts_files` / `modules_web_component_files` / `modules_css_files` を削除
  - `resources/new_tab_page/BUILD.gn` からモジュールのアイコン、grdp、Mojo の依存を削除
  - `new_tab_page.ts` からモジュール用の Mojo export を削除
  - `chrome/browser/resources/new_tab_page/modules/`（77 ファイル）を削除
  - 未使用になっていた `test_support.ts` の `initNullModule()` を削除
  - 注意: `ntp_microsoft_auth_shared_ui` の Mojo 依存は残した。`new_tab_page.mojom-webui.ts` が同ファイルを import しており、削除すると `TS6307` で製品 TS が失敗する
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/browser/resources/new_tab_page:build_ts` 成功
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/test/data/webui/new_tab_page:build_ts` 成功（TS エラー 0）
  - 確認: `PATH="$HOME/depot_tools:$PATH" autoninja -C out/Release -j 6 chrome/test/data/webui:browser_tests` 成功
  - 確認: `./scripts/build-chrome.sh` 成功（15:25:50、`chrome` も再リンク）
  - 確認: 新規プロファイル + `--headless=new` + CDP で `chrome://new-tab-page/` の `ntp-app.shadowRoot` を検査
    - `cr-most-visited`: あり
    - `ntp-customize-buttons`: あり
    - `ntp-searchbox`: あり
    - `#mybrowserLabel`: `thisismybrowser`
    - `#modules` / `ntp-modules` / `iframe#microsoftAuth`: なし
    - モジュール関連プロパティ: なし
    - console error: なし
  - 学び: モジュール用に見える Mojo 依存でも、`new_tab_page.mojom-webui.ts` から推移的に import されているものは残す必要がある。削除前に生成 TS の import を確認する
  - 学び: `new_tab_page.ts` はテスト向けの再 export ファイルなので、モジュールテストを消すとモジュール用 Mojo export も安全に消せる


## 2026-10-24（AI / Google 連携の初期棚卸し）

- GitHub 上の `dev` のソースを静的に確認し、`docs/features.md` の NTP 以外の台帳を初期化
- 主に確認した入口と実装:
  - Glic / Gemini / Actor: `chrome/common/chrome_features.cc`、`chrome/browser/glic/public/features.cc`、`chrome/browser/ui/browser_actions.cc`、toolbar / tab-strip の Glic 連携
  - Omnibox AI Mode / マルチモーダル: `components/omnibox/common/omnibox_features.cc`、`components/omnibox/browser/omnibox_field_trial.cc`、`chrome/browser/ui/browser_actions.cc`
  - History Embeddings: `components/history_embeddings/core/history_embeddings_features.cc`、`chrome/browser/history_embeddings/history_embeddings_utils.cc`、`chrome/browser/history_embeddings/history_embeddings_service_factory.cc`、History WebUI
  - Built-in AI: `chrome/browser/ai/BUILD.gn`、Blink AI Mojo、`components/on_device_ai`、設定ハンドラー
  - Optimization Guide: `components/optimization_guide/core/optimization_guide_features.cc` と browser / component ディレクトリ
  - Organizer Panel: `chrome/browser/ui/tabs/organizer/`、`chrome/browser/ui/views/tabs/organizer/`、`chrome/browser/ui/webui/organizer_panel/`
  - History の Google リンク / プロモ: `chrome/browser/ui/webui/history/history_ui.cc`、`chrome/browser/resources/history/`
  - Sign-in / Sync: `chrome/browser/ui/webui/signin/`、`components/signin/`、`components/sync/`
- 確認結果:
  - Linux では Glic の親 feature `features::kGlic` が既定無効。ただし他プラットフォームでは既定有効で、ソースと子機能は存在する
  - History Embeddings と AI Overlay Dialog は主機能フラグが既定無効だが、関連 UI / 実装 / 依存 target は残っている
  - Optimization Guide は AI 以外のページ最適化・予測機能とも共有されるため、全体削除の対象にしない
  - Organizer Panel の AI との直接の関係は今回未確認。別機能として扱う
  - History UI には Google My Activity / Gemini アプリ活動へのリンクと Sync / サインイン案内がある
- これはソースを読んだ静的調査。ローカルの `gn refs`、ビルド、テスト、実ブラウザ確認は未実施。コード変更も行っていない
- 次の作業: AI Overlay Dialog または History の Google / 同期案内 UI を対象に、参照・GN target・Mojo・テストを詳細追跡する


## 2026-10-24（AI Overlay Dialog の削除計画）

- Overlay の専用入口・Controller・toolbar ActionItem・untrusted WebUI / Mojo・Android JNI・Profile pref・feature flags・URL/switch definitions・GN target を調査
- 削除計画を `docs/notes/2026-10-24-ai-overlay-dialog-removal-plan.md` に作成
- 方針: Overlay 専用コードは切り離し候補。Glic / TTC core / Actor / Optimization Guide / Page Content Annotations など共有基盤は削除しない
- `chrome/browser/ttc/resources/` は Overlay UI 専用と見られるが、削除前にローカル `gn refs` で別 consumer がないことを確認する
- 今回は計画のみ。ローカル参照全文検索、GN、ビルド、テスト、実ブラウザ確認は未実施。次は隔離した候補ブランチでソース変更を行い、ローカルビルドと実ブラウザ確認後に `dev` へ統合する

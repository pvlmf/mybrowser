# NTP モジュール削除計画

日付: 2026-10-22
状態: 計画のみ（コードはまだ削除しない）

## ゴール

- NTP のモジュールをユーザーに見せない（2026-10-21 に無効化済み）
- 可能な範囲でコード・ビルド依存・設定・テストを削除する
- 上流追従のコストを増やしすぎない

## 現状

- `NewTabPageUI::OnLoad()` で `modulesEnabled` を false に固定済み
- NTP に `#modules` は出ない。ショートカット・カスタマイズは動作する
- ただし、モジュールの WebUI / C++ / Mojo / prefs / テストは残っている

## モジュールの全体像

```text
app.html / app.ts
  ├─ <ntp-modules> ─ lazy_load.ts ─ modules/modules.ts
  │    ├─ module_registry.ts / module_descriptors.ts
  │    ├─ calendar / file_suggestion / most_relevant_tab_resumption / tab_groups
  │    └─ authentication（Microsoft 認証）
  ├─ Microsoft 認証 iframe（chrome-untrusted://ntp-microsoft-auth）
  └─ browser promo / undo toast（modulesEnabled_ と連動）

C++:
NewTabPageUI
  ├─ module_id_details_（MakeModuleIdDetails）
  ├─ BindInterface(各モジュール handler)
  └─ NewTabPageHandler
       ├─ PageHandler のモジュール API
       ├─ prefs / HaTS / Microsoft 認証
       └─ modules/ 以下のバックエンド

Customize Chrome サイドパネル:
  ├─ cards.ts → CustomizeChromePageHandler のモジュール設定
  └─ modulesEnabled / ModuleSettings
```

## 主な参照箇所

| 層 | ファイル | 内容 |
|---|---|---|
| WebUI | `resources/new_tab_page/app.html` | `<ntp-modules>`、Microsoft 認証 iframe、undo toast 条件 |
| WebUI | `resources/new_tab_page/app.ts` | `modulesEnabled_`、`modulesShownToUser`、`modulesLoadedStatus_`、モジュールイベント |
| WebUI | `resources/new_tab_page/lazy_load.ts` | モジュール各要素の import / export |
| WebUI | `resources/new_tab_page/modules/**` | モジュール本体（TS/CSS/HTML/アイコン） |
| WebUI | `resources/new_tab_page/new_tab_page.gni` | `modules.gni` の import とファイル配列 |
| WebUI | `resources/new_tab_page/BUILD.gn` | アイコン、grdp、Mojo の依存 |
| C++ | `ui/webui/new_tab_page/new_tab_page_ui.cc/.h` | `module_id_details_`、モジュール handler、文字列、loadTimeData |
| C++ | `ui/webui/new_tab_page/new_tab_page_handler.cc/.h` | モジュール API、prefs、HaTS、Microsoft 認証 |
| Mojo | `ui/webui/new_tab_page/new_tab_page.mojom` | `ModuleIdName`、`PageHandler` / `Page` のモジュール API |
| C++ | `browser/new_tab_page/modules/**` | カレンダー、ファイル提案、タブ再開、タブグループ |
| C++ | `browser/new_tab_page/microsoft_auth/**` | Microsoft 認証サービス |
| C++ | `ui/webui/ntp_microsoft_auth/**` | Microsoft 認証用の untrusted UI |
| 設定 | `components/search/ntp_features.*` | モジュール用フィーチャーフラグ |
| 設定 | `chrome/common/pref_names.h` | モジュール表示・無効化・並び順などの prefs |
| カスタマイズ | `resources/side_panel/customize_chrome/**` | 「カード」セクションと `cards.ts` |
| カスタマイズ | `ui/webui/side_panel/customize_chrome/**` | `ModuleSettings`、モジュール設定 API |
| テスト | `chrome/test/data/webui/new_tab_page/modules/**` | モジュールの WebUI テスト |
| テスト | 各 `*_unittest.cc` / `*_browsertest.cc` | handler / util / customize のモジュールテスト |

## 依存の要点

- `app.ts` の `modulesEnabled_` は、モジュール表示だけでなく **browser promo** と **undo toast** にも使われている
- `modulesShownToUser` は `ntp-customize-buttons` にも渡されている（共有コンポーネント）
- `new_tab_page_handler` はモジュール API と HaTS、prefs、Microsoft 認証が同じクラスに混在している
- `NewTabPageUI` は各モジュールの Mojo handler を `BindInterface` で生成している
- `sync_service_` と `segmentation_platform_service_` は、現状 `NewTabPageHandler` の初期化以外で使われていない（モジュール用の渡し残し）
- `customize_chrome` サイドパネルは、NTP とは別にモジュール設定 API を持っている
- `ntp_microsoft_auth` はモジュール専用の可能性が高いが、navigation throttle など共有登録がある
- `ntp_features` のフラグは、他の NTP 機能やテストから参照されているものがある。**一括削除しない**

## 削除の段階

### Phase 0: 無効化（完了）

- `modulesEnabled` を false に固定
- `#modules` が出ないことを実ブラウザで確認済み

### Phase 1: NTP フロントエンドからモジュールを外す

#### 1a. `app.html` / `app.ts` からモジュール UI を外す

変更対象:

- `chrome/browser/resources/new_tab_page/app.html`
- `chrome/browser/resources/new_tab_page/app.ts`
- `chrome/browser/resources/new_tab_page/customize_dialog_types.ts`
- `chrome/test/data/webui/new_tab_page/app_test.ts`

内容:

- Microsoft 認証 iframe を削除
- `<ntp-modules>` ブロックを削除
- `ntp-customize-buttons` への `modules-shown-to-user` バインドを削除
- undo toast の条件から `modulesEnabled_` を削除
- `app.ts` から以下を削除
  - `ModuleLoadStatus`
  - `MSAL_IFRAME_ORIGIN`
  - `ParentTrustedDocumentProxy` の import
  - `modulesEnabled_` / `modulesShownToUser` / `modulesLoaded_` / `modulesLoadedStatus_`
  - `microsoftModuleEnabled_` / `microsoftAuthIframePath_`
  - `onModulesLoaded_` / `onModulesLoadedChange_` / `onModulesShownToUserChanged_`
  - `onCustomizeModule_` / `onModulesAutoRemoved_`
  - `connectMicrosoftAuthToParentDocumentListenerId_` と listener 登録・解除
  - `computeModulesLoaded_` / `computeShowBrowserPromo_` のモジュール依存部分
  - `CustomizeDialogPage.MODULES` の分岐
- `customize_dialog_types.ts` から `MODULES` を削除
- `app_test.ts` からモジュール関連の suite / import を削除

この段階では `modules/` のファイルと `lazy_load.ts` の export は残す。
理由: 変更を小さくし、WebUI テストの module_registry などは次の段階まで維持するため。

確認:

- `./scripts/build-chrome.sh`
- NTP を開き、`#modules` がないこと
- ラベル、ショートカット、カスタマイズ、検索ボックスが残ること
- console error がないこと
- 可能なら `chrome/test/data/webui/new_tab_page:build` をビルド

#### 1b. モジュールの WebUI リソースを削除する

変更対象:

- `chrome/browser/resources/new_tab_page/modules/**`（ディレクトリごと）
- `chrome/browser/resources/new_tab_page/lazy_load.ts`
- `chrome/browser/resources/new_tab_page/new_tab_page.gni`
- `chrome/browser/resources/new_tab_page/BUILD.gn`
- `chrome/test/data/webui/new_tab_page/modules/**`（ディレクトリごと）
- `chrome/test/data/webui/new_tab_page/BUILD.gn`

内容:

- `lazy_load.ts` からモジュールの import / export を削除
- `new_tab_page.gni` から `import("./modules/modules.gni")` と
  `modules_ts_files` / `modules_web_component_files` / `modules_css_files` を削除
- `resources/new_tab_page/BUILD.gn` からモジュールの
  `icons_html_files` / `extra_grdp_files` / `extra_grdp_deps` /
  `mojo_files_deps` / `mojo_files` を削除
- モジュールの WebUI テストと `modules.gni` を削除
- `app_test.ts` に残ったモジュール import を削除

確認:

- `./scripts/build-chrome.sh`
- NTP の実ブラウザ確認（1a と同じ）
- `git grep -n "ntp-modules\|modules.gni\|module_descriptors" -- chrome/browser/resources/new_tab_page chrome/test/data/webui/new_tab_page`

#### 1c. Customize Chrome の「カード」セクションを外す

変更対象:

- `chrome/browser/resources/side_panel/customize_chrome/app.ts`
- `chrome/browser/resources/side_panel/customize_chrome/app.html.ts`
- `chrome/browser/resources/side_panel/customize_chrome/cards.ts`
- `chrome/browser/resources/side_panel/customize_chrome/cards.html.ts`
- `chrome/browser/resources/side_panel/customize_chrome/cards.css`
- `chrome/browser/resources/side_panel/customize_chrome/BUILD.gn`
- `chrome/test/data/webui/side_panel/customize_chrome/cards_test.ts`

内容:

- `import './cards.js';` と `customize-chrome-cards` のセクションを削除
- `modulesEnabled_` と `CustomizeChromeSection.kModules` のマッピングを削除
- `cards.*` とテストを削除
- `CustomizeChromePageHandler` の `SetModulesVisible` / `SetModuleDisabled` /
  `UpdateModulesSettings` と `module_id_details_` を削除
- `customize_chrome.mojom` の `ModuleSettings` とモジュール設定 API を削除
- `customize_chrome_ui.cc/.h` の `module_id_details_`、`modulesEnabled`、
  「カード」関連の文字列を削除

確認:

- `./scripts/build-chrome.sh`
- NTP からカスタマイズを開き、「カード」セクションがないこと
- 背景・テーマ・ショートカットが動くこと

### Phase 2: NTP のモジュール API と handler を削除する

変更対象:

- `chrome/browser/ui/webui/new_tab_page/new_tab_page.mojom`
- `chrome/browser/ui/webui/new_tab_page/new_tab_page_handler.cc/.h`
- `chrome/browser/ui/webui/new_tab_page/new_tab_page_ui.cc/.h`
- `chrome/browser/chrome_browser_interface_binders_webui.cc`
- `chrome/browser/chrome_browser_interface_binders_webui_parts_desktop.cc`
- `chrome/browser/ui/webui/new_tab_page/BUILD.gn`
- 各 `*_unittest.cc` / `*_browsertest.cc`

内容:

- `new_tab_page.mojom` から `ModuleIdName` と
  `PageHandler` / `Page` のモジュール API を削除
- `NewTabPageHandler` からモジュール API、prefs 監視、HaTS のモジュール処理、
  Microsoft 認証 observer、`module_id_details_` を削除
- 使われていない `sync_service_` / `segmentation_platform_service_` の
  コンストラクタ引数とメンバーを削除
- `NewTabPageUI` から `module_id_details_`、各モジュール handler、
  `BindInterface` のオーバーロード、モジュール用 loadTimeData / 文字列を削除
- `chrome_browser_interface_binders_webui*.cc` からモジュールの binder 登録を削除
- モジュール関連テストを削除

確認:

- `./scripts/build-chrome.sh`
- `autoninja -C out/Release unit_tests`（可能なら）
- `out/Release/unit_tests --gtest_filter='NewTabPageHandlerTest.*'`
- NTP とカスタマイズの実ブラウザ確認

### Phase 3: C++ バックエンドをモジュール単位で削除する

小さく分ける。1つ消すごとにビルドする。

1. `modules/v2/tab_groups`
2. `modules/v2/most_relevant_tab_resumption`
3. `modules/v2/calendar`
4. `modules/file_suggestion`（Drive / Microsoft Files）
5. `modules/` の共通部分
   - `new_tab_page_modules.*`
   - `modules_constants.h`
   - `modules_switches.*`
   - `test_support.*`
   - 各 unittest / interactive_uitest
6. Microsoft 認証
   - `browser/new_tab_page/microsoft_auth/**`
   - `ui/webui/ntp_microsoft_auth/**`
   - navigation throttle / untrusted UI の登録
7. `new_tab_page_util` のモジュール用ヘルパー
   - `IsDriveModuleEnabledForProfile` など
   - `new_tab_page_util_browsertest.cc` のモジュールテスト

各項目で:

- 対象ディレクトリ / `BUILD.gn` の target と deps を削除
- `DEPS` / `OWNERS` を削除
- `git grep` で参照が残っていないことを確認
- `./scripts/build-chrome.sh`

### Phase 4: 設定・文字列・テスト・BUILD の後片付け

- `components/search/ntp_features.h/.cc` のモジュール用フラグ
  - 参照が残っていないものだけ削除
  - `kNtpChromeCartModule` など、他機能と共有している可能性があるものは個別確認
- `chrome/common/pref_names.h` のモジュール prefs
- `components/ntp_tiles/pref_names.*` のモジュール prefs
- モジュール用の `IDS_NTP_MODULES_*` / Microsoft 認証の文字列
- モジュールのアイコン / grdp
- WebUI テスト、unit tests、browser tests の残り
- 各 `BUILD.gn` の不要な deps
- `docs/customizations.md` / `docs/log.md` / `docs/features.md` の更新

## リスク

| リスク | 内容 | 対策 |
|---|---|---|
| `app.ts` の挙動変化 | browser promo / undo toast / customize buttons と結合 | 1a で promo の条件を簡素化し、実ブラウザで確認 |
| handler の巨大化 | モジュール API と HaTS / prefs / Microsoft 認証が混在 | Phase 2 でまとめて外す。テストで確認 |
| 共有コンポーネント | `ntp-customize-buttons` は footer と共有 | NTP 側のバインドだけ外す。共有側はすぐ消さない |
| Microsoft 認証 | untrusted UI / navigation throttle と結合 | Phase 3 で参照を確認してから削除 |
| フラグの共有 | `ntp_features` は他機能も参照 | 1つずつ `grep` してから削除 |
| 上流との衝突 | `app.ts` / handler / mojom / BUILD は衝突しやすい | Phase 1 で止める選択肢も持つ |

## 推奨する進め方

**最初は Phase 1a + 1b まで**を推奨する。

- ユーザーに見えるモジュール UI と WebUI リソースが消える
- C++ のバックエンドは残るが、NTP からは呼ばれない
- 上流との衝突を最小限にできる
- ここで一度ビルド・実ブラウザ確認・コミットし、負荷を調整できる

Phase 2 以降は、ビルド時間やコード量の削減効果と、上流追従の衝突コストを比べて決める。
「ユーザーに見えなければよい」なら Phase 1 で止めてよい。
「コードも減らしたい」なら Phase 2 → 3 → 4 と小さく進める。

## 確認コマンド

```bash
cd /home/pvlmf/Projects/mybrowser/src

# ビルド
./scripts/build-chrome.sh

# 参照確認の例
git grep -n "ntp-modules\|modulesEnabled\|modulesShownToUser" \
  -- chrome/browser/resources/new_tab_page chrome/browser/ui/webui/new_tab_page

git grep -n "MakeModuleIdDetails\|HasModulesEnabled\|ModuleIdDetail" \
  -- chrome/browser

git grep -n "GetModules\|SetModulesVisible\|SetModulesDisabled" \
  -- chrome/browser/ui/webui/new_tab_page

# 実ブラウザ確認（CDP スクリプトは /tmp/opencode/cdp-check.mjs）
# Phase 1a 以降は modulesEnabled_ がなくなるため、
# 「#modules がない」「ショートカットがある」「ラベルがある」を中心に確認する
```

## 次の一歩

Phase 1a の変更案を作り、ビルド＋実ブラウザ確認してからコミットする。

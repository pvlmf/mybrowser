# AI Overlay Dialog 削除計画

更新日: 2026-10-24
対象ブランチ: `dev`（計画作成時点）
状態: **候補ブランチに専用コード削除案を作成。ローカル GN / ビルド / テスト検証待ち。**

## 目的と範囲

Chromium に含まれる試作の AI Overlay Dialog を削除する。これはマイク入力・音声応答・現在のタブのページ文脈・WebMCP ツール・Remembered Notes を持つ独立したオーバーレイで、通常の検索、タブ、履歴、ブックマーク、Glic 本体とは区別する。

`chrome/browser/ui/ui_features.cc` では `kAiOverlayDialog` が `FEATURE_DISABLED_BY_DEFAULT` であり、コメントにも試作状態で本番利用しないよう明記されている。**無効化されていることをコード削除済みと誤認しない。** 今回は UI / Controller / Action / WebUI / Mojo / Android bridge とその専用設定・GN 参照を削除候補にする。

## 入口からたどった依存

### 1. 表示・起動経路

- `chrome/browser/ui/browser_actions.cc`: Glic のプロフィール適格性と `features::kAiOverlayDialog` を条件に `kActionShowAiOverlayDialog` ActionItem を登録し、`AiOverlayDialogController::ToggleOverlay()` を呼ぶ。専用の `AiOverlayToolbarButton` factory もここで登録する。
- `chrome/browser/ui/views/toolbar/toolbar_view.cc`: 同じ feature gate を使い ActionItem の表示・有効化・ピン状態を更新する。
- `chrome/browser/ui/browser_window/internal/browser_window_features.cc`: 通常ウィンドウで feature が有効な場合に `AiOverlayDialogControllerViews` を構築し、終了処理で破棄する。
- `chrome/browser/ui/views/toolbar/ai_overlay_toolbar_button.{h,cc}`: マイク／一時停止アイコン、キャプション・ペルソナ設定、Remembered Notes へのリンクを実装する。
- `chrome/browser/ui/browser_window/public/browser_window_features.h`: Controller の forward declaration と所有メンバーを持つ。
- `chrome/browser/ui/actions/chrome_action_id.h`: `kActionShowAiOverlayDialog` を宣言する。

### 2. WebUI とリソース

- `chrome/browser/ui/webui/ai_overlay_dialog/`: untrusted WebUI、PageHandler、Mojo、ページ文脈監視、Markdown builder、WebMCP tools、専用テストを持つ。
- `chrome/browser/ui/webui/chrome_untrusted_web_ui_configs.cc`: `AiOverlayDialogUntrustedUIConfig` を untrusted WebUI registry に登録する。
- `chrome/browser/ttc/resources/`: `chrome-untrusted://ai-overlay-dialog/` と Notes ページの専用 WebUI 資産。候補ブランチではこれらも削除対象に含めた。
- `chrome/common/webui_url_constants.h`: `chrome-untrusted://ai-overlay-dialog/` の host / URL 定数。
- `chrome/common/chrome_switches.h`: 自動起動・テスト API 用の `--ai-overlay-dialog-test-mode` スイッチ。

### 3. Feature / Profile pref / Android

- `chrome/browser/ui/ui_features.h/.cc`: `kAiOverlayDialog`、Dev・API key・mock JSON path・MES・Page Tools・Next と navigation-context 用 feature / params。
- `chrome/browser/prefs/browser_prefs.cc`: `AiOverlayDialogController::RegisterProfilePrefs()` を呼び、Remembered Notes 用 dictionary pref `ai_overlay.remembered_notes` を登録する。
- `chrome/browser/ui/android/ai_overlay_dialog/`: 専用 Java / JNI bridge。コメントによると、現在は JNI が Android APK 全体へ取り込まれるため、Android での build 参照も外す必要がある。
- GN の直参照は主に `chrome/browser/BUILD.gn`、`chrome/browser/ui/BUILD.gn`、`chrome/browser/ui/browser_window/internal/BUILD.gn`、`chrome/browser/ui/views/toolbar/BUILD.gn`、`chrome/browser/ui/webui/BUILD.gn` にある。

## 削除計画

### Phase A: 入口を切り離す

1. `browser_actions.cc` から Overlay ActionItem / custom toolbar button factory と Controller / Button の include を外す。
2. `toolbar_view.cc/.h` から Overlay の可視化ロジックと専用メンバーを外す。
3. `browser_window_features.h` と `browser_window/internal/browser_window_features.cc` から専用 Controller の所有、初期化、破棄を外す。
4. `browser_prefs.cc` から専用 Controller の include / pref registration を外す。
5. `chrome_untrusted_web_ui_configs.cc` から専用 WebUI config 登録を外す。

### Phase B: feature / ID / URL / GN を整理する

1. `chrome_action_id.h`、`ui_features.h/.cc`、`webui_url_constants.h`、`chrome_switches.h` の Overlay 専用宣言を削除する。
2. 以下の BUILD 参照を削除する。
   - `chrome/browser/ui/BUILD.gn`
   - `chrome/browser/ui/browser_window/internal/BUILD.gn`
   - `chrome/browser/ui/views/toolbar/BUILD.gn`
   - `chrome/browser/ui/webui/BUILD.gn`
   - `chrome/browser/BUILD.gn`
3. 専用ソースツリーを削除する。
   - `chrome/browser/ui/ai_overlay_dialog/`
   - `chrome/browser/ui/views/toolbar/ai_overlay_toolbar_button.cc/.h`
   - `chrome/browser/ui/webui/ai_overlay_dialog/`（tools / Mojo / tests を含む）
   - `chrome/browser/ui/android/ai_overlay_dialog/`
   - `chrome/browser/ttc/resources/`（Overlay UI / Notes の専用資産。候補ブランチでは削除済み。ローカル GN generation で別 consumer が判明した場合は復元して依存を再分離）
4. generated Grit / Mojo の名前や生成先は手書きで直接変更せず、GN / WebUI のソースと依存から再生成させる。

### Phase C: 残存参照と回帰を確認する

ローカルで実装前後に次を確認する。GitHub 上の静的閲覧では `gn refs` を実行できないため、実装前の正確な参照数はまだ確定していない。

```sh
rg -n 'AiOverlayDialog|ai_overlay_dialog|kAiOverlayDialog|kActionShowAiOverlayDialog|kChromeUIAiOverlayDialog|kAiOverlayDialogTestMode' chrome
gn refs out/Release //chrome/browser/ui/ai_overlay_dialog
gn refs out/Release //chrome/browser/ui/webui/ai_overlay_dialog
gn refs out/Release //chrome/browser/ui/android/ai_overlay_dialog
gn refs out/Release //chrome/browser/ttc/resources
```

削除後は `rg` の結果を確認し、ドキュメント中の記録を除くソース参照をゼロにする。GN target 自体がなくなるため、削除前の `gn refs` は事前に保存する。

推奨の検証順:

1. 変更した各 `BUILD.gn` の生成構成を `gn gen out/Release` で確認。
2. `autoninja -C out/Release -j 6 browser_tests unit_tests` でテスト実行ファイルまでリンクできることを確認する（必要に応じてプロジェクト環境で有効なターゲット名へ調整）。
3. `./scripts/build-chrome.sh` で本体ビルド。
4. 実ブラウザで通常起動、NTP、omnibox 検索、履歴、設定、タブ操作を確認。ツールバーに Overlay の Action がなく、`chrome-untrusted://ai-overlay-dialog/` が登録されていないことも確認する。
5. 実行したコマンド、成功 / 失敗、DOM・コンソール結果を `docs/log.md` に残してから `dev` へ統合する。

## 削除しない共有基盤

以下は他機能との共有や、別の入口があるため今回の対象外にする。

- `chrome/browser/glic/` と Glic keyed service / eligibility
- `chrome/browser/ttc/core/`、`chrome/browser/ttc/app/`、`components/ttc/app/`
- `components/actor/` / Actor UI
- `chrome/browser/optimization_guide/`、`components/optimization_guide/`
- `chrome/browser/page_content_annotations/`、`components/page_content_annotations/`
- Component Updater、モデル実行サービス等の共有基盤
- TTC core 内の `ttc::EntrypointController` など、AI Overlay Dialog と別の BrowserWindow feature

この区別を崩してディレクトリごと削除すると、Overlay 以外の機能まで壊す可能性がある。

## 候補ブランチの実装案

- ブランチ: [`agent/remove-ai-overlay-dialog`](https://github.com/pvlmf/mybrowser/tree/agent/remove-ai-overlay-dialog)
- Overlay 専用の Action / Controller / WebUI / Mojo / Android bridge、feature / pref / URL / test switch、GN 参照を削除する変更案を作成した
- 専用の Controller 9 ファイル、WebUI / Mojo / tools / tests 30 ファイル、Android bridge 4 ファイル、toolbar button 2 ファイル、TTC UI / Notes 資産 27 ファイル、計 72 ファイルを削除し、残っていた `chrome/browser/ttc/resources/internal` gitlink も削除した
- 追加で `ContentsContainerView` の埋め込み WebView、Element Identifier、frame GN dependency、browser / unit test aggregate の残存参照を削除
- 関連する主要 BUILD.gn では、TTC resources の consumer は削除した Overlay WebUI 以外に見つからなかった。ただしローカル `gn refs` は未実施のため、GN generation で確認する
- この段階のコミットは候補ブランチ上のレビュー・ビルド用。ローカル検証前に `dev` へマージしない

## 現時点の制約

- 本計画は GitHub 上のソースと BUILD 定義を読む静的調査に基づく。
- ローカルの全ソース参照検索、`gn refs`、ビルド、テスト、実ブラウザ確認は未実施。
- よって、削除安全性の最終判定はローカル検証後に行う。
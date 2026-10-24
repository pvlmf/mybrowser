# 機能台帳と削減計画

## 目的

- ブラウザの機能を洗い出し、使う／使わないを決める
- 削減の順番とリスクを記録する
- 削除したもの・残したものを後から追えるようにする
- 保守する範囲を小さくする

「全機能」は、まず**ユーザーに見える機能**を単位にする。
内部の部品（mojo、サービス等）は、それを支える機能を調べるときだけ追う。

## 判断の種類

| 判断 | 意味 | 方法 | 上流更新への影響 |
|---|---|---|---|
| Keep | 残す | そのまま | なし |
| Hide | UI から隠す | CSS / HTML / フラグ | 小 |
| Disable | ビルドから外す | GN args / feature flags | 小〜中 |
| Remove | コードを削除 | ファイル削除 + `BUILD.gn` 更新 | 大（衝突） |
| Defer | 後で決める | 保留 | なし |

## 削除の原則

1. **一度に1機能だけ**変える
2. **Hide → Disable → Remove** の順で試す（いきなり消さない）
3. 各段階でビルド・起動・目視確認
4. **1機能 = 1コミット**（戻せるように）
5. 上流を追う場合、`Remove` は自己完結した機能だけにする
6. 削除前に参照を調べる（`grep -rn`、`BUILD.gn`、`gn refs`）
7. 削除したファイルの一覧をこの文書に残す

## 上流更新との関係

Chromium の更新（特にセキュリティ修正）を追う場合、コード削除はマージ衝突の原因になる。

- **自己完結した機能**（NTP のモジュールなど）→ `Remove` しやすい
- **深く統合された機能**（sync、extensions、autofill など）→ `Disable`（GN args）に留める
- どうしても消す場合は、削除コミットを小さく分け、`docs/log.md` に記録する

推奨: **上流は追う。削除は WebUI / Views の自己完結機能から。サービス系は GN args で無効化。**

手順とコンフリクト解消は [upstream.md](upstream.md) を参照。コンフリクトは自分でコードを読んで直す。

## 機能グループと順番（大まかな全体順）

| 順 | グループ | 例 | 主な場所 | リスク | 学ぶこと |
|---|---|---|---|---|---|
| 1 | NTP | モジュール、composebox、Lens、action chips、カスタマイズ | `chrome/browser/resources/new_tab_page/` | 低 | WebUI、`BUILD.gn` |
| 2 | ツールバー・Omnibox | サイドパネル、Cast、Lens、音声検索、QR | `chrome/browser/ui/views/toolbar/`、`omnibox/` | 中 | Views、commands |
| 3 | タブ | タブグループ、タブ検索、ホバーカード | `chrome/browser/ui/views/tabs/` | 中 | Views、Browser |
| 4 | パネル・ブックマーク | サイドパネル、ブックマークバー | `ui/views/side_panel/`、`chrome/browser/bookmarks/` | 中 | Views、prefs |
| 5 | メニュー・ショートカット | アプリメニュー項目、キーボードショートカット | `ui/views/toolbar/`、`ui/accelerator*` | 低〜中 | commands |
| 6 | 設定画面 | 削除した機能の設定項目 | `resources/settings/`、`chrome/browser/prefs/` | 中 | WebUI、prefs |
| 7 | 履歴・ブックマーク・DL | 各サービス | `chrome/browser/history/`、`bookmarks/`、`downloads/` | 高 | services、prefs |
| 8 | 拡張機能・テーマ | extensions、themes | `extensions/`、`chrome/browser/themes/` | 高 | services |
| 9 | 同期・アカウント | sync、signin、profiles | `sync/`、`signin/`、`profiles/` | 高 | services |
| 10 | メディア・DevTools | メディアコントロール、DevTools | `media/`、`devtools/` | 高 | 深い依存 |

順番の理由:

- 上から順に「見える・自己完結・戻しやすい」
- 下に行くほど「深く統合・壊れやすい・上流と衝突しやすい」
- 各グループで Hide → Disable → Remove を1周すると、層ごとの学びになる

## AI 機能の方針

- ブラウザに AI を極力出さない
- 「出さない」は、まず UI を隠す／無効化することを指す。コード削除は保守性のための別判断
- 対象（NTP）: composebox、Lens、action chips、AI モジュール（タブ再開・ファイル提案）
- 対象（ブラウザ全体）: 履歴の AI 検索、タブ整理、Optimization Guide など。棚卸しで追加する
- 順番: Hide → Disable → Remove
- 深い AI サービスは GN args / feature flags で無効化し、コードは消さない（上流追従のため）
- 新しい AI 機能が上流に入ってきたら、同じ方針で無効化する

## Google 連携の方針

- Google アカウント・Google サービスとの連携を極力削る
- ここでいう「Google 連携」は、アカウント・サービス連携を指す。検索エンジンとしての Google は別項目として扱う
- 対象: OneGoogleBar、Google サービス系モジュール（カレンダー、Drive）、Google AI（composebox、Lens、action chips）、sync / signin など
- 残す: Safe Browsing、コンポーネント更新（セキュリティ・安定性のため）
- 順番: Hide → Disable → Remove。深い連携は GN args / feature flags で無効化
- 検索エンジンを Google 以外に変えるかは、別途決める

## 最初の対象: NTP（Stage 1 の入口）

| # | 機能 | 説明 | AI | 使う? | 判断 |
|---|---|---|---|---|---|
| 1 | モジュール（カード） | ショートカット下のカード（カレンダー、Drive/OneDrive、タブ再開、タブグループ） | 一部 | いいえ | **WebUI 資産削除済み**（C++ バックエンド等は維持） |
| 2 | composebox | 検索ボックス内の AI 作成・添付 UI | はい | — | **無効化済み**（AI 方針） |
| 3 | Lens | 画像で検索する機能 | はい | — | **無効化済み**（AI 方針） |
| 4 | action chips | 検索ボックス下の AI 提案チップ（Deep Search、画像生成など） | はい | — | **無効化済み**（AI 方針） |
| 5 | カスタマイズ（背景・テーマ） | 背景・テーマ・ショートカット表示の設定 | いいえ | はい | Keep |
| 6 | OneGoogleBar | 上部の Google アカウント/アプリバー | いいえ | いいえ | **無効化済み**（Google 連携） |
| 7 | ショートカット | よく使うサイトのタイル | いいえ | はい | **Keep** |
| 8 | 音声検索 | マイクで音声入力する | いいえ（Google 連携） | いいえ | **無効化済み** |
| 9 | realbox next（AI Mode） | 検索ボックスの AI Mode 表示 | はい | — | **無効化済み** |

### 各機能の補足

- **モジュール**: `chrome/browser/resources/new_tab_page/modules/`。カレンダー、Drive/OneDrive のファイル提案、最近のタブの再開、タブグループなど。タブ再開・ファイル提案はランキング/ML を使うため AI 系として扱う。方針: 全モジュールを Remove 候補（Google/外部サービス + AI）。使うものがあれば個別に残す。
- **composebox**: `ntp_composebox.*`、`chrome/browser/ui/webui/new_tab_page/composebox/`。フラグ `ntp_composebox::kNtpComposebox`（デフォルト有効）。
- **Lens**: `lens_form.*`、`lens_upload_dialog.*`、`components/lens/`。フラグ `lens::kLensStandalone` など。omnibox と共有する部分があるため、コード削除は慎重に。
- **action chips**: WebUI は `chrome/browser/resources/new_tab_page/action_chips/`、C++ は `chrome/browser/ui/webui/new_tab_page/action_chips/`。現在は `AreActionChipsEnabled()` が `false` を返すため無効化されているが、TS の import/export、GN 依存、C++ handler/generator/metrics、Mojo 参照、実ファイルは残っている。**Remove は未実施**。削除前に入口から依存を追い、他機能との共有部品を切り分ける。
- **カスタマイズ**: `customize_buttons_proxy.ts`、`side_panel/customize_chrome/`。背景画像・テーマに必要なので Keep。
- **OneGoogleBar**: `chrome/browser/new_tab_page/one_google_bar/`。方針: 使わないので Hide → Remove（Google 連携）。
- **ショートカット**: `cr-most-visited`（共有コンポーネント）。`ntp_features::kNtpShortcuts`。

### 決定事項（2026-10-21）

- AI 機能は出さない（Hide → Disable → Remove）
- Google 連携も極力削る（同上）
- モジュールは全削除する（使うものが出てきたら個別に戻す）
- OneGoogleBar は削除する
- カスタマイズとショートカットは Keep
- 最初の実装は action chips の無効化

### 実装済み（Stage 2-1: action chips）

- 変更: `AreActionChipsEnabled()` を `return false;` に固定
- 確認: NTP 表示、`thisismybrowser` ラベルあり、`ntp-action-chips` なし、`isActionChipsVisible_` false
- 現在のコード確認（2026-10-24）: `AreActionChipsEnabled()` は `false` 固定だが、`action_chips/` の WebUI / C++ 実装、`lazy_load.ts` の import/export、GN 依存は残っている。**無効化済みであり、コード削除済みではない**。

### 実装済み（Stage 2-2: composebox）

- 変更: `searchboxShowComposeEntrypoint` と `searchboxShowComposebox` を false
- 確認: compose ボタンなし、composebox なし、検索ボックスは残る
- 学び: `loadTimeData` のキー名とプロパティ名は一致しないことがある

### 実装済み（Stage 2-3: Lens / 音声検索）

- 変更: `GetWebUIDataSourceDict` の `enable_lens_search` と `enable_voice_search` を false
- 確認: `#lensSearchButton` / `#voiceSearchButton` なし、検索ボックスは残る
- 学び: 共有コンポーネントはオプションで切り替えると他画面に影響しにくい

### 実装済み（Stage 2-4: realbox next / AI Mode）

- 変更: `kNtpRealboxNext` のデフォルトを `FEATURE_DISABLED_BY_DEFAULT` に
- 確認: `ntpRealboxNextEnabled_` false、AI Mode ボタンなし、プレースホルダーが通常検索に戻る
- 学び: 機能フラグのデフォルトを変えると、派生する値もまとめて false になる

### 実装済み（Stage 2-5: OneGoogleBar）

- 変更: `oneGoogleBarEnabled` を false
- 確認: `oneGoogleBarEnabled_` false、`#oneGoogleBar` なし、ショートカットは残る
- 学び: app.html の条件分岐で iframe 自体が作られない

### 実装済み（Stage 2-6: モジュール）

- 変更: `NewTabPageUI::OnLoad()` の `modulesEnabled` を false
- 確認: `modulesEnabled_` false、`#modules` なし、ショートカットは残る
- 学び: `loadTimeData.getBoolean()` はキーの存在を前提にするため、値だけ変えてキーは残す
- 次: ブラウザ全体の AI / Google 連携を棚卸しする。モジュール WebUI の削除済み資産と、維持している C++ / Mojo の依存は区別して記録する。

### 実装済み（Stage 2-7: モジュール WebUI 削除）

- 実施時の計画: [notes/2026-10-22-modules-removal-plan.md](notes/2026-10-22-modules-removal-plan.md)
- Phase 1a + 1b として、NTP の WebUI からモジュールを外し、製品資産とモジュール専用テストを削除済み
- C++ バックエンド、`untrusted/`、Customize のカード定義、enum の履歴値、およびビルド上必要な一部 Mojo 依存は維持
- ビルド・テスト・実ブラウザ確認の結果は `docs/log.md` の 2026-10-24 の記録を参照。次の機能の削除前にもコードと記録の照合を行う

## 台帳（NTP 以外）

| # | 機能 | 使う? | 判断 | 場所 | 依存 | リスク | 状態 |
|---|---|---|---|---|---|---|---|
| 1 |  |  |  |  |  |  | 未調査 |
| 2 |  |  |  |  |  |  | 未調査 |

## 削除の手順（1機能ごと）

1. **入口を特定**: どこから表示・実行されるか（UI、設定、コマンド）
2. **参照を調べる**: `grep -rn "機能名"`、`BUILD.gn`、`gn refs out/Release //target`
3. **Hide**: CSS / HTML / フラグで隠す → ビルド → 確認
4. **Disable**: GN args / feature flags で無効化 → ビルド → 確認
5. **Remove**: ファイル削除、`BUILD.gn` 更新、参照削除 → ビルド → 確認
6. **記録**: `docs/log.md` に「消したもの・残したもの・学び」
7. **コミット**: 1機能1コミット

## 効果の測定

削除の前後で記録する:

| 指標 | 測り方 |
|---|---|
| ビルド時間 | `time ./scripts/build-chrome.sh` |
| バイナリサイズ | `ls -lh out/Release/chrome` |
| 変更量 | `git diff --stat` |
| 参照数 | `grep -rn` の件数 |

「削ったのにビルドが速くならない」こともある。依存を切らないと効果が出ないため、測定して判断する。

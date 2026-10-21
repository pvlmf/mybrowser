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

## 最初の対象: NTP（Stage 1 の入口）

| # | 機能 | 場所の目安 | 使う? | 判断 |
|---|---|---|---|---|
| 1 | モジュール（カード） | `new_tab_page/modules/` | ? | ? |
| 2 | composebox | `new_tab_page/composebox/` | ? | ? |
| 3 | Lens | `new_tab_page/`（lens 関連） | ? | ? |
| 4 | action chips | `new_tab_page/`（action chips） | ? | ? |
| 5 | カスタマイズ（背景・テーマ） | `new_tab_page/customize*` | ? | ? |
| 6 | OneGoogleBar | `new_tab_page/`（one google bar） | ? | ? |
| 7 | ショートカット | `cr-most-visited` | ? | ? |

`?` を埋めながら、Stage 1 で台帳を完成させる。

## 台帳（記入式）

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

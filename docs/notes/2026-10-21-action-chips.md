# action chips を無効化した

日付: 2026-10-21

## 目的

AI / Google 連携を出さない方針の最初の実装。
NTP の検索ボックス下に出る AI 提案チップ（Deep Search、画像生成など）を止める。

## 変更

`chrome/browser/ui/webui/new_tab_page/new_tab_page_ui.cc`

`AreActionChipsEnabled()` を `return false;` にした。

## 表示の流れ

```text
AreActionChipsEnabled()
  → loadTimeData["actionChipsEnabled"]
  → app.ts の isActionChipsVisible_
  → app.html の ${... ? html`<ntp-action-chips>` : ''}
```

`false` になると `<ntp-action-chips>` 自体が作られない。
そのため `action_chips.ts` の `connectedCallback()` も走らず、
`startActionChipsRetrieval()`（AI サービスへの取得処理）も呼ばれない。

## なぜ CSS で隠さないか

CSS の `display: none` だと、要素は作られてコンポーネントも動く。
AI サービスへの取得処理を止めるには、表示の入口（この関数）を false にする方が確実。

## 確認

- ビルド成功
- GUI 版を一時プロファイル + リモートデバッグで起動
- NTP（`chrome://new-tab-page/`）が表示される
- `#mybrowserLabel` が `thisismybrowser` のまま
- `ntp-action-chips` が DOM に存在しない
- `ntp-app.isActionChipsVisible_` が `false`
- composebox はまだ有効（次の対象）

## 学び

- C++ の `loadTimeData` を介して、WebUI（TS）に値が渡る
- Lit の shadow DOM の中は `document.querySelector` では届かない。
  `document.querySelector('ntp-app').shadowRoot` からたどる
- Chromium は `-Wunreachable-code-aggressive` を使うため、
  早期 `return` の後ろにコードを残すと警告になる。
  今回は関数自体を `return false;` に置き換えた

## 次

composebox を無効化する。

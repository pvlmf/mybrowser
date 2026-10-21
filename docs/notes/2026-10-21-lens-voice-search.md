# Lens と音声検索を無効化した

日付: 2026-10-21

## 目的

AI / Google 連携を出さない方針。
NTP の検索ボックスから Lens ボタンと音声検索ボタンを消す。

## 変更

`chrome/browser/ui/webui/new_tab_page/new_tab_page_ui.cc`

`SearchboxHandler::GetWebUIDataSourceDict` に渡すオプションを変更した。

- `.enable_lens_search = false`
- `.enable_voice_search = false`

## 表示の流れ

```text
enable_lens_search
  → loadTimeData["searchboxLensSearch"]
  → searchboxLensSearchEnabled_
  → shouldShowVoiceLens_()
  → #lensSearchButton

enable_voice_search
  → loadTimeData["searchboxVoiceSearch"]
  → searchboxVoiceSearchEnabled_
  → #voiceSearchButton
```

## なぜ共有コードを触らないか

`SearchboxHandler` は omnibox など他の検索ボックスと共有している。
NTP に渡すオプションだけ false にすることで、他の画面への影響を避けた。

## 確認

- ビルド成功
- NTP（`chrome://new-tab-page/`）が表示
- `#mybrowserLabel` が `thisismybrowser` のまま
- `searchboxLensSearchEnabled` が `false`
- `searchboxVoiceSearchEnabled` が `false`
- `#lensSearchButton` が存在しない
- `#voiceSearchButton` が存在しない
- `ntp-searchbox` は存在する（通常の検索は残る）
- action chips / composebox は引き続き無効

## 学び

- 共有コンポーネントは「オプション」で機能を切り替えると、他画面に影響しにくい
- `loadTimeData` のキーは `searchboxLensSearch` / `searchboxVoiceSearch`
- shadow DOM のボタンは `ntp-searchbox.shadowRoot` から確認する

## 次

realbox next（AI Mode）が残っていれば無効化する。
その後、OneGoogleBar、モジュールの順で進める。

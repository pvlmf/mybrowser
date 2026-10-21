# realbox next（AI Mode）を無効化した

日付: 2026-10-21

## 目的

検索ボックスの AI Mode を止め、通常の検索に戻す。

## 変更

`chrome/browser/ui/webui/new_tab_page/composebox/variations/composebox_fieldtrial.cc`

```cpp
BASE_FEATURE(kNtpRealboxNext, base::FEATURE_DISABLED_BY_DEFAULT);
```

## 確認

- ビルド成功
- NTP（`chrome://new-tab-page/`）が表示
- `#mybrowserLabel` が `thisismybrowser` のまま
- `ntpRealboxNextEnabled_` が `false`
- `searchboxCyclingPlaceholders_` が `false`
- AI Mode ボタンが `false`
- プレースホルダーが「Google に質問する」から
  「Google で検索または URL を入力」に戻った
- Lens / 音声検索 / composebox / action chips は引き続き無効

## 学び

- 機能フラグのデフォルトを変えると、そこから派生する `loadTimeData` も
  まとめて false になる
- `kNtpRealboxNext` は omnibox など他の検索ボックスとも共有している。
  AI を出さない方針なので、他画面でも AI Mode が消えるのは許容
- 機能フラグは `--enable-features=NtpRealboxNext` で戻せる

## 次

OneGoogleBar を無効化する。

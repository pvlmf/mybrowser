# OneGoogleBar を無効化した

日付: 2026-10-21

## 目的

Google 連携を極力削る方針。
NTP 上部の Google アカウントバー（OneGoogleBar）を出さない。

## 変更

`chrome/browser/ui/webui/new_tab_page/new_tab_page_ui.cc`

```cpp
dict.Set("oneGoogleBarEnabled", false);
```

## なぜこれで消えるか

`app.html` は次の条件で OneGoogleBar の iframe を作る。

```text
this.lazyRender_ && this.oneGoogleBarEnabled_
```

`oneGoogleBarEnabled` が false なら iframe 自体が作られない。
`oneGoogleBarIframePath_` などのコードは残しているので、今回は Hide 段階。

## 確認

- ビルド成功
- NTP（`chrome://new-tab-page/`）が表示
- `#mybrowserLabel` が `thisismybrowser` のまま
- `oneGoogleBarEnabled_` が `false`
- `#oneGoogleBar` が存在しない
- ショートカット（`cr-most-visited`）は残る
- 他の AI / Google 機能は引き続き無効

## 学び

- WebUI の表示は `loadTimeData` の bool で切り替わることが多い
- OneGoogleBar は AI ではないが、Google アカウント連携なので方針の対象

## 次

モジュールを無効化する。

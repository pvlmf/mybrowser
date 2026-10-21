# composebox を無効化した

日付: 2026-10-21

## 目的

AI / Google 連携を出さない方針。
NTP の compose ボタンと composebox を止める。

## 変更

`chrome/browser/ui/webui/new_tab_page/new_tab_page_ui.cc`

- `searchboxShowComposeEntrypoint` を `false`
- `searchboxShowComposebox` を `false`
- 使わなくなった `service` / `aim_eligible` を削除

## 2つのキーの違い

- `searchboxShowComposeEntrypoint` → 検索ボックス内の compose ボタン
- `searchboxShowComposebox` → composebox 本体

片方だけ false にすると「ボタンは出るが composebox は開かない」という中途半端な状態になる。
そのため両方 false にした。

## 確認

- ビルド成功
- NTP（`chrome://new-tab-page/`）が表示
- `#mybrowserLabel` が `thisismybrowser` のまま
- `composeButtonEnabled` が `false`
- `composeboxEnabled` が `false`
- `#composeButton` が shadow DOM に存在しない
- `ntp-composebox` が存在しない
- `ntp-searchbox` は存在する（通常の検索は残る）
- Lens ボタンはまだ存在する（次の対象）

## 学び

- `loadTimeData` のキー名は、WebUI のプロパティ名と一致しないことがある
  - 例: `composeboxEnabled` は `searchboxShowComposebox` を読む
- C++ の `dict.Set` を false にすると、WebUI の条件分岐が止まる
- 使わなくなった変数は一緒に消す（未使用警告を避ける）

## 次

Lens ボタンを隠す。
`SearchboxHandler::GetWebUIDataSourceDict` に渡す `enable_lens_search` を false にする。

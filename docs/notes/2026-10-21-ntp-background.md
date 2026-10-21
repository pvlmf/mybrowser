# NTP の背景色を変える（2026-10-21）

## 変更したファイル

`src/chrome/browser/resources/new_tab_page/app.css`

```css
:host {
  display: block;
  --mybrowser-ntp-background: lightgreen;
  ...
  background: var(--mybrowser-ntp-background);
}

/* 背景画像があるときは色を塗らない */
:host([show-background-image_]) {
  background: transparent;
}
```

## なぜ `display: block` が必要か

`ntp-app` はカスタム要素で、既定の `display` は **inline**。
中身が block 要素だけの場合、inline 要素には背景を塗る領域がなく、背景色は表示されない。

検証（同じ構造のページをヘッドレスで描画し、ピクセルを確認）:

| 指定 | 10,10 の色 |
|---|---|
| `background: blue;` のみ | 白（描画されない） |
| `display: block; background: blue;` | 青 |

## レイヤー順

```
（上）
  ntp-app の中身        #rhsContent { position:relative; z-index:1 }
  iframe#backgroundImage position:fixed の背景画像
  ntp-app の背景         background: lightgreen
  body の背景            テーマ色（$i18n{backgroundColor}）
（下）
```

- `iframe#backgroundImage` は `position: fixed` なので、通常フローの `ntp-app` 背景より上
- `#rhsContent` は `z-index: 1` なので、fixed の iframe よりさらに上
- したがって `background: transparent` は「画像を透かす」ためではなく、
  画像の下に色を塗らないための指定

## 再ビルドが必要な理由

CSS はビルド時に `app.css.js` へ変換され、`resources.pak` に梱包される。
編集だけでは反映されない。

```bash
./scripts/build-chrome.sh
grep -o "mybrowser-ntp-background:lightgreen" \
  src/out/Release/gen/chrome/browser/resources/new_tab_page/tsc/app.css.js
```

## 動作確認（背景画像）

1. `./scripts/run-chrome.sh` で起動
2. 新しいタブ → 右下の「カスタマイズ」→「背景」
3. 画像をアップロード（オフラインでも可）
4. 画像が表示され、緑が消えていれば OK
5. 背景を「なし」に戻すと緑が戻る

DevTools での確認:

```js
document.querySelector('ntp-app').hasAttribute('show-background-image_')
document.body.hasAttribute('show-background-image')
```

## コミット

- `721ec0cee3` NTP: set a custom background color for mybrowser

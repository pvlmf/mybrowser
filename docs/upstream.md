# 上流（Chromium）更新の追い方

## 「上流を追う」とは

Chromium 本体の更新（セキュリティ修正・新機能）を、自分のフォークに取り込むこと。

- Git が自動で統合できるのは、変更が重なっていない部分だけ
- 同じファイル・同じ行を変更していると **コンフリクト** になる
- コンフリクトはコマンドでは解決できない。**自分でコードを読んで直す**
- 削除や変更が多いほど、コンフリクトも増える

つまり「上流を追う」＝「更新を取り込み、衝突を自分の手で解消する」。
自動でコードを書き換えてくれるわけではない。

## 方針

- 上流は追う（セキュリティ修正のため）
- コンフリクト解消は自分で行う（コードを理解して直す）
- 削除は自己完結した WebUI / Views の機能から
- 深く統合された機能（sync、extensions など）は GN args で無効化し、コードは消さない
- 上流ファイルへの編集は最小限にする

## なぜ浅いクローンでは merge しないか

このリポジトリは `--depth 1` の浅いクローンで、上流との共通祖先をローカルに持っていない。
`git merge upstream/main` をしようとすると、履歴を大量にダウンロードする必要がある（数十GB）。

そこで **cherry-pick 方式** を使う。

## 更新手順（cherry-pick 方式）

```bash
cd /home/pvlmf/Projects/mybrowser/src

# 1. 上流リモートを追加（初回のみ）
git remote add upstream https://chromium.googlesource.com/chromium/src.git

# 2. 上流の最新コミットを浅く取得
git fetch upstream main --depth=1

# 3. 上流の上に作業ブランチを作る
git checkout -b sync FETCH_HEAD

# 4. 自分の変更を載せ直す（docs/customizations.md の一覧を使う）
git cherry-pick <custom-commit>...

# 5. コンフリクトを自分で直す
#    git status で対象を確認 → エディタで修正 → git add → git cherry-pick --continue

# 6. ビルド・起動確認
./scripts/dev.sh --version

# 7. dev を更新して push
git checkout dev
git reset --hard sync
git push --force-with-lease origin dev
```

- 上流の基点をタグで残す: `git tag upstream-YYYY-MM-DD FETCH_HEAD`
- 自分の変更一覧は [customizations.md](customizations.md) に残す
- 定期的に行う（例: 月1回、またはセキュリティ修正が出たとき）

## コンフリクトを減らすコツ

1. 上流ファイルの変更は最小限にする（`app.css` / `app.html` など）
2. 新しいファイル・ディレクトリに閉じ込める（`mybrowser/` など）
3. 削除より無効化（GN args / feature flags）を優先する
4. 変更を小さなコミットに分ける（1機能1コミット）
5. 更新の間隔を空けすぎない（衝突が大きくなる）

## 注意

- `git reset --hard` はローカルの変更を消す。実行前に `git status` を確認する
- push は `--force-with-lease` を使う
- 上流更新後は、変更ファイルが多いためフルに近い再ビルドになることがある
- 上流の `docs/` に自分の文書を置いているため、同名ファイルが追加されると衝突する。
  衝突が増えたら、mybrowser 固有の文書を `mybrowser/` に移すことも検討する

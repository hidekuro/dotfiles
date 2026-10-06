---
name: handle-review-comments
description: プルリクエストに付けられたレビューコメントに対応する。「レビューコメントに対応して」「指摘事項を修正して」「レビュー指摘を反映して」など、レビューコメントへの対応が必要な場面では必ずこのスキルを使用すること。コメントの取得・分析・修正実装・返信を行う。PR のレビュー実施には review-pr スキルを使用。
---

# PR レビューコメント対応

## ワークフロー

### 1. PR 番号の取得

現在のブランチから PR 番号を自動取得:

```bash
gh pr view --json number --jq '.number'
```

PR が存在しない場合は、ユーザーに PR 番号または PR URL の入力を求めます。

### 2. レビューコメントの取得

行に付いたコメントは、スレッド単位で GraphQL から取得する。REST API のレビューコメントには、解決済みかどうかの情報が含まれないため。

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F pr={pr} -f query='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){reviewThreads(first:100){totalCount nodes{isResolved isOutdated path line originalLine comments(first:50){totalCount nodes{databaseId author{login __typename} body}}}}}}}' --jq '{threadCount: .data.repository.pullRequest.reviewThreads.totalCount, threads: [.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not) | {path, line: (.line // .originalLine), isOutdated, commentCount: .comments.totalCount, comments: [.comments.nodes[] | {id: .databaseId, author: .author.login, type: .author.__typename, body}]}]}'
```

レビュー全体に付いたコメント (行に紐付かない総評) は別に取得する。

```bash
gh pr view {pr} --json reviews --jq '[.reviews[] | select(.body != "") | {author: .author.login, state, body}]'
```

**重要な注意点**:

- まず全コメントを取得する (ユーザー名で絞り込まない)
- outdated のスレッド (コードの変更で行がずれたもの) は除外しない。行番号は変更前のコードのものになるので、指摘が今のコードにも当てはまるかを確認する
- スレッド内の返信も読み、すでに返信や合意が済んでいるかを判断する
- 取得の上限はスレッド 100 件、1 スレッドあたりのコメント 50 件。`threadCount` や `commentCount` が上限を超えていたらユーザーに伝える
- `{owner}` と `{repo}` は gh がカレントディレクトリのリポジトリで埋める。別リポジトリの PR を URL で指定されたときは実際の値で埋める

### 3. コメントの分類

レビュアーの種類でグループ化:

- **Copilot** (`author == "copilot-pull-request-reviewer"`)
- **自動ツール** (`type == "Bot"` で Copilot 以外。`github-actions` など)
- **チームメンバー** (`type == "User"`)

### 4. 各コメントの分析

各レビューコメントについて、該当コードの文脈を理解するため必要に応じてファイルを読み、以下の項目を分析:

1. **要約**: 何を提案しているか (1-2 行)
2. **評価**:
   - 妥当性 (妥当/不適切/議論の余地あり)
   - 重要度 (致命的/重要/推奨/nitpick)
   - 影響範囲 (大/中/小/些細)
3. **推奨**: 対応すべきか (はい/いいえ/検討)
4. **理由**: この推奨の根拠

分析結果を表形式で提示する。

| No. | ファイル:行 | レビュアー | 要約 | 評価 | 推奨 |
|---|---|---|---|---|---|
| 1 | service.js:42 | Copilot | エラーハンドリング追加 | 妥当、重要、中 | はい |
| 2 | utils.ts:10 | github-actions | 型アノテーション追加 | 妥当、推奨、小 | はい |
| 3 | component.tsx:55 | alice | useMemo で最適化 | 議論の余地あり、推奨、中 | 検討 |

### 5. ユーザーの判断を仰ぐ

分析を提示したら止まり、どのコメントに対応するかはユーザーの指示を待つ。分析と同じターンで質問しない。

### 6. 修正の実装

承認された各コメントについて:

1. 該当ファイルの関連箇所を Read ツールで読む
2. 必要な変更を実施
3. プロジェクトで使用されているフォーマッターやリンターがあれば実行
4. `commit` スキルを使って **1 つのレビューコメントにつき 1 つ**のコミットを作成する
   - コミットハッシュをレビューコメント返信に記載できるようにするため、1 コメント = 1 コミットの粒度を守る

### 7. まとめ

全ての修正完了後、作成したコミット一覧を提示して止まる。push はユーザーの指示を受けてから実行する。

### 8. レビューコメントへの返信

コミットハッシュはリモートに無いとレビュアーが辿れないので、返信は push の後に行う。

対応したスレッドごとに返信文 (対応内容 1 行とコミットハッシュ) を一覧で提示し、承認を得てから投稿する。返信先はスレッドの先頭コメントの `id` にする。GitHub の API は返信への返信を受け付けないため。

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -f body='<返信文>'
```

レビュー全体に付いたコメントにはスレッドがないので、返信が要るときは `gh pr comment` で PR に投稿する。対応しなかったコメントに返信するかどうかは、ユーザーの指示に従う。

投稿後は次のステップ (例: レビュー再依頼) を提案する。

## エラーハンドリング

- `gh api` が失敗した場合、エラーを説明して修正方法を提案
- コメントが参照しているコードが既に存在しない場合、その旨を記載
- コメントの意図が不明な場合、ユーザーに確認

## 注意事項

- レビューコメントへの対応は、ユーザーの明示的な指示があるまで実装に着手しない
- 複数の対応方法がある場合は、それぞれのメリット・デメリットを提示する
- 自動ツールのコメントであっても、妥当性を批判的に評価する
- 分析は簡潔かつ技術的に正確に行う

# 依存関係更新 PR のレビュー

renovate / dependabot による依存関係更新 PR と判定された場合、通常のコードレビュー観点は適用せず、以下の専用フローで「安全にマージできるか」を評価する。

## A. 更新内容の把握

PR の差分から、更新されたパッケージとバージョン差分を抽出する。

```bash
gh pr diff {pr_number}
```

確認対象のファイル例:

- `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- `Gemfile`, `Gemfile.lock`
- `go.mod`, `go.sum`
- `pyproject.toml`, `poetry.lock`, `requirements.txt`
- `Cargo.toml`, `Cargo.lock`
- `.github/workflows/*.yml` (GitHub Actions の更新)

抽出する情報:

- パッケージ名
- 更新前バージョン → 更新後バージョン
- バージョン差分の種類 (major / minor / patch、SemVer の場合)
- production 依存か dev 依存か (manifest ファイルから判別)

## B. Changelog / Release notes の確認

PR 本文に renovate / dependabot が埋め込んだ release notes / changelog が含まれることが多い。まず PR 本文を確認する。

PR 本文に十分な情報がない、または major / minor 更新で breaking changes を確認したい場合は、上流リポジトリの releases を取得する。

```bash
# GitHub 上のリポジトリの場合
gh release view {tag} --repo {owner}/{repo}
gh release list --repo {owner}/{repo} --limit 20
```

GitHub 以外の場所にある場合は WebFetch で公式の changelog / release notes を取得する。

確認する観点:

- breaking changes の有無
- security fix の有無 (含まれていればマージ優先度が上がる)
- deprecation 通知
- 新機能の概要 (プロジェクトで利用しているものに関連するか)

## C. CI ステータスの確認

```bash
gh pr checks {pr_number}
```

`state` が `pass` / `fail` のチェックに注目する。`skipping` のジョブは条件付き実行 (特定のパス変更時のみ走るなど) で対象外となっているケースが多く、無視してよい。

評価で重視するのは次のいずれか:

- 期待される `pass` のチェックがすべて pass しているか
- `fail` / `failure` のチェックがあるか (あれば内容を取得して原因を確認)

```bash
gh pr checks {pr_number} --json name,state,link
```

## D. 影響範囲の確認

更新されたパッケージがコードベース内でどう使われているかを確認する。

### D.1 検索対象のディレクトリの決定

まず、grep の対象となるローカルディレクトリを決定する。判定順序は次のとおり:

1. **カレントディレクトリが対象 PR のリポジトリと一致する場合**: そのまま実施する。
   - 判定方法: `gh repo view --json nameWithOwner --jq .nameWithOwner` の結果が PR のリポジトリ (`{owner}/{repo}`) と一致するか確認。
2. **一致しない場合**: ユーザーに次のいずれかを選択してもらう。
   - ローカルクローンがある → パスを入力してもらい、そのディレクトリで実施
   - ローカルクローンがない、または検索不要 → このステップをスキップし、評価レポートではパッケージの性質 (CLI ツールか、import されるライブラリか、ビルドツールかなど) から影響範囲を推定する

検索を実施しない場合は、評価レポートの「影響範囲」セクションで「ローカルでの利用箇所検索は未実施。パッケージの性質から推定」と明記する。

### D.2 利用箇所の検索

検索を実施する場合は、パッケージに応じたパターンで grep する。

```bash
# 例: npm パッケージ
rg -l "from ['\"]{package_name}['\"]|require\(['\"]{package_name}['\"]\)"
```

### D.3 確認観点

- production 依存か dev 依存か (dev 依存は本番影響なし)
- コードベース内での利用箇所数 (多いほど影響大)
- 利用している API が breaking changes の対象か
- 推移的依存 (transitive dependency) のみの更新か直接依存か
- パッケージの性質 (CLI ツール / ビルドツール / ライブラリ) — CLI・ビルドツールは通常 import されず、影響範囲は CI スクリプトや設定ファイルに限定される

## E. 評価レポートの生成

上記の調査結果を踏まえ、次のテンプレートで評価レポートを作成する。

レポート冒頭の見出しは `## Claude (<モデル名>) による評価` とする。`<モデル名>` には、現在の会話のシステムプロンプトに記載された Claude のモデル表示名 (例: `Opus 4.8`、`Sonnet 4.6`、`Haiku 4.5` など) を入れる。1M context 版などのサフィックスがあれば併記する (例: `Opus 4.8 (1M context)`)。

```markdown
## Claude (<モデル名>) による評価

### 概要

- **更新パッケージ**: {package_name}
- **バージョン**: {old_version} → {new_version} ({major|minor|patch})
- **依存種別**: {production | dev | transitive}
- **CI ステータス**: {✅ pass | ❌ fail | ⏳ pending}

### 評価サマリー

**マージ可否**: ✅ 安全にマージ可能 / ⚠️ 注意してマージ / ❌ マージ前に確認・対応が必要

**リスクレベル**: 低 / 中 / 高

### Breaking changes

{release notes / changelog から抽出した breaking changes、なければ「なし」}

### Security fix

{セキュリティ修正が含まれる場合は CVE 番号や概要、なければ省略}

### 影響範囲

- 利用箇所: {N 箇所 / 利用なし / 推移的依存のみ}
- 影響を受けそうな箇所: {breaking changes の対象 API を使っている箇所、なければ「なし」}

### 推奨アクション

{具体的な次のステップ。例: そのままマージ可、CI が通るのを待ってマージ、特定のコードを修正してからマージ など}
```

複数パッケージが同時に更新されている PR (renovate の grouped updates 等) の場合は、パッケージごとに「概要」「Breaking changes」「影響範囲」を繰り返し、最後に PR 全体の評価サマリーをまとめる。

## F. 出力先の選択

評価レポートを提示する前に、ユーザーに出力方法を確認する。

> "評価が完了しました。次のいずれの方法で提示しますか？
> 1. このチャットにマークダウンコードブロックで表示 (ユーザーがコピーして使用)
> 2. PR に直接コメントとして投稿"

選択に応じて以下を実行する:

- **1 を選択**: 評価レポート全体をマークダウンコードブロック (` ```markdown ... ``` `) で囲んで提示する。ユーザーがそのままコピー&ペーストで PR コメントに転記できる形にする。
- **2 を選択**: `gh pr comment` で PR に直接投稿する。

```bash
gh pr comment {pr_number} --body-file -  <<'EOF'
## Claude (<モデル名>) による評価

...
EOF
```

投稿後、コメントの URL を提示する。

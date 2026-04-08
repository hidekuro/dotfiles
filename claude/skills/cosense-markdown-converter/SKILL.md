---
name: cosense-markdown-converter
description: >
  Markdown と Cosense（旧 Scrapbox）記法の相互変換を行う。
  「Cosense を Markdown に変換して」「Markdown を Cosense 記法にして」
  「Scrapbox 記法に変換して」「Cosense のページを Markdown にして」など、
  Cosense/Scrapbox と Markdown の間でテキストを変換する必要がある場面では
  必ずこのスキルを使用すること。ファイルの変換にもクリップボードからの
  テキスト変換にも対応する。Cosense や Scrapbox という単語が含まれる
  変換リクエストを見たら、このスキルをトリガーすること。
---

# Cosense-Markdown 相互変換スキル

Cosense（旧 Scrapbox）記法と Markdown 記法を相互変換する。
ユーザーからテキストまたはファイルが与えられたら、変換方向を判断し、以下のルールに従って変換する。

## 変換方向の判断

- 入力に Cosense 特有の記法（`[* 見出し]`、`[リンク]`、`code:filename`、`table:name`、スペースインデントによるリスト等）が含まれていれば **Cosense → Markdown**
- 入力に Markdown 特有の記法（`# 見出し`、`[text](url)`、三連バッククォートのコードブロック、`- ` や `1. ` によるリスト等）が含まれていれば **Markdown → Cosense**
- 判断が難しい場合はユーザーに確認する

## Cosense → Markdown 変換ルール

### 見出し

Cosense の `[* ... ]` 記法は `*` の数が多いほど大きい見出しになる。Markdown では `#` が少ないほど大きいので、逆転させる。
ただし `[* テキスト]`（星 1 つ）は Cosense では太字として使われるのが一般的なので、見出しではなく太字に変換する。

| Cosense | Markdown |
|---------|----------|
| `[***** テキスト]` | `# テキスト` |
| `[**** テキスト]` | `## テキスト` |
| `[*** テキスト]` | `### テキスト` |
| `[** テキスト]` | `#### テキスト` |

`[* テキスト]` は行頭・インラインを問わず常に太字 `**テキスト**` に変換する。

### リンク

Cosense のページリンクを Markdown に変換するには、Cosense プロジェクトの URL が必要になる。
ページリンク（`[ページ名]` や `[/project/page]`）が含まれている場合、ユーザーに「現在のページまたは Cosense プロジェクトの URL」を尋ねること。
URL から `https://scrapbox.io/<project>/` の形式でベース URL を構成する。

| Cosense | Markdown |
|---------|----------|
| `[ページ名]` | `[ページ名](https://scrapbox.io/<project>/ページ名)` |
| `[/project/page]` | `[page](https://scrapbox.io/project/page)` |
| `[ラベル https://example.com]` | `[ラベル](https://example.com)` |
| `[https://example.com]` | `<https://example.com>` |
| `[https://example.com ラベル]` | `[ラベル](https://example.com)` |

ページ名に含まれるスペースは URL エンコードすること。

### 太字・斜体

| Cosense | Markdown |
|---------|----------|
| `[* テキスト]` | `**テキスト**` |
| `[** テキスト]`（インライン） | `**テキスト**` |
| `[/ テキスト]` | `*テキスト*` |
| `[*/ テキスト]` または `[/* テキスト]` | `***テキスト***` |

### コードブロック

Cosense:
```
code:example.py
 print("hello")
 print("world")
```

Markdown:
````
```python
print("hello")
print("world")
```
````

`code:filename.ext` の拡張子から言語を推定する（`.py` → `python`、`.js` → `javascript`、`.ts` → `typescript`、`.rb` → `ruby` など）。
コードブロック内の各行は先頭のスペース 1 つを除去する。

### リスト

Cosense ではスペースのインデントでリストを表現する（1 スペース = レベル 1）。

Cosense:
```
 項目1
 項目2
  サブ項目
```

Markdown:
```markdown
- 項目1
- 項目2
  - サブ項目
```

数字で始まる行（` 1. 項目`）は番号付きリストとして変換する。

### テーブル

Cosense:
```
table:データ
 名前	年齢	役割
 田中	30	エンジニア
 佐藤	25	デザイナー
```

Markdown:
```markdown
| 名前 | 年齢 | 役割 |
|------|------|------|
| 田中 | 30 | エンジニア |
| 佐藤 | 25 | デザイナー |
```

最初の行をヘッダーとして扱い、区切り行 `|------|` を挿入する。
各行はタブ区切り。先頭のスペース 1 つを除去する。

### アイコン記法

`[user.icon]` のようなアイコン記法は Markdown にはないため、インラインコードとして変換する。

| Cosense | Markdown |
|---------|----------|
| `[user.icon]` | `` `[user.icon]` `` |
| `[user.icon*3]` | `` `[user.icon*3]` `` |

### その他

- 画像 URL（`[https://example.com/image.png]`）→ `![image](https://example.com/image.png)`
- Gyazo 画像（`[https://gyazo.com/xxxx]`）→ `![image](https://gyazo.com/xxxx/raw)`
- 打ち消し線 `[- テキスト]` → `~~テキスト~~`
- 引用 `> テキスト` → `> テキスト`（同じ）

## Markdown → Cosense 変換ルール

### 見出し

Cosense の見出し最大レベルは `[*** ]`（星 3 つ）とする。

| Markdown | Cosense |
|----------|---------|
| `# テキスト` | `[*** テキスト]` |
| `## テキスト` | `[** テキスト]` |
| `### テキスト` | `[* テキスト]`（太字扱い） |
| `#### テキスト` | ` テキスト`（スペース 1 つでインデント） |
| `##### テキスト` | `  テキスト`（スペース 2 つでインデント） |

`####` 以下は Cosense の見出し記法ではなく、スペースインデントを用いて親セクション配下の記述であることを示す。

### リンク

Markdown のリンクはそのまま Cosense のリンク記法に変換する。

| Markdown | Cosense |
|----------|---------|
| `[ラベル](https://example.com)` | `[ラベル https://example.com]` |
| `<https://example.com>` | `[https://example.com]` |

### 太字・斜体

| Markdown | Cosense |
|----------|---------|
| `**テキスト**` | `[* テキスト]` |
| `*テキスト*` | `[/ テキスト]` |
| `***テキスト***` | `[*/ テキスト]` |

### コードブロック

````
```python
print("hello")
print("world")
```
````

→

```
code:example.py
 print("hello")
 print("world")
```

言語名から適切な拡張子を推定してファイル名にする（`python` → `.py` など）。
ファイル名の推定が難しければ `code:snippet` とする。
各行の先頭にスペース 1 つを付与する。

### リスト

```markdown
- 項目1
- 項目2
  - サブ項目
```

→

```
 項目1
 項目2
  サブ項目
```

レベルに応じてスペースのインデントを付与する。

### テーブル

```markdown
| 名前 | 年齢 |
|------|------|
| 田中 | 30 |
```

→

```
table:table
 名前	年齢
 田中	30
```

区切り行は除去する。各列はタブ区切りにする。先頭にスペース 1 つを付与する。

### その他

- 画像 `![alt](url)` → `[url]`
- 打ち消し線 `~~テキスト~~` → `[- テキスト]`
- 引用 `> テキスト` → `> テキスト`（同じ）
- インラインコード内のアイコン記法（`` `[user.icon]` ``）→ `[user.icon]` に復元する

## 入出力の扱い

- ユーザーがファイルパスを指定した場合：ファイルを読み込んで変換し、結果を新しいファイルに書き出す
  - Cosense → Markdown: `.md` 拡張子で出力
  - Markdown → Cosense: `.cosense.txt` 拡張子で出力
- ユーザーがテキストを直接貼り付けた場合：変換結果をそのまま会話に返す

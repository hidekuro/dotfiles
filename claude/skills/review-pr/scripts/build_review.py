"""Markdown で書いたレビューから、レビュー作成 API に渡す JSON を作る。

使い方: build_review.py <owner/repo> <pr_number> <review.md> [COMMENT|APPROVE|REQUEST_CHANGES]

review.md の拡張子を .json に変えたパスに JSON を書き出し、そのパスとインラインコメントの指摘一覧の表を標準出力に出す。
送信の種別を省くと、レビューは送信前の下書き (PENDING) になる。
インラインコメントの行が差分の外にあると API がレビュー全体を受け付けないため、JSON を書き出す前にここで検出する。
"""

import json
import re
import subprocess
import sys
from pathlib import Path

HUNK_HEADER = re.compile(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@")
COMMENT_MARKER = re.compile(r"^<!-- comment (.+?) -->$", re.MULTILINE)
HEADLINE = re.compile(r"^\*\*No\. (\d+) (\[\w+\])\*\* (.+)$", re.MULTILINE)


def gh_api(path, *args):
    out = subprocess.run(
        ["gh", "api", *args, path], check=True, stdout=subprocess.PIPE, text=True
    ).stdout
    return json.loads(out)


def parse_review(text):
    parts = COMMENT_MARKER.split(text)
    body = parts[0].strip()
    comments = []
    for attrs, comment_body in zip(parts[1::2], parts[2::2]):
        c = dict(pair.split("=", 1) for pair in attrs.split())
        for key in ("line", "start_line"):
            if key in c:
                c[key] = int(c[key])
        c.setdefault("side", "RIGHT")
        c["body"] = comment_body.strip()
        comments.append(c)
    return body, comments


def commentable_lines(patch):
    lines = set()
    old = new = 0
    for raw in patch.split("\n"):
        m = HUNK_HEADER.match(raw)
        if m:
            old, new = int(m[1]), int(m[2])
            continue
        if not raw or raw.startswith("\\"):
            continue
        if raw.startswith("-"):
            lines.add(("LEFT", old))
            old += 1
        elif raw.startswith("+"):
            lines.add(("RIGHT", new))
            new += 1
        else:
            lines.add(("LEFT", old))
            lines.add(("RIGHT", new))
            old += 1
            new += 1
    return lines


def main():
    repo, pr_number, review_path = sys.argv[1:4]
    event = sys.argv[4] if len(sys.argv) > 4 else None
    body, comments = parse_review(Path(review_path).read_text(encoding="utf-8"))

    head_sha = gh_api(f"repos/{repo}/pulls/{pr_number}")["head"]["sha"]
    pages = gh_api(f"repos/{repo}/pulls/{pr_number}/files?per_page=100", "--paginate", "--slurp")
    patches = {f["filename"]: f.get("patch") for page in pages for f in page}

    errors = []
    for i, c in enumerate(comments, 1):
        start = c.get("start_line", c["line"])
        if start >= c["line"] and "start_line" in c:
            errors.append(f"コメント {i}: start_line ({start}) は line ({c['line']}) より小さくする")
            continue
        patch = patches.get(c["path"])
        if patch is None:
            errors.append(f"コメント {i}: {c['path']} は差分に含まれないか、差分が取得できない")
            continue
        lines = commentable_lines(patch)
        missing = [n for n in range(start, c["line"] + 1) if (c["side"], n) not in lines]
        if missing:
            errors.append(f"コメント {i}: {c['path']} の {c['side']} 側 {missing} 行目は差分の外")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)

    review = {"commit_id": head_sha, "body": body, "comments": comments}
    if event:
        review["event"] = event
    json_path = Path(review_path).with_suffix(".json")
    json_path.write_text(json.dumps(review, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json_path)
    if comments:
        print("\n| No. | ファイル:行 | 重要度 | 指摘内容 |\n|---|---|---|---|")
    for c in comments:
        m = HEADLINE.search(c["body"])
        number, severity, summary = m.groups() if m else ("", "", c["body"].splitlines()[0])
        start = c.get("start_line", c["line"])
        location = f"{c['path']}:{start}" + (f"-{c['line']}" if start != c["line"] else "")
        summary = summary.replace("|", "\\|")
        print(f"| {number} | `{location}` | {severity} | {summary} |")


if __name__ == "__main__":
    main()

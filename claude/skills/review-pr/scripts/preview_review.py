"""Markdown で書いたレビューから、レビュー作成 API に渡す JSON とチャット用のプレビューを作る。

使い方: preview_review.py <owner/repo> <pr_number> <review.md>

review.md の拡張子を .json に変えたパスに JSON を書き出し、プレビューを標準出力に出す。
インラインコメントの行が差分の外にあると API がレビュー全体を受け付けないため、JSON を書き出す前にここで検出する。
"""

import json
import re
import subprocess
import sys
from pathlib import Path

HUNK_HEADER = re.compile(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@")
COMMENT_MARKER = re.compile(r"^<!-- comment (.+?) -->$", re.MULTILINE)


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
    lines = {}
    old = new = 0
    for raw in patch.split("\n"):
        m = HUNK_HEADER.match(raw)
        if m:
            old, new = int(m[1]), int(m[2])
            continue
        if not raw or raw.startswith("\\"):
            continue
        if raw.startswith("-"):
            lines[("LEFT", old)] = raw
            old += 1
        elif raw.startswith("+"):
            lines[("RIGHT", new)] = raw
            new += 1
        else:
            lines[("LEFT", old)] = raw
            lines[("RIGHT", new)] = raw
            old += 1
            new += 1
    return lines


def main():
    repo, pr_number, review_path = sys.argv[1:4]
    body, comments = parse_review(Path(review_path).read_text(encoding="utf-8"))

    head_sha = gh_api(f"repos/{repo}/pulls/{pr_number}")["head"]["sha"]
    pages = gh_api(f"repos/{repo}/pulls/{pr_number}/files?per_page=100", "--paginate", "--slurp")
    patches = {f["filename"]: f.get("patch") for page in pages for f in page}
    login = gh_api("user")["login"]
    reviews = gh_api(f"repos/{repo}/pulls/{pr_number}/reviews?per_page=100", "--paginate", "--slurp")
    has_pending = any(
        r["state"] == "PENDING" and r["user"]["login"] == login for page in reviews for r in page
    )

    errors = []
    sections = []
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
            continue
        location = f"{c['path']}:{start}" + (f"-{c['line']}" if start != c["line"] else "")
        code = "\n".join(lines[(c["side"], n)] for n in range(start, c["line"] + 1))
        sections.append(f"#### {location} ({c['side']})\n\n```diff\n{code}\n```\n\n{c['body']}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)

    json_path = Path(review_path).with_suffix(".json")
    json_path.write_text(
        json.dumps({"commit_id": head_sha, "body": body, "comments": comments}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    if has_pending:
        print(
            "警告: この PR には書きかけのレビュー (PENDING) があります。"
            "GitHub の画面で送信するか破棄しないと、このレビューは投稿できません。\n"
        )
    print(f"JSON: {json_path}\n")
    print("### レビュー全体の本文\n")
    print(body)
    print("\n### インラインコメント\n")
    print("\n\n".join(sections))


if __name__ == "__main__":
    main()

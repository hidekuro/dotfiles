#!/usr/bin/env python3
"""追加されたコードコメントを CLAUDE.md「コードコメント」の規則に機械的に照らす PostToolUse フック。

表層パターンしか判定できないので deny はせず、疑わしい行を additionalContext で提示して見直しを促す。
検出するもの:
- 会話・検証の経緯を示す語 (動作確認、ローカルで試した、以前は、レビュー指摘 など)
- 実装計画の付番 (PR-1、フェーズ1 など)
- フラグ名を主語にした説明 (`--foo` を使う)
- 日本語コメントの文中改行、および 150 文字を超える 1 行
Edit / Write / MultiEdit は tool_input から追加行を取る。Bash は heredoc や sed による編集を拾うため git diff HEAD から取る。
同じ行を繰り返し指摘しないよう、報告済みの行をセッション単位で一時ファイルに記録する。
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

HASH_EXT = {
    "py", "rb", "pl", "pm", "t", "sh", "bash", "zsh", "fish", "yaml", "yml", "toml",
    "cfg", "ini", "conf", "tf", "tfvars", "hcl", "nix", "r", "ps1", "mk", "cmake",
    "gitignore", "dockerignore", "env", "psgi",
}
HASH_BASENAMES = {
    "Dockerfile", "Makefile", "GNUmakefile", "Brewfile", "cpanfile", "Rakefile",
    "Gemfile", "Vagrantfile", "Procfile", "Justfile", "justfile",
}
SLASH_EXT = {
    "js", "mjs", "cjs", "ts", "tsx", "jsx", "go", "java", "kt", "kts", "swift", "c", "h",
    "cc", "cpp", "hpp", "cs", "rs", "php", "scala", "dart", "jsonnet", "libsonnet",
    "groovy", "proto", "vue", "svelte",
}
DASH_EXT = {"sql", "lua", "hs", "elm"}

JAPANESE = re.compile(r"[぀-ヿ一-鿿]")
# 読点・助詞・接続表現で終わる行は文が途中で改行されたとみなす。「こと」「なし」「まで」は名詞で終わる例が多いので除く
CONTINUATION_END = re.compile(r"(?<!こ)(?<!な)(?<!ま)(?:、|,|・|て|で|が|を|に|は|の|と|し|ので|から|ため|たり|また|および|または)$")
LIST_MARKER = re.compile(r"^(?:[-*・]|\d+[.)]|No\.\s*\d+)\s")
SEPARATOR = re.compile(r"^[-=*#_~/]{3,}$")

PATTERNS = [
    ("経緯の記述", re.compile(
        r"動作確認|ローカルで(?:試|確認|実行)|(?:試|検証|確認)し(?:た(?:ところ|ら|結果)|てみ)"
        r"|以前は|従来は|元々は|もともとは|今回(?:は|の(?:変更|修正|対応))|修正前(?:は|の)"
        r"|レビュー(?:で|の)?指摘|指摘(?:を受け|され|により)"
        r"|\bpreviously\b|\bused to\b|\btested locally\b|\bas discussed\b|\bper review\b"
    )),
    ("実装計画の付番", re.compile(r"\bPR-\d+\b|フェーズ\s?\d|\bPhase\s?\d\b")),
    ("フラグ名を主語にした説明", re.compile(
        r"`?--[A-Za-z][\w-]*`?\s*(?:を|で)\s*(?:使|指定|付け|渡|有効|無効)"
    )),
]
MAX_LINE_CHARS = 150
MAX_DIFF_BYTES = 2 * 1024 * 1024


def comment_prefixes(path):
    base = os.path.basename(path)
    if base in HASH_BASENAMES or base.startswith("Dockerfile") or base.startswith(".env"):
        return ("#",)
    if base.startswith(".") and "." not in base[1:]:
        # .zshrc, .bashrc, .gitconfig などの設定ファイル
        return ("#",)
    ext = base.rsplit(".", 1)[-1].lower() if "." in base else ""
    if ext in HASH_EXT:
        return ("#",)
    if ext in SLASH_EXT:
        return ("//", "/*", "*", "*/")
    if ext in DASH_EXT:
        return ("--",)
    return None


def comment_body(line, prefixes):
    stripped = line.strip()
    if not stripped or stripped.startswith("#!"):
        return None
    for prefix in prefixes:
        if stripped.startswith(prefix):
            body = stripped[len(prefix):].strip()
            # shellcheck / eslint などのディレクティブと区切り線は対象外
            if body.startswith(("shellcheck", "eslint", "noqa", "type:", "pragma", "@")):
                return None
            if SEPARATOR.match(body) or not body:
                return None
            return body
    return None


def find_issues(path, numbered_lines):
    """numbered_lines: (行番号または None, 行文字列) のリスト。隣接判定のため元の並び順を保つ。"""
    prefixes = comment_prefixes(path)
    if not prefixes:
        return []
    issues = []
    prev = None  # (行番号, 本文)
    for lineno, line in numbered_lines:
        body = comment_body(line, prefixes)
        if body is None:
            prev = None
            continue
        for label, pattern in PATTERNS:
            if pattern.search(body):
                issues.append((path, lineno, label, body))
                break
        if JAPANESE.search(body) and len(body) > MAX_LINE_CHARS:
            issues.append((path, lineno, f"1 行が {MAX_LINE_CHARS} 文字超", body))
        if prev is not None:
            prev_lineno, prev_body = prev
            adjacent = lineno is None or prev_lineno is None or lineno == prev_lineno + 1
            if (adjacent and JAPANESE.search(prev_body) and CONTINUATION_END.search(prev_body)
                    and not LIST_MARKER.match(body) and not LIST_MARKER.match(prev_body)):
                issues.append((path, prev_lineno, "文中改行の疑い", f"{prev_body} ⏎ {body}"))
        prev = (lineno, body)
    return issues


def lines_from_tool_input(tool_name, tool_input):
    """Edit / Write / MultiEdit の入力から (パス, 追加行) を組み立てる。行番号は分からないので None。"""
    path = tool_input.get("file_path", "")
    if not path:
        return []
    results = []
    if tool_name == "Write":
        results.append((path, [(None, l) for l in tool_input.get("content", "").splitlines()]))
    elif tool_name == "Edit":
        results.append((path, added_lines(tool_input.get("old_string", ""), tool_input.get("new_string", ""))))
    elif tool_name == "MultiEdit":
        for edit in tool_input.get("edits", []):
            results.append((path, added_lines(edit.get("old_string", ""), edit.get("new_string", ""))))
    return results


def added_lines(old, new):
    old_set = set(old.splitlines())
    return [(None, l) for l in new.splitlines() if l not in old_set]


def lines_from_git_diff(cwd):
    try:
        proc = subprocess.run(
            ["git", "diff", "HEAD", "-U0", "--no-color", "--no-ext-diff", "--diff-filter=AM"],
            cwd=cwd, capture_output=True, text=True, timeout=5, errors="replace",
        )
    except (OSError, subprocess.SubprocessError):
        return []
    if proc.returncode != 0 or len(proc.stdout) > MAX_DIFF_BYTES:
        return []
    results = []
    path = None
    lineno = 0
    current = []
    for raw in proc.stdout.splitlines():
        if raw.startswith("+++ "):
            if path and current:
                results.append((path, current))
            path = raw[4:]
            path = path[2:] if path.startswith("b/") else None
            current = []
        elif raw.startswith("@@"):
            m = re.search(r"\+(\d+)", raw)
            lineno = int(m.group(1)) if m else 0
        elif raw.startswith("+") and path:
            current.append((lineno, raw[1:]))
            lineno += 1
    if path and current:
        results.append((path, current))
    return results


def state_path(session_id):
    directory = os.path.join(tempfile.gettempdir(), "claude-check-added-comments")
    os.makedirs(directory, exist_ok=True)
    safe = re.sub(r"[^\w-]", "_", session_id or "unknown")
    return os.path.join(directory, f"{safe}.json")


def load_state(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {"seen": [], "bash_baselined": False}


def save_state(path, state):
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f, ensure_ascii=False)
    except OSError:
        pass


def issue_key(issue):
    path, _lineno, label, body = issue
    return hashlib.sha1(f"{path}\n{label}\n{body}".encode("utf-8")).hexdigest()


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}
    cwd = data.get("cwd") or os.getcwd()

    if tool_name in ("Edit", "Write", "MultiEdit"):
        sources = lines_from_tool_input(tool_name, tool_input)
        baseline_only = False
    elif tool_name == "Bash":
        sources = lines_from_git_diff(cwd)
        baseline_only = None  # 状態ファイルを見て決める
    else:
        return 0

    issues = []
    for path, numbered_lines in sources:
        issues.extend(find_issues(path, numbered_lines))

    state_file = state_path(data.get("session_id", ""))
    state = load_state(state_file)
    seen = set(state.get("seen", []))

    # Bash 経路の初回はセッション開始前から存在する差分を含むので、記録だけして報告しない
    if baseline_only is None:
        baseline_only = not state.get("bash_baselined", False)
        state["bash_baselined"] = True

    new_issues = []
    for issue in issues:
        key = issue_key(issue)
        if key in seen:
            continue
        seen.add(key)
        new_issues.append(issue)
    state["seen"] = sorted(seen)
    save_state(state_file, state)

    if baseline_only or not new_issues:
        return 0

    lines = [
        "[check-added-comments] 追加・変更されたコメントに、CLAUDE.md「コードコメント」の規則に反する可能性のある行があります。"
        "将来の読者向けの恒久的な情報か、コードから読み取れない情報かを見直し、該当するなら消すか書き直してください。妥当なコメントならそのままで構いません。",
    ]
    for path, lineno, label, body in new_issues[:20]:
        rel = os.path.relpath(path, cwd) if os.path.isabs(path) else path
        location = f"{rel}:{lineno}" if lineno else rel
        lines.append(f"- {location} ({label}): {body[:200]}")
    if len(new_issues) > 20:
        lines.append(f"- ほか {len(new_issues) - 20} 件")

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": "\n".join(lines),
        }
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

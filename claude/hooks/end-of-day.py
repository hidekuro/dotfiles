#!/usr/bin/env python3
"""退勤時刻が近づいたら残り時間を書かせ、退勤 5 分前からは作業を続けるか切り上げるかを問うて止まらせる UserPromptSubmit フック。

モデルには日付しか渡らず現在時刻を知る手段がないので、発言のたびに時刻を判定し、標準出力からモデルのコンテキストに指示を足す。

冒頭に問いを置いて本文を続けると、答えを待たずに作業が進んでガードにならないので、問いだけを返してターンを終え、ユーザーが続けると答えてから依頼に取りかかる形にする。

同じ問いが毎ターン続くと作業の邪魔になるので、session_id と日付ごとの状態ファイルを一時ディレクトリに置き、問わせたターンで作る。
- hook は応答の中身も、ユーザーが続けると答えたかも見られないので、問わせたことだけを記録し、以後は問いの指示を出さない
- 日をまたいで続くセッションでは翌日の退勤時にも問いたいので、状態ファイルの名前に日付を入れる
- 状態ファイルを作れないと問いが毎ターン出てしまうので、作れないときは問いを出さない
- ユーザーが話しかけていないターン (`!` で実行したシェルコマンドと、サブエージェントの報告) で問わせると 1 回だけの問いを使い切るので、そこでは何も出力せず記録もしない
"""
import json
import os
import re
import sys
import tempfile
from datetime import datetime

END_OF_DAY = (19, 0)
NOTICE_MINUTES = 20
WRAP_UP_MINUTES = 5
NOT_FROM_USER = ("<bash-input>", "Another Claude session sent a message:")


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        data = {}
    if (data.get("prompt") or "").startswith(NOT_FROM_USER):
        return

    now = datetime.now()
    remaining = (END_OF_DAY[0] * 60 + END_OF_DAY[1]) - (now.hour * 60 + now.minute)
    if remaining > NOTICE_MINUTES:
        return

    end_label = f"{END_OF_DAY[0]}:{END_OF_DAY[1]:02d}"
    now_label = now.strftime("%H:%M")
    if remaining > 0:
        status = f"退勤時刻 ({end_label}) まで残り {remaining} 分です。"
        notice = f"現在時刻は {now_label} で、{status}回答の冒頭に「退勤まで残り {remaining} 分」と 1 行だけ書いてください。"
    else:
        status = f"退勤時刻 ({end_label}) を過ぎています。"
        notice = None
    if remaining > WRAP_UP_MINUTES:
        print(notice)
        return

    directory = os.path.join(tempfile.gettempdir(), "claude-end-of-day")
    safe = re.sub(r"[^A-Za-z0-9_-]", "_", data.get("session_id") or "unknown")
    path = os.path.join(directory, f"{safe}-{now:%Y-%m-%d}")
    try:
        os.makedirs(directory, exist_ok=True)
        if os.path.exists(path):
            if notice:
                print(notice)
            return
        with open(path, "w"):
            pass
    except OSError:
        return
    print(
        f"現在時刻は {now_label} で、{status}\n"
        f"ユーザーが続けるかどうかを決める前に作業が進まないよう、このターンでは依頼のためのツール (ファイルの読み書き、コマンド、検索など) を呼ばず、「{status}作業を続けますか、今日は切り上げますか。」と書いてターンを終えてください。続けると答えたら取りかかる依頼を 1 行で添えてもよいですが、その作業はしないでください。次の一手の欄 (wrap_up) を使えるときは、その問いにも同じ質問を入れ、ボタンを「続ける」「切り上げる」にしてください。CLAUDE.md の切り上げの規則は、このターンを例外にしています。\n"
        "ユーザーがこの発言で切り上げると言っているなら、問わずに wrap-up スキルを使ってください。\n"
        "ユーザーが続けると答えたら、この問いの直前に受けた依頼に取りかかり、以後このセッションでは、切り上げを問うことも wrap-up スキルを勧めることもしないでください。切り上げると答えたら wrap-up スキルを使ってください。\n"
        "この問いはこのセッションで今回だけ出します。"
    )


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""退勤時刻が近づいたら残り時間を、切り上げ作業に要する時間を切ったら切り上げの提案をモデルに促す UserPromptSubmit フック。

モデルには日付しか渡らず現在時刻を知る手段がないので、発言のたびに時刻を判定して注意文を差し込む。
UserPromptSubmit の標準出力はそのままモデルのコンテキストに追加される。
"""
from datetime import datetime

END_OF_DAY = (19, 0)
NOTICE_MINUTES = 20
WRAP_UP_MINUTES = 5


def main():
    now = datetime.now()
    remaining = (END_OF_DAY[0] * 60 + END_OF_DAY[1]) - (now.hour * 60 + now.minute)
    end_label = f"{END_OF_DAY[0]}:{END_OF_DAY[1]:02d}"
    now_label = now.strftime("%H:%M")

    if remaining <= 0:
        print(
            f"現在時刻は {now_label} で、退勤時刻 ({end_label}) を過ぎています。"
            "この会話でまだ提案していなければ、回答の冒頭で今日の切り上げ (wrap-up スキル) を提案してください。"
        )
    elif remaining <= WRAP_UP_MINUTES:
        print(
            f"現在時刻は {now_label} で、退勤時刻 ({end_label}) まで残り {remaining} 分です。"
            f"回答の冒頭に「退勤まで残り {remaining} 分」と 1 行書いてください。"
            "この会話でまだ提案していなければ、続けて今日の切り上げ (wrap-up スキル) を提案してください。"
        )
    elif remaining <= NOTICE_MINUTES:
        print(
            f"現在時刻は {now_label} で、退勤時刻 ({end_label}) まで残り {remaining} 分です。"
            f"回答の冒頭に「退勤まで残り {remaining} 分」と 1 行だけ書いてください。"
        )


if __name__ == "__main__":
    main()

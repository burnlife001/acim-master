#!/usr/bin/env python3
"""生成书集的文件名（不创建文件）。

用法:
  gen_filename.py riji  "标题"     -> 2026-10-02（标题）.md 或 2026-10-02-04（标题）.md
  gen_filename.py wenda "标题"     -> 012.标题.md
  gen_filename.py riji  "标题" --full   输出绝对路径

语料根定位（先到先得）:
  1. <当前目录>/src/books        —— 宿主项目 live 语料
  2. <仓库>/src/books            —— 技能位于 <仓库>/.claude/skills/ 时的 legacy 位置
  3. 同级 acim 技能 corpus/      —— 便携兜底
目标子目录（07.日记 / 06.问答）不存在时自动创建。

规则:
  日记: 当天无文件 → 无后缀；当天已有文件 → 序号 = 当天最大序号+1（无后缀文件视为 01）
        落盘带后缀文件时若当天存在无后缀文件，脚本自动将其改名为 -01（目标已存在则跳过并告警）
  问答: 序号 = 现有最大 NNN + 1，三位零填充
"""
import re
import sys
from datetime import date
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

SKILL_DIR = Path(__file__).resolve().parent.parent  # <skills>/acimd


def find_books() -> Path:
    for c in (Path.cwd() / "src" / "books",
              SKILL_DIR.parents[2] / "src" / "books",
              SKILL_DIR.parent / "acim" / "corpus"):
        if (c / "01.正文").is_dir():
            return c
    sys.exit("错误: 找不到书集语料（试过: 当前目录 src/books、"
             f"{SKILL_DIR.parents[2] / 'src' / 'books'}、{SKILL_DIR.parent / 'acim' / 'corpus'}）")


BOOKS = find_books()
DIRS = {"riji": BOOKS / "07.日记", "wenda": BOOKS / "06.问答"}
for _d in DIRS.values():
    _d.mkdir(parents=True, exist_ok=True)


def sanitize(title: str) -> str:
    title = re.sub(r'[\\/:*?"<>|]', "", title).strip()
    if not title:
        sys.exit("错误: 标题为空或全是非法字符")
    return title


def riji_name(title: str) -> str:
    today = date.today().isoformat()
    d = DIRS["riji"]
    pat = re.compile(rf"^{re.escape(today)}(?:-(\d+))?（.*）\.md$")
    files = [(f, m) for f in d.glob(f"{today}*") if (m := pat.match(f.name))]
    if not files:
        return f"{today}（{title}）.md"
    nxt = max(int(m.group(1) or 1) for _, m in files) + 1
    # 落盘带后缀文件前，把无后缀的首个文件自动改名为 -01，保持序列一致
    for f, m in files:
        if m.group(1) is None:
            target = f.with_name(f"{today}-01{f.name[len(today):]}")
            if target.exists():
                print(f"警告: {target.name} 已存在，跳过自动改名 {f.name}", file=sys.stderr)
            else:
                f.rename(target)
                print(f"已自动改名: {f.name} -> {target.name}", file=sys.stderr)
    return f"{today}-{nxt:02d}（{title}）.md"


def wenda_name(title: str) -> str:
    d = DIRS["wenda"]
    nums = [int(m.group(1)) for f in d.glob("*.md") if (m := re.match(r"^(\d{3})\.", f.name))]
    return f"{(max(nums) if nums else 0) + 1:03d}.{title}.md"


def main() -> None:
    if len(sys.argv) < 3 or sys.argv[1] not in DIRS:
        sys.exit(__doc__)
    kind, title = sys.argv[1], sanitize(sys.argv[2])
    name = riji_name(title) if kind == "riji" else wenda_name(title)
    print(DIRS[kind] / name if "--full" in sys.argv else name)


if __name__ == "__main__":
    main()

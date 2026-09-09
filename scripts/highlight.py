#!/usr/bin/env python3

# HTML code syntax highlighter
# Copyright (C) 2026, Nathan Gill
# Licensed under the MIT license
# See LICENSE_MIT for details

import sys
import tomllib
from pathlib import Path
from pygments import lex
from pygments.lexers import get_lexer_by_name
from pygments.styles import get_style_by_name
from pygments.formatters import HtmlFormatter
from bs4 import BeautifulSoup, NavigableString

BUILD_DIR = None
INCL_GLOBS = None
EXCL_GLOBS = None

for arg in sys.argv:
    try:
        data = tomllib.loads(arg)
        key, value = next(iter(data.items()))
    except ValueError:
        continue

    if key == "build_dir":
        BUILD_DIR = Path(value)
    elif key == "incl":
        INCL_GLOBS = list(value)
    elif key == "excl":
        EXCL_GLOBS = list(value)
    else:
        sys.exit(1)

style = get_style_by_name("catppuccin-mocha")
formatter = HtmlFormatter(nowrap=True, style=style)

def find_pages():
    pages = []

    for glob in INCL_GLOBS:
        paths = BUILD_DIR.rglob(glob)
        for path in paths:
            if path not in pages:
                pages.append(path)

    for glob in EXCL_GLOBS:
        paths = BUILD_DIR.rglob(glob)
        for path in paths:
            if path in pages:
                pages = list(filter(lambda p: p != path, pages))

    return pages

def highlight_one(p):
    f = open(p, "rt")
    ht = f.read()
    f.close()

    soup = BeautifulSoup(ht, "html.parser")

    pr = 0
    for code in soup.select('code[class*="language-"]'):
        pre = code.find_parent("pre")
        if pre == None:
            continue

        ls = []
        for c in code.get("class", []):
            if c.startswith("language-"):
                ls.append(c.removeprefix("language-"))

        if len(ls) == 0:
            continue
        lang = ls[0]
        
        try:
            lexr = get_lexer_by_name(lang)
        except Exception:
            continue

        source = code.get_text("", strip=False)

        code.clear()
        code["class"].append("highlight")

        for tt, val in lex(source, lexr):
            ts = style.style_for_token(tt)
            sp = soup.new_tag("span")

            sp["class"] = [formatter._get_css_class(tt)]
            sp.append(NavigableString(val))
            code.append(sp)
        pr = 1

    if pr == 1:
        ln = soup.new_tag("link")
        ln["href"] = "/static/highlight.css"
        ln["rel"] = "stylesheet"
        soup.head.append(ln)

        f = open(p, "wt")
        f.write(str(soup))
        f.close()

def main():
    pages = find_pages()

    st = formatter.get_style_defs(".highlight")
    # i'm hardcoding this, no, i don't care
    f = open(BUILD_DIR / "static" / "highlight.css", "wt")
    f.write(st)
    f.close()
    
    for page in pages:
        highlight_one(page)

if __name__ == "__main__":
    main()


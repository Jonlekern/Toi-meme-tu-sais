#!/usr/bin/env python3
"""Print characters from the given text files that a font lacks.

usage: glyphs.py FONT.ttf TEXTFILE [TEXTFILE ...]
Pass '-s "some text"' as a file name prefix to check a literal string: use
the form  str:Some text  instead of a path.
"""
import sys
from fontTools.ttLib import TTFont

font = TTFont(sys.argv[1])
cmap = font.getBestCmap()
missing = {}
for src in sys.argv[2:]:
    if src.startswith("str:"):
        text = src[4:]
    else:
        with open(src, encoding="utf-8") as f:
            text = f.read()
    for ch in text:
        if ch in "\n\r\t":
            continue
        if ord(ch) not in cmap:
            missing.setdefault(ch, set()).add(src[:20])
for ch, where in sorted(missing.items()):
    print("U+%04X %r missing (%s)" % (ord(ch), ch, ", ".join(sorted(where))))

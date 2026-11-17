#!/usr/bin/env python3
"""nInvaders' picture for its GlowIcons (art/ninvaders.png), drawn here:
upstream has none. A green invader over the gun and a bunker, on the
console's black, in the game's own colours. 64 x 64, RGBA.
    python3 amiga/icons/draw_art.py amiga/icons/art
Pure Python. MIT, Copyright (c) 2026 AmiCradle Team."""
import struct, sys, zlib
from pathlib import Path

W = H = 64
INK = (16, 18, 22, 255)
GREEN = (70, 200, 80, 255)
CYAN = (60, 190, 210, 255)
YELLOW = (230, 210, 60, 255)
WHITE = (235, 235, 235, 255)
INVADER = [  # 11 x 8
    "..X.....X..",
    "...X...X...",
    "..XXXXXXX..",
    ".XX.XXX.XX.",
    "XXXXXXXXXXX",
    "X.XXXXXXX.X",
    "X.X.....X.X",
    "...XX.XX...",
]
GUN = [  # 7 x 3
    "...X...",
    ".XXXXX.",
    "XXXXXXX",
]


def png(px, path):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def draw():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    def rect(x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                px[y][x] = c
    def sprite(rows, x0, y0, scale, c):
        for r, row in enumerate(rows):
            for k, ch in enumerate(row):
                if ch == "X":
                    rect(x0 + k * scale, y0 + r * scale, x0 + (k + 1) * scale, y0 + (r + 1) * scale, c)
    rect(2, 2, 62, 62, INK)
    rect(4, 4, 60, 60, (8, 8, 12, 255))
    sprite(INVADER, 10, 7, 4, GREEN)
    rect(31, 41, 33, 46, WHITE)                  # the gun's shot
    sprite(GUN, 22, 50, 3, CYAN)
    for x0 in (6, 46):                           # bunkers
        rect(x0, 47, x0 + 12, 52, YELLOW)
        rect(x0 + 4, 50, x0 + 8, 52, (8, 8, 12, 255))
    return px


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "art")
    out.mkdir(parents=True, exist_ok=True)
    png(draw(), out / "ninvaders.png")

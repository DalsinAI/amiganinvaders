#!/bin/sh
# Host tests of the port, on this machine: amiga/curses.c and amiga/keys.c
# built with upstream's nInvaders (amiga/patches applied, __amigaos__ set,
# so the Amiga's code is the one built: the ticks from the game's own loop,
# not SIGALRM) over a plain terminal (tests/host/console_host.c), played
# with keys sent over time; tests/host/vt.py reads back the screen as the
# Amiga's console would show it:
#  - curses: pads drawn only through copywin, copywin's rectangle and its
#    overlay, mvwin, a pad's own refresh refused;
#  - the title screen (its text, the aliens' points, "Press SPACE to
#    start"), in the pairs' colours;
#  - SPACE starts: the aliens, the bunkers, the gun and the status line;
#  - the ticks run without keys: the aliens move by themselves;
#  - the cursor keys (and h, l) move the gun, SPACE fires;
#  - Q ends the game with the final score; the window's close ends it too.
# Needs a C compiler and python3; skipped without a compiler.
#   UP=/path/to/ninvaders-0.1.1 (patched) sh tests/host/test_ninvaders.sh
# Copyright (c) 2026 AmiCradle Team. MIT (the port's own files).
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
UP=${UP:?UP=upstream source}
CC=${HOSTCC:-cc}
command -v "$CC" >/dev/null 2>&1 || { echo "host tests: skipped (no C compiler)"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/ninvaders-host.XXXXXX")
[ -n "${TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM
cd "$ROOT"

MINE="-std=gnu99 -Wall -Werror -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -Iamiga/include -Iamiga"
for f in curses keys; do $CC $MINE -c -o "$T/$f.o" "amiga/$f.c"; done
$CC $MINE -c -o "$T/con.o" tests/host/console_host.c
for f in globals view aliens ufo player nInvaders; do
    $CC -std=gnu11 -fcommon -w -Werror=implicit-function-declaration -D_DEFAULT_SOURCE -D__amigaos__ \
        -Iamiga/include -Iamiga -I"$UP" -c -o "$T/u_$f.o" "$UP/$f.c"
done
$CC -o "$T/nInvaders" "$T"/u_*.o "$T/curses.o" "$T/keys.o" "$T/con.o"
fails=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; fails=$((fails + 1)); }

# curses: pads and copywin
cat > "$T/pad_test.c" <<'C'
#include <stdio.h>
#include <string.h>
#include "curses.h"
static int row(WINDOW *w, int y, const char *want)
{
	char got[81]; int x;
	for (x = 0; x < (int)strlen(want); x++) got[x] = (char)(w->line[y][x] & A_CHARTEXT);
	got[x] = 0;
	if (strcmp(got, want)) { printf("row %d: '%s', want '%s'\n", y, got, want); return 1; }
	return 0;
}
int main(void)
{
	WINDOW *pad, *field;
	int bad = 0;
	initscr();
	pad = newpad(2, 5); field = newwin(4, 10, 0, 0);
	mvwaddstr(pad, 0, 0, "<o o>"); mvwaddstr(pad, 1, 0, "a b c");
	if (wrefresh(pad) != ERR) { printf("a pad refreshed itself\n"); bad = 1; }
	mvwaddstr(field, 1, 0, "xxxxxxxxxx"); mvwaddstr(field, 2, 0, "xxxxxxxxxx");
	if (copywin(pad, field, 0, 0, 1, 2, 1, 6, 0) != OK) { printf("copywin\n"); bad = 1; }
	bad |= row(field, 1, "xx<o o>xxx");
	if (copywin(pad, field, 1, 0, 2, 3, 2, 7, 1) != OK) { printf("copywin overlay\n"); bad = 1; }
	bad |= row(field, 2, "xxxaxbxcxx");
	if (copywin(pad, field, 0, 0, 3, 6, 3, 10, 0) != ERR) { printf("copywin past the window\n"); bad = 1; }
	if (copywin(pad, field, 1, 0, 0, 0, 1, 4, 0) != ERR) { printf("copywin past the pad\n"); bad = 1; }
	if (mvwin(field, 20, 0) != OK || field->begy != 20) { printf("mvwin\n"); bad = 1; }
	if (mvwin(field, 22, 0) != ERR) { printf("mvwin off the screen\n"); bad = 1; }
	endwin();
	return bad;
}
C
$CC $MINE -o "$T/pad_test" "$T/pad_test.c" "$T/curses.o" "$T/keys.o" "$T/con.o"
if "$T/pad_test" > "$T/pad.out" 2>&1; then pass "curses: pads, copywin (and its overlay), mvwin"; else fail "curses: $(grep -av "$(printf '\033')" "$T/pad.out" | head -5)"; fi

# keys sent over time: "WAIT KEYS WAIT KEYS ..." (seconds, printf formats)
play() {	# output, then WAIT KEYS pairs
    out=$1; shift
    (
        while [ $# -ge 2 ]; do sleep "$1"; printf "$2"; shift 2; done
        [ $# -eq 1 ] && sleep "$1"
    ) | (cd "$T" && timeout 30 ./nInvaders > "$out" 2> "$out.err")
}
screen() { python3 "$HERE/vt.py" "$1"; }
want() {	# name, output, texts...
    name=$1; out=$2; shift 2
    n=$#
    for t in "$@"; do set -- "$@" --want "$t"; done
    shift "$n"
    if python3 "$HERE/vt.py" "$out" "$@" > "$T/vt.txt"; then pass "$name"; else fail "$name"; cat "$T/vt.txt"; fi
}
gun_x() { screen "$1" | sed -n 23p | awk '{ print index($0, "/-^-\\") }'; }
aliens() { screen "$1" | sed -n 1,16p; }

play "$T/title.out" 0.6
if [ -s "$T/title.out" ]; then pass "the window's close ends the game"; else fail "no screen at all"; fi
want "the title screen" "$T/title.out" "Press SPACE to start" "= 500" "= 200" "= 150" "= 100"
if grep -q "$(printf '\033')\[0;3[1-7];40m" "$T/title.out"; then pass "the pairs' colours (SGR 3x on 40)"; else fail "no colours"; fi

play "$T/start.out" 0.3 ' ' 0.4
want "SPACE starts: the gun, the status line" "$T/start.out" "/-^-\\" "Level: 01" "Score:" "Lives:"
if aliens "$T/start.out" | grep -q '<O>\|<o>\|_O-\|-O_'; then pass "the aliens are drawn"; else fail "no aliens"; screen "$T/start.out"; fi
if screen "$T/start.out" | sed -n 16,20p | grep -q '#'; then pass "the bunkers are drawn"; else fail "no bunkers"; fi

play "$T/later.out" 0.3 ' ' 2.5
if [ "$(aliens "$T/start.out")" != "$(aliens "$T/later.out")" ]; then pass "the aliens move by themselves (the game's own ticks)"; else fail "the aliens did not move"; fi

x0=$(gun_x "$T/start.out")
# the gun starts at the left: right first, then back
play "$T/right.out" 0.3 ' ' 0.3 '\033[C\033[C\033[C\033[C\033[C\033[C' 0.4
play "$T/left.out" 0.3 ' ' 0.3 '\033[C\033[C\033[C\033[C\033[C\033[C' 0.3 'hh' 0.4
play "$T/l.out" 0.3 ' ' 0.3 'llll' 0.4
xr=$(gun_x "$T/right.out"); xl=$(gun_x "$T/left.out"); xk=$(gun_x "$T/l.out")
if [ "$xr" -gt "$x0" ] && [ "$xl" -gt 0 ] && [ "$xl" -lt "$xr" ] && [ "$xk" -gt "$x0" ]; then
    pass "the cursor keys and h/l move the gun ($x0 -> $xr -> $xl; l: $xk)"
else
    fail "the gun did not move: $x0 $xr $xl $xk"
fi
play "$T/fire.out" 0.3 ' ' 0.3 ' ' 0.06
if screen "$T/fire.out" | sed -n 1,22p | grep -q '!'; then pass "SPACE fires"; else fail "no missile"; screen "$T/fire.out"; fi

play "$T/quit.out" 0.3 ' ' 0.3 'q' 0.5
if grep -q "Final score" "$T/quit.out.err"; then pass "Q ends the game with the final score"; else fail "Q: $(head -3 "$T/quit.out.err")"; fi

if [ "$fails" -ne 0 ]; then echo "host tests: $fails failed"; exit 1; fi
echo "host tests: all passed"

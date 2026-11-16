nInvaders for GFOS
==================

Dettus' nInvaders: the aliens march down the screen; move the gun along
the bottom and shoot them before they land. Bunkers give cover until
they are shot away, and a UFO crosses the top now and then.

SPACE starts a game and fires. The cursor keys (or h and l) move the gun;
holding a key down moves it faster. P pauses, Q ends the game (as does
the window's close gadget) and shows the final score and rating.
nInvaders -l N sets the skill, 0 (nightmare) to 9 (gentle); 1 is the
default.

What it needs
-------------
GFOS (AmigaOS 3.2 with GFOpenUp) on a 68040 or 68060; the FPU is not
needed. The game runs in a console window on any screen with eight
colours or more: no SDL, no ACGame, no GFOpenGPU.

How it was ported
-----------------
The game is built from upstream's 0.1.1 tarball as it is, with one patch
(amiga/patches/0001): AmigaOS has no SIGALRM, so instead of setitimer the
game's own loop runs its 50 ticks a second (a clock from dos.library
DateStamp) and waits for keys between them; the final score stays in the
window until a key.

amiga/curses.c is the part of ncurses the game uses: the layer of
DalsinAI/amiga2048 (windows in memory, a refresh that sends the console
only what changed, as ANSI that console.device reads, colour pairs on the
screen's first eight pens), with what nInvaders adds: pads (newpad),
copywin, mvwin and redrawwin. amiga/console_amiga.c opens the window,
puts it in raw mode and reads the keys (amiga/keys.c: the cursor keys as
curses' KEY_*).

Tests: tests/host/test_ninvaders.sh builds the game on the build machine
over a plain terminal, plays it with keys sent over time and reads back
the screen: pads and copywin, the title screen and its colours, SPACE
starting a game (aliens, bunkers, gun, status line), the aliens moving on
the game's own ticks, the gun moving by cursor keys and h/l, SPACE firing,
Q with the final score, the window's close.

Credits
-------
nInvaders (c) 2002-2003 Dettus, GPL-2.0-or-later (COPYING.txt).
Amiga port: Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team; the port's own files MIT.

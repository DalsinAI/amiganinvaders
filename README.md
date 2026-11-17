# nInvaders for GFOS

The AmiCradle Team's port of Dettus' nInvaders 0.1.1, Space Invaders for
the text console, to GFOS: AmigaOS 3.2 with GFOpenUp, 68040/68060. It
runs in its own 80 x 24 console window, in colour: no SDL, no ACGame and
no GFOpenGPU. It ships as a release archive with an Installer and as the
GFOpenUp part Parts/nInvaders.

Upstream is fetched at build time (package/ninvaders.lock, its SHA-256
checked) and patched (amiga/patches); this repository holds only the
Amiga port. See [AMIGA_PORT.md](AMIGA_PORT.md).

nInvaders is GPL-2.0-or-later (COPYING.txt in the drawer); the port's own
files (amiga/, tests/, package/, tools/) are MIT. Copyright (c) 2026
AmiCradle Team.

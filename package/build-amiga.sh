#!/bin/sh
# The release archive and the GFOpenUp part, for Cradle's stove_build
# (target package):
#  1. upstream nInvaders, the tarball package/ninvaders.lock names (fetched,
#     its SHA-256 checked, never kept in this repository), with amiga/patches;
#  2. the host tests (tests/host/test_ninvaders.sh), when the machine has a C
#     compiler and python3;
#  3. the game built by amiga/Makefile.amigaos;
#  4. the drawer, its icon and the Installer script beside it packed as
#     NAME-VERSION-68040.lha (tools/pack_dist.py), with its .sha256 and a
#     short .readme;
#  5. OUT/Parts/nInvaders, a GFOpenUp part: its Part file and the
#     drawer's files for SYS:Games/nInvaders, installed with
#       GFOpenUpTool INSTALL Parts/nInvaders
# Nothing is published from here.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
# everything on stdout, and the step a failure stopped in: the stove log keeps only stdout
exec 2>&1
STEP=start
trap 'rc=$?; [ $rc = 0 ] || echo "build-amiga.sh: failed (exit $rc) in step: $STEP"' EXIT

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/.." && pwd)
. "$HERE/package.env"
. "$HERE/ninvaders.lock"
OUT=${OUT:-"$ROOT/build-amiga-package"}
mkdir -p "$OUT"
OUT=$(CDPATH= cd -- "$OUT" && pwd)
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK=${WORK:-"$HOME/.cache/amiganinvaders"}
mkdir -p "$WORK"
cd "$ROOT"
t0=$(date +%s)
if [ -x "$STOVE/prefix/bin/m68k-amigaos-gcc" ]; then PREFIX="$STOVE/prefix"; else PREFIX="$STOVE"; fi

# 1. upstream's tarball, checked, unpacked and patched afresh every time
STEP=upstream
TGZ="$WORK/ninvaders-$UP_VERSION.tar.gz"
if [ "$(sha256sum "$TGZ" 2>/dev/null | cut -d' ' -f1)" != "$UP_SHA256" ]; then
    curl -fsSL -o "$TGZ.part" "$UP_URL"
    [ "$(sha256sum "$TGZ.part" | cut -d' ' -f1)" = "$UP_SHA256" ] || { echo "$UP_URL: SHA-256 is not the lock's"; exit 1; }
    mv "$TGZ.part" "$TGZ"
fi
UPSRC="$WORK/ninvaders-$UP_VERSION"
rm -rf "$UPSRC"; mkdir -p "$WORK/unpack"; rm -rf "$WORK/unpack/"*
tar xzf "$TGZ" -C "$WORK/unpack"
mv "$WORK/unpack/ninvaders-$UP_VERSION" "$UPSRC"
for p in "$ROOT"/amiga/patches/*.patch; do
    patch -s -d "$UPSRC" -p1 < "$p"
done

# 2. the host tests
STEP="host tests"
if command -v cc >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    UP="$UPSRC" sh tests/host/test_ninvaders.sh
fi

# 3. the game
STEP=build
make -f amiga/Makefile.amigaos UP="$UPSRC" STOVE="$STOVE" PREFIX="$PREFIX" -j4 $TARGET \
    > "$OUT/build-output.txt" 2>&1 || { grep -E ': (fatal )?error' "$OUT/build-output.txt" | head -40; tail -n 30 "$OUT/build-output.txt"; exit 1; }

# 4. the archive
STEP=archive
python3 "$ROOT/tools/pack_dist.py" --dist "$DIST" --name "$NAME" --out "$OUT"

# 5. the GFOpenUp part
STEP=part
sh "$ROOT/package/write-part.sh" "$DIST/$NAME" "$OUT/Parts/$NAME" "$NAME" "$PORT_VERSION" \
    "nInvaders: Space Invaders in a console window"
echo "part: $(grep -c '^copy' "$OUT/Parts/$NAME/Part") files, $(du -sk "$OUT/Parts/$NAME" | cut -f1) KB"
ls -l "$DIST/$NAME"
echo "total: $(( $(date +%s) - t0 )) s"

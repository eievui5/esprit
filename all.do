#!/usr/bin/env bash
set -euo pipefail

VERSION=0
SRAMSIZE=2 # One bank of 8 KiB.
LDFLAGS=(-p 0xFF -w -S romx=256)
FIXFLAGS=(-p 0xFF
	-j -c
	-k "EV"
	-l 0x33
	-m MBC5+RAM+Battery
	-n "$VERSION"
	-r "$SRAMSIZE"
	-t 'Esprit')

# We do this before the `OBJS` detection, to ensure that it is picked up, only once, and from `src/`.
redo src/version.asm # Unconditionally re-assemble the version file.

mapfile -d '' OBJS < <(find src -name '*.asm' -printf 'obj/%P.o\0' -o -name '*.evs' -printf 'obj/%P.asm.o\0')
redo-ifchange "${OBJS[@]}"

mkdir -p bin/
rgblink "${LDFLAGS[@]}"  -o - -m bin/esprit.map -n bin/esprit.sym  "${OBJS[@]}" | rgbfix >bin/esprit.gb  -v "${FIXFLAGS[@]}"

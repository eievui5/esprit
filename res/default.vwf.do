#!/usr/bin/env bash
. ./res.sh

MAKEFONT=../tools/target/release/makefont
redo-ifchange "$MAKEFONT"

apply_vpath IMG "$2.png"

mkdir -p "${2%/*}"
redo-ifchange "$IMG"
exec $MAKEFONT "$IMG" "$3" "$2_glyphs.inc"

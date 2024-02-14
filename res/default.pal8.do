#!/usr/bin/env bash
PALCONV=../tools/target/release/palconv
redo-ifchange "$PALCONV"

. ./res.sh

apply_vpath PAL "$2.pal"

exec $PALCONV "$3" "$PAL"

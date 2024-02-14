#!/usr/bin/env bash
. ./res.sh

apply_vpath IMG "$2.png"
apply_vpath ARGSFILE "$2.arg"

if [[ -e "$ARGSFILE" ]]; then
	GFXFLAGS=("@$ARGSFILE")
# `-Z` is common enough that making an arg-file for each would be annoying.
# So we do a little hack here.
elif [[ $2 = *.obj ]]; then
	GFXFLAGS=(-Z)
else
	GFXFLAGS=(-c embedded)
fi

exec rgbgfx "${GFXFLAGS[@]}" "$IMG" -o "$3" -p "$2.pal" -t "$2.map" -a "$2.pmap"

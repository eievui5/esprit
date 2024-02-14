#!/usr/bin/env bash
GIT_VERSION=$(git describe --tags --always --dirty)

redo-always
redo-stamp <<<"$GIT_VERSION"

printf "section \"Version\", rom0\nVersion:: db \"Esprit v%s\\\\nBuilt on {d:__UTC_YEAR__}-{d:__UTC_MONTH__}-{d:__UTC_DAY__}\\\\nUsing RGBDS {__RGBDS_VERSION__}\", 0\n" "$GIT_VERSION" >$3

#!/usr/bin/env bash
set -euo pipefail

INCPATHS=(src/  src/include/)
WARNINGS=(all  extra  no-unmapped-char)
ASFLAGS=(-p 0xFF -h  -Q 4  "${INCPATHS[@]/#/-I}"  "${WARNINGS[@]/#/-W}")

# Look for sources in `src/`, but if not found, try in `obj/` as they might be auto-generated.
SRC="src/${2#obj/}"
if ! [[ -e "$SRC" ]]; then
	SRC="obj/${SRC#src/}"
fi
redo-ifchange $SRC

mkdir -p "${2%/*}" # Create the output directory.

# RGBASM exits with status 0 if either it completed successfully, or it encountered a missing dependency.
# To distinguish the two, we check for the output file, which is only produced in the former case.
# But if the output already exists, we may take the latter for the former; so, delete it.
rm -rf "$3"

while ! [[ -e "$3" ]]; do
	# Attempt to build and discover dependencies, passing each of them to `redo-ifchange` via `-M`.
	# Redirect RGBASM's stdout (which `PRINTLN` & co. write to) to a file,
	# since stdout points at the output file ($3), and we don't want to corrupt it
	# by adding text to it...
	# Additionally, some commands may want to do something with that output.
	rgbasm >"$2.out" "${ASFLAGS[@]}" "$SRC" -o "$3" -M "$2.d" -MG
	# Dependencies are passed via a file so we can want for `redo-ifchange` to complete
	# (`> >(cmd)` spawns `cmd` as a background process), and because we can't use a pipe
	# (stdout would conflict with e.g. `println`).
	cut -d : -f 2- "$2.d" | xargs redo-ifchange
	# We will keep retrying until all dependencies have been built, since then RGBASM will have generated the output file.
done

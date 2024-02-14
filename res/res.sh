#!/usr/bin/env bash

# Create the target's directory.
# (No need to fork a `dirname`, this is a file.)
mkdir -p "${2%/*}"

apply_vpath() {
	local -n src="$1"
	# Look for a version in `src`, which always has priority.
	# (This ensures that we don't accidentally rely on the order of operations,
	# as we could generate a conflicting version in `res/` in the middle of the build.)
	if [[ -e "../src/res/$2" ]]; then
		src="../src/res/$2"
	else
		# We'll try to use a generated version, then.
		src="$2"
	fi
}

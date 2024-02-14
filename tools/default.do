#!/usr/bin/env bash
set -euo pipefail

# Passed as-is to `cargo build --features`.
declare -A FEATURES=(
	[makefont]=image
)

progname="${2#target/*/}"
profile=$(cut -d / -f 2 <<<"$2")
features="${FEATURES[$progname]-}"

cargo b --profile "$profile" --bin "$progname" -F "$features"
mv "$1" "$3"

# Cargo automatically generates Make-style dependency info!
cut -s -d : -f 2- "$1.d" | xargs redo-ifchange

#!/usr/bin/env bash
redo-ifchange "$2.2bpp" # The `.2bpp` build always builds this too.
mv "$1" "$3"

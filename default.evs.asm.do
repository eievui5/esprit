#!/usr/bin/env bash
EVS="src/${2#obj/}.evs"
redo-ifchange "$EVS"

mkdir -p "${2%/*}"
evscript -o "$3" "$EVS"

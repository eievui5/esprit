#!/usr/bin/env bash
redo-ifchange ../obj/libs/vwf.asm.o
exec cp ../obj/libs/vwf.asm.out "$3"

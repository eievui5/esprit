include "defines.inc"
include "menu.inc"

; These two helper macros define the themes and palettes, automatically turning
; them into a circular linked list. You're welcome :3

macro themes
	def FIRST_NAME equs "\1MenuTheme"
	rept _NARG / 2
		def CUR_NAME equs "\1"
		section "\1 Theme", romx
		\1MenuTheme::
			if _NARG > 2
				db bank(\3MenuTheme)
				dw \3MenuTheme
			else
				db bank(FIRST_NAME)
				dw FIRST_NAME
			endc
			incbin "res/ui/\2_cursor.obj.2bpp"
			dw .end - .emblem, .emblem, .map
			db "{CUR_NAME}", 0
		.emblem incbin "res/ui/\2_emblem.2bpp"
		.end
		.map incbin "res/ui/\2_emblem.map"
			shift 2
		purge CUR_NAME
	endr
	purge FIRST_NAME
endm

macro colors
	def FIRST_NAME equs "\1MenuPalette"
	rept _NARG / 13
		def CUR_NAME equs "\1"
		section "\1 Theme", romx
		\1MenuPalette::
			if _NARG > 13
				shift 13
				db bank(\1MenuPalette)
				dw \1MenuPalette
				shift -13
			else
				db bank(FIRST_NAME)
				dw FIRST_NAME
			endc
			shift 1
			rgb \1, \2, \3
			shift 3
			rgb \1, \2, \3
			shift 3
			rgb \1, \2, \3
			shift 3
			rgb \1, \2, \3
			shift 3
			db "{CUR_NAME}", 0
		purge CUR_NAME
	endr
	purge FIRST_NAME
endm

	themes Pawprint, paw, Explorer, explorer, Heart, heart

	colors \
		Pink,   255, 160, 255,\
		        255,  24, 255,\
		        128,   0, 128,\
		          0,   0,   0,\
		Red,    255, 160, 160,\
		        255,  24,  24,\
		        128,   0,   0,\
		          0,   0,   0,\
		Orange, 255, 238, 204,\
		        230, 153,  16,\
		        150, 102,   0,\
		          0,   0,   0,\
		Yellow, 255, 255, 160,\
		        255, 255,  24,\
		        128, 128,   0,\
		          0,   0,   0,\
		Green,  160, 255, 160,\
		         24, 255,  24,\
		          0, 128,   0,\
		          0,   0,   0,\
		Blue,   160, 160, 255,\
		         24,  24, 255,\
		          0,   0, 128,\
		          0,   0,   0,\
		Black,    0,   0,   0,\
		         64,  64,  64,\
		        128, 128, 128,\
		        255, 255, 255,\

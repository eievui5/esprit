include "config.inc"
include "defines.inc"
include "draw_menu.inc"
include "hardware.inc"
include "menu.inc"

section "Title screen", romx
xTitleScreen::
	db bank(@)
	dw xTitleScreenInit
	; Used Buttons
	db PADF_A | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 0
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw TitleScreenA, null, null, null, null, null, xTitleScreenMove, xTitleScreenMove
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 1
	; Number of items in the menu
	db 2
	; Redraw
	dw xTitleScreenRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw null

xTitleTiles:
	incbin "res/ui/title/title_screen.2bpp"
.end
xTitleMap:
	incbin "res/ui/title/title_screen.map"
xTitleAttrmap:
	incbin "res/ui/title/title_screen.pmap"
xTitlePalettes:
	incbin "res/ui/title/title_screen.pal8"

xTitleTilesDmg:
	incbin "res/ui/title/title_screen_dmg.2bpp"
.end
xTitleMapDmg:
	incbin "res/ui/title/title_screen_dmg.map"

xSleepingProtags:
	incbin "res/ui/title/luvui_sleeping.obj.2bpp"
	incbin "res/ui/title/aris_sleeping.obj.2bpp"
	incbin "res/ui/title/campfire.obj.2bpp"
	incbin "res/ui/title/stars.obj.2bpp"
	incbin "res/ui/title/text_sprites.2bpp"
.end
xProtagPalettes:
	incbin "res/ui/title/luvui_sleeping.obj.pal8", 3
	incbin "res/ui/title/aris_sleeping.obj.pal8", 3
	incbin "res/ui/title/campfire.obj.pal8", 3
	incbin "res/ui/title/stars.obj.pal8", 3
	incbin "res/ui/title/text_sprites.pal8", 3
	hex 404040, ff0000, 000000

xTitleScreenInit:
	xor a, a
	ld [wTextLetterDelay], a
	ld [wSelectionMode], a

	ld a, %11011000
	ld [wOBP1], a

	ld bc, xSleepingProtags.end - xSleepingProtags
	ld de, $8000
	ld hl, xSleepingProtags
	call VramCopy

	ldh a, [hSystem]
	and a, a
	jr z, .noCgb
		ld bc, 128 * 16
		ld de, $9000
		ld hl, xTitleTiles
		call VramCopy

		ld bc, 128 * 16
		ld de, $8800
		call VramCopy

		ld a, 1
		ldh [rVBK], a
			lb bc, SCRN_X_B, SCRN_Y_B
			ld de, $9800
			ld hl, xTitleAttrmap
			call MapRegion
		xor a, a
		ldh [rVBK], a

		ld c, 4 * 3 * 8
		ld de, wBGPaletteBuffer
		ld hl, xTitlePalettes
		rst MemCopySmall

		ld c, 3 * 3 * 8
		ld de, wOBJPaletteBuffer
		ld hl, xProtagPalettes
		rst MemCopySmall

		lb bc, SCRN_X_B, SCRN_Y_B
		ld de, $9800
		ld hl, xTitleMap
		call MapRegion
		jr .noDmg
.noCgb
		ld bc, 128 * 16
		ld de, $9000
		ld hl, xTitleTilesDmg
		call VramCopy

		ld bc, 128 * 16
		ld de, $8800
		call VramCopy

		lb bc, SCRN_X_B, SCRN_Y_B
		ld de, $9800
		ld hl, xTitleMapDmg
		call MapRegion
.noDmg

	assert wLuvuiFrameCounter + 1 == wArisFrameCounter
	ld hl, wLuvuiFrameCounter
	inc a
	ld [hli], a
	ld [hli], a

	ld a, BANK(xLakeMusic)
	ld de, xLakeMusic
	call StartSongTrampoline

	jp FadeIn

PUSHS
SECTION "Start Song Trampoline", ROM0
StartSongTrampoline:
	call StartSong.force
	ld a, BANK(xTitleScreen)
	rst SwapBank
	ret
POPS

xTitleScreenRedraw:
	call Rand

	call xDrawParty
	ld a, [wSelectionMode]
	and a, a
	jp z, xDrawStars

	for line, 2;3
		for i, 7
			lb bc, 48 + line * 16, 52 + i * 8
			lb de, $28 + i * 2 + line * 14, 5 | OAMF_PAL1
			ld hl, sp+2
			ld a, [hli]
			ld h, [hl]
			ld l, a
			dec hl
			dec hl
			dec hl
			ld a, [hl]
			cp a, line
			jr nz, :+
				ld e, 4
			:
			call RenderSimpleSprite
		endr
	endr

	ret

xTitleScreenMove:
	ld a, [wSelectionMode]
	and a, a
	ret nz
	ld [wMenuAction], a
	ret

xDrawParty:
	def LUVUI_POSITION EQUS "97, 87"
	def ARIS_POSITION EQUS "97, 58"
	def FIRE_POSITION EQUS "91, 72"

	def LUVUI_SPEED EQU 90
	def ARIS_SPEED EQU 100

	ld a, [hFrameCounter]
	rra
	jr nc, .ignoreFrame
		ld a, [wLuvuiFrameCounter]
		inc a
		cp a, LUVUI_SPEED * 2
		jr nz, :+
		xor a, a
:
		ld [wLuvuiFrameCounter], a
		ld a, [wArisFrameCounter]
		inc a
		cp a, ARIS_SPEED * 2
		jr nz, :+
		xor a, a
:
		ld [wArisFrameCounter], a
.ignoreFrame

	lb bc, {LUVUI_POSITION}
	lb de, 0, 0
	ld a, [wLuvuiFrameCounter]
	cp a, LUVUI_SPEED
	jr c, :+
	ld d, 4
:
	call RenderSimpleSprite
	lb bc, {LUVUI_POSITION} + 8
	lb de, 2, 0
	ld a, [wLuvuiFrameCounter]
	cp a, LUVUI_SPEED
	jr c, :+
	ld d, 6
:
	call RenderSimpleSprite

	lb bc, {ARIS_POSITION}
	lb de, 8, 1
	ld a, [wArisFrameCounter]
	cp a, ARIS_SPEED
	jr nc, :+
	ld d, 12
:
	call RenderSimpleSprite
	lb bc, {ARIS_POSITION} + 8
	lb de, 10, 1
	ld a, [wArisFrameCounter]
	cp a, ARIS_SPEED
	jr nc, :+
	ld d, 14
:
	call RenderSimpleSprite

	lb bc, {FIRE_POSITION}
	ld e, 2
	ldh a, [hFrameCounter]
	rra
	rra
	and a, 3 << 2
	add a, 16
	ld d, a
	call RenderSimpleSprite
	lb bc, {FIRE_POSITION} + 8
	ld e, 2
	ldh a, [hFrameCounter]
	rra
	rra
	and a, 3 << 2
	add a, 18
	ld d, a
	jp RenderSimpleSprite

xDrawStars:
	ld hl, xStarTable
.drawStars
	ld a, [hli]
	and a, a
	jr z, .finishedStars
	dec a
	jr z, .solid
	dec a
	jr z, .dimFlicker
	dec a
	jr z, .flicker
.twinkle
	ldh a, [hFrameCounter]
	add a, [hl]
	and a, %00110000
	swap a
	add a, a
	cpl
	inc a
	add a, 38
	ld d, a
	jr .drawStar

.dimFlicker
	ldh a, [hFrameCounter]
	add a, [hl]
	and a, %00100000
	jr z, .solid
	ld d, 34
	jr .drawStar

.flicker
	ldh a, [hFrameCounter]
	add a, [hl]
	and a, %00100000
	jr z, .solid
	inc hl
	inc hl
	inc hl
	jr .drawStars

.solid
	ld d, 32
.drawStar
	inc hl
	ld e, 3
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	push hl
	call RenderSimpleSprite
	pop hl
	jr .drawStars
.finishedStars
	ret

rsset 1
def solid rb
def dim_flicker rb
def flicker rb
def twinkle rb

def random = 2834123757

macro next_random ; xorshift32
	def random ^= random << 13
	def random ^= random >> 17
	def random ^= random << 5
endm

macro star
	next_random
	db random % 4 + 1
	next_random
	db random & $FF, \1, \2
endm

xStarTable:
	star 17, 9
	star 13, 18
	star 36, 4
	star 65, 1
	star 25, 25
	star 45, 18
	star 93, 5
	star 108, 3
	star 116, 11
	star 27, 37
	star 42, 36
	star 34, 44
	star 41, 52
	star 60, 44
	star 58, 52
	star 75, 53
	star 91, 45
	star 107, 41
	star 122, 49
	star 145, 5
	star 130, 20
	star 138, 28
	star 130, 41
	db 0

section "title screen rom0", rom0
TitleScreenA:
	xor a, a
	ld [wMenuAction], a
	ld a, [wFadeSteps]
	and a, a
	ret nz

	ld a, [hCurrentBank]
	push af
	ld a, bank(xInitializeSaveFile)
	rst SwapBank

	ld a, [wSelectionMode]
	and a, a
	jr z, .enterSelectionMode
		ld hl, sp+4
		ld a, [hli]
		ld h, [hl]
		ld l, a

		inc hl
		ld a, [hl]
		and a, a
		jr z, .newGame
		dec a
		jr z, .continue
		todo

	.newGame
		call xInitializeSaveFile
	.continue
		ld a, MENU_ACTION_VALIDATE
		ld [wMenuAction], a
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a
		ld a, $10
		ld [wFadeSteps], a
		ld a, -5
		ld [wFadeDelta], a
		ld a, 1
		ld [wFadeMusic], a
		ld hl, wFadeCallback
		ld a, low(InitMap)
		ld [hli], a
		ld [hl], high(InitMap)
		ld a, %11100100
		ld [wOBP1], a
		jp BankReturn

.enterSelectionMode
	
	call xVerifySaveFile
	jr z, :+
		call xInitializeSaveFile
		ld a, MENU_ACTION_VALIDATE
		ld [wMenuAction], a
		call FadeToBlack
		ld hl, wFadeCallback
		ld a, low(InitMap)
		ld [hli], a
		ld [hl], high(InitMap)
		jp BankReturn
	:

	ld a, %11111111
	ld [wBGPaletteMask], a
	xor a, a
	ld [wOBJPaletteMask], a
	ld a, $10
	ld [wFadeSteps], a
	ld a, $80
	ld [wFadeAmount], a
	ld a, -3
	ld [wFadeDelta], a
	ld [wSelectionMode], a
	jp BankReturn

section "Title screen variables", wram0
wLuvuiFrameCounter: db
wArisFrameCounter: db
wSelectionMode: db

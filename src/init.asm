include "config.inc"
include "defines.inc"
include "entity.inc"
include "hardware.inc"

section "Header", rom0[$100]
	jp InitializeSystem
	ds $150 - @, 0

section "Initialize", rom0
; Inits system value based off `a` and `b`. Do not jump to this!
InitializeSystem:
	cp a, $11 ; The CGB boot rom sets `a` to $11
	jr nz, .dmg
	bit 0, b ; The AGB boot rom sets bit 0 of `b`
	jr z, .cgb
.agb
	ld a, SYSTEM_AGB
	jr .store
.dmg
	assert SYSTEM_DMG == 0
	xor a, a ; ld a, SYSTEM_DMG
	jr .store
.cgb
	ld a, SYSTEM_CGB
.store
	ldh [hSystem], a

	; Overclock the CGB
	and a, a
	jr z, Initialize

	; Do lotsa stuff to be very safe.
:   ldh a, [rLY]
	cp a, 144
	jr c, :-
	xor a, a
	ldh [rLCDC], a
	ldh [rIE], a
	ld a, $30
	ldh [rP1], a

	ld a, 1
	ldh [rKEY1], a
	stop
	jr Initialize.waitSkip

Initialize::
.waitVBlank
	ldh a, [rLY]
	cp a, 144
	jr c, .waitVBlank
	xor a, a
	ldh [rLCDC], a
.waitSkip

	; Reset Stack to WRAMX
	ld sp, wStack.top

	; Clear OAM.
	xor a, a
	ld bc, 160
	ld hl, wShadowOAM
	call MemSet
	ldh [hOAMIndex], a

	; zero-init vars
	ld [wMapShouldSave], a
	ld [wSTATTarget], a
	ld [wSTATTarget + 1], a
	ld [wTextVoice + 0], a
	ld [wTextVoice + 1], a
	ld [wTextCharset], a
	ld [wTextCurPixel], a
	ld [wNbMenus], a
	ld [wFadeCallback], a
	ld [wFadeCallback + 1], a
	ld [wWindowSticky], a
	ldh [hSound.frames], a
	ldh [hSongBank], a
	ldh [hMutedChannels], a
	ldh [hCurrentBank], a
	ldh [hCurrentKeys], a
	ldh [hFrameCounter], a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a
	ldh [hBGP], a
	ldh [rBGP], a
	ldh [hOBP0], a
	ldh [rOBP0], a
	ldh [hOBP1], a
	ldh [rOBP1], a
	ldh [rIF], a
	ld bc, $2000
	ld d, a
	ld hl, _VRAM
	call VramSet
	ld c, $10 * 2
	ld hl, wTextTileBuffer
	rst MemSetSmall
	ld c, 4 * 3 * 8
	ld hl, wBGPaletteBuffer
	rst MemSetSmall
	ld c, 3 * 3 * 8
	ld hl, wOBJPaletteBuffer
	rst MemSetSmall
	ld c, 256 / 8
	ld hl, wFlags
	rst MemSetSmall

	ld a, $FF
	ld [wTextSrcPtr + 1], a
	ldh [rNR51], a ; set panning

	ld a, 42
	ld [randstate], a
	ld [randstate + 1], a
	ld [randstate + 2], a
	ld [randstate + 3], a
	; Set palettes.
	; These never change for the whole course of the program.
	ld a, %11100100
	ld [wBGP], a
	ld [wOBP1], a
	ld a, %11010000
	ld [wOBP0], a

	ld a, OCPSF_AUTOINC
	ldh [rOCPS], a
	ld a, $FF
	ld b, 2 * 8
	:
		ldh [rOCPD], a
		dec c
		jr nz, :-

	; We use SRAM as scratch space, so it needs to be left unlocked.
	; Not ideal, but neither is having 16KiB of ROM0
	ld a, CART_SRAM_ENABLE
	ld [rRAMG], a

	; Copy fonts to WRAM
	ld a, bank(xCharset0)
	rst SwapBank
	ld hl, xCharset0
	ld de, sCharset0
	ld bc, xCharset0.end - xCharset0
	call MemCopy
	ld a, bank(xCharset2)
	rst SwapBank
	ld hl, xCharset2
	ld de, sCharset2
	ld bc, xCharset2.end - xCharset2
	call MemCopy

	; Initialize OAM
	call InitSprObjLib
	ld a, high(wShadowOAM)
	call hOAMDMA

	; Enable interrupts
	ld a, IEF_VBLANK | IEF_STAT
	ldh [rIE], a

	ld a, STATF_LYC
	ldh [rSTAT], a

	; Turn on the screen.
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
	ldh [hShadowLCDC], a
	ldh [rLCDC], a
	ld a, SCRN_X
	ldh [rWX], a
	ldh [hShadowWX], a
	ld a, SCRN_Y
	ldh [rWY], a
	ldh [hShadowWY], a

	ld a, GAMESTATE_MENU
	ld [wGameState], a

	ld a, bank("Save File Functions")
	rst SwapBank
	call xLoadSaveFile

	ld a, $FF
	ld [wBGPaletteMask], a
	ld [wOBJPaletteMask], a
	xor a, a
	ld [wFadeDelta], a ; Initialize this value to fade in from white

if !NO_QUICKLOAD
	call xVerifySaveFile
	jr nz, .title
	ld a, [wQuicksave.isPresent]
	and a, a
	jr z, .title
.quickload
	call QuickloadDungeon
	jr .end
endc
.title
	ld b, bank(xTitleScreen)
	ld de, xTitleScreen
	call AddMenu
.end

	ei
	jp Main

section "Stack", wram0
wStack:
	ds 32 * 2
.top

section "System type", hram
; The type of system the program is running on.
; Nonzero values indicate CGB features.
; @ 0: DMG
; @ 1: CGB
; @ 2: AGB
hSystem:: db

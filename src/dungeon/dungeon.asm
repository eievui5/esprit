include "defines.inc"
include "dungeon.inc"
include "entity.inc"
include "hardware.inc"
include "item.inc"

section "Init dungeon", rom0
QuickloadDungeon::
	; Null init
	xor a, a
	ld c, SIZEOF("dungeon BSS")
	ld hl, STARTOF("dungeon BSS")
	call MemSetSmall

	; Null out all enemies.
	ld hl, wEntity0
	ld b, NB_ENTITIES
.clearEntities
	ld [hl], a
	inc h
	dec b
	jr nz, .clearEntities

	dec a
	ld [wSkipAllyTurn], a
	ld [wSkipQuicksave], a

	ld de, randstate
	ld hl, wQuicksave.floorSeed
	ld c, 4
	call MemCopySmall

	ld a, [wQuicksave.floor]
	ld [wDungeonCurrentFloor], a

	ld de, wActiveDungeon
	ld hl, wQuicksave.dungeon
	ld c, 3
	call MemCopySmall

	ld de, wEntity0
	ld hl, wQuicksave.player
	ld c, sizeof_Entity
	call MemCopySmall

	ld de, wEntity1
	ld hl, wQuicksave.partner
	ld c, sizeof_Entity
	call MemCopySmall
	jr EnterNewFloor

; Switch to the dungeon state.
; @clobbers: bank
InitDungeon::
	; Null init
	xor a, a
	ld c, SIZEOF("dungeon BSS")
	ld hl, STARTOF("dungeon BSS")
	call MemSetSmall

	; Null out all enemies.
	ld hl, wEntity0
	ld b, NB_ENTITIES
.clearEntities
	ld [hl], a
	inc h
	dec b
	jr nz, .clearEntities

	dec a
	ld [wSkipAllyTurn], a

	ld a, 1
	ld [wDungeonCurrentFloor], a

	call LoadPlayers

	ld h, high(wEntity0)
	call RestoreEntity
	ld h, high(wEntity1)
	call RestoreEntity

EnterNewFloor::
	ld a, DUNGEON_WIDTH / 2
	ld hl, wEntity0_SpriteY
	ld [hl], 0
	inc l
	ld [hli], a
	ld [hl], 0
	inc l
	ld [hli], a
	ld [hli], a
	ld [hli], a

	ld a, DUNGEON_HEIGHT / 2
	ld hl, wEntity1_SpriteY
	ld [hl], 0
	inc l
	ld [hli], a
	ld [hl], 0
	inc l
	inc a
	ld [hli], a
	ld [hli], a
	dec a
	ld [hli], a
	ld [hl], LEFT

	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	; Deref pointer
	ld a, [hli]
	ld h, [hl]
	add a, Dungeon_Music
	ld l, a
	adc a, h
	sub a, l
	ld h, a

	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	call StartSong

	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	; Deref pointer
	ld a, [hli]
	ld h, [hl]
	add a, Dungeon_AlternateColorTerminals
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	ld [wDungeonAlternateColorTerminals], a

	xor a, a
	ld [wfmt_xEnteredFloorString_quicksave], a

	ld a, [wDungeonCurrentFloor]
	dec a
	jr z, .noQuicksave
	ld a, [wSkipQuicksave]
	and a, a
	jr nz, .noQuicksave
		ld a, 1
		ld [wfmt_xEnteredFloorString_quicksave], a
		ld hl, randstate
		ld de, wQuicksave.floorSeed
		ld c, 4
		call MemCopySmall

		ld a, [wDungeonCurrentFloor]
		ld [wQuicksave.floor], a

		ld hl, wActiveDungeon
		ld de, wQuicksave.dungeon
		ld c, 3
		call MemCopySmall

		ld hl, wEntity0
		ld de, wQuicksave.player
		ld c, sizeof_Entity
		call MemCopySmall

		ld hl, wEntity1
		ld de, wQuicksave.partner
		ld c, sizeof_Entity
		call MemCopySmall

		ld a, bank(xCommitQuicksave)
		rst SwapBank
		call xCommitQuicksave
	.noQuicksave
	xor a, a
	ld [wSkipQuicksave], a

	call DungeonGenerateFloor

	; Make sure to clear the tile to the right for the partner
	xor a, a
	ld [wDungeonMap + DUNGEON_WIDTH / 2 + 1 + DUNGEON_HEIGHT / 2 * DUNGEON_WIDTH], a

	call InitUI
	ld b, bank(xEnteredFloorString)
	ld hl, xEnteredFloorString
	call PrintHUD

	jr SwitchToDungeonState.skipUI

; Re-initializes some aspects of the dungeon, such as rendering the map.
; @clobbers: bank
SwitchToDungeonState::
	call InitUI
.skipUI
	ld a, GAMESTATE_DUNGEON
	ld [wGameState], a
	xor a, a
	ld [wIsDungeonFading], a
	ld hl, wWindowMode
	ld [hli], a
	ld [hli], a
	ld a, 1
	ld [wMapShouldSave], a

	ld h, high(wEntity0)
.loop
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	and a, a
	call nz, LoadEntityGraphics
.next
	inc h
	ld a, h
	cp a, high(wEntity0) + NB_ENTITIES
	jp nz, .loop

	; Load the active dungeon.
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	; Deref pointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
		; Deref tileset
		assert Dungeon_Tileset == 0
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ld bc, 20 * 16
		ld de, $8000 + BLANK_METATILE_ID * 16
		call VramCopy
	pop hl

	call FadeIn

	; Deref palette if on CGB
	ldh a, [hSystem]
	and a, a
	jp z, .skipCGB
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a

		assert Dungeon_Palette == 2
		inc hl
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 3 * 12
		call MemCopySmall
		pop hl

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 4 * 12
		call MemCopySmall
		pop hl

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 5 * 12
		call MemCopySmall
		pop hl

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 6 * 12
		call MemCopySmall
		pop hl

		; Load first 3 palettes
		ld c, 3 * 12
		ld de, wBGPaletteBuffer
		call MemCopySmall

		ld hl, wActiveDungeon + 1
		ld a, [hli]
		ld h, [hl]
		ld l, a
		inc hl
		inc hl
		inc hl
		inc hl
		assert Dungeon_Items == 4
		; Push each item onto the stack :)
		ld b, DUNGEON_ITEM_COUNT
	.pushItems
		ld a, [hli]
		push af
		ld a, [hli]
		ld e, a
		ld a, [hli]
		ld d, a
		push de
		dec b
		jr nz, .pushItems

	.color
		; Now pop each in order and load their palettes and graphics
		ld b, DUNGEON_ITEM_COUNT
		ld de, wBGPaletteBuffer + 6 * 12 + 3
	.copyItemColor
		pop hl
		pop af
		rst SwapBank
		assert Item_Palette == 0
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ld c, 9
		call MemCopySmall
		ld a, e
		sub a, 21
		ld e, a
		ld a, d
		sbc a, 0
		ld d, a
		dec b
		jr nz, .copyItemColor
.skipCGB
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	inc hl
	inc hl
	inc hl
	assert Dungeon_Items == 4
	; Push each item onto the stack :)
	ld b, DUNGEON_ITEM_COUNT
.pushItems2
	ld a, [hli]
	push af
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push de
	dec b
	jr nz, .pushItems2

.items
	; And finally, copy the graphics
	ld b, DUNGEON_ITEM_COUNT
	ld de, $8000 + (ITEM_METATILE_ID + 3 * 4) * 16
.copyItemGfx
	pop hl
	pop af
	rst SwapBank
	inc hl
	inc hl
	assert Item_Graphics == 2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld c, 16 * 4
	call VramCopySmall
	ld a, e
	sub a, 128
	ld e, a
	ld a, d
	sbc a, 0
	ld d, a
	dec b
	jr nz, .copyItemGfx

	; Initialize previous health
	call SetPreviousHudStats
	call DrawAttackWindow

	ld a, bank(xFocusCamera)
	rst SwapBank
	call xFocusCamera
	ld hl, wDungeonLerpCameraX
	ld de, wDungeonCameraX
	ld c, 4
	rst MemCopySmall
	ld a, [wDungeonCameraX + 1]
	ld [wLastDungeonCameraX], a
	ld a, [wDungeonCameraY + 1]
	ld [wLastDungeonCameraY], a
	ld a, bank(xUpdateScroll)
	rst SwapBank
	call xUpdateScroll
	ld a, bank(xDrawDungeon)
	rst SwapBank
	jp xDrawDungeon

section "Dungeon State", rom0
DungeonState::
	; If fading out, do nothing but animate entities and wait for the fade to
	; complete.
	ld a, [wIsDungeonFading]
	and a, a
	jr z, .notFading
	ld a, [wFadeSteps]
	and a, a
	jr nz, .dungeonRendering
		ld hl, wDungeonFadeCallback
		ld a, [hli]
		ld h, [hl]
		ld l, a
		jp hl
.notFading
	ld hl, wEntityAnimation.pointer
	ld a, [hli]
	or a, [hl]
	jr nz, .playAnimation
		bankcall xMoveEntities
		call ProcessEntities
		; Scroll the map after moving entities.
.dungeonRendering
		bankcall xHandleMapScroll
		ld a, bank(xFocusCamera)
		rst SwapBank
		call xFocusCamera
		assert bank(xFocusCamera) == bank(xLerpCamera)
		call xLerpCamera
		call xLerpCamera
		call xLerpCamera
		bankcall xUpdateScroll
		jr :+
.playAnimation
		bankcall xUpdateAnimation
:

	; Render entities after scrolling.
	bankcall xRenderEntities
	call UpdateEntityGraphics

	ld a, [wPrintString]
	and a, a
	call nz, DrawPrintString

	ld a, [wForceHudUpdate]
	and a, a
	jr nz, .updateStatus

	; Make sure health is not displayed as negative
	ld hl, wEntity0_Health + 1
	bit 7, [hl]
	jr z, :+
		xor a, a
		ld [hld], a
		ld [hli], a
	:
	inc h
	bit 7, [hl]
	jr z, :+
		xor a, a
		ld [hld], a
		ld [hli], a
	:

	ld hl, wPreviousStats
	ld de, wEntity0_Health
	ld a, [de]
	inc e
	cp a, [hl]
	jr nz, .updateStatus
	inc hl
	ld a, [de]
	cp a, [hl]
	jr nz, .updateStatus
	inc hl
	ld e, low(wEntity0_Fatigue)
	ld a, [de]
	cp a, TIRED_THRESHOLD
	ld a, 0
	jr nc, :+
	inc a
:
	cp a, [hl]
	jr nz, .updateStatus
	inc hl
:
	ld de, wEntity1_Bank
	ld a, [de]
	and a, a
	jr z, .skipUpdateStatus
	ld e, low(wEntity0_Health)
	ld a, [de]
	inc e
	cp a, [hl]
	jr nz, .updateStatus
	inc hl
	ld a, [de]
	cp a, [hl]
	jr nz, .updateStatus
	inc hl
	ld e, low(wEntity0_Fatigue)
	ld a, [de]
	cp a, TIRED_THRESHOLD
	ld a, 0
	jr nc, :+
	inc a
:
	cp a, [hl]
	jr z, .skipUpdateStatus
.updateStatus
	xor a, a
	ld [wForceHudUpdate], a
	call DrawStatusBar
	call SetPreviousHudStats
.skipUpdateStatus

	; Run the dungeon's tick function (if any)
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, Dungeon_TickFunction
	ld l, a
	adc a, h
	sub a, l
	ld h, a

	ld a, [hli]
	ld h, [hl]
	ld l, a

	rst CallHL

	; Wait after a level up for the next check.
	ld a, [wLevelUpMessageLifetime]
	and a, a
	jr z, .checkForLevelUp
	dec a
	ld [wLevelUpMessageLifetime], a
	jr .skipLevelUp

.checkForLevelUp
	; Iterate through each party member to check if their XP has changed.
	ld de, wPartyLastXp
	ld h, high(wEntity0)
.levelUpLoop
	ld l, low(wEntity0_Bank)
	ld a, [hl]
	and a, a
	jr z, .levelUpNext
	ld l, low(wEntity0_Experience)
	ld a, [de]
	cp a, [hl]
	jr nz, .callCheck
	inc de
	inc l
	ld a, [de]
	dec de
	cp a, [hl]
	jr z, .levelUpNext
.callCheck
	; If XP has changed, check if we can level up
	ld a, bank(xCheckForLevelUp)
	rst SwapBank
	push hl
		push de
			call xCheckForLevelUp
		pop de
	pop hl
	ld a, c
	and a, a
	jr z, .levelUpNext
	; If we leveled up, delay the next check
	ld a, 255
	ld [wLevelUpMessageLifetime], a
	ld hl, wPreviousStats
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	jr .skipLevelUp

.levelUpNext
	inc de
	inc de
	inc h
	ld a, h
	cp a, high(wEntity0) + NB_ALLIES
	jr nz, .levelUpLoop
.skipLevelUp
	ld a, bank(xUpdateAttackWindow)
	rst SwapBank
	jp xUpdateAttackWindow

OpenPauseMenu::
	ld b, bank(xPauseMenu)
	ld de, xPauseMenu
	call AddMenu
	ld a, GAMESTATE_MENU
	ld [wGameState], a
	xor a, a
	di
	ld [wSTATTarget], a
	ld [wSTATTarget + 1], a
	reti

section "Set previous hud stats", rom0
SetPreviousHudStats:
	ld hl, wPreviousStats
	ld de, wEntity0_Bank
	ld a, [de]
	and a, a
	jr z, :+
	ld e, low(wEntity0_Health)
	ld a, [de]
	inc e
	ld [hli], a
	ld a, [de]
	ld [hli], a
	ld e, low(wEntity0_Fatigue)
	ld a, [de]
	cp a, TIRED_THRESHOLD
	ld a, 0
	jr nc, :+
	inc a
:
	ld [hli], a
:
	ld de, wEntity1_Bank
	ld a, [de]
	and a, a
	ret z
	ld e, low(wEntity0_Health)
	ld a, [de]
	inc e
	ld [hli], a
	ld a, [de]
	ld [hli], a
	ld e, low(wEntity0_Fatigue)
	ld a, [de]
	cp a, TIRED_THRESHOLD
	ld a, 0
	jr nc, :+
	inc a
:
	ld [hli], a
	ret

section "Floor complete", rom0
FloorComplete::
	ld b, high(wEntity0)
	ld e, 80
	call RestoreEntityFatigue
	inc b
	call RestoreEntityFatigue

	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, Dungeon_FloorCount
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	ld hl, wDungeonCurrentFloor
	inc [hl]
	cp a, [hl]
	jp z, DungeonComplete
.nextFloor
	ld a, 1
	ld [wIsDungeonFading], a
	ld a, low(EnterNewFloor)
	ld [wDungeonFadeCallback], a
	ld a, high(EnterNewFloor)
	ld [wDungeonFadeCallback + 1], a
	; Set palettes
	ld a, %11111111
	ld [wBGPaletteMask], a
	ld a, %11111111
	ld [wOBJPaletteMask], a
	jp FadeToWhite

section "Dungeon complete!", rom0
DungeonComplete::
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, Dungeon_CompletionType
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	assert DUNGEON_COMPLETION_EXIT == 0
	and a, a
	jr z, .exit
	assert DUNGEON_COMPLETION_SWITCH == 1
	dec a
	jr z, .switch
	assert DUNGEON_COMPLETION_SCENE == 2
.scene
	; Scenes can do a few things, including switching the dungeon pointer or exiting the dungeon.
	; SWITCH and EXIT are just shortcuts for common operations.
	assert Dungeon_CompletionType + 1 == Dungeon_NextScenePointer
	inc hl
	ld a, [hli]
	ld [wActiveScene], a
	ld a, [hli]
	ld [wActiveScene + 1], a
	ld a, [hli]
	ld [wActiveScene + 2], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, low(InitScene)
	ld [hli], a
	ld [hl], high(InitScene)
	ret

.switch
	assert Dungeon_CompletionType + 1 == Dungeon_NextDungeonPointer
	inc hl
	ld a, [hli]
	ld [wActiveDungeon], a
	ld a, [hli]
	ld [wActiveDungeon + 1], a
	ld a, [hli]
	ld [wActiveDungeon + 2], a
	jp FloorComplete.nextFloor

.exit
	assert Dungeon_CompletionType + 1 == Dungeon_CompletionFlag
	inc hl
	ld c, [hl]
	call GetFlag
	or a, [hl]
	ld [hl], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, low(InitMap)
	ld [hli], a
	ld [hl], high(InitMap)
	ret

section "Get Item", rom0
; Get a dungeon item given an index in b
; @param b: Item ID
; @return b: Item bank
; @return hl: Item pointer
; @clobbers bank
GetDungeonItem::
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	assert Dungeon_Items == 4
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, b
	add a, b
	add a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

section "Focus Camera", romx
xFocusCamera:
	ld a, [wFocusedEntity]
	add a, high(wEntity0)
	ld b, a
	ld c, low(wEntity0_SpriteY)
	ld a, [bc]
	inc c
	ld l, a
	ld a, [bc]
	inc c
	ld h, a
	ld de, (SCRN_Y - 34) / -2 << 4
	add hl, de
	bit 7, h
	jr z, :+
		xor a, a
		ld [wDungeonLerpCameraY], a
		ld [wDungeonLerpCameraY + 1], a
		jr .doneY
:
	ld a, h
	cp a, 64 - 9
	jr c, :+
		ld a, -1
		ld [wDungeonLerpCameraY], a
		ld a, 64 - 10
		ld [wDungeonLerpCameraY + 1], a
		jr .doneY
:
	ld a, l
	ld [wDungeonLerpCameraY], a
	ld a, h
	ld [wDungeonLerpCameraY + 1], a
.doneY
	ld a, [bc]
	inc c
	ld l, a
	ld a, [bc]
	inc c
	ld h, a
	ld de, (SCRN_X - 24) / -2 << 4
	add hl, de
	bit 7, h
	jr z, :+
		xor a, a
		ld [wDungeonLerpCameraX], a
		ld [wDungeonLerpCameraX + 1], a
		ret
:
	ld a, h
	cp a, 64 - 10
	jr c, :+
		ld a, -1
		ld [wDungeonLerpCameraX], a
		ld a, 64 - 11
		ld [wDungeonLerpCameraX + 1], a
		ret
:
	ld a, l
	ld [wDungeonLerpCameraX], a
	ld a, h
	ld [wDungeonLerpCameraX + 1], a
	ret

xLerpCamera:
	ld a, [wDungeonLerpCameraX + 1]
	ld b, a
	ld a, [wDungeonCameraX + 1]
	cp a, b
	jr c, .higherX
	jr z, :+
	jr nc, .lowerX
:
	ld a, [wDungeonLerpCameraX]
	and a, $F0
	ld b, a
	ld a, [wDungeonCameraX]
	and a, $F0
	cp a, b
	jr c, .higherX
	jr z, .noXMovement
.lowerX
	ld bc, -1.0
	jr .writeX
.higherX
	ld bc, 1.0
.writeX
	ld hl, wDungeonCameraX
	ld a, [hli]
	ld h, [hl]
	ld l, a

	add hl, bc
	ld a, l
	ld [wDungeonCameraX], a
	ld a, h
	ld [wDungeonCameraX + 1], a
.noXMovement

	ld a, [wDungeonLerpCameraY + 1]
	ld b, a
	ld a, [wDungeonCameraY + 1]
	cp a, b
	jr c, .higherY
	jr z, :+
	jr nc, .lowerY
:
	ld a, [wDungeonLerpCameraY]
	and a, $F0
	ld b, a
	ld a, [wDungeonCameraY]
	and a, $F0
	cp a, b
	jr c, .higherY
	ret z
.lowerY
	ld bc, -1.0
	jr .writeY
.higherY
	ld bc, 1.0
.writeY
	ld hl, wDungeonCameraY
	ld a, [hli]
	ld h, [hl]
	ld l, a

	add hl, bc
	ld a, l
	ld [wDungeonCameraY], a
	ld a, h
	ld [wDungeonCameraY + 1], a
	ret

section "Generate Floor", rom0
; Generate a new floor
; @clobbers bank
DungeonGenerateFloor::
	ld a, TILE_WALL
	ld bc, DUNGEON_WIDTH * DUNGEON_HEIGHT
	ld hl, wDungeonMap
	call MemSet
	ld hl, wEntity{d:NB_ALLIES}
	xor a, a
	ld b, NB_ENEMIES
.clearEnemies
	ld [hl], a
	inc h
	dec b
	jr nz, .clearEnemies

	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	add a, Dungeon_GenerationType
	ld h, [hl]
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	ld b, a
	add a, b
	add a, b
	add a, low(.jumpTable)
	ld l, a
	adc a, high(.jumpTable)
	sub a, l
	ld h, a
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wMainScript_Pool
	call ExecuteScript
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, Dungeon_ItemsPerFloor
	add hl, bc
	ld b, [hl]

.generateItem
	ld a, bank(xGenerateItems)
	rst SwapBank
	ld hl, xGenerateItems
	push bc
		call ExecuteScript
	pop bc
	dec b
	jr nz, .generateItem
	ld a, NB_ENEMIES
.spawnEnemies
	push af
	call SpawnEnemy
	pop af
	dec a
	jr nz, .spawnEnemies
	ret

.jumpTable
	assert DUNGEON_TYPE_SCRAPER == 0
	farptr xGenerateScraper
	assert DUNGEON_TYPE_HALLS == 1
	farptr xGenerateHalls
	assert DUNGEON_TYPE_LATTICE == 2
	farptr xGenerateLattice
	assert DUNGEON_TYPE_GROTTO == 3
	farptr xGenerateGrotto
	assert DUNGEON_TYPE_HALLS_OR_CLEARING == 4
	farptr xGenerateHallsOrClearing
	assert DUNGEON_TYPE_BRIDGE == 5
	farptr xGenerateBridge
	assert DUNGEON_TYPE_DEBUG == 6
	farptr xGenerateDebug

section "MapCheck3x3IsEmpty", rom0
; @param d: X
; @param e: Y
; @return hl: map pointer
; @preserves de
GetTileXY::
	ld a, e
	assert DUNGEON_WIDTH == 64
	add a, a ; y * 2
	add a, a ; y * 4
	; Now we have to switch to 16-bit; 64 * 4 == 256
	ld l, a
	ld h, 0
	add hl, hl ; y * 8
	add hl, hl ; y * 16
	add hl, hl ; y * 32
	add hl, hl ; y * 64
	ld a, d
	add a, l
	ld l, a
	adc a, h
	sub a, l
	assert low(wDungeonMap) == 0
	add a, high(wDungeonMap)
	ld h, a
	ret

GetEmptyTile::
	call Rand
	and a, 63
	ld d, a
	ld a, e
	and a, 63
	ld e, a
	call GetTileXY
	ld a, [hl]
	ASSERT TILE_CLEAR == 0
	and a, a
	jr nz, GetEmptyTile
	ret

; All tiles in a map are guaranteed to be connected, meaning there is ALWAYS a valid adjacent tile.
; @param d: X
; @param e: Y
; @return de: adjusted
; @return hl: pointer to adjusted de
; @clobbers: hl
MapGetAdjacentClearing::
	call GetTileXY
	; first check right
	inc hl
	inc d
	ld a, [hl]
	cp a, TILE_WALL
	ret nz
	; adjust coords
	dec d
	dec d
	; adjust pointer
	dec hl
	dec hl
	ld a, [hl]
	cp a, TILE_WALL
	ret nz
	; adjust coords
	inc d
	dec e
	; adjust pointer
	ld a, l
	sub a, DUNGEON_WIDTH - 1
	ld l, a
	ld a, h
	sbc a, 0
	ld h, a
	; check
	ld a, [hl]
	cp a, TILE_WALL
	ret nz
	; adjust pointer
	ld a, DUNGEON_WIDTH * 2
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	; adjust coords
	inc e
	inc e
	ret

; Check if a 3x3 area is made up of floor tiles, starting from the top-left.
; @param bc: top-left of 3x3 area
; @return nz == fail
MapCheck3x3IsEmpty::
	; Start from the top left
	call .checkRow
	ret nz
	call .checkRow
	ret nz
	; fallthrough
; Check three tiles from left to right
; adds 2 to BC
.checkRow
	ld a, [bc]
	and a, a
	ret nz
	inc bc
	ld a, [bc]
	and a, a
	ret nz
	inc bc
	ld a, [bc]
	and a, a
	ret nz
	ld a, c
	add a, DUNGEON_WIDTH - 2
	ld c, a
	adc a, b
	sub a, c
	ld b, a
	xor a, a
	ret

section "Update Scroll", romx
xUpdateScroll:
	ld a, [wDungeonCameraX + 1]
	ld b, a
	ld a, [wDungeonCameraX]
	rept 4
		srl b
		rra
	endr
	ldh [hShadowSCX], a
	ld a, [wDungeonCameraY + 1]
	ld b, a
	ld a, [wDungeonCameraY]
	rept 4
		srl b
		rra
	endr
	ldh [hShadowSCY], a
	ret

; Variables which must be accessible from all states.
section "dungeon globals", wram0
; A far pointer to the current dungeon. Bank, Low, High.
wActiveDungeon:: ds 3
wDungeonCurrentFloor:: db

section UNION "State variables", wram0, ALIGN[8]
; This map uses 4096 bytes of WRAM, but is only ever used in dungeons.
; If more RAM is needed for other game states, it should be unionized with this
; map.
wDungeonMap:: ds DUNGEON_WIDTH * DUNGEON_HEIGHT
wDungeonCameraX:: dw
wDungeonCameraY:: dw
; These are the actual locations that appear on screen
wDungeonLerpCameraX:: dw
wDungeonLerpCameraY:: dw
; Only the high byte needs to be saved.
wLastDungeonCameraX:: db
wLastDungeonCameraY:: db
wIsDungeonFading:: db

wMapgenLoopCounter: db

wDungeonFadeCallback:: dw

wPreviousStats::
.player ds 3 ; Health and fatigue
.partner ds 3

; TODO: rather than skipping a turn, this should just disable movement.
; If the player tries to move, tell them why they can't.
wSkipAllyTurn:: db

section FRAGMENT "dungeon BSS", wram0
wPartyLastXp: ds 6
; Ticks remaining to show levelup menu.
wLevelUpMessageLifetime: db
wTurnCounter:: db
wSkipQuicksave:: db

include "defines.inc"
include "entity.inc"
include "hardware.inc"
include "structs.inc"

	struct MapNode
		bytes 4, Up
		bytes 4, Right
		bytes 4, Down
		bytes 4, Left
		bytes 4, Press
		bytes 1, X
		bytes 1, Y
		alias Name
	end_struct

rsreset
def MAP_NODE_NONE rb     ; No action; the default
def MAP_NODE_MOVE rb     ; Move to another node
def MAP_NODE_LOCK rb     ; Move to another node if FLAG is set
def MAP_NODE_DUNGEON rb  ; Enter a dungeon
def MAP_NODE_SCENE rb    ; Enter a town
def MAP_NODE_TRADER rb   ; Begin a trade
def MAP_NODE_AUTOMOVE rb ; Automatically progress to the next node; do not draw name.

macro _node_dir
	redef _NODE_\1_TYPE     equ MAP_NODE_NONE
	redef _NODE_\1_ARG0     equs "0"
	redef _NODE_\1_ARG1     equs "0"
	redef _NODE_\1_ARG2     equs "0"
endm

macro node
	redef _NODE_IDENTIFIER equs "\1"
	redef _NODE_X equ \3
	redef _NODE_Y equ \4
	redef _NODE_NAME equs \2
	_node_dir UP
	_node_dir RIGHT
	_node_dir DOWN
	_node_dir LEFT
	_node_dir PRESS
endm

macro _node_entry
	redef _NODE_\1_TYPE equ MAP_NODE_\2
	; For MOVE, the bank is redundant.
	; Because of this it is repurposed for LOCK to be a flag ID.
	if !strcmp("LOCK", "\2")
		redef _NODE_\1_ARG0 equs "FLAG_\4"
	else
		redef _NODE_\1_ARG0 equs "bank(\3)"
	endc
	redef _NODE_\1_ARG1 equs "low(\3)"
	redef _NODE_\1_ARG2 equs "high(\3)"
endm

def up    equs "_node_entry UP, "
def right equs "_node_entry RIGHT, "
def down  equs "_node_entry DOWN, "
def left  equs "_node_entry LEFT, "
def press equs "_node_entry PRESS, "

macro _node_define
	db _NODE_\1_TYPE, _NODE_\1_ARG0, _NODE_\1_ARG1, _NODE_\1_ARG2
endm

macro end_node
	{_NODE_IDENTIFIER}::
		_node_define UP
		_node_define RIGHT
		_node_define DOWN
		_node_define LEFT
		_node_define PRESS
		db _NODE_X, _NODE_Y, "{_NODE_NAME}", 0
endm

def NB_DROPLETS equ 16
def NB_EFFECTS equ NB_DROPLETS + 3

section "World map nodes", romx
	node xVillageNode, "The village", 48, 88
		left MOVE, xForestNode
		press TRADER, xFoodTrader
	end_node

	node xForestNode, "Circum Thicket", 12, 88
		right MOVE, xVillageNode
		up LOCK, xFieldsNode, FOREST_COMPLETE
		press DUNGEON, xForestDungeon
	end_node

	node xFieldsNode, "Circum Outskirts", 12, 32
		press DUNGEON, xFieldDungeon
		down MOVE, xForestNode
		up LOCK, xRemoteHouse, FIELDS_COMPLETE
		right LOCK, xLakeNode, FIELDS_COMPLETE
	end_node

	node xRemoteHouse, "Remote house", 12, 16
		down MOVE, xFieldsNode
	end_node

	node xLakeNode, "Crystal Lake", 45, 32
		press SCENE, xLakeScene1
		left MOVE, xFieldsNode
		right LOCK, xTurn0, LAKE_COMPLETE
	end_node

	node xTurn0, "", 69, 32
		press AUTOMOVE, null
		down MOVE, xTurn1
		left MOVE, xLakeNode
	end_node

	node xTurn1, "", 69, 56
		press AUTOMOVE, null
		right MOVE, xPlainsNode
		up MOVE, xTurn0
	end_node

	node xPlainsNode, "Blazing Plains", 101, 56
		press DUNGEON, xPlainsDungeon
		left MOVE, xTurn1
		up LOCK, xTurn2, PLAINS_COMPLETE
		down LOCK, xCrystalwoodNode, CAVES_COMPLETE
	end_node

	node xTurn2, "", 101, 24
		press AUTOMOVE, null
		down MOVE, xPlainsNode
		left MOVE, xTurn3
	end_node

	node xTurn3, "", 85, 24
		press AUTOMOVE, null
		right MOVE, xTurn2
		up MOVE, xTurn4
	end_node

	node xTurn4, "", 85, 8
		press AUTOMOVE, null
		down MOVE, xTurn3
		right MOVE, xCavesNode
	end_node

	node xCavesNode, "Sursum Caverns", 101, 8
		press DUNGEON, xCavesDungeon
		left MOVE, xTurn4
	end_node

	node xCrystalwoodNode, "Crystalwood", 101, 80
		press DUNGEON, xCrystalwoodDungeon
		up MOVE, xPlainsNode
	end_node

section "World Map", romx
xWorldMap:
.tiles incbin "res/worldmap/crater.2bpp"
.map incbin "res/worldmap/crater.map"
.colors incbin "res/worldmap/crater.pal8"
.colormap incbin "res/worldmap/crater.pmap"
.dmgtiles incbin "res/worldmap/crater-dmg.2bpp"
.dmgmap incbin "res/worldmap/crater-dmg.map"
.hoof incbin "res/worldmap/hoofprint.2bpp"
.objTiles
	incbin "res/worldmap/floppy.obj.2bpp"
	incbin "res/worldmap/haze1.2bpp"
	incbin "res/worldmap/haze2.2bpp"
	incbin "res/worldmap/duck.2bpp"
	ds 16, 0
	incbin "res/worldmap/droplet.2bpp"
	ds 16, 0
.objColors
	incbin "res/worldmap/droplet.pal8", 3
	incbin "res/worldmap/duck.pal8", 3
	incbin "res/worldmap/hoofprint.pal8", 3
	incbin "res/worldmap/haze1.pal8", 3
	incbin "res/worldmap/floppy.obj.pal8", 3

section "Map State Init", rom0
InitMap::
	ldh a, [hCurrentBank]
	push af

	ld a, [wMapShouldSave]
	and a, a
	jr z, :+
		for i, 2
			ld d, high(wEntity{d:i})
			ld e, low(wEntity0_Bank)
			if !i
				ld hl, wPlayerData
			endc
			ld a, [de]
			ld [hli], a
			inc e
			ld a, [de]
			ld [hli], a
			inc e
			ld a, [de]
			ld [hli], a
			inc e
			ld e, low(wEntity0_Level)
			ld a, [de]
			ld [hli], a
			ld e, low(wEntity0_Experience)
			ld a, [de]
			ld [hli], a
			inc e
			ld a, [de]
			ld [hli], a
			ld e, low(wEntity0_CanRevive)
			ld a, [de]
			ld [hli], a
		endr
	:

	; Null out all enemies.
	xor a, a
	ld hl, wEntity0
	ld b, NB_ENTITIES
.clearEntities
	ld [hl], a
	inc h
	dec b
	jr nz, .clearEntities

	; This isn't redundant, it reorders the party if they've been switched
	call LoadPlayers
	ld h, high(wEntity0)
	call LoadEntityGraphics

	xor a, a
	ld [wMapLockInput], a

	ld a, bank(xWorldMap)
	rst SwapBank

	ldh a, [hSystem]
	and a, a
	jr z, .dmg
.cgb
	ld de, wBGPaletteBuffer
	ld hl, xWorldMap.colors
	ld c, 7 * 3 * 4
	call MemCopySmall

	ld de, wOBJPaletteBuffer + 3 * 3
	ld hl, xWorldMap.objColors
	ld c, 7 * 3 * 3
	call MemCopySmall

	ld a, 1
	ldh [rVBK], a
	lb bc, SCRN_X_B, SCRN_Y_B
	ld de, $9800
	ld hl, xWorldMap.colormap
	call MapRegion
	xor a, a
	ldh [rVBK], a

	ld hl, xWorldMap.tiles
	ld de, $8800
	ld bc, xWorldMap.map - xWorldMap.tiles
	call VramCopy

	lb bc, SCRN_X_B, SCRN_Y_B
	ld de, $9800
	ld hl, xWorldMap.map
	call MapRegion
	jr .noDmg

.dmg
	ld hl, xWorldMap.dmgtiles
	ld de, $8800
	ld bc, xWorldMap.map - xWorldMap.tiles
	call VramCopy

	lb bc, SCRN_X_B, SCRN_Y_B
	ld de, $9800
	ld hl, xWorldMap.dmgmap
	call MapRegion

.noDmg

	ld hl, xWorldMap.objTiles
	ld de, $8800 - (xWorldMap.objColors - xWorldMap.objTiles)
	ld bc, xWorldMap.objColors - xWorldMap.objTiles
	call VramCopy

	def HOOFTILE equ $7F
	ld hl, xWorldMap.hoof
	ld de, $9800 - 16
	ld c, 16
	call VramCopySmall

	ld b, NB_DROPLETS
	ld hl, wEffects
.initDroplets
	ld a, bank(xDropletEffect)
	ld [hli], a
	ld a, low(xDropletEffect)
	ld [hli], a
	ld a, high(xDropletEffect)
	ld [hli], a
	ld a, l
	add a, evscript_script_pool_size
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	dec b
	jr nz, .initDroplets

	ld hl, wEffects + (3 + evscript_script_pool_size) * NB_DROPLETS
	ld a, bank(xDuckEffect)
	ld [hli], a
	ld a, low(xDuckEffect)
	ld [hli], a
	ld a, high(xDuckEffect)
	ld [hli], a

	ld hl, wEffects + (3 + evscript_script_pool_size) * (NB_DROPLETS + 1)
	ld a, bank(xHazeEffect)
	ld [hli], a
	ld a, low(xHazeEffect)
	ld [hli], a
	ld a, high(xHazeEffect)
	ld [hli], a

	ld a, bank(xCommitSaveFile)
	rst SwapBank

	ld a, [wMapShouldSave]
	and a, a
	jr nz, :+
		xor a, a
		ld hl, wEffects + (3 + evscript_script_pool_size) * (NB_DROPLETS + 2)
		ld [hli], a
		ld [hli], a
		ld [hli], a
		jr .noSave
	:
		call xCommitSaveFile
		ld hl, wEffects + (3 + evscript_script_pool_size) * (NB_DROPLETS + 2)
		ld a, bank(xFloppyEffect)
		ld [hli], a
		ld a, low(xFloppyEffect)
		ld [hli], a
		ld a, high(xFloppyEffect)
		ld [hli], a
	.noSave

	call InitUI

	ld hl, wActiveMapNode
	ld de, wEntity0_SpriteY
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, MapNode_Y
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	xor a, a
	ld b, a ; clear flags and set b
	ld a, [hld]
	rept 4
		rla
		rl b
	endr
	ld [de], a
	inc e
	ld a, b
	ld [de], a
	inc e
	assert Entity_SpriteY + 2 == Entity_SpriteX
	assert MapNode_Y - 1 == MapNode_X
	xor a, a
	ld b, a ; clear flags and set b
	ld a, [hli]
	rept 4
		rla
		rl b
	endr
	ld [de], a
	inc e
	ld a, b
	ld [de], a
	inc l
	assert MapNode_Y + 1 == MapNode_Name
	ldh a, [hCurrentBank]
	ld b, a
	call PrintHUD
	call DrawPrintString

	ld a, bank(xMapMusic)
	ld de, xMapMusic
	call StartSong

	ld c, FLAG_CAVES_COMPLETE
	call GetFlag
	and a, [hl]
	jr z, .noPrints
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	ld a, HOOFTILE
	ld [$9800 + 13 + 9 * 32], a
	ld [$9800 + 13 + 10 * 32], a
	ld [$9800 + 13 + 11 * 32], a
.noPrints
	call FadeIn

	ld hl, wSTATTarget
	ld a, low(ShowOnlyTextBox)
	di
	ld [hli], a
	ld a, high(ShowOnlyTextBox)
	ld [hli], a
	ei
	xor a, a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a
	ld [wMapShouldSave], a

	ld a, GAMESTATE_MAP
	ld [wGameState], a
	jp BankReturn

section "Map State", rom0
MapState::
	; The player and partner entities are always accessible, as entities are not
	; within the state union. This means the entity struct and entity renderer
	; can be reused for the map and town states.
	call UpdateEntityGraphics

	ld a, bank(xRenderEntity)
	rst SwapBank
	ld h, high(wEntity0)
	call xRenderEntity

	ld de, wEffects
	ld a, NB_EFFECTS
.runEffects
	push af
	ld a, [de]
	inc de
	rst SwapBank
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a
	call ExecuteScript
	dec de
	ld a, h
	ld [de], a
	dec de
	ld a, l
	ld [de], a
	ld a, e
	add a, 2 + evscript_script_pool_size
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	pop af
	dec a
	jr nz, .runEffects

	call MapMovement
	call c, UpdateMapNode

	ret

section "Map Movement", rom0
; @return carry: Set if not moving
MapMovement:
	for Y, 2
		if Y
			.yCheck
		endc
		; Compare the active map node's position to the player's.
		ld hl, wActiveMapNode
		ld a, [hli]
		rst SwapBank
		ld a, [hli]
		ld h, [hl]
		add a, MapNode_X + Y
		ld l, a
		adc a, h
		sub a, l
		ld h, a
		ld a, [hli]
		ld b, a
		ld de, wEntity0_SpriteX - Y * 2
		ld a, [de]
		ld c, a
		inc e
		ld a, [de]
		rept 4
			rra
			rr c
		endr
		ld a, c
		cp a, b
		if Y
			; If Y matches, set the player to face foward and stand still.
			jr z, .noMovement
		else
			; If X matches, check Y
			jr z, .yCheck
		endc
	:
		ld a, c
		cp a, b
		; If they do not match, animate the player. This does NOT clobber flags!
		ld a, ENTITY_FRAME_STEP
		ld [wEntity0_Frame], a
		; If the target is greater, move right.
		ld a, (RIGHT + Y) & 3
		jr c, :+
		; Otherwise move left.
		ld a, (LEFT + Y) & 3
	:
		ld [wEntity0_Direction], a
		if Y
			cp a, DOWN
		else
			assert RIGHT == 1
			dec a ; cp a, RIGHT
		endc
		ld de, wEntity0_SpriteX - Y * 2 + 1
		ld a, [de]
		ld h, a
		dec de ; 16-bit to preserve Z
		ld a, [de]
		ld l, a
		ld bc, 16
		jr z, :+
		ld bc, -16
	:
		add hl, bc
		ld a, l
		ld [de], a
		inc e
		ld a, h
		ld [de], a
		xor a, a
		ret
	endr
.noMovement
	ld a, DOWN
	ld [wEntity0_Direction], a
	ld a, ENTITY_FRAME_IDLE
	ld [wEntity0_Frame], a
	scf
	ret

section "Update Map Node", rom0
UpdateMapNode:
	ld hl, wActiveMapNode
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, MapNode_Press
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	cp a, MAP_NODE_AUTOMOVE
	jr nz, .noAutomove

	; Find the first direction containing MOVE that is not equal to the current direction.
	ld a, [wEntity0_LastDirection]
	ld b, a
	assert MapNode_Press - 4 == MapNode_Left
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, RIGHT
	cp a, b
	jp nz, MapNodeMove
:
	assert MapNode_Left - 4 == MapNode_Down
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, UP
	cp a, b
	jp nz, MapNodeMove
:
	assert MapNode_Down - 4 == MapNode_Right
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, LEFT
	cp a, b
	jp nz, MapNodeMove
:
	assert MapNode_Right - 4 == MapNode_Up
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, DOWN
	cp a, b
	jp nz, MapNodeMove
:

.noAutomove

	ld a, [wPrintString]
	and a, a
	call nz, DrawPrintString

	ld a, [wMapLockInput]
	and a, a
	ret nz

	ld hl, wActiveMapNode
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hCurrentKeys]
	and a, PADF_A | PADF_UP | PADF_RIGHT | PADF_DOWN | PADF_LEFT
	ret z ; If no keys are pressed, no action is neccessary!
	call PadToDir
	; If PadToDir fails, that means A is the only key which is pressed.
	; A corresponds to an index of 4
	jr nc, .notA
	; However, we need to make sure that A was just pressed, not held down.
	ldh a, [hNewKeys]
	bit PADB_A, a
	ret z
	; Otherwise, select the map node.
	ld a, 4
.notA
	; Preserve the direction in B, so that it may be referenced by the target
	ld b, a
	add a, a ; a * 2
	add a, a ; a * 4
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	; Now we have a pointer to one of the five map node actions.
	; An action is followed by 3 bytes, generally a far pointer to a level,
	; town, or another map node.
	ld a, [hli]
	; Of course, a value of zero means no action should be taken.
	assert MAP_NODE_NONE == 0
	and a, a
	ret z
	assert MAP_NODE_MOVE == 1
	dec a
	jr z, MapNodeMove
	assert MAP_NODE_LOCK == 2
	dec a
	jr z, MapNodeLock
	assert MAP_NODE_DUNGEON == 3
	dec a
	jr z, MapNodeDungeon
	assert MAP_NODE_SCENE == 4
	dec a
	jr z, MapNodeScene
	assert MAP_NODE_TRADER == 5
	jr MapNodeTrader

MapNodeMove:
	inc hl
.noInc
	ld a, b
	ld [wMapLastDirectionMoved], a
	ld de, wActiveMapNode + 1
	ld a, [hli]
	ld [de], a
	ld c, a
	inc de
	ld a, [hli]
	ld [de], a
	ld b, a
	ld a, c
	add a, MapNode_Name
	ld l, a
	adc a, b
	sub a, l
	ld h, a
	ldh a, [hCurrentBank]
	ld b, a
	jp PrintHUD

MapNodeLock:
	ld a, [hli]
	push hl
	ld c, a
	call GetFlag
	and a, [hl]
	pop hl
	ret z
	jr MapNodeMove.noInc

MapNodeDungeon:
	ld de, wActiveDungeon
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a

	ld a, 1
	ld [wMapLockInput], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, low(InitDungeon)
	ld [hli], a
	ld [hl], high(InitDungeon)

	ret

MapNodeScene:
	ld de, wActiveScene
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, low(InitScene)
	ld [hli], a
	ld [hl], high(InitScene)
	ret

MapNodeTrader:
	ld de, wCurrentTrader
	inc hl ; Bank is ignored by this.
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, low(.openTrader)
	ld [hli], a
	ld [hl], high(.openTrader)
	ret

.openTrader
	ld a, GAMESTATE_MENU
	ld [wGameState], a
	ld b, bank(xTradeMenu)
	ld de, xTradeMenu
	jp AddMenu

section UNION "State variables", wram0
wEffects: ds (3 + evscript_script_pool_size) * NB_EFFECTS

wMapLockInput: db

section "wMapShouldSave", wram0
wMapShouldSave:: db

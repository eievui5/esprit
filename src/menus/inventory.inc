include "item.inc"

def INVENTORY_CURSOR_X equ SCRN_VX - SCRN_X + 69
def INVENTORY_CURSOR_Y equ 20

xInventoryMenu::
	db bank(@)
	dw xInventoryMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_START | PADF_SELECT | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw xInventoryA, null, xInventorySelect, xInventoryStart, null, null, xInventoryMove, xInventoryMove
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	; This is overwritten each frame to match the size of the inventory.
	db INVENTORY_SIZE
	; Redraw
	dw xInventoryMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xInventoryMenuClose

xDrawInventoryMenu:
	set_region 20, 0, SCRN_VX_B - 20, SCRN_Y_B, idof_vBlankTile
	dtile_section vScratchRegion
	dregion vInventoryMenu, 20, 0, 12, 4 + INVENTORY_SIZE
	print_text 23, 1, "Inventory"
	set_frame vInventoryMenu, idof_vFrame
	dregion vInventoryDescription, 20, 4 + INVENTORY_SIZE, 12, 6
	set_frame vInventoryDescription, idof_vFrame
	dtile vItemNames, 7 * INVENTORY_SIZE
	dtile_anon 1
	dtile vItemDesc
	end_menu

xInventoryMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a

	ld hl, wSubMenuCursor
	ld a, INVENTORY_CURSOR_X
	ld [hli], a
	ld a, INVENTORY_CURSOR_Y
	ld [hli], a
	ld a, idof_vItemCursor
	ld [hli], a
	ld [hl], OAMF_PAL1 | 1

	ld hl, wUseItemMenuCursor
	ld a, SCRN_VX - SCRN_X + 4
	ld [hli], a
	ld a, SCRN_Y + 4
	ld [hli], a
	ld a, idof_vItemCursor
	ld [hli], a
	ld [hl], OAMF_PAL1 | 1

	ld a, 1
	ld [wInventoryRedrawDesc], a
	ld hl, xDrawInventoryMenu
	call DrawMenu
	call xInventoryDrawItemNames
	ret

xInventoryDrawItemNames:
	xor a, a
	ld [wInventoryIsEmpty], a
	; Text is already mostly initialized by the menu renderer.
	xor a, a
	ld [wTextLetterDelay], a
	ld a, idof_vItemNames
	ld [wTextCurTile], a
	ld [wWrapTileID], a
	ld a, $FF
	ld [wLastTextTile], a

	; Print item names
	ld hl, wInventoryDrawPosition
	ld a, low($9800 + 23 + 3 * 32 - 32)
	ld [hli], a
	ld [hl], high($9800 + 23 + 3 * 32 - 32)
	ld hl, wInventory
	ld a, [hl]
	and a, a
	jr nz, .next
		ld a, 1
		ld [wInventoryIsEmpty], a
		ld b, bank(.emptyString)
		ld hl, .emptyString
		call PrintVWFText
		lb de, 8, 1
		ld hl, $9800 + 23 + 3 * 32
		call TextDefineBox
		call PrintVWFChar
		jp DrawVWFChars
.next
	ld a, [hli]
	and a, a
	jr z, .skip
	push hl
		call GetNextItemName
	PUSHS
	section "Get Next Item Name", rom0
	GetNextItemName:
		rst SwapBank
		ld b, a
		ld a, [hli]
		ld h, [hl]
		ld l, a
		inc hl
		inc hl
		inc hl
		inc hl
		assert Item_Name == 4
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ld a, 1
		call PrintVWFText
		ld a, bank(xInventoryDrawItemNames)
		rst SwapBank
		ret
	POPS
		lb de, 8, 1
		ld hl, wInventoryDrawPosition
		ld a, [hli]
		ld h, [hl]
		add a, 32
		ld l, a
		ld [wInventoryDrawPosition], a
		adc a, h
		sub a, l
		ld h, a
		ld [wInventoryDrawPosition + 1], a
		call TextDefineBox
		call PrintVWFChar
		call DrawVWFChars
	pop hl
.skip
	inc hl
	inc hl
	ld a, l
	cp a, low(wInventory.end)
	jr nz, .next
	ld a, h
	cp a, high(wInventory.end)
	jr nz, .next

	ret

.emptyString db "It's empty!", 0

xInventoryMenuRedraw:
	; Calculate the number of items in the inventory.
	ld hl, wInventory - 2
	ld b, INVENTORY_SIZE
.countItems
	inc hl
	inc hl
	ld a, [hli]
	and a, a
	jr z, .end
	dec b
	jr nz, .countItems
.end
	ld a, INVENTORY_SIZE
	sub a, b
	ld b, a

	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec hl
	dec hl ; Size
	; Set the size of the menu to match the number of entries in the inventory
	ld [hl], b
	dec hl ; Selection
	ld a, b
	cp a, [hl]
	jr nz, :+
	dec b
	ld [hl], b
:
	ld a, [wInventoryRedrawDesc]
	and a, a
	ld a, [hl]
	jr z, :+
	push af
	call xInventoryLoadItemSelection
	xor a, a
	ld [wInventoryRedrawDesc], a
	pop af
:
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, INVENTORY_CURSOR_Y
	ld b, a
	ld c, INVENTORY_CURSOR_X
	ld hl, wSubMenuCursor
	call DrawCursor
	
	ld hl, wPauseMenuCursor
	call DrawCursorStatic

	ld hl, wUseItemMenuCursor
	call DrawCursorStatic
	jp xScrollInterp

xInventoryMenuClose:
	xor a, a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
	ret

xInventoryA:
	ld a, [wInventoryIsEmpty]
	and a, a
	ret nz
	ld [wMenuAction], a
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	add a, a ; a * 2
	add a, [hl] ; a * 3
	add a, low(wInventory)
	ld e, a
	adc a, high(wInventory)
	sub a, e
	ld d, a
	call InventoryUsableCheck
PUSHS
section "Inventory Usable Check", rom0
InventoryUsableCheck:
	ld a, [de]
	inc de
	rst SwapBank
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	ld d, a
	ld a, Item_Type
	add a, b
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]
	and a, a
	ld a, bank(xInventoryA)
	rst SwapBank
	ret
POPS
	jr z, .cannotUse
	ld a, [hl]
	ld [wInventorySelection], a
	ld de, xUseItemMenu
	ld b, bank(xUseItemMenu)
	jp AddMenu

.cannotUse
	lb bc, 10, 4
	ld d, idof_vBlankTile
	ld hl, $9800 + 21 + 13 * 32
	call FillRegion
	lb bc, idof_vItemDesc, $FF
	lb de, SCRN_Y_B, $80
	ld a, 10 * 8
	call TextInit
	ld a, 1
	ld b, bank(.cannotUseString)
	ld hl, .cannotUseString
	call PrintVWFText
	lb de, 10, 3
	ld hl, $9800 + 21 + 13 * 32
	call TextDefineBox
	call PrintVWFChar
	jp DrawVWFChars

.cannotUseString db "You can't use this right now. Press START to toss.", 0

xInventoryStart:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	ld [wInventorySelection], a
	ld b, bank(xTossItemMenu)
	ld de, xTossItemMenu
	jp AddMenu

xInventorySelect:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	cp a, INVENTORY_SIZE - 1
	ret z
	inc a
	ld b, a
	add a, b ; a * 2
	add a, b ; a * 3
	add a, low(wInventory)
	ld l, a
	adc a, high(wInventory)
	sub a, l
	ld h, a
	ld a, [hli]
	and a, a
	ret z
	; cache the item in b:de.
	ld b, a
	ld a, [hli]
	ld e, a
	ld a, [hld] ; we can start moving backwards now
	ld d, a
	; Now swap!
	dec hl ; gotta move back to the previous item
	dec hl
	; we'll store this item in e:cd
	ld c, [hl] ; swap high
	ld a, d ; only b:e left
	ld [hld], a
	ld d, [hl]
	ld a, e ; just b!
	ld [hld], a
	ld e, [hl]
	ld a, b
	ld [hli], a
	inc hl
	inc hl
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	ld a, c
	ld [hli], a
	; increment the cursor too
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	inc [hl]
	lb bc, 8, 8
	ld hl, $9877
	ld d, idof_vBlankTile
	call FillRegion
	jp xInventoryDrawItemNames

xInventoryMove:
	ld a, 1
	ld [wInventoryRedrawDesc], a
	ret

xInventoryLoadItemSelection:
	push af
	ld a, [wInventoryIsEmpty]
	and a, a
	jr nz, .noCursor
	lb bc, 10, 4
	ld d, idof_vBlankTile
	ld hl, $9800 + 21 + 13 * 32
	call FillRegion
	pop af
	ld b, a
	add a, b ; a * 2
	add a, b ; a * 3
	add a, low(wInventory)
	ld l, a
	adc a, high(wInventory)
	sub a, l
	ld h, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp InventoryLoadItemSelection
.noCursor
	pop af
	xor a, a
	ld hl, vItemCursor
	lb bc, 0, 64
	jp VramSetSmall

PUSHS
section "Load Inventory Item Graphic", rom0
InventoryLoadItemSelection:
	ld a, b
	rst SwapBank
	push bc
		ldh a, [hSystem]
		and a, a
		jr z, .skipColor
		push hl
			ld a, [hli]
			ld h, [hl]
			ld l, a
			ld de, wOBJPaletteBuffer + 3 * 3 ; Set second palette
			ld c, 3 * 3
			call MemCopySmall
			call ReloadColor
		pop hl
	.skipColor
		assert Item_Graphics == 2
		inc hl
		inc hl
		ld a, [hli]
		push hl
			ld h, [hl]
			ld l, a
			ld de, vItemCursor
			ld c, 16
			call VramCopySmall
			ld de, vItemCursor + 32
			ld c, 16
			call VramCopySmall
			ld de, vItemCursor + 16
			ld c, 16
			call VramCopySmall
			ld de, vItemCursor + 48
			ld c, 16
			call VramCopySmall
		pop hl
		assert Item_Graphics + 4 == Item_Description
		inc hl
		inc hl
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a
		lb bc, idof_vItemDesc, $FF
		lb de, SCRN_Y_B, $80
		ld a, 10 * 8
		call TextInit
	pop bc
	ld a, 1
	call PrintVWFText
	lb de, 10, 3
	ld hl, $9800 + 21 + 13 * 32
	call TextDefineBox
	call PrintVWFChar
	call DrawVWFChars
	ld a, bank("Pause Menu")
	rst SwapBank
	ret

section "Inventory Draw Position", wram0
wInventoryDrawPosition: dw
wInventoryRedrawDesc: db
wInventorySelection: db
wInventoryIsEmpty: db
POPS

xTossItemMenu:
	db bank(@)
	dw xTossItemMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw xTossItemMenuA, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 2
	; Redraw
	dw xTossItemMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xTossItemMenuClose

xTossItemMenuInit:
	ld hl, wUseItemMenuCursor
	ld a, 21 * 8
	ld [hli], a
	ld a, 14 * 8 + 4
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1
	lb bc, 10, 4
	ld d, idof_vBlankTile
	ld hl, $9800 + 21 + 13 * 32
	call FillRegion
	lb bc, idof_vItemDesc, $FF
	lb de, SCRN_Y_B, $80
	ld a, 10 * 8
	call TextInit
	ld a, 1
	ld b, bank(.tossString)
	ld hl, .tossString
	call PrintVWFText
	lb de, 10, 3
	ld hl, $9800 + 21 + 13 * 32
	call TextDefineBox
	call PrintVWFChar
	jp DrawVWFChars

.tossString db "Toss this item?\n\n         No\n         Yes", 0

xTossItemMenuRedraw:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec hl
	dec hl ; Size
	dec hl ; Selection
	ld a, [hl]
	dec a
	jr nz, :+
	ld a, 7
:
	inc a
	add a, 14 * 8 + 4
	ld b, a
	ld c, 21 * 8
	ld hl, wUseItemMenuCursor
	call DrawCursor
	ld hl, wSubMenuCursor
	call DrawCursorStatic
	ret

xTossItemMenuA:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	dec a
	ret nz

	ld a, [wInventorySelection]
	inc a
	ld c, a
	add a, c
	add a, c
	add a, low(wInventory)
	ld l, a
	adc a, high(wInventory)
	sub a, l
	ld h, a
	ld d, h
	ld e, l
	dec de
	dec de
	dec de
	jr .moveCondition
.move
	ld a, [hli]
	ld [de], a
	inc de
.moveCondition
	ld a, l
	cp a, low(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	ld a, h
	cp a, high(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	xor a, a
	ld [de], a
	ret

xTossItemMenuClose:
	ld a, 30 * 8
	ld [wUseItemMenuCursor_Y], a
	ld a, 1
	ld [wInventoryRedrawDesc], a
	ld hl, xDrawInventoryMenu
	call DrawMenu
	jp xInventoryDrawItemNames
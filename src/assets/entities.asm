include "defines.inc"
include "entity.inc"

macro entity ; label, name, graphic
	section "\1 entity", romx
	\1:: dw .gfx, .palette, .name, .moves
	.gfx incbin \3
	.name:: db \2, 0
endm

macro level
	db \1, bank(\2)
	dw \2
endm

	; Players
	entity xLuvui, "Luvui", "res/sprites/luvui.obj.2bpp"
	.palette
		rgb 255, 255, 160
		rgb 144, 32, 48
		rgb 32, 0, 0
	.moves
		level 1, xScratch
		level 6, xBite
		level 7, xPounce
		level 9, xWish

		level 11, xSlash
		level 12, xCrunch
		level 13, xLunge
		db 0

	entity xAris, "Aris", "res/sprites/aris.obj.2bpp"
	.palette
		rgb 255, 255, 128
		rgb 32, 32, 176
		rgb 0, 0, 32
	.moves
		level 1, xScratch
		level 6, xBite
		level 7, xPounce
		level 9, xGrowl

		level 11, xSlash
		level 12, xCrunch
		level 13, xLunge
		level 15, xRoar
		db 0

	; Enemies
	entity xForestRat, "Forest Rat", "res/sprites/rat.obj.2bpp"
	.palette
		rgb 144, 200, 112
		rgb 48, 80, 16
		rgb 16, 24, 0
	.moves
		level 1, xNibble
		level 5, xScratch
		db 0

	entity xFieldRat, "Field Rat", "res/sprites/rat.obj.2bpp"
	.palette
		rgb 120, 120, 80
		rgb 64, 64, 16
		rgb 16, 24, 0
	.moves
		level 1, xScratch
		level 5, xPounce
		db 0

	entity xPlatypus, "Platypus", "res/sprites/platypus.obj.2bpp"
	.palette
		rgb 88, 216, 152
		rgb 96, 48, 16
		rgb 0, 16, 16
	.moves
		level 1, xScratch
		level 5, xPoisonBarbs
		db 0

	entity xSnake, "Snake", "res/sprites/snake.obj.2bpp"
	.palette
		hex ff8e00
		hex ac2c44
		hex 000000
	.moves
		level 1, xPoisonFangs
		db 0

	entity xFirefly, "Lampyr", "res/sprites/firefly.obj.2bpp"
	.palette
		hex f58a9b
		hex fcef00
		hex 01133e
	.moves
		level 1, xMoonlight
		level 1, xStingShot
		level 5, xFly
		db 0

	entity xAlligator, "Alligator", "res/sprites/alligator.obj.2bpp"
	.palette
		incbin "res/sprites/alligator.obj.pal8", 3
	.moves
		level 1, xBite
		db 0

	entity xMudCrab, "Mud Crab", "res/sprites/crustacean.obj.2bpp"
	.palette
		rgb 120, 120, 80
		rgb 64, 64, 16
		rgb 16, 24, 0
	.moves
		level 1, xClawBite
		db 0

	; NPCS
	entity xMom, "Mom", "res/sprites/kangaroo.obj.2bpp"
	.palette
		incbin "res/sprites/kangaroo.obj.pal8", 3
	.moves
		db 0

	entity xPuppy, "Puppy", "res/sprites/puppy.obj.2bpp"
	.palette
		rgb 255, 255, 128
		rgb 32, 32, 176
		rgb 0, 0, 32
	.moves
		db 0

	entity xTachy, "Tachy", "res/sprites/wolf.obj.2bpp"
	.palette
		incbin "res/sprites/wolf.obj.pal8", 3
	.moves
		db 0

	entity xFox, "Fox", "res/sprites/fox.obj.2bpp"
	.palette
		incbin "res/sprites/fox.obj.pal8", 3
	.moves
		db 0

	entity xSephone, "Sephone", "res/sprites/sephone.obj.2bpp"
	.palette
		incbin "res/sprites/sephone.obj.pal8", 3
	.moves
		db 0

	entity xLibera, "Libera", "res/sprites/libera.obj.2bpp"
	.palette
		incbin "res/sprites/libera.obj.pal8", 3
	.moves
		db 0

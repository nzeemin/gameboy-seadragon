; Sea Dragon for GameBoy
; Main

;------------------------------------------------------------------------------
; GameBoy Hardware Defines
        INCLUDE "gbhw.inc"

;------------------------------------------------------------------------------
; Beginning
        SECTION "Org $0",HOME
        ret
        SECTION "Org $40",HOME[$40]
	jp	IntVBlank
        SECTION "Org $48",HOME[$48]
        jp      IntLCDStat

;------------------------------------------------------------------------------
; Variables
	SECTION "Vars",BSS
SpriteTable     DS      160	; Sprite data prepared
ScrollDelay	DB
ScrollCurrent	DB
NextColumnAddr	DW		; Address of landscape data for the next column

;------------------------------------------------------------------------------
; Code & data section start
        SECTION "Org $100",HOME[$100]
        nop
        jp      Begin
; Cart header
        ROM_HEADER      ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

;------------------------------------------------------------------------------
; Additional includes
        INCLUDE "memory.asm"

	INCLUDE "font.inc"
	INCLUDE "sprites.inc"
	INCLUDE "tileland.inc"
	INCLUDE "landscape.inc"

;------------------------------------------------------------------------------
; Additional defines
LandscapeRows	EQU	15
LandscapeCols	EQU	(LandscapeDataEnd - LandscapeData) / LandscapeRows
LCDCF_NORMNOWIN	EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINOFF
LCDCF_NORMWIN	EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINON

;------------------------------------------------------------------------------
; Starting point
Begin:
        di				; Disable interrupts
        ld      sp,$ffff		; Initialize the stack
;
        call    StopLCD			; Turn off the screen
;
        ld      a,$e4
        ld      [rBGP],a        	; Setup the default background palette

; Set scroll to upper left corner
        xor     a
        ld      [rSCX],a
        ld      [rSCY],a
        ld      [rWY],a
	ld	a,7
        ld      [rWX],a
; Clear variables RAM at C000-CFFF
	xor	a
	ld	hl,$C000
	ld	bc,$1000
	call    mem_Set
; Clear tiles memory
        xor     a
        ld      hl,$8000
        ld      bc,$1800
        call    mem_Set
; Prepare font tiles, 64 characters
        ld      hl,FontData
        ld      de,$8000 + 16 * 32
        ld      bc,8 * 64       	; length (8 bytes per tile) x (64 tiles)
        call    mem_CopyMono    	; Copy tile data to memory
; Prepare sprite tiles
	ld	hl,Sprites
	ld	de,$8000
	ld	bc,8 * SpritesCount
        call    mem_CopyMono    	; Copy tile data to memory
; Prepare landscape tiles, 96 tiles
        ld      hl,LandscapeTiles
        ld      de,$8000 + 16 * 128
        ld      bc,8 * 96       	; length (8 bytes per tile) x (96 tiles)
        call    mem_CopyMono    	; Copy tile data to memory

; Clear the canvas
        xor     a			; Clear background tile map memory
        ld      hl,$9800
        ld      bc,SCRN_VX_B * SCRN_VY_B
        call    mem_Set
        xor     a			; Clear window tile map memory
        ld      hl,$9C00
        ld      bc,SCRN_VX_B * SCRN_VY_B
        call    mem_Set
; Clear SpriteTable
	xor	a
	ld	hl,SpriteTable
	ld	bc,160
	call	mem_Set

; DEBUG: Show sprite for the boat
	ld	hl,SpriteTable
	ld	[hl],4+39		; Y pos
	inc	hl
	ld	[hl],20			; X pos
	inc	hl
	ld	[hl],6			; Sprite tile
	inc	hl
	ld	[hl],0			; Sprite attrs
	inc	hl
;
	ld	[hl],4+39		; Y pos
	inc	hl
	ld	[hl],20+8		; X pos
	inc	hl
	ld	[hl],7			; Sprite tile
	inc	hl
	ld	[hl],0			; Sprite attrs
	inc	hl

; Draw strings on the window
        ld      hl,StrBoats
	ld	de, $0001		; line 0, column 1
        ld      bc,4
	call	DrawString
        ld      hl,StrHighScore
	ld	de, $000A		; line 0, column 10
        ld      bc,10
	call	DrawString
        ld      hl,Str000000
	ld	de, $0102		; line 1, column 2
        ld      bc,6
	call	DrawString
        ld      hl,Str000000
	ld	de, $010C		; line 1, column 12
        ld      bc,6
	call	DrawString
        ld      hl,StrAir
	ld	de, $0200		; line 2, column 0
        ld      bc,4
	call	DrawString
; Draw air level
	ld	a,5
	ld	hl,$9C00 + SCRN_VX_B * 2 + 4
	ld	bc,14
        call    mem_Set
        
; Prepare first 32 columns of the landscape
	ld	de,LandscapeData
	call	PrepareLandscapeFirst32
	ld	hl,NextColumnAddr
	ld	[hl],e
	inc	hl
	ld	[hl],d

; Turn on the LCD
        ld      a,LCDCF_NORMWIN
        ld      [rLCDC],a
; Enable interrupts
	ld	a,IEF_VBLANK|IEF_LCDC	; Enable VBlank and LCDC interrupts
	ld	[rIE],a
	ld	a,STATF_MODE00		; Enable mode 0 (H-Blank) for LCDC interrupt
	ld	[rSTAT],a
        ei
; Menu mode main loop
.menumainloop:
	halt
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,.menumainloop
; Check joypad state
	call	ReadJoypad
	and	$08			; Start button pressed?
	jp	nz,.startgamemode	; Yes, start the game
; Continue menu main loop	
        jr      .menumainloop

;------------------------------------------------------------------------------
; Prepare game mode
.startgamemode:
	di
; Prepare scroll
	ld	a,2
	ld	[ScrollDelay],a
	ld	[ScrollCurrent],a
; Clear game variables
	xor	a
	;TODO
; Enable interrupts
	ei
; Game mode main loop
.gamemainloop:
	halt				; Wait for a next interrupt
.gamemainloop2:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,.gamemainloop2	; No, keep waiting
; VBlank mode processing
; Copy SpritesTable to OAM using DMA
	ld      a,$c0			; SpriteTable/256
	ld	[rDMA],a		; during this time the CPU can access only HRAM
	ld	a,$28			; delay
.waitdma:				; total 5x40 cycles, approx 200ms
	dec	a          		; 1 cycle
	jr	nz,.waitdma    		; 4 cycles
; Scroll
	ld	a,[ScrollCurrent]
	dec	a
	ld	[ScrollCurrent],a
	jr	nz,.skipscroll
	ld	a,[ScrollDelay]
	ld	[ScrollCurrent],a
	ld	a,[rSCX]
	inc	a
	ld	[rSCX],a
; Check if scrolled to the next column
	ld	c,a
	and	7
	jr	nz,.skipscroll
; Prepare next landscape column
	ld	hl,NextColumnAddr
	ld	e,[hl]
	inc	hl
	ld	d,[hl]			; Get NextColumnAddr
	ld	hl,$9800 + SCRN_VX_B * 2
	ld	a,c
	rra
	rra
	rra				; Divide by 8
	dec	a
	and	$1f
	ld	c,a
	ld	b,0
	add	hl,bc			; HL now contains proper address on the background map
	call	PrepareLandscapeNext	; Draw the column
	ld	hl,NextColumnAddr
	ld	[hl],e
	inc	hl
	ld	[hl],d			; Store updated NextColumnAddr 
.skipscroll:
; Process joypad
	call	ReadJoypad
	ld	de,0
	ld	c,a
	and	$80			; Down pressed?
	jr	z,.gamemainJoy1
	inc	e
.gamemainJoy1:
	ld	a,c
	and	$40			; Up pressed?
	jr	z,.gamemainJoy2
	dec	e
.gamemainJoy2:
	ld	a,c
	and	$20			; Left pressed?
	jr	z,.gamemainJoy3
	dec	d
.gamemainJoy3:
	ld	a,c
	and	$10			; Right pressed?
	jr	z,.gamemainJoy4
	inc	d
.gamemainJoy4:
; Analyse Y movement delta value
	ld	a,e
	or	a
	jr	z,.gamemainMove1
	ld	hl,SpriteTable
	ld	b,[hl]			; Get boat Y position
	add	a,b
	ld	[hl],a			; Save updated Y position
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	[hl],a			; Save updated Y position for the 2nd sprite
.gamemainMove1:
; Analyse X movement delta value
	ld	a,d
	or	a
	jr	z,.gamemainMove2
	ld	hl,SpriteTable + 1
	ld	b,[hl]			; Get boat X position
	add	a,b
	ld	[hl],a			; Save updated X position
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	add	a,8
	ld	[hl],a			; Save updated X position for the 2nd sprite
.gamemainMove2:
; Continue game main loop	
        jp      .gamemainloop

;------------------------------------------------------------------------------
; VBlank Interrupt Routine
IntVBlank:
	di
	push	af
;; Turn on the LCD with window
;        ld      a,LCDCF_NORMWIN
;        ld      [rLCDC],a
;
        pop	af
	reti
	
;------------------------------------------------------------------------------
; LCDC Interrupt Routine
IntLCDStat:
	di
	push	af
;
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	jr	nz,.intlcdstatExit	; Not H-blank mode
; Check scanline and show/hide window
	ld      a,[rLY]
	cp	16			; Scanline 16?
	jr	nz,.intlcdstat2		; No
	ld	a,LCDCF_NORMNOWIN	; Hide window, show background
        ld      [rLCDC],a
	jr	.intlcdstatExit
.intlcdstat2:
	cp	134			; Scanline 134?
	jr	nz,.intlcdstatExit
	ld	a,LCDCF_NORMWIN		; Show window and background
        ld      [rLCDC],a
	jr	.intlcdstatExit
;
.intlcdstatExit:
	pop	af
	reti

;------------------------------------------------------------------------------
; String constants
StrHighScore:
	DB      "HIGH SCORE"
StrBoats:
	DB      6,7,":5"
Str000000:
	DB      "000000"
StrAir:
	DB      "AIR:"

;------------------------------------------------------------------------------
; Draw string to window
; Input: hl - string address, bc - string length, de - line and column.
DrawString:
	push	hl
	ld	a,d
	ld	h,$9C			; $9C00 - window tile map starting address
	ld	l,e
	ld	de, SCRN_VX_B
	or	a
.loopline:
	jr	z,.copystr
	add	hl, de
	dec	a
	jr	nz,.loopline
.copystr
	ld	d,h
	ld	e,l
	pop	hl
        call    mem_Copy
	ret

;------------------------------------------------------------------------------
; Turn off the LCD display
; Uses: af
StopLCD:
        ld      a,[rLCDC]
        rlca                    	; Put the high bit of LCDC into the Carry flag
        ret     nc              	; Screen is off already. Exit.
; Loop until we are in VBlank
.wait:
        ld      a,[rLY]
        cp      145             	; Is display on scan line 145 yet?
        jr      nz,.wait        	; no, keep waiting
; Turn off the LCD
        ld      a,[rLCDC]
        res     7,a             	; Reset bit 7 of LCDC
        ld      [rLCDC],a
        ret
        
;------------------------------------------------------------------------------
; Read Joypad data
; Output: a - high bits:Dn,Up,Lt,Rt, low bits:Start,Select,B,A
; Uses:   b
ReadJoypad:
	ld	a,$20
	ld	[$FF00],a		; Turn on P15
	ld	a,[$FF00]
	ld	a,[$FF00]		; Wait a few cycles
	cpl
	and	$0f
	swap	a
	ld	b,a
	ld	a,$10
	ld	[$FF00],a		; Turn on P14
	ld	a,[$FF00]
	ld	a,[$FF00]
	ld	a,[$FF00]
	ld	a,[$FF00]		; Wait a few MORE cycles
	cpl
	and	$0f
	or	b
	ret

;------------------------------------------------------------------------------
; Prepare first 32 columns of landscape
; Input:  de - landscape data starting address
; Output: de - next landscape column address
; Uses:   af,bc,hl
PrepareLandscapeFirst32:
	ld	c,0			; First column
.landscape1:
	ld	b,LandscapeRows
	ld	hl,$9800 + SCRN_VX_B * 2
	push	bc
	ld	b,0
	add	hl,bc
	pop	bc
.landscape2:
	ld	a,[de]
	ld	[hl],a
	inc	de
	push	bc
	ld	b,0
	ld	c,SCRN_VX_B
	add	hl,bc
	pop	bc
	dec	b
	jr	nz,.landscape2
	inc	c
	ld	a,c
	sub	32			; Column count
	jr	nz,.landscape1
	ret

;------------------------------------------------------------------------------
; Prepare next column of landscape
; Input:  de - landscape data starting address, hl - address on the screen
; Output: de - next landscape column address
; Uses:   af,bc,hl
PrepareLandscapeNext:
	ld	b,LandscapeRows
	ld	c,0
	push	bc
	ld	b,0
	add	hl,bc
	pop	bc
.nlandscape2:
	ld	a,[de]
	ld	[hl],a
	inc	de
	push	bc
	ld	b,0
	ld	c,SCRN_VX_B
	add	hl,bc
	pop	bc
	dec	b
	jr	nz,.nlandscape2
	ret

;------------------------------------------------------------------------------
;* End of File *

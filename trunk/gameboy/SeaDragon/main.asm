; Sea Dragon for GameBoy
; Main

; GameBoy Hardware Defines
        INCLUDE "gbhw.inc"

; Defines
LCDCF_NORMNOWIN	EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINOFF
LCDCF_NORMWIN	EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINON

; Beginning
        SECTION "Org $0",HOME
        ret
        SECTION "Org $40",HOME[$40]
	jp	IntVBlank
        SECTION "Org $48",HOME[$48]
        jp      IntLCDStat

; Variables
	SECTION "Vars",BSS
SpriteTable     DS      160	; Sprite data prepared
ScrollDelay	DB
ScrollCurrent	DB

; Code & data section start
        SECTION "Org $100",HOME[$100]
        nop
        jp      Begin
; Cart header
        ROM_HEADER      ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

; Additional includes
        INCLUDE "memory.asm"

	INCLUDE "font.inc"
	INCLUDE "sprites.inc"
	INCLUDE "tileland.inc"
	INCLUDE "landscape.inc"

; Additional defines
LandscapeRows	EQU	15
LandscapeCols	EQU	(LandscapeDataEnd - LandscapeData) / LandscapeRows

; Starting point
Begin:
        di
        ld      sp,$ffff

        call    StopLCD

        ld      a,$e4
        ld      [rBGP],a        ; Setup the default background palette

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
        ld      bc,8 * 64       ; length (8 bytes per tile) x (64 tiles)
        call    mem_CopyMono    ; Copy tile data to memory
; Prepare sprite tiles
	ld	hl,Sprites
	ld	de,$8000
	ld	bc,8 * SpritesCount
        call    mem_CopyMono    ; Copy tile data to memory
; Prepare landscape tiles, 96 tiles
        ld      hl,LandscapeTiles
        ld      de,$8000 + 16 * 128
        ld      bc,8 * 96       ; length (8 bytes per tile) x (96 tiles)
        call    mem_CopyMono    ; Copy tile data to memory

; Clear the canvas
        xor     a		; Clear background tile map memory
        ld      hl,$9800
        ld      bc,SCRN_VX_B * SCRN_VY_B
        call    mem_Set
        xor     a		; Clear window tile map memory
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
	ld	[hl],4+39	; Y pos
	inc	hl
	ld	[hl],20		; X pos
	inc	hl
	ld	[hl],6		; Sprite tile
	inc	hl
	ld	[hl],0		; Sprite attrs
	inc	hl
;
	ld	[hl],4+39	; Y pos
	inc	hl
	ld	[hl],20+8	; X pos
	inc	hl
	ld	[hl],7		; Sprite tile
	inc	hl
	ld	[hl],0		; Sprite attrs
	inc	hl
;DEBUG: Prepare scroll
	ld	a,2
	ld	[ScrollDelay],a
	ld	[ScrollCurrent],a

;;DEBUG: Show all the tiles
;	xor     a
;	ld      hl,$9800
;	ld	bc,SCRN_VX_B * SCRN_VY_B
;.loopbg:
;	ld	[hl],a
;	inc	a
;	inc	hl
;	dec	bc
;	jr	nz,.loopbg

; Draw strings on the window
        ld      hl,StrBoats
	ld	de, $0001	; line 0, column 1
        ld      bc,4
	call	DrawString
        ld      hl,StrHighScore
	ld	de, $000A	; line 0, column 10
        ld      bc,10
	call	DrawString
        ld      hl,Str000000
	ld	de, $0102	; line 1, column 2
        ld      bc,6
	call	DrawString
        ld      hl,Str000000
	ld	de, $010C	; line 1, column 12
        ld      bc,6
	call	DrawString
        ld      hl,StrAir
	ld	de, $0200	; line 2, column 0
        ld      bc,4
	call	DrawString
; Draw air level
	ld	a,5
	ld	hl,$9C00 + SCRN_VX_B * 2 + 4
	ld	bc,14
        call    mem_Set

; Draw water
	ld	a,1
	ld	hl,$9800 + SCRN_VX_B * 3
	ld	bc,SCRN_VX_B
        call    mem_Set
; Draw mine
	ld	bc,SCRN_VX_B + 2
	add	hl,bc
	ld	[hl],3
	ld	bc,SCRN_VX_B
	add	hl,bc
	ld	[hl],4
        
; DEBUG: Prepare first columns of the landscape
	ld	de,LandscapeData
	ld	c,0		; First column
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
	sub	32	; Column count
	jr	nz,.landscape1

; Turn on the LCD
        ;ld      a,LCDCF_NORM
        ;ld      [rLCDC],a
; Enable interrupts
	ld	a,IEF_VBLANK|IEF_LCDC	; Enable VBlank and LCDC interrupts
	ld	[rIE],a
	ld	a,STATF_MODE00		; Enable mode 0 (H-Blank) for LCDC interrupt
	ld	[rSTAT],a
        ei
; Deadloop; TODO: create main loop for game mode and for menu mode
.wait:
	halt
        jp      .wait
        
; VBlank Interrupt Routine
IntVBlank:
	di
	push	af
; Turn on the LCD with window
        ld      a,LCDCF_NORMWIN
        ld      [rLCDC],a
; Scroll -- DEBUG; TODO: move to main loop
	ld	a,[ScrollCurrent]
	dec	a
	ld	[ScrollCurrent],a
	jr	nz,.skipscroll
	ld	a,[ScrollDelay]
	ld	[ScrollCurrent],a
	ld	a,[rSCX]
	inc	a
	ld	[rSCX],a
.skipscroll:
; Copy SpritesTable to OAM using DMA; TODO: move to main loop
	ld      a,$c0		; SpriteTable/256
	ld	[rDMA],a	; during this time the CPU can access only HRAM
	ld	a,$28		; delay
.waitdma:			; total 5x40 cycles, approx 200ms
	dec	a          	; 1 cycle
	jr	nz,.waitdma    	; 4 cycles
;
        pop	af
	reti
	
; LCDC Interrupt Routine
IntLCDStat:
	di
	push	af
;
	ld	a,[rSTAT]
	and	3
	jr	nz,.intlcdstatExit	; Not H-blank mode
; Check scanline and show/hide window
	ld      a,[rLY]
	sub	16			; scanline 0..15?
	jr	c,.intlcdstatWin
	add	16
	sub	132			; scanline 132..144?
	jr	nc,.intlcdstatWin
;	
	ld	a,LCDCF_NORMNOWIN	; Hide window, show background
        ld      [rLCDC],a
	jr	.intlcdstatExit
.intlcdstatWin:
	ld	a,LCDCF_NORMWIN		; Show window
        ld      [rLCDC],a
.intlcdstatExit:
	pop	af
	reti

; String constants
StrHighScore:
	DB      "HIGH SCORE"
StrBoats:
	DB      6,7,":5"
Str000000:
	DB      "000000"
StrAir:
	DB      "AIR:"

; *** Draw string to window ***
; Input: hl - string address, bc - string length, de - line and column.
DrawString:
	push	hl
	ld	a,d
	ld	h,$9C		; $9C00 - window tile map starting address
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

; *** Turn off the LCD display ***
StopLCD:
        ld      a,[rLCDC]
        rlca                    ; Put the high bit of LCDC into the Carry flag
        ret     nc              ; Screen is off already. Exit.
; Loop until we are in VBlank
.wait:
        ld      a,[rLY]
        cp      145             ; Is display on scan line 145 yet?
        jr      nz,.wait        ; no, keep waiting
; Turn off the LCD
        ld      a,[rLCDC]
        res     7,a             ; Reset bit 7 of LCDC
        ld      [rLCDC],a
        ret
        
; *** Read Joypad data ***
; Output: a - high bits:A,B,SEL,STRT, low bits:Up,Dn,Lt,Rt
; Uses: b
ReadJoypad:
	ld	a,$20
	ld	[$FF00],a	; Turn on P15
	ld	a,[$FF00]
	ld	a,[$FF00]	; Wait a few cycles
	cpl
	and	$0f
	swap	a
	ld	b,a
	ld	a,$10
	ld	[$FF00],a	; Turn on P14
	ld	a,[$FF00]
	ld	a,[$FF00]
	ld	a,[$FF00]
	ld	a,[$FF00]	; Wait a few MORE cycles
	cpl
	and	$0f
	or	b
	ret

;* End of File *

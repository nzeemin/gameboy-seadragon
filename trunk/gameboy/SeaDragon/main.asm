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
        SECTION "Org $50",HOME[$50]	; Timer overflow IRQ
        reti
        SECTION "Org $58",HOME[$58]	; Serial IRQ
        reti
        SECTION "Org $60",HOME[$60]
        reti
        SECTION "Org $68",HOME[$68]
        DS	$98		; Filler, to prevent use of the area

;------------------------------------------------------------------------------
; Variables
	SECTION "Vars",BSS
SpriteTable     DS      160	; Sprite data prepared
ScrollDelay	DB		; Scrolling delay
ScrollCurrent	DB		; Scrolling count
NextColumnAddr	DW		; Address of landscape data for the next column
NextVisColAddr	DW		; Address of the next visible column on the background tile map 
JoypadDataPrev	DB		; Previous value read from joypad port
JoypadData	DB		; Current value read from joypad port
HighScore	DW		; Current score value
Score		DW		; Current score value
AirLevel	DB		; Current air level: 0..128
AirDelta	DB		; Accumulator for AirLevel change
Lives		DB		; Lives

;------------------------------------------------------------------------------
; Data section
SECTION "Org Bank1",CODE,BANK[1]
	INCLUDE "sprites.inc"
	INCLUDE "tileland.inc"
	INCLUDE "font.inc"

	INCLUDE "landscape.inc"
	DB	$ff		; Marker "end of the landscape

	INCLUDE "credits.inc"

; Sprites data prepared for game mode
SpritesDataPrepared:
;		Y pos	X pos	Tile	Attrs
	DB	4+39,	20,	6,	0	; Boat 1st tile
	DB	4+39,	20+8,	7,	0	; Boat 2nd tile
	DB	0,	0,	12,	0	; Ship 1st tile
	DB	0,	0,	13,	0	; Ship 2nd tile
	DB	0,	0,	2,	0	; Torpedo 1
	DB	0,	0,	2,	0	; Torpedo 2
	DB	0,	0,	2,	0	; Torpedo 3
	DB	0,	0,	2,	0	; Missile 1
	DB	0,	0,	2,	0	; Missile 2
	DB	0,	0,	2,	0	; Missile 3
	DB	0,	0,	3,	0	; Mine 1
	DB	0,	0,	3,	0	; Mine 2
	DB	0,	0,	3,	0	; Mine 3
	DB	0,	0,	3,	0	; Mine 4
	DB	0,	0,	3,	0	; Mine 5
	DB	0,	0,	3,	0	; Mine 6
	DB	0,	0,	3,	0	; Mine 7
	DB	0,	0,	3,	0	; Mine 8
	DB	0,	0,	9,	0	; Bullet 1
	DB	0,	0,	9,	0	; Bullet 2
	DB	0,	0,	9,	0	; Bullet 3
	DB	0,	0,	9,	0	; Bullet 4
	DB	0,	0,	9,	0	; Bullet 5
	DB	0,	0,	9,	0	; Bullet 6
	DB	0,	0,	9,	0	; Bullet 7
	DB	0,	0,	9,	0	; Bullet 8
	DB	0,	0,	14,	0	; Bomb 1
	DB	0,	0,	14,	0	; Bomb 2
	DB	0,	0,	14,	0	; Bomb 3
	DB	0,	0,	14,	0	; Bomb 4
	DB	0,	0,	14,	0	; Bomb 5
	DB	0,	0,	14,	0	; Bomb 6
	DB	0,	0,	15,	0	; Rock 1
	DB	0,	0,	15,	0	; Rock 2
	DB	0,	0,	15,	0	; Rock 3
	DB	0,	0,	15,	0	; Rock 4
SpritesDataPreparedEnd:

; String constants
StrWindowRows1:
	DB      " ",6,7,":0     HIGH SCORE"
StrWindowRows2:
	DB      "  000000    000000  "
StrWindowRows3:
	DB      "AIR:                "
StrWindowStart:
	DB      "PRESS START TO BEGIN"

;------------------------------------------------------------------------------
; Additional includes
        INCLUDE "memory.asm"

;------------------------------------------------------------------------------
; Code & data section start
        SECTION "Org $100",HOME[$100]
        nop
        jp      Begin
; Cart header
        ROM_HEADER      ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

;------------------------------------------------------------------------------
; Additional defines
DMACODELOC	EQU	$ff80
LandscapeRows	EQU	15
LandscapeCols	EQU	(LandscapeDataEnd - LandscapeData) / LandscapeRows
LCDCF_NORMNOWIN	EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINOFF
LCDCF_NORMWIN	EQU	LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINON
BoatWaterLevel	EQU	43
BoatLowerLevel	EQU	139
BoatLeftEdge	EQU	8
BoatRightEdge	EQU	140
AirLevelTop	EQU	128
AirDeltaDefault	EQU	28
AirDeltaTop	EQU	28+12
ObjTorpedoCount	EQU	3

;------------------------------------------------------------------------------
; Starting point
Begin:
        di				; Disable interrupts
        ld      sp,$fffe		; Initialize the stack
; Prepare DMA code
	call	InitDma
; Turn off the screen
        call    StopLCD
; Default palette
        ld      a,$e4
        ld      [rBGP],a        	; Setup the default background palette
; Turn off the sound
	xor	a
	ld	[rNR50],a
; Clear tiles memory
        xor     a
        ld      hl,$8000
        ld      bc,$1800
        call    mem_Set
; Prepare sprite tiles
	ld	hl,Sprites
	ld	de,$8000
	ld	bc,8 * SpritesCount
        call    mem_CopyMono    	; Copy tile data to memory
; Prepare font tiles, 64 characters
        ld      hl,FontData
        ld      de,$8000 + 16 * 32
        ld      bc,8 * 64       	; length (8 bytes per tile) x (64 tiles)
        call    mem_CopyMono    	; Copy tile data to memory
; Prepare landscape tiles, 96 tiles
        ld      hl,LandscapeTiles
        ld      de,$8000 + 16 * 128
        ld      bc,8 * 96       	; length (8 bytes per tile) x (96 tiles)
        call    mem_CopyMono    	; Copy tile data to memory
; Clear the canvas
        xor     a			; Clear background and window tile map memory
        ld      hl,$9800
        ld      bc,$0800		; Clear area $9800-$9fff
        call    mem_Set
; Draw strings on the window
        ld      hl,StrWindowRows1
	ld	de, $9C00		; line 0, column 0
        ld      bc,20
	call	mem_Copy
        ld      hl,StrWindowRows2
	ld	de, $9C00+SCRN_VX_B	; line 1, column 0
        ld      bc,20
	call	mem_Copy
	jp	StartMenuMode

;------------------------------------------------------------------------------
; Service routines
        INCLUDE "service.inc"

;------------------------------------------------------------------------------
; Prepare menu mode
RestartMenuMode:
        call    StopLCD
	di
StartMenuMode:
; Draw "Press Start to begin" line
        ld      hl,StrWindowStart
	ld	de, $9C00+SCRN_VX_B*2	; line 2, column 0
        ld      bc,20
	call	mem_Copy
; Clear variables RAM at C000-CFFF
	xor	a
	ld	hl,$C000
	ld	bc,$1000
	call    mem_Set
; Set scroll registers to upper left corner
        xor     a
        ld      [rSCX],a
        ld      [rSCY],a
        ld      [rWY],a
	ld	a,7
        ld      [rWX],a
; Clear SpriteTable
	xor	a
	ld	hl,SpriteTable
	ld	bc,160
	call	mem_Set
; Update sprites in DMA
	call	DMACODELOC
; Prepare sprites
	ld	hl,SpritesDataPrepared
	ld	de,SpriteTable
	ld	bc,SpritesDataPreparedEnd-SpritesDataPrepared
	call    mem_Copy
; Draw high score
	ld	a,[HighScore]
	ld	l,a
	ld	a,[HighScore+1]
	ld	h,a
	ld	bc, $9C00+SCRN_VX_B+12	; line 1, column 12
	call	PrintWord
        
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
	ld	bc,60*25		; Counter for 25 seconds
.menumainloop:
;	halt
	nop				; Sometimes an instruction after halt is skipped
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,.menumainloop
; Check joypad state
	ld	a,[JoypadData]
	ld	[JoypadDataPrev],a	; Store previous joypad data
	push	bc
	call	ReadJoypad
	pop	bc
	ld	[JoypadData],a
; Check if START button just released
	bit	PADB_START,a		; Start button pressed?
	jr	nz,.menumainNoStart	; Yes
	ld	a,[JoypadDataPrev]
	bit	PADB_START,a		; Start button was pressed?
	jp	nz,StartGameMode	; Yes, start the game
.menumainNoStart:
; Wait for end of VBlank
.menumainWaitVEnd:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	z,.menumainWaitVEnd	; Yes, keep waiting
; Continue menu main loop
	dec	c
	jr	nz,.menumainloop
	dec	b
        jr      nz,.menumainloop
        jp	StartCreditsMode

;------------------------------------------------------------------------------
; Credits vertical scrolling mode        
StartCreditsMode:
	call	WaitVBlank
; Clear "AIR" line
	xor	a
	ld	hl, $9C00+SCRN_VX_B*2	; line 2, column 0
        ld      bc,20
	call	mem_Set
; Prepare scroll
	ld	a,5
	ld	[ScrollDelay],a
	ld	[ScrollCurrent],a
; Prepare data
	ld	de,CreditsData
	ld	hl,$9800+SCRN_VX_B*17
	call	PrepareCreditsNext
	ld	hl,NextColumnAddr
	ld	[hl],e
	inc	hl
	ld	[hl],d
; Credits mode main loop
	ei				; Enable interrupts
.credMainLoop:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,.credMainLoop	; No, keep waiting
; VBlank mode processing
; Scroll
	ld	a,[ScrollCurrent]
	dec	a
	ld	[ScrollCurrent],a
	jr	nz,.credSkipScroll
	ld	a,[ScrollDelay]
	ld	[ScrollCurrent],a
	ld	a,[rSCY]
	inc	a
	ld	[rSCY],a
; Check if scrolled to the next row
	ld	c,a
	and	7
	jr	nz,.credSkipScroll
; Prepare next credits row
	ld	hl,NextColumnAddr
	ld	e,[hl]
	inc	hl
	ld	d,[hl]			; Get next row address
	ld	hl,$9800
	ld	a,c
	srl	a
	srl	a
	srl	a			; 
	add	17
	and	$1f
	jr	z,.credScroll2
.credScroll1:
	ld	bc,SCRN_VX_B
	add	hl,bc
	dec	a
	jr	nz,.credScroll1
.credScroll2:
; Check for scroll end mark
	ld	a,[de]
	inc	a			; $ff ?
	jp	z,RestartMenuMode	; EXIT to menu
; Prepare next row
	call	PrepareCreditsNext
	ld	hl,NextColumnAddr
	ld	[hl],e
	inc	hl
	ld	[hl],d
.credSkipScroll:
; Check joypad state
	ld	a,[JoypadData]
	ld	[JoypadDataPrev],a	; Store previous joypad data
	call	ReadJoypad
	ld	[JoypadData],a
	or	a			; Some button pressed?
	jr	nz,.credSkipJoypad	; Yes, wait for release
	ld	a,[JoypadDataPrev]
	or	a			; Some button was pressed?
	jp	nz,RestartMenuMode	; Yes, EXIT to menu
.credSkipJoypad:	
.credWaitVEnd:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	z,.credWaitVEnd		; Yes, keep waiting
	jr	.credMainLoop
	
;------------------------------------------------------------------------------
; Prepare game mode
StartGameMode:
	di
; Draw "AIR" line
        ld      hl,StrWindowRows3
	ld	de, $9C00+SCRN_VX_B*2	; line 2, column 0
        ld      bc,20
	call	mem_Copy
; Prepare scroll
	ld	a,2
	ld	[ScrollDelay],a
	ld	[ScrollCurrent],a
; Prepare game variables
	xor	a
	ld	[Score],a
	ld	[Score+1],a
	ld	a,AirLevelTop
	ld	[AirLevel],a
	ld	a,AirDeltaDefault
	ld	[AirDelta],a
	ld	a,4
	ld	[Lives],a
; Show number of lives
	ld	a,[Lives]
	add	a,$30
	ld	[$9C00 + 4],a
; Game mode main loop
	ei				; Enable interrupts
.gamemainloop:
;	halt				; Wait for a next interrupt
	nop				; Sometimes an instruction after halt is skipped
.gamemainloop2:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,.gamemainloop	; No, keep waiting
; VBlank mode processing
; Copy SpritesTable to OAM using DMA
	call	DMACODELOC
; Scroll
	ld	a,[ScrollCurrent]
	or	a			; Scrolling stopped?
	jr	z,.skipscroll		; Yes
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
; Calculate next visible column
	ld	hl,$9800 + SCRN_VX_B * 2
	ld	a,c
	srl	a
	srl	a
	srl	a			; Divide by 8
	add	20
	and	$1f
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	a,l
	ld	[NextVisColAddr],a	; Store the calculated address of the next visible column
	ld	a,h
	ld	[NextVisColAddr+1],a
; Check if the landscape ended
	ld	a,[hl]
	inc	a			; A == $ff ?
	jr	nz,.prepnextcol		; No
	ld	[ScrollCurrent],a	; Stop scrolling
	jr	.skipscroll
.prepnextcol:
; Prepare next landscape column
	ld	hl,NextColumnAddr
	ld	e,[hl]
	inc	hl
	ld	d,[hl]			; Get NextColumnAddr
	ld	hl,$9800 + SCRN_VX_B * 2
	ld	a,[rSCX]
	srl	a
	srl	a
	srl	a			; Divide by 8
	dec	a
	and	$1f
	ld	c,a
	ld	b,0
	add	hl,bc			; HL now contains proper address on the background map
; Check if the landscape ended
	ld	a,[de]			; Get first tile of the landscape column
	inc	a			; Landscape end mark?
	jr	nz,.doprepnextcol	; No
	ld	[hl],$ff		; Put landscape end mark on the background map
	jr	.skipscroll
.doprepnextcol:
	call	PrepareLandscapeNext	; Draw the column
	ld	hl,NextColumnAddr
	ld	[hl],e
	inc	hl
	ld	[hl],d			; Store updated NextColumnAddr
; Analyse next visible column
	call	AnalyzeNextVisCol
.skipscroll:
; Process joypad
	ld	a,[JoypadData]
	ld	[JoypadDataPrev],a	; Store previous joypad data
	call	ReadJoypad
	ld	[JoypadData],a		; Store last joypad data read from port
; Check D-pad buttons
	ld	de,0
	bit	PADB_DOWN,a		; Down pressed?
	jr	z,.gamemainJoy1
	inc	e
.gamemainJoy1:
	bit	PADB_UP,a		; Up pressed?
	jr	z,.gamemainJoy2
	dec	e
.gamemainJoy2:
	bit	PADB_LEFT,a		; Left pressed?
	jr	z,.gamemainJoy3
	dec	d
.gamemainJoy3:
	bit	PADB_RIGHT,a		; Right pressed?
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
	cp	BoatWaterLevel		; Above water level?
	jr	nc,.gamemainTop		; No
	ld	a,BoatWaterLevel	; Fix to water level
.gamemainTop:
	cp	BoatLowerLevel		; Below lower level?
	jr	c,.gamemainBottom	; No
	ld	a,BoatLowerLevel	; Fix to lower level
.gamemainBottom:
	ldi	[hl],a			; Save updated Y position
	inc	l
	inc	l
	inc	l
	ld	[hl],a			; Save updated Y position for the 2nd sprite
.gamemainMove1:
; Analyse X movement delta value
	ld	a,d
	or	a
	jr	z,.gamemainMove2
	ld	hl,SpriteTable + 1
	ld	b,[hl]			; Get boat X position
	add	a,b
	cp	BoatLeftEdge		; Too left?
	jr	nc,.gamemainLeft	; No
	ld	a,BoatLeftEdge		; Fix to left position
.gamemainLeft:
	cp	BoatRightEdge		; Too right?
	jr	c,.gamemainRight	; No
	ld	a,BoatRightEdge		; Fix to right position
.gamemainRight:
	ldi	[hl],a			; Save updated X position
	inc	l
	inc	l
	inc	l
	add	a,8
	ld	[hl],a			; Save updated X position for the 2nd sprite
.gamemainMove2:
; Check if the START button just released
	ld	a,[JoypadData]
	bit	PADB_START,a		; Start button pressed?
	jr	nz,.gamemainNoStart	; Yes
	ld	a,[JoypadDataPrev]
	bit	PADB_START,a		; Start button was pressed?
	jp	nz,RestartMenuMode	; EXIT to menu
.gamemainNoStart:
;TODO: Checkif the SELECT button just released, implement Pause Mode 
; Update AirDelta/AirLevel values
	call	ChangeAirDelta
;TODO: if AirLevel is 0 then end the round
; Check if fire button just pressed
	ld	a,[JoypadData]
	bit	PADB_A,a		; "A" button pressed?
	jr	z,.gamemainNoFire	; No
	ld	a,[JoypadDataPrev]
	bit	PADB_A,a		; "A" button was pressed previously?
	jr	nz,.gamemainNoFire	; Yes
; Create a new torpedo object
	call	CreateNewTorpedo
.gamemainNoFire:
; Move objects: ship, mines, torpedos, bullets, bombs
	call	MoveObjects
; TODO: Check for collisions
; Draw current score value
	ld	a,[Score]
	ld	l,a
	ld	a,[Score+1]
	ld	h,a
	ld	bc, $9C00+SCRN_VX_B+2		; line 1, column 2
	call	PrintWord
; Show air level
	call	ShowAirLevel
; Wait for end of VBlank
.gamemainWaitVEnd:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	z,.gamemainWaitVEnd	; Yes, keep waiting
; Continue game main loop	
        jp      .gamemainloop2

;------------------------------------------------------------------------------
; DMA related code
InitDma:				; Prepare DMA code in HRAM
 	ld	de, DMACODELOC
 	ld	hl, DmaCode
 	ld	bc, DmaEnd - DmaCode
 	call	mem_CopyVRAM		; Copy when VRAM is available
 	ret
DmaCode:
 	push	af
 	ld	a, $C0			; Bank where OAM DATA is stored
 	ldh	[rDMA], a		; Start DMA
 	ld	a, $28			; 160ns
.dmawait:
 	dec	a
 	jr	nz, .dmawait
 	pop	af
 	ret
DmaEnd:

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
	ld	bc,SCRN_VX_B
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
.nlandscape2:
	ld	a,[de]
	ld	[hl],a
	inc	de
	push	bc
	ld	bc,SCRN_VX_B
	add	hl,bc
	pop	bc
	dec	b
	jr	nz,.nlandscape2
	ret

;------------------------------------------------------------------------------
; Input:  de - credits data starting address, hl - address on the screen
; Output: de - next credits column address
PrepareCreditsNext:
	ld	b,20
.prepcrednext1:
	ld	a,[de]
	inc	de
	cp	13
	jr	z,.prepcred13
	cp	10
	ret	z
	cp	$ff
	jr	z,.prepcredff
	ld	[hl],a
	inc	hl
	dec	b
	jr	nz,.prepcrednext1
	ret
.prepcred13:
	ld	a,b
	or	a
	ret	z
.prepcred13loop:
	ld	[hl],0
	inc	hl
	dec	b
	jr	nz,.prepcred13loop
	ret
.prepcredff:
	ld	de,CreditsData
	ret
	
;------------------------------------------------------------------------------
; Analyze next visible column
AnalyzeNextVisCol:
	ld	a,[NextVisColAddr]
	ld	l,a
	ld	a,[NextVisColAddr+1]
	ld	h,a
	ld	b,LandscapeRows
.analyzeloop:
	ld	a,[hl]
	cp	$0c			; Ship?
	jr	nz,.analyzeNotShip
	ld	[hl],$01		; Replace to water tile
	;TODO: Create a ship sprite
.analyzeNotShip:
; Next row
	push	bc
	ld	bc,SCRN_VX_B
	add	hl,bc
	pop	bc
	dec	b
	jr	nz,.analyzeloop
	ret

;------------------------------------------------------------------------------
; Update AirDelta/AirLevel values
ChangeAirDelta:
	ld	a,[AirLevel]
	ld	c,a
	ld	a,[AirDelta]
	ld	b,a
	ld	a,[SpriteTable]		; Get boat Y position
	cp	7+39			; Can the boat get fresh air?
	jr	nc,.updateairNoAir	; No
	inc	b
	ld	a,b
	cp	AirDeltaTop
	jr	c,.updateairFin
	ld	b,AirDeltaDefault
	inc	c
	jr	.updateairFin
.updateairNoAir:	
	dec	b
	jr	nz,.updateairFin
	ld	b,AirDeltaDefault
	dec	c
.updateairFin:
	ld	a,b
	ld	[AirDelta],a		; Save new AirDelta
	ld	a,c
	cp	AirLevelTop+1		; AirLevel is over the top level?
	jr	nc,.updateairSkipAir	; Yes
	ld	[AirLevel],a		; Save new AirLevel
.updateairSkipAir:
	ret

;------------------------------------------------------------------------------
; Update air level indicator
ShowAirLevel:
; Draw solid part
	ld	a,[AirLevel]
	srl	a
	srl	a
	srl	a			; Divide by 8
	ld	hl,$9c00+SCRN_VX_B*2+4
	jr	z,.airnosolid
	push	af
	ld	c,a
	ld	b,0
	ld	a,5			; Tile for air level
	call	mem_Set
	pop	af
.airnosolid:
; Draw empty space for (A-16) tiles
	push	hl			; Remember address for the reminder tile
	ld	c,a
	ld	a,16
	sub	c
	jr	z,.airnofiller
	ld	c,a
	ld	b,0
	xor	a			; Tile for empty space
	call	mem_Set
.airnofiller:
	pop	de
; Draw reminder
	ld	a,[AirLevel]
	and	$07
	ret	z			; have no reminder, finished
	ld	c,a
.airremloop:
	scf
	rra
	dec	c
	jr	nz,.airremloop
; Prepare tile for the reminder
	ld	hl,$8000+$15*16		; Tile number $15 address
	ld	c,a
	xor	a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ld	a,c
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	ldi	[hl],a
	xor	a
	ldi	[hl],a
	ldi	[hl],a
; Draw the reminder tile
	ld	a,$15
	ld	[de],a
	ret

;------------------------------------------------------------------------------
CreateNewTorpedo:
; Find an empty slot first
	ld	hl,SpriteTable+4*4	; Address of the first torpedo sprite
	ld	b,ObjTorpedoCount
.findtorpedoslot:
	ld	a,[hl]
	or	a
	jr	z,.preptorpedo
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	dec	b
	jr	nz,.findtorpedoslot
	ret				; No empty slots
; Prepare the torpedo sprite; HL is the sprite address
.preptorpedo:
	ld	a,[SpriteTable]		; Get boat Y position
	ldi	[hl],a			; Torpedo Y position
	ld	a,[SpriteTable+1]	; Get boat X position
	add	13			; Calculate torpedo initial X position
	ld	[hl],a			; Torpedo X position
	ret

;------------------------------------------------------------------------------
; Move objects: ship, mines, torpedos, bullets, bombs
MoveObjects:
; Move torpedos
	ld	hl,SpriteTable+4*4
	ld	b,ObjTorpedoCount
.movetorpedos:
	ld	a,[hl]		; Current Y position
	or	a		; Empty slot?
	jr	nz,.movetorpedo	; No
	inc	hl		; Skip the sprite
	inc	hl
	jr	.nexttorpedo
.movetorpedo:
	inc	hl		; No need to change Y position
	ld	a,[hl]		; Current X position
	add	a,2		; X increment
	ldi	[hl],a
	cp	160+8		; Out of the screen?
	jr	c,.nexttorpedo	; No
	xor	a
	dec	hl
	dec	hl
	ldi	[hl],a		; Clear X and Y position
	ldi	[hl],a
.nexttorpedo:
	inc	hl
	inc	hl
	dec	b
	jr	nz,.movetorpedos
;TODO: Move mines
	ret

;------------------------------------------------------------------------------
WaitVBlank:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,WaitVBlank
	ret

;------------------------------------------------------------------------------
;* End of File *

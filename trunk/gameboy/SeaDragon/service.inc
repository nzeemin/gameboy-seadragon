; Sea Dragon for GameBoy 
; Service routines

;------------------------------------------------------------------------------
WaitVBlank:
	ld	a,[rSTAT]		; Check Mode flags
	and	3
	cp	1			; VBlank?
	jr	nz,WaitVBlank
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
; Print word value as decimal number, five digits (00000-65535)
; Input:  hl - number to print, bc - address on the screen
; Uses:   af,de
PrintWord:
	ld	a,4		; Number of digits to print minus 1
.pdw1:
	push	bc
	push	hl
	ld	hl,PrintWordTable
	ld	b,0
	ld	c,a
	add	hl,bc
	add	hl,bc
	ld      e,[hl]		; Get next table value
	inc	hl
        ld      d,[hl]
        pop	hl
        pop	bc
; Loop for one digit
        push	af
        xor     a		; Clear counter and flag C
.pdw2:
	inc     a		; Increase counter
        add     hl,de		; Add table value
        jr      c,.pdw2    	; Repeat while hl>=0
        add     a,$30 - 1	; Translate to digit character
	ld	[bc],a		; Print the character
	inc	bc
; Substract DE from HL
	ld	a,l
	sub	e
	ld	l,a
	ld	a,h
	sbc	d
	ld	h,a
;
	pop	af
        dec	a
        jr	nz,.pdw1	; Digits loop
; Print the reminder
	ld	a,l
        add     a,$30		; Translate to digit character
	ld	[bc],a		; Print the character
	ret
PrintWordTable:
	DW	65536-1
	DW	65536-10
	DW	65536-100
	DW	65536-1000
	DW	65536-10000

;------------------------------------------------------------------------------

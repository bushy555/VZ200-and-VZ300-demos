; ************************************************
; SG56L_FIXED_V3.ASM
; VZ200 FIRE EFFECT (MODE 0)
;
; FIXES:
; 1) 16-bit LFSR whitened (no periodic black)
; 2) Palette latch safety
; 3) VRAM HARDENING (bit 7 forced ON)
;    -> left-arrow glyph now IMPOSSIBLE
; ************************************************

        ORG $8000

VRAM        EQU $7000
FIRE_BUF    EQU $A000
STACK	    EQU $C000

COLS        EQU 32
SCREEN_ROWS EQU 16
UPDATE_ROWS EQU 17

ROW17       EQU FIRE_BUF + (17*COLS)
ROW18       EQU FIRE_BUF + (18*COLS)

; --------------------------------------
START:
	di

        XOR A
        LD ($6800),A

; Clear VRAM
        LD HL,VRAM
        LD DE,VRAM+1
        LD BC,511
        LD (HL),0;32
        LDIR

; Clear fire buffer (17 rows)
        LD HL,FIRE_BUF
        LD DE,FIRE_BUF+1
        LD BC,607
        LD (HL),0
        LDIR

; --------------------------------------
MAIN:
        CALL RESEED
        CALL UPDATE
        CALL DRAW
        JP MAIN

; --------------------------------------
; RESEED (16-bit RNG, whitened)
; --------------------------------------
RESEED:
	exx
        LD HL,ROW18
        LD DE,ROW17
        LD B,COLS
RS_LOOP:

LFSR16: LD 	HL,(RAND16)
        LD 	A,L
        RRA
        LD 	L,A
        LD 	A,H
        RRA
        LD 	H,A
        JP 	NC,L16_SKIP
        LD 	A,L
        XOR 	$08
        LD 	L,A
        LD 	A,H
        XOR 	$D0
        LD 	H,A
L16_SKIP:
        LD 	(RAND16),HL
        LD 	A,L	

        LD C,A
        LD A,(RAND16+1)
        XOR C
        AND $10
        JP Z,RS_COLD
        LD A,32
        JP RS_STORE
RS_COLD:
        XOR A
RS_STORE:
        LD (HL),A
        LD (DE),A
        INC HL
        INC DE
        DEC B
        JP NZ,RS_LOOP
	exx

        RET





; --------------------------------------
; UPDATE
; --------------------------------------
UPDATE: LD HL,FIRE_BUF+1
        LD B,UPDATE_ROWS
UR_ROW: LD C,30
UR_COL: LD (WPTR),HL
        LD DE,COLS-1
        ADD HL,DE
        LD A,(HL)
        INC HL
        ADD A,(HL)
        INC HL
        ADD A,(HL)
        LD HL,(WPTR)
        LD DE,2*COLS
        ADD HL,DE
        ADD A,(HL)
        SRL A
        SRL A
        LD HL,(WPTR)
        LD (HL),A
        INC HL
        DEC C
        JP NZ,UR_COL
        INC HL
        INC HL
        DEC B
        JP NZ,UR_ROW
        RET

; --------------------------------------
; DRAW (SAFE + HARDENED)
; --------------------------------------
DRAW:   LD 	DE,FIRE_BUF
        LD 	HL,VRAM
        LD 	B,SCREEN_ROWS
DR_ROW: LD 	C,COLS
DR_COL: LD 	A,(DE)
        INC 	DE
        AND 	$1F
        PUSH 	HL
        LD 	H,HIGH(PALMAP)
        LD 	L,A
        LD 	A,(HL)
        POP 	HL
        LD 	(HL),A
        INC 	HL
        DEC 	C
        JP 	NZ,DR_COL
        DEC 	B
        JP 	NZ,DR_ROW
        RET



; --------------------------------------
RAND16: DW $ACE1
WPTR:   DW $0000

; --------------------------------------
        ORG ($+$FF) & $8F00 


black		equ $80	; 128
dk_orange	equ $20	; 32
br_orange	equ $60	; 96
green		equ $8f	; 143
yellow		equ $9f	; 159
blue		equ $af	; 175
red		equ $bf	; 191
buff		equ $cf	; 207
cyan		equ $df	; 223
magenta		equ $ef	; 239
orange		equ $ff	; 255

PALMAP:
        DB 	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80	; Black x10
 	db 	red
	db 	red
	db 	orange
	db 	orange
	db 	orange
	db 	yellow
	db 	yellow
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff
	db 	buff

; ============================================================
; DOOM FIRE effect for VZ200 / VZ300 -- FLICKER SOURCE variant
; MODE(0): 32x16 colour blocks, VRAM $7000-$71FF
; ORG $8000, SP $F000
; PASMO assembler
; ============================================================
;
; CHANGE vs df1.asm: Flickering source row
;
;   Previously FILL_SOURCE seeded every cell of the bottom row
;   every frame (75% BUFF, 25% YELLOW) -- a mostly solid base.
;
;   Now each cell is independently tested:
;     RND8 & 3 == 0  (25%)  -> leave cell BLACK (skip it)
;     RND8 & 3 == 1,2 (50%) -> BUFF  (white-hot)
;     RND8 & 3 == 3  (25%)  -> YELLOW
;
;   Skipping ~25% of source cells each frame means the base
;   breaks up into a jagged, organic line rather than a solid
;   wall, and the pattern changes every frame -- giving the
;   classic flickering fire-at-the-base look.
;
; Palette (unchanged, authentic DOOM colours):
;   BLACK  $80  background / off
;   RED    $BF  coolest visible flame
;   ORANGE $FF  mid flame
;   YELLOW $9F  hot
;   BUFF   $CF  white-hot (source)
;
; Cooling chain: BUFF -> YELLOW -> ORANGE -> RED -> BLACK
;
; ============================================================

        ORG     $8000

VRAM            EQU     $7000
;BUFFER		EQU	$8800
WIDTH           EQU     32
HEIGHT          EQU     16

BLACK_BLOCK     EQU     $80
RED_BLOCK       EQU     $BF
ORANGE_BLOCK    EQU     $FF
YELLOW_BLOCK    EQU     $9F
BUFF_BLOCK      EQU     $CF

; ============================================================
; ENTRY
; ============================================================
START:
        DI

        XOR     A
        LD      ($6800),A

        LD      HL,BUFFER
        LD      A,BLACK_BLOCK
        LD      (HL),A
        LD      DE,BUFFER+1
        LD      BC,512-1
        LDIR

; ============================================================
; MAIN LOOP
; ============================================================
MAIN_LOOP:
        CALL    FILL_SOURCE
        CALL    PROPAGATE

vbloop
                ld a,($6800)
                rla
                jr nc,vbloop



	LD	HL, BUFFER
	LD	DE, VRAM
	LD	BC, 2048

Copy2048_64LDI:	    ; 2048 / 64 = 32 iterations
Copy64_loop:
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    jp      pe, Copy64_loop





        JP      MAIN_LOOP

; ============================================================
; FILL_SOURCE
; Seeds the bottom row (row 15) with flickering fire.
;
; Each cell is tested independently each frame:
;   AND 3 == 0  (25%) -> BLACK  (gap / flicker)
;   AND 3 == 1  (25%) -> BUFF   (white-hot)
;   AND 3 == 2  (25%) -> BUFF   (white-hot)
;   AND 3 == 3  (25%) -> YELLOW (hot but not peak)
;
; The random gaps shift every frame, producing the organic
; flickering base characteristic of real fire.
; ============================================================
FILL_SOURCE:
        LD      HL,BUFFER + 15 * WIDTH		; VRAM+15*WIDTH
        LD      A,WIDTH
        LD      (FSCNT),A

FS_LOOP:
        CALL    RND8
        AND     3
        CP      0
        JP      Z,FS_BLACK      ; 25% gap -> leave black
        CP      3
        JP      Z,FS_YELLOW     ; 25% yellow
        LD      A,BUFF_BLOCK    ; 50% white-hot
        JP      FS_STORE
FS_BLACK:
        LD      A,BLACK_BLOCK
        JP      FS_STORE
FS_YELLOW:
        LD      A,YELLOW_BLOCK
FS_STORE:
        LD      (HL),A
        INC     HL
        LD      A,(FSCNT)
        DEC     A
        LD      (FSCNT),A
        JP      NZ,FS_LOOP
        RET

; ============================================================
; PROPAGATE
; For each cell in rows 0-14, read from the row below,
; optionally cool one step, write with random +-1 col drift.
;
;   HL = destination (rows 0..14, starts VRAM)
;   DE = source      (rows 1..15, starts VRAM+WIDTH)
;   BC = cells remaining (15*32 = 480)
;   COL = current column 0..31 (memory)
; ============================================================
PROPAGATE:
        LD      HL,BUFFER; VRAM
        LD      DE,BUFFER + WIDTH	; VRAM+WIDTH
        LD      BC,15*WIDTH
        XOR     A
        LD      (COL),A

PROP_LOOP:
        LD      A,(DE)
        LD      (TEMP),A

        CP      BLACK_BLOCK
        JP      Z,NO_COOL

        CALL    RND8
        BIT     3,A
        JP      Z,NO_COOL

        LD      A,(TEMP)
        CP      BUFF_BLOCK
        JP      Z,COOL_YELLOW
        CP      YELLOW_BLOCK
        JP      Z,COOL_ORANGE
        CP      ORANGE_BLOCK
        JP      Z,COOL_RED
        LD      A,BLACK_BLOCK
        JP      COOL_DONE
COOL_YELLOW:
        LD      A,YELLOW_BLOCK
        JP      COOL_DONE
COOL_ORANGE:
        LD      A,ORANGE_BLOCK
        JP      COOL_DONE
COOL_RED:
        LD      A,RED_BLOCK
COOL_DONE:
        LD      (TEMP),A

NO_COOL:CALL    RND8
        AND     3
        CP      0
        JP      Z,TRY_LEFT
        CP      2
        JP      Z,TRY_RIGHT

CENTER: LD      A,(TEMP)
        LD      (HL),A
        JP      WRITE_DONE

TRY_LEFT:
        LD      A,(COL)
        OR      A
        JP      Z,CENTER
        DEC     HL
        LD      A,(TEMP)
        LD      (HL),A
        INC     HL
        JP      WRITE_DONE

TRY_RIGHT:
        LD      A,(COL)
        CP      WIDTH-1
        JP      Z,CENTER
        INC     HL
        LD      A,(TEMP)
        LD      (HL),A
        DEC     HL

WRITE_DONE:
        INC     HL
        INC     DE

        LD      A,(COL)
        INC     A
        CP      WIDTH
        JP      NZ,STORE_COL
        XOR     A
STORE_COL:
        LD      (COL),A

        DEC     BC
        LD      A,B
        OR      C
        JP      NZ,PROP_LOOP
        RET


; ============================================================
; RND8
; Returns pseudo-random byte in A.  Clobbers A ONLY.
; ============================================================
RND8:
        LD      A,(SEED)
        RRCA
        RRCA
        RRCA
        XOR     $1F
        LD      (RNDSCRATCH),A
        LD      A,(SEED)
        PUSH    HL
        LD      HL,RNDSCRATCH
        ADD     A,(HL)
        POP     HL
        LD      (SEED),A
        RET

; ============================================================
; DATA
; ============================================================
SEED:           DB      $A7
TEMP:           DB      0
RNDSCRATCH:     DB      0
COL:            DB      0
FSCNT:          DB      0

BUFFER	equ	$

        END

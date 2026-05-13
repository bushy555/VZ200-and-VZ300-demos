; ============================================================
; DOOM FIRE effect for VZ200 / VZ300
; MODE(0): 32x16 colour blocks, VRAM $7000-$71FF
; ORG $8000, SP $F000
; PASMO assembler
; ============================================================
;
; PALETTE FIX: Authentic DOOM fire colours
;
;   The original DOOM fire (PSX, 1994) uses NO green.
;   Its palette runs strictly from black (cold) through red,
;   orange, yellow, up to white/buff (white-hot at source).
;
;   The previous version used GREEN ($8F) as the background /
;   "off" colour, causing green to saturate the display.
;
;   VZ200 MODE(0) block colour ranges (decimal / hex):
;     GREEN:   129-144  $81-$90   <- NOT used (was wrong bg)
;     YELLOW:  145-160  $91-$A0
;     BLUE:    161-176  $A1-$B0   <- NOT used
;     RED:     177-192  $B1-$C0
;     BUFF:    193-208  $C1-$D0   (cream/white -- hottest)
;     CYAN:    209-224  $D1-$E0   <- NOT used
;     MAGENTA: 225-240  $E1-$F0   <- NOT used
;     ORANGE:  241-255  $F1-$FF
;
;   $80 (128) is below the graphics block range and renders as
;   a plain space character -- which is black on the VZ200.
;   We use it as our BLACK / background value.
;
;   Authentic DOOM fire palette (cold -> hot):
;     BLACK  = $80   off / background
;     RED    = $BF   coolest visible flame
;     ORANGE = $FF   mid flame
;     YELLOW = $9F   hot
;     BUFF   = $CF   white-hot source row (hottest)
;
;   Cooling chain (hot -> cold):
;     BUFF -> YELLOW -> ORANGE -> RED -> BLACK
;
;   Source row seeded mostly BUFF, some YELLOW -- matching the
;   original DOOM solid white-hot bottom row.
;
; ============================================================

        ORG     $8000

VRAM            EQU     $7000
WIDTH           EQU     32
HEIGHT          EQU     16

; Authentic DOOM fire palette -- NO GREEN, NO BLUE, NO CYAN:
BLACK_BLOCK     EQU     $80     ; Black  (space = black bg)
RED_BLOCK       EQU     $BF     ; Red    (coolest visible flame)
ORANGE_BLOCK    EQU     $FF     ; Orange (mid flame)
YELLOW_BLOCK    EQU     $9F     ; Yellow (hot)
BUFF_BLOCK      EQU     $CF     ; Buff   (white-hot, source row)

; ============================================================
; ENTRY
; ============================================================
START:
        DI
        LD      SP,$F000

        ; Enter MODE(0)
        XOR     A
        LD      ($6800),A

        ; Clear all 512 VRAM bytes to BLACK_BLOCK
        LD      HL,VRAM
        LD      A,BLACK_BLOCK
        LD      (HL),A
        LD      DE,VRAM+1
        LD      BC,512-1
        LDIR

; ============================================================
; MAIN LOOP
; ============================================================
MAIN_LOOP:
        CALL    FILL_SOURCE
        CALL    PROPAGATE
;        CALL    FRAME_DELAY
        JP      MAIN_LOOP

; ============================================================
; FILL_SOURCE
; Seeds the bottom row (row 15) with hot fire colours.
; Biased heavily toward BUFF (white-hot) to match the original
; DOOM solid-white source row, with occasional YELLOW falloff.
; Uses memory counter FSCNT -- safe against RND8 clobbering B.
; ============================================================
FILL_SOURCE:
        LD      HL,VRAM+15*WIDTH
        LD      A,WIDTH
        LD      (FSCNT),A

FS_LOOP:
        CALL    RND8
        AND     3
        ; 0,1,2 -> BUFF (75% white-hot), 3 -> YELLOW (25%)
        ; Gives a strong solid base like original DOOM.
        CP      3
        JP      Z,FS_YELLOW
        LD      A,BUFF_BLOCK
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
;
; Cooling chain matches original DOOM (hot -> cold):
;   BUFF -> YELLOW -> ORANGE -> RED -> BLACK
; ============================================================
PROPAGATE:
        LD      HL,VRAM
        LD      DE,VRAM+WIDTH
        LD      BC,15*WIDTH
        XOR     A
        LD      (COL),A

PROP_LOOP:
        ; Read pixel from row below
        LD      A,(DE)
        LD      (TEMP),A

        ; Already black? No cooling possible
        CP      BLACK_BLOCK
        JP      Z,NO_COOL

        ; ~50% chance to cool (test bit 3)
        CALL    RND8
        BIT     3,A
        JP      Z,NO_COOL

        ; Cool one step along DOOM palette chain:
        ; BUFF -> YELLOW -> ORANGE -> RED -> BLACK
        LD      A,(TEMP)
        CP      BUFF_BLOCK
        JP      Z,COOL_YELLOW
        CP      YELLOW_BLOCK
        JP      Z,COOL_ORANGE
        CP      ORANGE_BLOCK
        JP      Z,COOL_RED
        LD      A,BLACK_BLOCK   ; RED or unknown -> BLACK
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

NO_COOL:
        ; Random horizontal drift: 0=left  1,3=centre  2=right
        CALL    RND8
        AND     3
        CP      0
        JP      Z,TRY_LEFT
        CP      2
        JP      Z,TRY_RIGHT

CENTER:
        LD      A,(TEMP)
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

        ; Advance column, wrap at WIDTH
        LD      A,(COL)
        INC     A
        CP      WIDTH
        JP      NZ,STORE_COL
        XOR     A
STORE_COL:
        LD      (COL),A

        ; Count down and loop
        DEC     BC
        LD      A,B
        OR      C
        JP      NZ,PROP_LOOP
        RET


; ============================================================
; RND8
; Returns pseudo-random byte in A.  Clobbers A ONLY.
; Uses PUSH/POP HL so ADD A,(HL) can reach RNDSCRATCH
; without touching B, C, D, E, or permanently altering HL.
;
;   new_seed = seed + ((seed RRCA RRCA RRCA) XOR $1F)
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
; DATA  (all DB at end of file)
; ============================================================
TEMP:           DB      0
RNDSCRATCH:     DB      0
COL:            DB      0
FSCNT:          DB      0
SEED:           DB      $A7

        END

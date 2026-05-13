; ============================================================
; VZ200 / VZ300  MODE(1)  Shadebob - Double Figure-Eight
; ORG $8000   VRAM $7000   Stack $F000
;
; Two glowing blobs trace a figure-8 (Lissajous 1:2) path.
; Movement is 1-pixel-at-a-time for smooth motion.
;
; --- Bugs fixed from a.asm / b.asm ---
;
; BUG 1 (both files) - SetPixel color register clobbered:
;   After the MaskTable lookup, C had been overwritten with
;   the bit-position (x&3).  The ColorShiftTable was then
;   indexed with that wrong value, giving garbage colors.
;   Fix: save color early into a dedicated variable (BLOBCOL)
;   and reload it cleanly at the point of the table lookup.
;
; BUG 2 (b.asm) - SetPixel bitpos lost after ADD HL,DE:
;   Code stored bitpos in L, then did LD HL,MaskTable /
;   ADD HL,DE, overwriting L with the low byte of the table
;   address.  Then LD A,L read the wrong value for the
;   ColorShiftTable index.
;   Fix: same as above - keep bitpos in a RAM variable.
;
; BUG 3 (a.asm) - Screen never cleared between frames:
;   The main loop only ORed new pixels onto old ones, so the
;   screen filled solid immediately.
;   Fix: clear VRAM at the start of every frame, then redraw
;   the full tail.
;
; BUG 4 (both files) - Coarse movement (phase step 3..9):
;   A step of 3 into a 64-entry table jumps ~18 pixels per
;   frame.  Step 1 gives max 3-pixel movement per frame.
;   Fix: phase always increments by 1 each frame (step=1).
;
; --- Design ---
;
; Figure-8 path: X = SIN_X[phase], Y = SIN_Y[phase]
;   SIN_X is a 128-entry sine wave, range 6..118 (for x)
;   SIN_Y is a 128-entry double-frequency sine, range 6..54 (for y)
;   phase increments by 1 each frame -> period = 128 frames
;
; Two snakes: snake 2 starts at phase+64 (half period offset)
;   so they trace opposite lobes of the figure-8 simultaneously.
;
; Tail length = 96 entries.  Each entry stores (x,y) only.
; Color is computed from tail position at draw time:
;   oldest 24 entries -> green  (color 0, darkest)
;   next   24 entries -> blue   (color 2)
;   next   24 entries -> yellow (color 1)
;   newest 24 entries -> red    (color 3, brightest)
; Draw order: oldest first, so newest pixel overwrites on top.
; This creates the classic glowing trail effect.
;
; Each blob is a single pixel (the shadebob "glow" comes from
; the overlapping gradient tail, not a fat sprite).
; ============================================================

            ORG     $8000

TAIL_LEN    EQU     96          ; entries per snake ring buffer
VRAM        EQU     $7000
LATCH       EQU     $6800
BUFFER	    EQU     $9000
Start:
;            LD      SP,$F000

            LD      A,8
            LD      (LATCH),A       ; MODE(1)
	di
            CALL    ClearVRAM

; --- Initialise snake state ---

            XOR     A
            LD      (PHASE1),A      ; snake 1 phase = 0

            LD      A,64
            LD      (PHASE2),A      ; snake 2 phase = 64 (half period)

            XOR     A
            LD      (T1W),A         ; tail 1 write pointer
            LD      (T2W),A         ; tail 2 write pointer

; Pre-fill tails with starting position so there are no stale zeros
            LD      A,(PHASE1)
            CALL    GetXY1          ; sets X1, Y1 from PHASE1
            LD      A,(PHASE2)
            CALL    GetXY2          ; sets X2, Y2 from PHASE2

            LD      B,TAIL_LEN
PrefillLoop:
            PUSH    BC
            CALL    PushTail1
            CALL    PushTail2
            POP     BC
            DEC     B
            JP      NZ,PrefillLoop

	di
; ============================================================
; Main loop
; ============================================================
MainLoop:

; -- Advance phase --
            LD      A,(PHASE1)
            INC     A
            AND     127             ; mod 128
            LD      (PHASE1),A

            LD      A,(PHASE2)
            INC     A
            AND     127
            LD      (PHASE2),A

; -- Compute new head positions --
            LD      A,(PHASE1)
            CALL    GetXY1

            LD      A,(PHASE2)
            CALL    GetXY2

; -- Push new positions into tail ring buffers --
            CALL    PushTail1
            CALL    PushTail2


	ld	HL, BUFFER
	ld	DE, VRAM
	ld	bc, 2048
	ldir


;	ld	hl, BUFFER
;	ld	de, BUFFER+1
;	ld	(hl), 0
;	ld	bc, 2048
;	ldir

; -- Draw both tails, oldest first (darkest under brightest) --
            CALL    DrawTail1
            CALL    DrawTail2

            JP      MainLoop

; ============================================================
; GetXY1: look up X1,Y1 from PHASE1 (passed in A)
; ============================================================
GetXY1:
            LD      E,A
            LD      D,0
            LD      HL,SIN_X
            ADD     HL,DE
            LD      A,(HL)
            LD      (X1),A

            LD      A,(PHASE1)
            LD      E,A
            LD      D,0
            LD      HL,SIN_Y
            ADD     HL,DE
            LD      A,(HL)
            LD      (Y1),A
            RET

; ============================================================
; GetXY2: look up X2,Y2 from PHASE2 (passed in A)
; ============================================================
GetXY2:
            LD      E,A
            LD      D,0
            LD      HL,SIN_X
            ADD     HL,DE
            LD      A,(HL)
            LD      (X2),A

            LD      A,(PHASE2)
            LD      E,A
            LD      D,0
            LD      HL,SIN_Y
            ADD     HL,DE
            LD      A,(HL)
            LD      (Y2),A
            RET

; ============================================================
; PushTail1: write (X1,Y1) into tail1 ring buffer at T1W
; ============================================================
PushTail1:
            LD      A,(T1W)
            LD      B,A             ; B = write index

            LD      HL,TAIL1_X
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(X1)
            LD      (HL),A

            LD      HL,TAIL1_Y
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(Y1)
            LD      (HL),A

            LD      A,(T1W)
            INC     A
            CP      TAIL_LEN
            JP      C,PT1NoWrap
            XOR     A
PT1NoWrap:
            LD      (T1W),A
            RET

; ============================================================
; PushTail2: write (X2,Y2) into tail2 ring buffer at T2W
; ============================================================
PushTail2:
            LD      A,(T2W)
            LD      B,A

            LD      HL,TAIL2_X
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(X2)
            LD      (HL),A

            LD      HL,TAIL2_Y
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(Y2)
            LD      (HL),A

            LD      A,(T2W)
            INC     A
            CP      TAIL_LEN
            JP      C,PT2NoWrap
            XOR     A
PT2NoWrap:
            LD      (T2W),A
            RET

; ============================================================
; DrawTail1: draw all TAIL_LEN entries, oldest first
;
; The write pointer T1W points to the NEXT slot to write,
; so the OLDEST entry is at T1W (it was overwritten least
; recently in the previous cycle) and the NEWEST is at T1W-1.
;
; We walk:  start = T1W, count = TAIL_LEN
; Color from position in walk (0=oldest=darkest):
;   walk 0..23  -> color 0 (green)
;   walk 24..47 -> color 2 (blue)
;   walk 48..71 -> color 1 (yellow)
;   walk 72..95 -> color 3 (red)
; ============================================================
DrawTail1:
            LD      A,(T1W)
            LD      (DT_IDX),A      ; current ring index
            LD      A,TAIL_LEN
            LD      (DT_CNT),A      ; entries left to draw
            XOR     A
            LD      (DT_POS),A      ; position in walk (0=oldest)

DT1_Loop:
            LD      A,(DT_CNT)
            OR      A
            JP      Z,DT1_Done

            ; fetch x,y at DT_IDX
            LD      A,(DT_IDX)
            LD      B,A

            LD      HL,TAIL1_X
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(HL)
            LD      (TMPX),A

            LD      HL,TAIL1_Y
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(HL)
            LD      (TMPY),A

            ; compute color from DT_POS
            CALL    PosToColor      ; returns color in A

            LD      (TMPC),A

            ; plot single pixel
            LD      A,(TMPX)
            LD      D,A
            LD      A,(TMPY)
            LD      E,A
            LD      A,(TMPC)
            LD      C,A
            CALL    SetPixel

            ; advance ring index
            LD      A,(DT_IDX)
            INC     A
            CP      TAIL_LEN
            JP      C,DT1_NoWrap
            XOR     A
DT1_NoWrap:
            LD      (DT_IDX),A

            ; advance walk position
            LD      A,(DT_POS)
            INC     A
            LD      (DT_POS),A

            ; decrement count
            LD      A,(DT_CNT)
            DEC     A
            LD      (DT_CNT),A

            JP      DT1_Loop
DT1_Done:
            RET

; ============================================================
; DrawTail2: same as DrawTail1 but for tail2
; ============================================================
DrawTail2:
            LD      A,(T2W)
            LD      (DT_IDX),A
            LD      A,TAIL_LEN
            LD      (DT_CNT),A
            XOR     A
            LD      (DT_POS),A

DT2_Loop:
            LD      A,(DT_CNT)
            OR      A
            JP      Z,DT2_Done

            LD      A,(DT_IDX)
            LD      B,A

            LD      HL,TAIL2_X
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(HL)
            LD      (TMPX),A

            LD      HL,TAIL2_Y
            LD      E,B
            LD      D,0
            ADD     HL,DE
            LD      A,(HL)
            LD      (TMPY),A

            CALL    PosToColor
            LD      (TMPC),A

            LD      A,(TMPX)
            LD      D,A
            LD      A,(TMPY)
            LD      E,A
            LD      A,(TMPC)
            LD      C,A
            CALL    SetPixel

            LD      A,(DT_IDX)
            INC     A
            CP      TAIL_LEN
            JP      C,DT2_NoWrap
            XOR     A
DT2_NoWrap:
            LD      (DT_IDX),A

            LD      A,(DT_POS)
            INC     A
            LD      (DT_POS),A

            LD      A,(DT_CNT)
            DEC     A
            LD      (DT_CNT),A

            JP      DT2_Loop
DT2_Done:
            RET

; ============================================================
; PosToColor: map DT_POS (0=oldest .. TAIL_LEN-1=newest)
;             to VZ200 color index (0=green,1=yellow,2=blue,3=red)
;
; Bands (TAIL_LEN=96, bands of 24):
;   pos  0..23 -> 0 (green,  darkest)
;   pos 24..47 -> 2 (blue)
;   pos 48..71 -> 1 (yellow)
;   pos 72..95 -> 3 (red,    brightest)
;
; Returns color in A.  Preserves BC,DE,HL.
; ============================================================
PosToColor:
            LD      A,(DT_POS)
            CP      24
            JP      C,PTC_Green
            CP      48
            JP      C,PTC_Blue
            CP      72
            JP      C,PTC_Yellow
            LD      A,3             ; red
            RET
PTC_Yellow:
            LD      A,1
            RET
PTC_Blue:
            LD      A,2
            RET
PTC_Green:
            XOR     A
            RET

; ============================================================
; SetPixel: plot one MODE(1) 2bpp pixel
;   In:  D=x (0..127), E=y (0..63), C=color (0..3)
;   All registers preserved except A.
;
; FIX vs a.asm: color (C) was clobbered by the bitpos value
;   during the MaskTable lookup; C was never reloaded before
;   the ColorShiftTable lookup.
; FIX vs b.asm: bitpos was stored in L, then lost when
;   HL was used to address MaskTable.
; SOLUTION: save bitpos and color into RAM variables
;   (SP_BPOS, SP_COL) at entry and reload as needed.
;   A-for-absolute rule observed throughout.
; ============================================================
SetPixel:
            PUSH    BC
            PUSH    DE
            PUSH    HL

            ; save color (C), x (D), y (E), bitpos (x&3) before any clobber
            LD      A,C
            LD      (SP_COL),A      ; save color
            LD      A,D
            LD      (SP_X),A        ; save x
            LD      A,E
            LD      (SP_Y),A        ; save y
            LD      A,D
            AND     3
            LD      (SP_BPOS),A     ; save bit position (0..3)

            ; --- fetch clear-mask from MaskTable[bitpos] ---
            LD      E,A             ; E = bitpos
            LD      D,0
            LD      HL,MaskTable
            ADD     HL,DE
            LD      A,(HL)
            LD      (SP_MASK),A     ; save mask

            ; --- fetch color bits from ColorShiftTable[bitpos*4 + color] ---
            LD      A,(SP_BPOS)
            RLCA
            RLCA                    ; A = bitpos * 4
            LD      E,A
            LD      D,0
            LD      HL,ColorShiftTable
            ADD     HL,DE           ; HL -> row for this bitpos
            LD      A,(SP_COL)      ; reload color (0..3)  <- THE FIX
            LD      E,A
            LD      D,0
            ADD     HL,DE           ; HL -> ColorShiftTable[bitpos*4 + color]
            LD      A,(HL)
            LD      (SP_CBITS),A    ; save color bits

            ; --- compute VRAM address: $7000 + y*32 + (x>>2) ---
            LD      A,(SP_Y)
            LD      L,A
            LD      H,0             ; HL = y
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL           ; HL = y * 32

            LD      A,(SP_X)        ; A = x
            SRL     A
            SRL     A               ; A = x >> 2  (byte column)
            LD      E,A
            LD      D,0
            ADD     HL,DE
            LD      DE,BUFFER; VRAM
            ADD     HL,DE           ; HL = VRAM + y*32 + (x>>2)

            ; --- read-modify-write ---
            LD      A,(HL)
            LD      B,A
            LD      A,(SP_MASK)
            AND     B               ; clear the 2-bit pixel field
            LD      B,A
            LD      A,(SP_CBITS)
            OR      B               ; insert new color bits
            LD      (HL),A

            POP     HL
            POP     DE
            POP     BC
            RET

; ============================================================
; ClearVRAM: fill $7000..$77FF with 0 (all green, MODE 1)
; ============================================================
ClearVRAM:
            LD      HL,VRAM
            LD      DE,VRAM+1
            LD      BC,2047
            LD      (HL),0
            LDIR
            RET

; ============================================================
; Variables
; ============================================================

PHASE1:     DB      0
PHASE2:     DB      0
X1:         DB      0
Y1:         DB      0
X2:         DB      0
Y2:         DB      0
T1W:        DB      0
T2W:        DB      0
TMPX:       DB      0
TMPY:       DB      0
TMPC:       DB      0
DT_IDX:     DB      0
DT_CNT:     DB      0
DT_POS:     DB      0
SP_COL:     DB      0
SP_BPOS:    DB      0
SP_X:       DB      0
SP_Y:       DB      0
SP_MASK:    DB      0
SP_CBITS:   DB      0

TAIL1_X:    DEFS    TAIL_LEN,0
TAIL1_Y:    DEFS    TAIL_LEN,0
TAIL2_X:    DEFS    TAIL_LEN,0
TAIL2_Y:    DEFS    TAIL_LEN,0

; ============================================================
; Tables
; ============================================================

; SIN_X: 128-entry sine, range 6..118
; x(phase) = 62 + 56*sin(phase * 2*PI / 128)
; Max x jump between adjacent frames = 3 pixels
SIN_X:
            DB      62,65,67,70,73,76,78,81
            DB      83,86,88,91,93,95,98,100
            DB      102,103,105,107,109,110,111,113
            DB      114,115,116,116,117,117,118,118
            DB      118,118,118,117,117,116,116,115
            DB      114,113,111,110,109,107,105,103
            DB      102,100,98,95,93,91,88,86
            DB      83,81,78,76,73,70,67,65
            DB      62,59,57,54,51,48,46,43
            DB      41,38,36,33,31,29,26,24
            DB      22,21,19,17,15,14,13,11
            DB      10,9,8,8,7,7,6,6
            DB      6,6,6,7,7,8,8,9
            DB      10,11,13,14,15,17,19,21
            DB      22,24,26,29,31,33,36,38
            DB      41,43,46,48,51,54,57,59

; SIN_Y: 128-entry double-frequency sine, range 6..54
; y(phase) = 30 + 24*sin(phase * 4*PI / 128)
; Combined with SIN_X at step 1, this traces a figure-8
; Max y jump between adjacent frames = 3 pixels
SIN_Y:
            DB      30,32,35,37,39,41,43,45
            DB      47,49,50,51,52,53,54,54
            DB      54,54,54,53,52,51,50,49
            DB      47,45,43,41,39,37,35,32
            DB      30,28,25,23,21,19,17,15
            DB      13,11,10,9,8,7,6,6
            DB      6,6,6,7,8,9,10,11
            DB      13,15,17,19,21,23,25,28
            DB      30,32,35,37,39,41,43,45
            DB      47,49,50,51,52,53,54,54
            DB      54,54,54,53,52,51,50,49
            DB      47,45,43,41,39,37,35,32
            DB      30,28,25,23,21,19,17,15
            DB      13,11,10,9,8,7,6,6
            DB      6,6,6,7,8,9,10,11
            DB      13,15,17,19,21,23,25,28

; MaskTable[bitpos]: clear mask for 2-bit pixel at bit position 0..3
;   pos0 bits7..6: mask = $3F
;   pos1 bits5..4: mask = $CF
;   pos2 bits3..2: mask = $F3
;   pos3 bits1..0: mask = $FC
MaskTable:
            DB      $3F,$CF,$F3,$FC

; ColorShiftTable[bitpos*4 + color]: pre-shifted 2-bit color value
; color: 0=green, 1=yellow, 2=blue, 3=red
ColorShiftTable:
; pos0 bits7..6
            DB      %00000000,%01000000,%10000000,%11000000
; pos1 bits5..4
            DB      %00000000,%00010000,%00100000,%00110000
; pos2 bits3..2
            DB      %00000000,%00000100,%00001000,%00001100
; pos3 bits1..0
            DB      %00000000,%00000001,%00000010,%00000011

            END     Start

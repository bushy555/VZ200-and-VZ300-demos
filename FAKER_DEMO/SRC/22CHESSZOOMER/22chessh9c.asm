
; ============================================================
; VZ200 MODE(1) 128x64 4-color
; 2bpp codes: 00=Green, 01=Yellow, 10=Blue, 11=Red
; Smooth Zooming Checkerboard anchored at (64,32)
; Zoom range: 2x2 <-> 64x64
;  - 2x2 uses half-byte patterns (left/right nibbles)
;  - >=4x4 uses solid bytes
; Color schemes (12 pairs): G-Y, G-B, G-R, Y-G, Y-B, Y-R, B-G, B-Y, B-R, R-G, R-Y, R-B
; ROTATION RULE (updated):
;   During ZOOM-IN at the 4x4 frame (N=1):
;     Next frame -> 2x2 SAME color (HB_PHASE=1)
;     Next frame -> 2x2 NEXT color (HB_PHASE=2, rotate here)
;     Next frame -> back to 4x4, then continue zoom-in (N=2...)
; PASMO constraints:
;   ORG $8000, VRAM $7000 (2048 bytes), LATCH $6800, BASIC $7AE9
;   JP only; no JR; no DJNZ; all mem I/O via A; one op per line
;   No illegal pair arithmetic; all DEFB/DB at end; SP=$B000
; ============================================================
        ORG     $8000

; ---------- Hardware ----------
LATCH_IO        EQU     $6800
VRAM            EQU     $a000       ;$7000

ROWS            EQU     64
COL_BYTES       EQU     32

; ============================================================
; Entry / Setup
; ============================================================
START:
        LD      SP,$B000
        DI
        LD      A,8
        LD      (LATCH_IO),A

; Optional clear VRAM (2048 bytes)
        LD      HL,VRAM
        LD      DE,2048
        XOR     A
CLRV_LOOP:
        LD      (HL),A
        INC     HL
        DEC     DE
        LD      A,D
        OR      E
        JP      NZ,CLRV_LOOP
        XOR     A

; Initial zoom state
        LD      A,1
        LD      (N_BYTES),A         ; N=1 -> 4x4 (byte-mode minimum)
        LD      (ZOOM_DIR),A        ; +1 (zooming in)

        XOR     A
        LD      (HB_MODE),A         ; 0=byte-mode (>=4x4), 1=2x2
        LD      (HB_PHASE),A        ; 0=inactive, 1=same-color 2x2, 2=rotated-color 2x2

; Initial color scheme index and derived bytes
        XOR     A
        LD      (COL_IDX),A         ; start at G-Y
        CALL    SET_COLORS_FROM_IDX

; ============================================================
; Main frame loop
; ============================================================
MAIN_LOOP:
; Optional vertical retrace wait
        PUSH    HL
        LD      HL,$6800
VBWAIT0:
        BIT     7,(HL)
        JP      NZ,VBWAIT0
        POP     HL

; ---- Per-frame vertical unit: H = 4*N (byte-mode) or 2 (2x2)
        LD      A,(HB_MODE)
        OR      A
        JP      Z,CALC_H_BYTE

; HB mode (2x2): H = 2 rows per color block
        LD      A,2
        LD      (Y_LIMIT),A
        JP      CALC_OFFSETS

CALC_H_BYTE:
        LD      A,(N_BYTES)         ; A=N
        LD      C,A                 ; C=N (keep for horizontal)
        ADD     A,A                 ; 2N
        ADD     A,A                 ; 4N
        LD      (Y_LIMIT),A

; ---- Anchor at (64,32) via BACKWARD stepping
; Vertical: boundary (phase=0, remain=H), step back 32 rows
CALC_OFFSETS:
        LD      A,0
        LD      (Y_PHASE),A
        LD      A,(Y_LIMIT)
        LD      (Y_REMAIN),A

        LD      B,32
YBACK_LOOP:
        LD      A,(Y_REMAIN)
        LD      D,A
        LD      A,(Y_LIMIT)
        CP      D
        JP      Z,YBACK_BOUNDARY
        LD      A,D
        INC     A
        LD      (Y_REMAIN),A
        JP      YBACK_NEXT
YBACK_BOUNDARY:
        LD      A,(Y_PHASE)
        XOR     1
        LD      (Y_PHASE),A
        LD      A,1
        LD      (Y_REMAIN),A
YBACK_NEXT:
        DEC     B
        JP      NZ,YBACK_LOOP

; Horizontal: byte-mode uses N-byte runs and step BACK 16 bytes
        LD      A,(HB_MODE)
        OR      A
        JP      Z,PREP_X_BYTEMODE

; HB mode (2x2): x parity over 16 bytes is even -> x_ofs_phase=0
        XOR     A
        LD      (X_OFS_PHASE),A
        LD      A,1
        LD      (X_FIRST_RUN),A     ; not used in HB path
        JP      DRAW_FRAME

PREP_X_BYTEMODE:
; Start boundary (x_phase=0, first_run=N), step back 16 bytes
        LD      A,0
        LD      (X_OFS_PHASE),A
        LD      A,(N_BYTES)
        LD      (X_FIRST_RUN),A

        LD      B,16
XBACK_LOOP:
        LD      A,(X_FIRST_RUN)
        LD      D,A
        LD      A,(N_BYTES)
        CP      D
        JP      Z,XBACK_BOUNDARY
        LD      A,D
        INC     A
        LD      (X_FIRST_RUN),A
        JP      XBACK_NEXT
XBACK_BOUNDARY:
        LD      A,(X_OFS_PHASE)
        XOR     1
        LD      (X_OFS_PHASE),A
        LD      A,1
        LD      (X_FIRST_RUN),A
XBACK_NEXT:
        DEC     B
        JP      NZ,XBACK_LOOP

; ============================================================
; Draw full frame
; ============================================================
DRAW_FRAME:
        LD      HL,VRAM
        LD      B,ROWS

ROW_LOOP:
; Row start phase (left edge)
        LD      A,(Y_PHASE)
        LD      D,A
        LD      A,(X_OFS_PHASE)
        XOR     D
        LD      D,A                 ; D = x_phase (0=A-first, 1=B-first)

; Branch by mode
        LD      A,(HB_MODE)
        OR      A
        JP      Z,DRAW_ROW_BYTE

; ---------- 2x2 MODE ----------
        LD      C,COL_BYTES
HB_COL_LOOP:
        LD      A,D
        OR      A
        JP      Z,HB_WRITE_AB
        LD      A,(PAT_BA)
        JP      HB_STORE
HB_WRITE_AB:
        LD      A,(PAT_AB)
HB_STORE:
        LD      (HL),A
        INC     HL
        LD      A,D
        XOR     1
        LD      D,A
        DEC     C
        JP      NZ,HB_COL_LOOP
        JP      END_ROW

; ---------- BYTE MODE (>=4x4) ----------
DRAW_ROW_BYTE:
        LD      A,(X_FIRST_RUN)
        LD      E,A                 ; bytes in current run
        LD      C,COL_BYTES
BYTE_COL_LOOP:
        LD      A,D
        OR      A
        JP      Z,BYTE_WRITE_A
        LD      A,(SOLID_B)
        JP      BYTE_STORE
BYTE_WRITE_A:
        LD      A,(SOLID_A)
BYTE_STORE:
        LD      (HL),A
        INC     HL

        DEC     E
        JP      NZ,BYTE_NEXT
        LD      A,D
        XOR     1
        LD      D,A
        LD      A,(N_BYTES)
        LD      E,A
BYTE_NEXT:
        DEC     C
        JP      NZ,BYTE_COL_LOOP

; ---------- End of row ----------
END_ROW:
        LD      A,(Y_REMAIN)
        DEC     A
        JP      NZ,ROW_STORE_YREM
        LD      A,(Y_PHASE)
        XOR     1
        LD      (Y_PHASE),A
        LD      A,(Y_LIMIT)
ROW_STORE_YREM:
        LD      (Y_REMAIN),A

        DEC     B
        JP      NZ,ROW_LOOP






	push	hl
	ld	hl, $a000
	ld	de, $7000
	ld	bc, 2048
	ldir
	pop	hl



; ============================================================
; Animate: zoom and HB hand-off with color rotation placement
; ============================================================
        LD      A,(ZOOM_DIR)
        CP      1
        JP      Z,ANIM_ZOOM_IN

; ---- ZOOM OUT (dir = -1) ----
; Normal byte-mode countdown until N=1; then enter HB but DO NOT rotate here.
        LD      A,(HB_MODE)
        OR      A
        JP      NZ,ANIM_OUT_SAFE

        LD      A,(N_BYTES)
        DEC     A
        LD      (N_BYTES),A
        CP      1
        JP      NZ,FRAME_LOOP

; Reached N=1 while zooming out -> enter HB for the far end; set dir=+1
        LD      A,1
        LD      (HB_MODE),A
        XOR     A
        LD      (HB_PHASE),A        ; ensure phase starts clean (0)
        LD      A,1
        LD      (ZOOM_DIR),A
        JP      FRAME_LOOP

ANIM_OUT_SAFE:
        LD      A,1
        LD      (ZOOM_DIR),A
        JP      FRAME_LOOP

; ---- ZOOM IN (dir = +1) ----
ANIM_ZOOM_IN:
; If we are in the HB hand-off, run its 2-step sequence:
;   HB_PHASE=0 -> first time we arrived (but we always set it explicitly below)
;   HB_PHASE=1 -> show 2x2 SAME color, then set to 2
;   HB_PHASE=2 -> show 2x2 NEXT color, rotate here, then exit HB and return to 4x4
        LD      A,(HB_MODE)
        OR      A
        JP      Z,ANIM_IN_BYTE

; In HB mode (2x2):
        LD      A,(HB_PHASE)
        CP      1
        JP      Z,HB_PHASE_ONE
        CP      2
        JP      Z,HB_PHASE_TWO

; HB_PHASE=0 (just entered from zoom-out). First HB frame should be SAME color.
        LD      A,1
        LD      (HB_PHASE),A
        JP      FRAME_LOOP

HB_PHASE_ONE:
; We just displayed SAME-color 2x2. Now set up NEXT frame to rotate.
        LD      A,2
        LD      (HB_PHASE),A
        JP      FRAME_LOOP

HB_PHASE_TWO:
; Rotate colors now, then EXIT HB back to 4x4 with N=1.
        CALL    ADVANCE_COLOR_SCHEME
        XOR     A
        LD      (HB_MODE),A         ; back to byte-mode
        XOR     A
        LD      (HB_PHASE),A        ; clear hand-off phase
        LD      A,1
        LD      (N_BYTES),A         ; return to 4x4 for the next frame
        JP      FRAME_LOOP

; In BYTE MODE during zoom-in: count up N until max
ANIM_IN_BYTE:
        LD      A,(N_BYTES)
        INC     A
        LD      (N_BYTES),A
        CP      20                  ; cap = 64x64
        JP      NZ,FRAME_LOOP
        LD      A,$FF
        LD      (ZOOM_DIR),A
        JP      FRAME_LOOP

FRAME_LOOP:
        JP      MAIN_LOOP

; ============================================================
; Subroutines: color scheme handling
; ============================================================
; SET_COLORS_FROM_IDX:
;   Reads COL_IDX -> loads color codes A/B from COL_TABLE,
;   computes SOLID_A/B and PAT_AB/PAT_BA.
SET_COLORS_FROM_IDX:
; HL = COL_TABLE + 2*COL_IDX
        LD      HL,COL_TABLE
        LD      A,(COL_IDX)
        LD      E,A
SCFI_ADV_LOOP:
        LD      A,E
        OR      A
        JP      Z,SCFI_AT
        INC     HL
        INC     HL
        DEC     E
        JP      SCFI_ADV_LOOP
SCFI_AT:
        LD      A,(HL)
        LD      (CUR_COL_A),A
        INC     HL
        LD      A,(HL)
        LD      (CUR_COL_B),A

; SOLID_A from SOLID_MAP[codeA]
        LD      HL,SOLID_MAP
        LD      A,(CUR_COL_A)
        LD      E,A
SMAP_A_LOOP:
        LD      A,E
        OR      A
        JP      Z,SMAP_A_AT
        INC     HL
        DEC     E
        JP      SMAP_A_LOOP
SMAP_A_AT:
        LD      A,(HL)
        LD      (SOLID_A),A

; SOLID_B from SOLID_MAP[codeB]
        LD      HL,SOLID_MAP
        LD      A,(CUR_COL_B)
        LD      E,A
SMAP_B_LOOP:
        LD      A,E
        OR      A
        JP      Z,SMAP_B_AT
        INC     HL
        DEC     E
        JP      SMAP_B_LOOP
SMAP_B_AT:
        LD      A,(HL)
        LD      (SOLID_B),A

; NIB_A from NIBBLE_MAP[codeA]
        LD      HL,NIBBLE_MAP
        LD      A,(CUR_COL_A)
        LD      E,A
NMAP_A_LOOP:
        LD      A,E
        OR      A
        JP      Z,NMAP_A_AT
        INC     HL
        DEC     E
        JP      NMAP_A_LOOP
NMAP_A_AT:
        LD      A,(HL)
        LD      D,A                 ; D = nibble A

; NIB_B from NIBBLE_MAP[codeB]
        LD      HL,NIBBLE_MAP
        LD      A,(CUR_COL_B)
        LD      E,A
NMAP_B_LOOP:
        LD      A,E
        OR      A
        JP      Z,NMAP_B_AT
        INC     HL
        DEC     E
        JP      NMAP_B_LOOP
NMAP_B_AT:
        LD      A,(HL)
        LD      E,A                 ; E = nibble B

; PAT_AB = (nibA<<4) | nibB
        LD      A,D
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A                 ; A = nibA << 4
        OR      E
        LD      (PAT_AB),A

; PAT_BA = (nibB<<4) | nibA
        LD      A,E
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A                 ; A = nibB << 4
        OR      D
        LD      (PAT_BA),A
        RET

; ADVANCE_COLOR_SCHEME:
;   COL_IDX = (COL_IDX + 1) mod 12, then recompute derived bytes.
ADVANCE_COLOR_SCHEME:
        LD      A,(COL_IDX)
        INC     A
        CP      12
        JP      NZ,ACS_NOWRAP
        XOR     A
ACS_NOWRAP:
        LD      (COL_IDX),A
        CALL    SET_COLORS_FROM_IDX
        RET

; ============================================================
; Data (all after code)
; ============================================================
; Draw/zoom state
N_BYTES:        DEFB    1           ; N (1..16) -> 4*N px
ZOOM_DIR:       DEFB    1           ; +1 or -1 ($FF)
HB_MODE:        DEFB    0           ; 0=byte-mode, 1=2x2
HB_PHASE:       DEFB    0           ; 0=inactive, 1=same-color HB, 2=rotated-color HB

Y_PHASE:        DEFB    0           ; 0 = A-first, 1 = B-first
Y_LIMIT:        DEFB    4           ; rows per vertical block
Y_REMAIN:       DEFB    4           ; rows left in vertical block

X_OFS_PHASE:    DEFB    0           ; horizontal parity offset (byte-mode)
X_FIRST_RUN:    DEFB    0           ; first run length in bytes (byte-mode)

; Color scheme state
COL_IDX:        DEFB    0           ; 0..11
CUR_COL_A:      DEFB    0           ; 0=G,1=Y,2=B,3=R
CUR_COL_B:      DEFB    1           ; 0=G,1=Y,2=B,3=R
SOLID_A:        DEFB    $00         ; 00,55,AA,FF
SOLID_B:        DEFB    $55         ; 00,55,AA,FF
PAT_AB:         DEFB    $05         ; (nibA<<4)|nibB
PAT_BA:         DEFB    $50         ; (nibB<<4)|nibA

; Lookup tables
; Byte for solid color: 00->00, 01->55, 10->AA, 11->FF
SOLID_MAP:      DEFB    $00,$55,$AA,$FF
; Nibble for two pixels: 00->0, 01->5, 10->A, 11->F
NIBBLE_MAP:     DEFB    $00,$05,$0A,$0F

; 12 ordered color pairs (A,B):
;   G-Y, G-B, G-R, Y-G, Y-B, Y-R, B-G, B-Y, B-R, R-G, R-Y, R-B
COL_TABLE:
        DEFB    0,1
        DEFB    0,2
        DEFB    0,3
        DEFB    1,0
        DEFB    1,2
        DEFB    1,3
        DEFB    2,0
        DEFB    2,1
        DEFB    2,3
        DEFB    3,0
        DEFB    3,1
        DEFB    3,2

        END     START

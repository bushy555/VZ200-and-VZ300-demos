
; ============================================================
; VZ200 / VZ300 MODE(1) 128x64 4-color (6847)
; Smooth Zooming Checkerboard with Orbiting Origin
; Double-buffered: draw to $A000, LDIR to $7000 during vblank
; ------------------------------------------------------------
; Requirements (PASMO-friendly):
; - ORG $8000
; - Video VRAM at $7000 (2048 bytes)
; - Back buffer at $A000 (2048 bytes)
; - Latch at $6800
; - Stack at $B000
; - Use JP, no JR
; - No DJNZ (use DEC/JP loops)
; - Use register A for all memory stores/loads to/from memory
; - No illegal 16-bit pair arithmetic (e.g., ADD DE,DE)
; - All DB/DEFB at end of source (after all code)
; ------------------------------------------------------------
; Display codes (2bpp): 00=Green, 01=Yellow, 10=Blue, 11=Red
; Zoom range:
;   - Byte-mode: blocks are (4*N) x (4*N) pixels, N = 1..16
;   - HB (2x2) mode: special 2x2 rendering using AB/BA nibbles
; Color rotation rule (during zoom-in at 2x2 hand-off):
;   - HB_PHASE=1 : show 2x2 SAME color
;   - HB_PHASE=2 : show 2x2 NEXT color, then rotate color scheme,
;                  exit HB back to 4x4 (N=1) and continue zoom-in
; Orbit:
;   - Center (64,32), radius 15, 96 steps (3.75° each)
;   - Updates per frame (one step)
;   - Uses small quarter-wave tables mirrored to all quadrants
; ============================================================

            ORG     $8000

; ---------------- Hardware ----------------
LATCH_IO    EQU     $6800
VRAM        EQU     $7000
BACKBUF     EQU     $A000
ROWS        EQU     64
COL_BYTES   EQU     32

; ============================================================
; Entry / Setup
; ============================================================
START:
            LD      SP,$B000
            DI
            ; Enter MODE(1)
            LD      A,8
            LD      (LATCH_IO),A

; Optional clear BACKBUF (2048 bytes)
            LD      HL,BACKBUF
            LD      DE,2048
            XOR     A
CLB_LOOP:
            LD      (HL),A
            INC     HL
            DEC     DE
            LD      A,D
            OR      E
            JP      NZ,CLB_LOOP

; Optional clear VRAM (2048 bytes)
            LD      HL,VRAM
            LD      DE,2048
            XOR     A
CLV_LOOP:
            LD      (HL),A
            INC     HL
            DEC     DE
            LD      A,D
            OR      E
            JP      NZ,CLV_LOOP

; Initialize zoom/orbit state
            ; N_BYTES=1 (4x4)
            LD      A,1
            LD      (N_BYTES),A
            ; ZOOM_DIR=+1
            LD      (ZOOM_DIR),A
            ; HB_MODE=0 (byte-mode initially)
            XOR     A
            LD      (HB_MODE),A
            ; HB_PHASE=0
            LD      (HB_PHASE),A

; Initial color scheme index = 0 (G-Y), and compute derived bytes
            XOR     A
            LD      (COL_IDX),A
            CALL    SET_COLORS_FROM_IDX

; Initialize orbit/frame index and origin
            XOR     A
            LD      (FRAME_IDX),A
            LD      A,64
            LD      (X0_PIX),A
            LD      A,32
            LD      (Y0_PIX),A

; ============================================================
; Main frame loop (double-buffered)
; ============================================================
MAIN_LOOP:

            PUSH    BC
            PUSH    DE
            PUSH    HL


	LD 	hl,0x6800
sync2:	BIT 	7,(hl)			; fancy wait retrace.
	jr	NZ,sync2

	LD 	hl,0x6800
sync3:	BIT 	7,(hl)			; fancy wait retrace.
	jr	Z,sync3




; Copy 2048 bytes: HL=BACKBUF, DE=VRAM, BC=2048

            LD      HL,BACKBUF
            LD      DE,VRAM
            LD      BC,2048
            LDIR

            POP     HL
            POP     DE
            POP     BC











; Update orbiting origin (x0,y0) once per frame
            CALL    UPDATE_ORIGIN

; -------- Per-frame vertical unit: H = 4*N (byte-mode) or 2 (HB 2x2) ----
            LD      A,(HB_MODE)
            OR      A
            JP      Z,CALC_H_BYTE

; HB mode: H = 2 rows per color block
            LD      A,2
            LD      (Y_LIMIT),A
            JP      CALC_OFFSETS

CALC_H_BYTE:
            LD      A,(N_BYTES)    ; A = N
            LD      C,A            ; keep N for horizontal
            ADD     A,A            ; 2N
            ADD     A,A            ; 4N
            LD      (Y_LIMIT),A

; -------- Anchor via BACKWARD stepping to (x0,y0) --------
; Vertical: boundary (phase=0, remain=H), step back y0 rows
CALC_OFFSETS:
            LD      A,0
            LD      (Y_PHASE),A
            LD      A,(Y_LIMIT)
            LD      (Y_REMAIN),A
            LD      A,(Y0_PIX)
            LD      B,A
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

; Horizontal prep
            LD      A,(HB_MODE)
            OR      A
            JP      Z,PREP_X_BYTEMODE

; ---- HB (2x2) MODE: set parity from floor(x0/2) ----
            LD      A,(X0_PIX)
            SRL     A              ; x0 >> 1
            AND     1
            LD      (X_OFS_PHASE),A
            ; X_FIRST_RUN unused in HB path; keep valid
            LD      A,1
            LD      (X_FIRST_RUN),A
            JP      DRAW_FRAME

; ---- BYTE MODE (>=4x4): step back floor(x0/4) bytes ----
PREP_X_BYTEMODE:
            LD      A,0
            LD      (X_OFS_PHASE),A
            LD      A,(N_BYTES)
            LD      (X_FIRST_RUN),A
            LD      A,(X0_PIX)
            SRL     A              ; x0 >> 1
            SRL     A              ; x0 >> 2 = bytes
            LD      B,A
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
; Draw full frame INTO BACK BUFFER (not VRAM)
; ============================================================
DRAW_FRAME:
            LD      HL,BACKBUF
            LD      B,ROWS

ROW_LOOP:
; Determine row start phase (left edge)
            LD      A,(Y_PHASE)
            LD      D,A
            LD      A,(X_OFS_PHASE)
            XOR     D
            LD      D,A            ; D = x_phase (0=A-first, 1=B-first)

; Branch by mode
            LD      A,(HB_MODE)
            OR      A
            JP      Z,DRAW_ROW_BYTE

; -------- HB (2x2) MODE --------
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

; -------- BYTE MODE (>=4x4) --------
DRAW_ROW_BYTE:
            LD      A,(X_FIRST_RUN)
            LD      E,A            ; E = run length in bytes
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

; -------- End of row --------
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

; ============================================================
; Vertical blank copy: BACKBUF -> VRAM (2048 bytes)
; Wait for vblank start, then LDIR copy
; ============================================================
; Wait for vblank start (bit 7 = 1)



; ============================================================
; Animate: zoom and HB hand-off with color rotation placement
; ============================================================
            LD      A,(ZOOM_DIR)
            CP      1
            JP      Z,ANIM_ZOOM_IN

; ----- ZOOM OUT (dir = -1) -----
            LD      A,(HB_MODE)
            OR      A
            JP      NZ,ANIM_OUT_SAFE

            LD      A,(N_BYTES)
            DEC     A
            LD      (N_BYTES),A
            CP      1
            JP      NZ,FRAME_LOOP

            ; Reached N=1 while zooming out -> enter HB for far end; set dir=+1
            LD      A,1
            LD      (HB_MODE),A
            XOR     A
            LD      (HB_PHASE),A
            LD      A,1
            LD      (ZOOM_DIR),A
            JP      FRAME_LOOP

ANIM_OUT_SAFE:
            LD      A,1
            LD      (ZOOM_DIR),A
            JP      FRAME_LOOP

; ----- ZOOM IN (dir = +1) -----
ANIM_ZOOM_IN:
            LD      A,(HB_MODE)
            OR      A
            JP      Z,ANIM_IN_BYTE

            ; In HB mode (2x2) during hand-off:
            LD      A,(HB_PHASE)
            CP      1
            JP      Z,HB_PHASE_ONE
            CP      2
            JP      Z,HB_PHASE_TWO

            ; HB_PHASE=0: first HB frame should be SAME color
            LD      A,1
            LD      (HB_PHASE),A
            JP      FRAME_LOOP

HB_PHASE_ONE:
            ; Just displayed SAME-color 2x2. Next frame will rotate.
            LD      A,2
            LD      (HB_PHASE),A
            JP      FRAME_LOOP

HB_PHASE_TWO:
            ; Rotate colors now, then EXIT HB back to 4x4 with N=1.
            CALL    ADVANCE_COLOR_SCHEME
            XOR     A
            LD      (HB_MODE),A
            XOR     A
            LD      (HB_PHASE),A
            LD      A,1
            LD      (N_BYTES),A
            JP      FRAME_LOOP

; In BYTE MODE during zoom-in: count up N until max
ANIM_IN_BYTE:
            LD      A,(N_BYTES)
            INC     A
            LD      (N_BYTES),A
            CP      16              ; max N = 16 -> 64x64 blocks
            JP      NZ,FRAME_LOOP
            LD      A,$FF           ; -1
            LD      (ZOOM_DIR),A

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
            LD      A,(HL)          ; A = nibble A
            LD      D,A             ; D = nibble A

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
            LD      A,(HL)          ; A = nibble B
            LD      E,A             ; E = nibble B

            ; PAT_AB = (nibA<<4) | nibB
            LD      A,D
            ADD     A,A
            ADD     A,A
            ADD     A,A
            ADD     A,A
            OR      E
            LD      (PAT_AB),A

            ; PAT_BA = (nibB<<4) | nibA
            LD      A,E
            ADD     A,A
            ADD     A,A
            ADD     A,A
            ADD     A,A
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
; UPDATE_ORIGIN:
;   FRAME_IDX -> (x0,y0) = (64 + dx, 32 + dy) on a radius-15 circle.
;   Uses 96 steps @ 3.75°; quadrant-mirrors quarter-wave tables.
;   Outputs: X0_PIX, Y0_PIX updated for this frame.
; ============================================================
UPDATE_ORIGIN:
            ; k = FRAME_IDX (0..95)
            LD      A,(FRAME_IDX)
            LD      E,A

            ; q = k / 24  (0..3),  r = k % 24  (A after loop)
            LD      D,0
UO_QDIV:
            CP      24
            JP      C,UO_QDONE
            SUB     24
            INC     D
            JP      UO_QDIV
UO_QDONE:
            LD      C,A            ; C = r (0..23), D = q

            ; Load sin = SIN_Q24[r] into H, cos = COS_Q24[r] into L
            LD      HL,SIN_Q24
            LD      B,C
UO_SIN_ADV:
            LD      A,B
            OR      A
            JP      Z,UO_SIN_AT
            INC     HL
            DEC     B
            JP      UO_SIN_ADV
UO_SIN_AT:
            LD      A,(HL)
            LD      H,A

            LD      HL,COS_Q24
            LD      B,C
UO_COS_ADV:
            LD      A,B
            OR      A
            JP      Z,UO_COS_AT
            INC     HL
            DEC     B
            JP      UO_COS_ADV
UO_COS_AT:
            LD      A,(HL)
            LD      L,A

            ; Quadrant mapping:
            ; q=0: dx= +cos (L), dy= +sin (H)
            ; q=1: dx= -sin (H), dy= +cos (L)
            ; q=2: dx= -cos (L), dy= -sin (H)
            ; q=3: dx= +sin (H), dy= -cos (L)

            LD      A,D
            OR      A
            JP      Z,UO_Q0
            CP      1
            JP      Z,UO_Q1
            CP      2
            JP      Z,UO_Q2

            ; q = 3
            LD      A,H            ; dy = -sin
            XOR     $FF
            INC     A
            LD      B,A
            LD      A,H            ; dx = +sin (use H)
            LD      C,A
            JP      UO_ADD_CENTER

UO_Q2:
            LD      A,L            ; dx = -cos
            XOR     $FF
            INC     A
            LD      C,A
            LD      A,H            ; dy = -sin
            XOR     $FF
            INC     A
            LD      B,A
            JP      UO_ADD_CENTER

UO_Q1:
            LD      A,H            ; dx = -sin
            XOR     $FF
            INC     A
            LD      C,A
            LD      A,L            ; dy = +cos
            LD      B,A
            JP      UO_ADD_CENTER

UO_Q0:
            LD      A,L            ; dx = +cos
            LD      C,A
            LD      A,H            ; dy = +sin
            LD      B,A

UO_ADD_CENTER:
            ; x0 = 64 + dx (C), y0 = 32 + dy (B)
            LD      A,64
            ADD     A,C
            LD      (X0_PIX),A
            LD      A,32
            ADD     A,B
            LD      (Y0_PIX),A

            ; FRAME_IDX = (FRAME_IDX + 1) % 96
            LD      A,(FRAME_IDX)
            INC     A
            CP      96
            JP      NZ,UO_NO_WRAP
            XOR     A
UO_NO_WRAP:
            LD      (FRAME_IDX),A
            RET

; ============================================================
; -----------------------  DATA  -----------------------------
; All DB/DEFB after this point (no executable code below)
; ============================================================

; Draw/zoom/orbit state
N_BYTES:        DEFB 1      ; N (1..16) -> 4*N px blocks
ZOOM_DIR:       DEFB 1      ; +1 or -1 ($FF)
HB_MODE:        DEFB 0      ; 0=byte-mode, 1=2x2 HB mode
HB_PHASE:       DEFB 0      ; 0=inactive, 1=same-color, 2=rotated-color
Y_PHASE:        DEFB 0      ; 0=A-first, 1=B-first (vertical parity)
Y_LIMIT:        DEFB 4      ; rows per vertical block
Y_REMAIN:       DEFB 4      ; rows remaining in current vertical block
X_OFS_PHASE:    DEFB 0      ; horizontal parity offset (byte-mode)
X_FIRST_RUN:    DEFB 0      ; first run length in bytes (byte-mode)

COL_IDX:        DEFB 0      ; 0..11
CUR_COL_A:      DEFB 0      ; 0=G,1=Y,2=B,3=R
CUR_COL_B:      DEFB 1      ; 0=G,1=Y,2=B,3=R
SOLID_A:        DEFB $00    ; 00,55,AA,FF
SOLID_B:        DEFB $55    ; 00,55,AA,FF
PAT_AB:         DEFB $05    ; (nibA<<4)|nibB
PAT_BA:         DEFB $50    ; (nibB<<4)|nibA

FRAME_IDX:      DEFB 0      ; 0..95
X0_PIX:         DEFB 64     ; current origin x (0..127)
Y0_PIX:         DEFB 32     ; current origin y (0..63)

; Lookup tables
; Byte for solid color: 00->00, 01->55, 10->AA, 11->FF
SOLID_MAP:      DEFB $00,$55,$AA,$FF

; Nibble for two pixels: 00->0, 01->5, 10->A, 11->F
NIBBLE_MAP:     DEFB $00,$05,$0A,$0F

; 12 ordered color pairs (A,B):
; G-Y, G-B, G-R, Y-G, Y-B, Y-R, B-G, B-Y, B-R, R-G, R-Y, R-B
COL_TABLE:
                DEFB 0,1
                DEFB 0,2
                DEFB 0,3
                DEFB 1,0
                DEFB 1,2
                DEFB 1,3
                DEFB 2,0
                DEFB 2,1
                DEFB 2,3
                DEFB 3,0
                DEFB 3,1
                DEFB 3,2

; Quarter-wave tables for radius 15 at 3.75° steps (24 entries)
; SIN_Q24[n] = round(15 * sin(n*3.75°)),  n=0..23
SIN_Q24:
                DEFB 0,1,2,3,4,5,6,7,8,8,9,10,11,11,12,12,13,13,14,14,14,15,15,15
; COS_Q24[n] = round(15 * cos(n*3.75°)),  n=0..23
COS_Q24:
                DEFB 15,15,15,15,14,14,13,13,13,12,12,11,11,10,9,8,8,7,6,5,4,3,2,1

            END     START

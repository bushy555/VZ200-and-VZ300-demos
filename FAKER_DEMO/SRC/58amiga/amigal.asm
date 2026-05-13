; ===========================================================
;  AMIGA BALL  -  VZ200/VZ300  MODE(1)
;  PASMO assembler  ORG $8000
;
;  Screen: 128x64 logical pixels, 2bpp, 32 bytes/row
;  VRAM:   $7000..$77FF  (2048 bytes)
;
;  Colour palette (2bpp):
;    %00 = green   (background)
;    %01 = yellow  (checker light)
;    %10 = blue    (unused)
;    %11 = red     (checker dark)
;
;  Pixel packing: each byte holds 4 pixels
;    bits 7-6 = leftmost pixel
;    bits 5-4 = next pixel
;    bits 3-2 = next pixel
;    bits 1-0 = rightmost pixel
;
;  Ball:
;    Centre: px=64, py=32
;    Radius: 24 logical pixels
;    Aspect correction: 9*dx^2 + 4*dy^2 <= 9*R^2 = 5184
;    Makes circle appear round on TV screen
;
;  Checker pattern:
;    zone_x = px >> 3   (8-pixel wide columns)
;    zone_y = py >> 2   (4-row tall bands)
;    checker = (zone_x + zone_y + FRAME) AND 1
;    0 -> yellow (%01)
;    1 -> red    (%11)
;
;  FRAME increments each animation loop -> rotation effect
;
;  Circle test uses precomputed (dx)^2 table to avoid
;  full multiply per pixel.
; ===========================================================

        ORG     $8000

; -----------------------------------------------------------
;  CONSTANTS
; -----------------------------------------------------------
CX          EQU     64          ; ball centre x
CY          EQU     32          ; ball centre y
RADIUS      EQU     16          ; logical pixel radius
; Aspect correction: pixels are 2 fine wide x 3 fine tall
; Circle test: 4*dx^2 + 9*dy^2 <= 4*R^2
; 4*R^2 = 4*256 = 1024
R2_ASP      EQU     1024        ; 4 * RADIUS^2

VRAM        EQU     $7000
VRAM_END    EQU     $77FF
BUFFER	    EQU	    $9000


; -----------------------------------------------------------
;  VARIABLES  (at $8F00)
; -----------------------------------------------------------
FRAME       EQU     $8F00       ; current frame counter (1 byte)
DX2_TAB     EQU     $8F01       ; dx^2 table, 129 words ($8F01..$9100)
                                ; index 0..128, value = dx^2

; -----------------------------------------------------------
;  ENTRY POINT
; -----------------------------------------------------------
        di

        ; Set MODE(1)
        LD      A, 8
        LD      ($6800), A

        ; Clear VRAM to green (all zeros)
        LD      HL, VRAM
        LD      DE, VRAM+1
        LD      BC, 2047
        LD      (HL), 0
        LDIR

        ; Init frame counter
        XOR     A
        LD      (FRAME), A

; -----------------------------------------------------------
;  BUILD dx^2 TABLE
;  DX2_TAB[i] = i*i  for i = 0..64
;  We only need 0..64 (since max |dx| = 64)
;  Stored as 16-bit words, little-endian
;  Address: DX2_TAB + i*2
; -----------------------------------------------------------
        LD      B, 0            ; i = 0

BUILD_DX2:
        ; compute B*B -> HL using repeated addition
        LD      A, B
        LD      H, 0
        LD      L, 0
        CP      0
        JP      Z, DX2_STORE
        LD      D, 0
        LD      E, B
        LD      C, B            ; loop counter = B
DX2_MUL:
        ADD     HL, DE
        DEC     C
        JP      NZ, DX2_MUL

DX2_STORE:
        ; store HL at DX2_TAB + B*2
        PUSH    HL
        PUSH    BC
        LD      H, 0
        LD      L, B
        ADD     HL, HL          ; B*2
        LD      DE, DX2_TAB
        ADD     HL, DE
        POP     BC
        POP     DE
        LD      (HL), E
        INC     HL
        LD      (HL), D

        INC     B
        LD      A, B
        CP      65
        JP      NZ, BUILD_DX2

; ===========================================================
;  MAIN ANIMATION LOOP
; ===========================================================
ANIM_LOOP:

        ; Clear VRAM to green (0)
;        LD      HL, BUFFER
 ;       LD      DE, BUFFER+1
  ;      LD      BC, 2047
   ;     LD      (HL), 0
    ;    LDIR

        ; Get current frame
        LD      A, (FRAME)
        LD      (FRAME_CACHE), A

        ; Render ball
        ; Outer loop: py = 0..63
        LD      B, 0            ; py = 0

ROW_LOOP:
        ; dy = py - CY  (signed)
        LD      A, B
        SUB     CY              ; A = dy (signed)

        ; dy2 = dy*dy
        ; take absolute value first
        BIT     7, A
        JP      Z, DY_POS
        NEG
DY_POS:
        ; A = |dy|, compute dy^2
        LD      H, 0
        LD      L, 0
        CP      0
        JP      Z, DY2_DONE
        LD      D, 0
        LD      E, A
        LD      C, A
DY2_LP:
        ADD     HL, DE
        DEC     C
        JP      NZ, DY2_LP
DY2_DONE:
        ; HL = dy^2, multiply by 9 for aspect correction
        LD      D, H
        LD      E, L
        ADD     HL, HL
        ADD     HL, HL
        ADD     HL, HL          ; HL = 8*dy^2
        ADD     HL, DE          ; HL = 9*dy^2

        ; if 9*dy^2 > 4*R^2, whole row is background - skip
        LD      DE, R2_ASP
        PUSH    HL
        XOR     A
        SBC     HL, DE
        POP     HL
        JP      NC, ROW_SKIP    ; skip row

        ; Save 9*dy^2
        LD      (DY2_STORE), HL

        ; Compute VRAM row address = VRAM + py*32
        LD      H, 0
        LD      L, B            ; py
        ADD     HL, HL
        ADD     HL, HL
        ADD     HL, HL
        ADD     HL, HL
        ADD     HL, HL          ; py*32
        LD      DE, VRAM
        ADD     HL, DE
        LD      (ROW_ADDR), HL

        ; Inner loop: process 32 bytes = 128 pixels per row
        ; C = byte column (0..31)
        LD      C, 0

BYTE_LOOP:
        ; px_base = C*4  (leftmost pixel of this byte)
        LD      A, C
        RLCA
        RLCA                    ; A = C*4 = px_base

        ; Build output byte from 4 pixels
        LD      (PX_BASE), A
        XOR     A
        LD      (OUT_BYTE), A

        ; Pixel 0: px = px_base + 0
        LD      A, (PX_BASE)
        CALL    GET_PIXEL       ; returns A = pixel value 0..3
        RLCA
        RLCA
        RLCA
        RLCA
        RLCA
        RLCA
        AND     $C0
        LD      (OUT_BYTE), A

        ; Pixel 1: px = px_base + 1
        LD      A, (PX_BASE)
        INC     A
        CALL    GET_PIXEL
        RLCA
        RLCA
        RLCA
        RLCA
        AND     $30
        LD      E, A
        LD      A, (OUT_BYTE)
        OR      E
        LD      (OUT_BYTE), A

        ; Pixel 2: px = px_base + 2
        LD      A, (PX_BASE)
        ADD     A, 2
        CALL    GET_PIXEL
        RLCA
        RLCA
        AND     $0C
        LD      E, A
        LD      A, (OUT_BYTE)
        OR      E
        LD      (OUT_BYTE), A

        ; Pixel 3: px = px_base + 3
        LD      A, (PX_BASE)
        ADD     A, 3
        CALL    GET_PIXEL
        AND     $03
        LD      E, A
        LD      A, (OUT_BYTE)
        OR      E

        ; Write byte to VRAM
        LD      HL, (ROW_ADDR)
        LD      D, 0
        LD      E, C
        ADD     HL, DE
        LD      (HL), A

  	ld   de, -664
	add  hl, de      ;$fffe +256
        LD      (HL), A


  	ld   de, +664 + 664
	add  hl, de      ;$fffe +256
        LD      (HL), A


        INC     C
        LD      A, C
        CP      32
        JP      NZ, BYTE_LOOP

ROW_SKIP:
        INC     B
        LD      A, B
        CP      64
        JP      NZ, ROW_LOOP

        ; Increment frame counter
        LD      A, (FRAME)
        INC     A
        LD      (FRAME), A

        JP      ANIM_LOOP

; ===========================================================
;  GET_PIXEL
;  In:  A  = px (0..127)
;       B  = py (0..63)  [unchanged from row loop]
;       (DY2_STORE) = dy^2 for this row
;  Out: A  = pixel colour (0=green, 1=yellow, 3=red)
;  Preserves: B, C
; ===========================================================
GET_PIXEL:
        PUSH    BC

        ; Save px before we modify A
        LD      (PX_SAVE), A

        ; dx = px - CX  (signed)
        SUB     CX              ; A = dx (signed, -64..+63)

        ; |dx|
        BIT     7, A
        JP      Z, GP_DXPOS
        NEG
GP_DXPOS:
        ; A = |dx| (0..64)
        ; dx^2 from table: DX2_TAB + |dx|*2
        LD      H, 0
        LD      L, A
        ADD     HL, HL          ; |dx|*2
        LD      DE, DX2_TAB
        ADD     HL, DE
        LD      E, (HL)
        INC     HL
        LD      D, (HL)         ; DE = dx^2

        ; DE = dx^2, multiply by 4
        LD      H, D
        LD      L, E
        ADD     HL, HL
        ADD     HL, HL          ; HL = 4*dx^2

        ; r2 = 4*dx^2 + 9*dy^2
        LD      DE, (DY2_STORE) ; DE = 9*dy^2
        ADD     HL, DE          ; HL = 4*dx^2 + 9*dy^2

        ; if r2 > 4*R^2 -> background (green=0)
        LD      DE, R2_ASP
        XOR     A
        SBC     HL, DE
        JP      NC, GP_BG       ; outside circle

        ; Inside ball - smooth horizontal scroll 1 pixel per frame
        LD      A, (PX_SAVE)

        ; zone_x = (px + FRAME) >> 3
        LD      HL, FRAME_CACHE
        ADD     A, (HL)         ; px + FRAME
        SRL     A
        SRL     A
        SRL     A               ; A = (px + FRAME) / 8
        LD      D, A

        ; zone_y = py >> 2
        LD      A, B
        SRL     A
        SRL     A               ; A = py / 4

        ADD     A, D            ; zone_x + zone_y
        AND     1
        JP      Z, GP_YELLOW
        LD      A, 3            ; red = %11
        JP      GP_RET
GP_YELLOW:
        LD      A, 1            ; yellow = %01
        JP      GP_RET
GP_BG:
        LD      A, 0            ; green = %00
GP_RET:
        POP     BC
        RET

; ===========================================================
;  VARIABLES (in code page for easy access)
; ===========================================================
DY2_STORE:  DEFW    0
ROW_ADDR:   DEFW    0
PX_BASE:    DEFB    0
PX_SAVE:    DEFB    0
OUT_BYTE:   DEFB    0
FRAME_CACHE: DEFB   0

        END

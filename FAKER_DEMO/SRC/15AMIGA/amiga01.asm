; ==============================================================
; VZ200/VZ300 MODE(1) - BOING BALL DEMO
;
; A red/white checkerboard ball bouncing around the screen,
; inspired by the Amiga Boing demo.
;
; HOW IT WORKS:
;   - Ball is a circle of radius 22 pixels
;   - Inside the circle: diagonal red/white checkerboard pattern
;   - Pattern is determined by: (dx + dy + phase) >> 2, bit 0
;     where dx,dy are pixel offsets from ball centre
;   - Each frame: erase ball at old pos, update pos+phase, draw at new pos
;   - No full-screen clear needed: only the ball area is touched
;   - Bounces off all four screen edges
;
; RENDERING:
;   For each scanline through the ball:
;     - Compute half-width from WIDTHTAB (precomputed sqrt values)
;     - Walk bytes across the ball span
;     - Each VRAM byte (4 pixels) is either $FF (red) or $00 (background)
;     - Colour alternates each byte (diagonal checker)
;     - Starting parity from (-w + dy + phase) >> 2 bit 0
;     - Edge bytes handled with masking (left/right partial pixels)
;
; STRICT RULES:
;   ORG $8000, JP-only (no JR/DJNZ), SP=$F000
;   LD A,(nn) / LD (nn),A for byte variables only
;   MODE(1) via $6800, 128x64, 2bpp (colour 3=red, 0=background)
;   All DB/DEFS at END
; ==============================================================

            ORG     $8000
            JP      Start

; --------------------- Constants ----------------------
VRAM        EQU     $9000
VIDEO	    EQU     $7000
LATCH       EQU     $6800
RX          EQU     30          ; horizontal radius in pixels
RY          EQU     20          ; vertical radius in pixels
; Pixel aspect ratio is 2:3 (2 units wide, 3 units tall per pixel)
; RX*2 = 60 physical units wide, RY*3 = 60 physical units tall -> round!
WIDTAB_LEN  EQU     41          ; 2*RY + 1

; Boundary constants (ball centre limits)
X_MIN       EQU     RX
X_MAX       EQU     127-RX
Y_MIN       EQU     RY
Y_MAX       EQU     63-RY

; ===================== Start ==========================
Start:

            LD      A,24;8
            LD      (LATCH),A       ; MODE 1


	DI

            ; Clear VRAM
            LD      HL,VRAM
            LD      DE,VRAM+1
            LD      BC,2047
            XOR     A
            LD      (HL),A
            LDIR

            ; Initialise ball state
            LD      A,64            ; BX = screen centre X
            LD      (BX),A
            LD      A,32            ; BY = screen centre Y
            LD      (BY),A
            LD      A,2             ; VX = +2
            LD      (VX),A
            LD      A,2             ; VY = +2
            LD      (VY),A
            XOR     A
            LD      (PHASE),A

            ; Draw initial ball
            LD      A,3             ; colour 3 = RED
            LD      (DRAWCOL),A
            CALL    DrawBall

; ======================== MainLoop ====================
MainLoop:
            ; --- Erase ball at current position ---
;            XOR     A               ; colour 0 = background
;            LD      (DRAWCOL),A
;            CALL    DrawBall

            ; --- Update phase (ball rotation) ---
            ; Phase advances by 2 each frame for visible spinning
            LD      A,(PHASE)
            ADD     A,2
            LD      (PHASE),A

            ; --- Update position ---
            LD      A,(BX)
            LD      B,A
            LD      A,(VX)
            ADD     A,B             ; BX = BX + VX
            LD      (BX),A

            LD      A,(BY)
            LD      B,A
            LD      A,(VY)
            ADD     A,B             ; BY = BY + VY
            LD      (BY),A

            ; --- Bounce X ---
            LD      A,(BX)
            CP      X_MIN
            JP      NC,BX_NoMin
            ; Hit left wall
            LD      A,X_MIN
            LD      (BX),A
            LD      A,(VX)
            CPL
            INC     A               ; negate VX
            LD      (VX),A
            JP      BX_Done
BX_NoMin:
            CP      X_MAX+1
            JP      C,BX_Done
            ; Hit right wall
            LD      A,X_MAX
            LD      (BX),A
            LD      A,(VX)
            CPL
            INC     A
            LD      (VX),A
BX_Done:
            ; --- Bounce Y ---
            LD      A,(BY)
            CP      Y_MIN
            JP      NC,BY_NoMin
            LD      A,Y_MIN
            LD      (BY),A
            LD      A,(VY)
            CPL
            INC     A
            LD      (VY),A
            JP      BY_Done
BY_NoMin:
            CP      Y_MAX+1
            JP      C,BY_Done
            LD      A,Y_MAX
            LD      (BY),A
            LD      A,(VY)
            CPL
            INC     A
            LD      (VY),A
BY_Done:


	


            ; --- Draw ball at new position ---
            LD      A,3
            LD      (DRAWCOL),A
            CALL    DrawBall

	ld	hl, $9000
	ld	de, $7000
	ld	bc, 2048
	ldir

	ld	hl, $9000
	ld	de, $9000+1
	ld	(hl), %01010101
	ld	bc, 1024
	LDIR

	ld	hl, $9000+1024
	ld	de, $9000+1+1024
	ld	(hl), %10101010
	ld	bc, 1024
	ldir


            JP      MainLoop

; ==============================================================
; DrawBall
;   Draws (or erases) the ball at position (BX, BY).
;   DRAWCOL = 3 to draw red ball, 0 to erase.
;   Uses PHASE for checker pattern offset.
;
;   For each row through the ball (i = 0..44):
;     dy = i - RADIUS  (= i - 22)
;     py = BY + dy
;     skip if py outside 0..63
;     w = WIDTHTAB[i]
;     fill pixels from (BX-w) to (BX+w) with alternating colour
; ==============================================================
DrawBall:
            ; Build the full-colour byte for red squares
            ; DRAWCOL=3 -> col_byte = $FF (colour 3 in all 4 slots)
            ; DRAWCOL=0 -> col_byte = $00
            LD      A,(DRAWCOL)
            OR      A
            JP      Z,DB_ColSet
            LD      A,$FF           ; colour 3 in all subpixels
DB_ColSet:
            LD      (COLBYTE),A     ; $FF or $00

            ; Loop i = 0..44
            XOR     A
            LD      (WIDX),A        ; WIDX = width table index (0..44)

DB_RowLoop:
            LD      A,(WIDX)
            CP      WIDTAB_LEN
            JP      NZ,DB_RowDo
            RET                     ; done all rows

DB_RowDo:
            ; dy = i - RY  (signed, -20..+20)
            SUB     RY              ; A = dy (signed two's complement)
            LD      (DY_TMP),A      ; save signed dy

            ; py = BY + dy
            LD      B,A             ; B = dy (signed)
            LD      A,(BY)
            ADD     A,B             ; A = BY + dy (may overflow/underflow)
            ; Check 0 <= py <= 63
            CP      64
            JP      NC,DB_SkipRow   ; py >= 64 (or wrapped negative -> >= 64)
            LD      (PY_TMP),A

            ; w = WIDTHTAB[i]
            LD      A,(WIDX)
            LD      E,A
            LD      D,0
            LD      HL,WIDTHTAB
            ADD     HL,DE
            LD      A,(HL)          ; A = w
            LD      (W_TMP),A

            ; px_left = BX - w
            LD      B,A             ; B = w
            LD      A,(BX)
            SUB     B               ; A = BX - w (px_left)
            ; Clamp: if carry (< 0), use 0
            JP      NC,DB_LeftOK
            XOR     A               ; clamp to 0
DB_LeftOK:
            LD      (PXLEFT),A

            ; px_right = BX + w
            LD      A,(BX)
            LD      B,A
            LD      A,(W_TMP)
            ADD     A,B             ; A = BX + w (px_right)
            ; Clamp: if > 127, use 127
            CP      128
            JP      C,DB_RightOK
            LD      A,127
DB_RightOK:
            LD      (PXRIGHT),A

            ; Compute VRAM row base address
            LD      A,(PY_TMP)
            LD      L,A
            LD      H,0
            ADD     HL,HL           ; HL = py*2
            LD      DE,YTAB
            ADD     HL,DE           ; HL = &YTAB[py*2]
            LD      E,(HL)
            INC     HL
            LD      D,(HL)          ; DE = $7000 + 32*py (row base)

            ; Compute starting band parity
            ; band_start = (-w + dy + PHASE) >> 2, test bit 0
            ; = (PHASE + dy - w) >> 2
            ; We only need bit 2 of (PHASE + dy - w) 
            LD      A,(PHASE)
            LD      B,A             ; B = PHASE
            LD      A,(DY_TMP)      ; A = dy (signed byte)
            ADD     A,B             ; A = dy + PHASE
            LD      B,A             ; B = dy + PHASE
            LD      A,(W_TMP)
            LD      C,A             ; C = w
            LD      A,B
            SUB     C               ; A = dy + PHASE - w
            ; bit 2 determines starting parity
            AND     4               ; isolate bit 2
            LD      (STARTPAR),A    ; $04 or $00

            ; Now render the span from PXLEFT to PXRIGHT
            ; Each byte covers pixels at x & ~3 .. (x & ~3)+3
            ;
            ; byte_left = PXLEFT >> 2
            ; byte_right = PXRIGHT >> 2
            ;
            ; If byte_left == byte_right: partial byte only
            ; Else: left partial, middle full, right partial

            LD      A,(PXLEFT)
            SRL     A
            SRL     A               ; A = byte_left column
            LD      (BCOLLEFT),A
            LD      A,(PXRIGHT)
            SRL     A
            SRL     A               ; A = byte_right column
            LD      (BCOLRIGHT),A

            ; HL = VRAM address of leftmost byte
            LD      A,(BCOLLEFT)
            LD      L,A
            LD      H,0
            ADD     HL,DE           ; HL = DE + byte_col_left
            LD      (VRAMPTR),HL    ; save for later

            ; Determine starting colour:
            ; startpar = $04: start with COLBYTE, then alternate
            ; startpar = $00: start with $00, then alternate
            LD      A,(STARTPAR)
            OR      A
            JP      NZ,DB_StartRed
            ; Start with background (COLBYTE is for the other half)
            XOR     A
            LD      (CURCOL),A
            LD      A,(COLBYTE)
            LD      (ALTCOL),A
            JP      DB_StartDone
DB_StartRed:
            LD      A,(COLBYTE)
            LD      (CURCOL),A
            XOR     A
            LD      (ALTCOL),A
DB_StartDone:

            ; Check if span fits in one byte
            LD      A,(BCOLLEFT)
            LD      B,A
            LD      A,(BCOLRIGHT)
            CP      B
            JP      NZ,DB_MultiBytes

            ; --- SINGLE BYTE CASE ---
            ; Need to mask: only affect pixels from PXLEFT&3 to PXRIGHT&3
            CALL    DrawSingleByte
            JP      DB_NextRow

            ; --- MULTI BYTE CASE ---
DB_MultiBytes:
            ; Left partial byte
            CALL    DrawLeftByte

            ; Swap colours for next byte
            CALL    SwapColours

            ; Middle full bytes
            LD      HL,(VRAMPTR)    ; currently points to byte after left
            LD      A,(BCOLLEFT)
            INC     A               ; first middle column
            LD      B,A
            LD      A,(BCOLRIGHT)
            ; middle bytes: from BCOLLEFT+1 to BCOLRIGHT-1
            CP      B
            JP      C,DB_NoMiddle   ; bcolright < bcolleft+1 means no middle
            DEC     A               ; last middle column
            SUB     B               ; count = last - first
            INC     A               ; count of middle bytes
            LD      B,A             ; B = count
DB_MiddleLoop:
            LD      A,(CURCOL)
            LD      (HL),A
            INC     HL
            CALL    SwapColours
            DEC     B
            JP      NZ,DB_MiddleLoop
            LD      (VRAMPTR),HL
DB_NoMiddle:

            ; Right partial byte
            CALL    DrawRightByte

DB_NextRow:
DB_SkipRow:
            LD      A,(WIDX)
            INC     A
            LD      (WIDX),A
            JP      DB_RowLoop

; ==============================================================
; DrawSingleByte - ball span fits entirely within one VRAM byte
; Masks out only the pixels between PXLEFT&3 and PXRIGHT&3
; ==============================================================
DrawSingleByte:
            LD      A,(PXLEFT)
            AND     3               ; left subpixel
            LD      B,A
            LD      A,(PXRIGHT)
            AND     3               ; right subpixel
            LD      C,A
            ; Build mask: bits set for subpixels B..C
            ; Mask = (full_left_mask) AND (full_right_mask)
            ; full_left_mask from subpixel B: clears pixels 0..B-1, keeps B..3
            ;   $FF >> (B*2) -- using table
            LD      E,B
            LD      D,0
            LD      HL,LMASK
            ADD     HL,DE
            LD      B,(HL)          ; B = left edge mask
            ; full_right_mask from subpixel C: keeps 0..C, clears C+1..3
            LD      E,C
            LD      D,0
            LD      HL,RMASK
            ADD     HL,DE
            LD      C,(HL)          ; C = right edge mask
            LD      A,B
            AND     C               ; A = combined mask (bits to affect)
            LD      B,A             ; B = pixel mask
            ; Colour within mask: if CURCOL != 0, fill with $FF masked
            LD      A,(CURCOL)
            AND     B               ; colour bits only where mask is 1
            LD      C,A             ; C = bits to set
            LD      A,B
            CPL                     ; invert mask = bits to clear
            LD      D,A             ; D = clear mask
            LD      HL,(VRAMPTR)
            LD      A,(HL)
            AND     D               ; clear target bits
            OR      C               ; set colour bits
            LD      (HL),A
            RET

; ==============================================================
; DrawLeftByte - write leftmost (partial) byte of span
; Affects pixels from PXLEFT&3 to pixel 3 of that byte
; ==============================================================
DrawLeftByte:
            LD      A,(PXLEFT)
            AND     3
            LD      E,A
            LD      D,0
            LD      HL,LMASK
            ADD     HL,DE
            LD      B,(HL)          ; B = left mask ($FF, $3F, $0F, $03)
            LD      A,(CURCOL)
            AND     B               ; colour bits in masked region
            LD      C,A
            LD      A,B
            CPL
            LD      D,A             ; D = clear mask
            LD      HL,(VRAMPTR)
            LD      A,(HL)
            AND     D
            OR      C
            LD      (HL),A
            INC     HL
            LD      (VRAMPTR),HL
            RET

; ==============================================================
; DrawRightByte - write rightmost (partial) byte of span
; Affects pixels 0 to PXRIGHT&3 of that byte
; ==============================================================
DrawRightByte:
            LD      A,(PXRIGHT)
            AND     3
            LD      E,A
            LD      D,0
            LD      HL,RMASK
            ADD     HL,DE
            LD      B,(HL)          ; B = right mask ($C0, $F0, $FC, $FF)
            LD      A,(CURCOL)
            AND     B
            LD      C,A
            LD      A,B
            CPL
            LD      D,A
            LD      HL,(VRAMPTR)
            LD      A,(HL)
            AND     D
            OR      C
            LD      (HL),A
            RET

; ==============================================================
; SwapColours - toggle CURCOL between COLBYTE and 0
; ==============================================================
SwapColours:
            LD      A,(CURCOL)
            OR      A
            JP      NZ,SC_WasRed
            LD      A,(COLBYTE)
            LD      (CURCOL),A
            RET
SC_WasRed:
            XOR     A
            LD      (CURCOL),A
            RET

; ==============================================================
; ====================  DATA SECTION  ==========================
; ==============================================================

; --- Ball state ---
BX:         DB      64              ; ball X centre (0..127)
BY:         DB      32              ; ball Y centre (0..63)
VX:         DB      2               ; X velocity (signed)
VY:         DB      1               ; Y velocity (signed)
PHASE:      DB      0               ; checker rotation phase

; --- Draw state ---
DRAWCOL:    DB      0               ; 0=erase, 3=draw red
COLBYTE:    DB      0               ; $FF or $00
STARTPAR:   DB      0               ; starting colour parity

; --- Per-row temporaries ---
WIDX:       DB      0               ; current row index (0..44)
DY_TMP:     DB      0               ; signed dy for this row
PY_TMP:     DB      0               ; screen Y for this row
W_TMP:      DB      0               ; half-width for this row
PXLEFT:     DB      0               ; left pixel X
PXRIGHT:    DB      0               ; right pixel X
BCOLLEFT:   DB      0               ; left byte column
BCOLRIGHT:  DB      0               ; right byte column
VRAMPTR:    DW      0               ; current VRAM write pointer
CURCOL:     DB      0               ; current fill colour ($FF or $00)
ALTCOL:     DB      0               ; alternate colour

; --- Edge pixel masks ---
; LMASK[sp] = mask for pixels sp..3 (left edge: keep sp and right)
;   sp=0: $FF (all 4 pixels)
;   sp=1: $3F (pixels 1,2,3 = bits 5-0)
;   sp=2: $0F (pixels 2,3 = bits 3-0)
;   sp=3: $03 (pixel 3 = bits 1-0)
LMASK:      DB      $FF, $3F, $0F, $03

; RMASK[sp] = mask for pixels 0..sp (right edge: keep 0 to sp)
;   sp=0: $C0 (pixel 0 = bits 7-6)
;   sp=1: $F0 (pixels 0,1 = bits 7-4)
;   sp=2: $FC (pixels 0,1,2 = bits 7-2)
;   sp=3: $FF (all 4 pixels)
RMASK:      DB      $C0, $F0, $FC, $FF

; --- VRAM row base table (little-endian 16-bit) ---
; YTAB[y] = $7000 + 32*y, y=0..63
YTAB:
            DB $00,$90, $20,$90, $40,$90, $60,$90
            DB $80,$90, $A0,$90, $C0,$90, $E0,$90
            DB $00,$91, $20,$91, $40,$91, $60,$91
            DB $80,$91, $A0,$91, $C0,$91, $E0,$91
            DB $00,$92, $20,$92, $40,$92, $60,$92
            DB $80,$92, $A0,$92, $C0,$92, $E0,$92
            DB $00,$93, $20,$93, $40,$93, $60,$93
            DB $80,$93, $A0,$93, $C0,$93, $E0,$93
            DB $00,$94, $20,$94, $40,$94, $60,$94
            DB $80,$94, $A0,$94, $C0,$94, $E0,$94
            DB $00,$95, $20,$95, $40,$95, $60,$95
            DB $80,$95, $A0,$95, $C0,$95, $E0,$95
            DB $00,$96, $20,$96, $40,$96, $60,$96
            DB $80,$96, $A0,$96, $C0,$96, $E0,$96
            DB $00,$97, $20,$97, $40,$97, $60,$97
            DB $80,$97, $A0,$97, $C0,$97, $E0,$97

; --- Circle half-width table (ELLIPSE corrected for pixel aspect ratio) ---
; Pixel aspect = 2 wide : 3 tall. To look round: RX=30, RY=20.
; WIDTHTAB[i] = floor(RX * sqrt(1 - ((i-RY)/RY)^2)), i=0..40
; Physical size: 30*2=60 units wide, 20*3=60 units tall -> perfect circle.
WIDTHTAB:
            DB  0, 9,13,15,17,19,21,22,24,25,25
            DB 26,27,28,28,29,29,29,29,29,30,29
            DB 29,29,29,29,28,28,27,26,25,25,24
            DB 22,21,19,17,15,13, 9, 0

; ==============================================================
; End of file
; ==============================================================


; ================================================================
; VZ200 / VZ300 6847 MODE(0) — 32x16 Inner-Circles Plasma (Solid blocks)
; Back-buffer at $A000, radial map at $A200, V-sync wait, 512B LDIR to $7000..$71FF
; Author: Copilot for David Maunder
; Origin: $8000, Latch: $6800, VRAM: $7000..$71FF (MODE(0) 32x16)
; Stack: $B000
;
; Semigraphics (MODE(0)) byte: bit7=1, bits6..4=colour(0..7), bits3..0=pattern.
; We force pattern=1111b so each cell is a solid 2x2 block:
; final = 1ccc1111 => 143,159,175,191,207,223,239,255.
;
; Colour per cell combines six 3-bit sines:
;   c0 = sine3[(x + phaseX0) & 63]
;   c1 = sine3[(y + phaseY0) & 63]
;   c2 = sine3[(x + y + phaseD0) & 63]
;   c3 = sine3[((2*x) + phaseX1) & 63]
;   c4 = sine3[((2*y) + phaseY1) & 63]
;   c5 = sine3[( radial(x,y) + phaseR ) & 63]   ; radial prebuilt (0..63)
; colour = ((c0+c1+c2)>>1 + (c3+c4+c5)>>1 + colPhase) & 7
; ================================================================

            ORG     $8000

RADIAL_BUF  EQU     $A200              ; 512 bytes (32x16) 0..63 per cell

START:
            DI

; --- MODE(0): A/G=0, CSS selectable (bit4); mirror to $783B ---
            LD      A,(css_init)       ; 0=green background, 16=orange background
            AND     16
            LD      ($6800),A
            LD      ($783B),A

; ---- Build 32x16 radial table once at startup at RADIAL_BUF ----
            CALL    BUILD_RADIAL

; ---- Init phases ----
            LD      A,0
            LD      (phaseX0),A
            LD      (phaseY0),A
            LD      (phaseD0),A
            LD      (phaseX1),A
            LD      (phaseY1),A
            LD      (phaseR),A
            LD      (colPhase),A
            LD      (frame),A

; Motion speeds (tweak to taste)
            LD      A,2
            LD      (stepX0),A
            LD      A,2
            LD      (stepY0),A
            LD      A,1
            LD      (stepD0),A

            LD      A,3
            LD      (stepX1),A
            LD      A,3
            LD      (stepY1),A

            LD      A,2
            LD      (stepR),A
            LD      A,1
            LD      (stepC),A

; ================================================================
; Main loop: render to $A000, V-sync, then LDIR 512 bytes to $7000
; ================================================================
MAIN_FRAME:
; Render to back-buffer ($A000)
            LD      DE,$A000
            LD      HL,RADIAL_BUF
            LD      A,16
            LD      (rows_left),A
            LD      A,0
            LD      (yidx),A

Y_LOOP:
; c1_row = sine3[(y + phaseY0) & 63]
            LD      A,(yidx)
            LD      H,A
            LD      A,(phaseY0)
            ADD     A,H
            AND     63
            LD      BC,sine3
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (c1_row),A

; Keep per-row pointer into radial map -> save HL to rad_lo/rad_hi via A
            LD      A,L
            LD      (rad_lo),A
            LD      A,H
            LD      (rad_hi),A

; X loop: 32 columns
            LD      A,32
            LD      (cols_left),A
            LD      A,0
            LD      (xidx),A

X_LOOP:
; c0 = sine3[(x + phaseX0) & 63]
            LD      A,(xidx)
            LD      H,A
            LD      A,(phaseX0)
            ADD     A,H
            AND     63
            LD      BC,sine3
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (c0_pix),A

; c2 = sine3[(x + y + phaseD0) & 63]
            LD      A,(xidx)
            LD      H,A
            LD      A,(yidx)
            ADD     A,H
            LD      H,A
            LD      A,(phaseD0)
            ADD     A,H
            AND     63
            LD      BC,sine3
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (c2_pix),A

; c3 = sine3[((2*x) + phaseX1) & 63]
            LD      A,(xidx)
            ADD     A,A
            AND     63
            LD      H,A
            LD      A,(phaseX1)
            ADD     A,H
            AND     63
            LD      BC,sine3
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (c3_pix),A

; c4 = sine3[((2*y) + phaseY1) & 63]
            LD      A,(yidx)
            ADD     A,A
            AND     63
            LD      H,A
            LD      A,(phaseY1)
            ADD     A,H
            AND     63
            LD      BC,sine3
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (c4_pix),A

; c5 = sine3[( radial(x,y) + phaseR ) & 63]
; Load HL from rad_lo/rad_hi via A
            LD      A,(rad_lo)
            LD      L,A
            LD      A,(rad_hi)
            LD      H,A
            LD      A,(HL)             ; A = radial 0..63
            INC     HL                 ; advance pointer for next column
; Store HL back via A
            LD      A,L
            LD      (rad_lo),A
            LD      A,H
            LD      (rad_hi),A

            LD      H,A
            LD      A,(phaseR)
            ADD     A,H
            AND     63
            LD      BC,sine3
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (c5_pix),A

; ((c0+c1+c2)>>1 + (c3+c4+c5)>>1 + colPhase) & 7
; sumA_half
            LD      A,(c0_pix)
            LD      H,A
            LD      A,(c1_row)
            ADD     A,H
            LD      H,A
            LD      A,(c2_pix)
            ADD     A,H
            SRL     A
            LD      (sumA_half),A

; sumB_half in A
            LD      A,(c3_pix)
            LD      H,A
            LD      A,(c4_pix)
            ADD     A,H
            LD      H,A
            LD      A,(c5_pix)
            ADD     A,H
            SRL     A                  ; A = sumB>>1

            LD      H,A
            LD      A,(sumA_half)
            ADD     A,H
            LD      H,A
            LD      A,(colPhase)
            ADD     A,H
            AND     7
            LD      (col_cur),A

; Solid semigraphics: 1ccc1111
            LD      A,(col_cur)
            RLCA
            RLCA
            RLCA
            RLCA
            OR      128
            LD      H,A
            LD      A,15;17;31;17;15
            OR      H                  ; A = 1ccc1111

; write to back-buffer and advance
            LD      (DE),A
            INC     DE

; xidx = (xidx + 1) & 63
            LD      A,(xidx)
            INC     A
            AND     63
            LD      (xidx),A

; cols_left--
            LD      A,(cols_left)
            DEC     A
            LD      (cols_left),A
            OR      A
            JP      NZ,X_LOOP

; end row: yidx = (yidx + 1) & 63
            LD      A,(yidx)
            INC     A
            AND     63
            LD      (yidx),A

; rows_left--
            LD      A,(rows_left)
            DEC     A
            LD      (rows_left),A
            OR      A
            JP      NZ,Y_LOOP

; ---- V-sync then LDIR 512 bytes buffer -> VRAM ----
WV_W0:
            LD      A,($6800)
            AND     128
            Jr      NZ,WV_W0

;            LD      HL,$A000
 ;           LD      DE,$7000
  ;          LD      BC,$0200
   ;         LDIR

	LD 	HL, $A000
 	LD 	DE, $7000
 	LD 	B, 128          ; 128 iterations of 16 LDIs = 2048 bytes

	CPYLOOP:LDI 
		LDI 
		LDI 
		LDI

		LDI 
		LDI 
		LDI 
		LDI

		LDI 
		LDI 
		LDI 
		LDI

		LDI 
		LDI 
		LDI

		LDI

		DJNZ CPYLOOP



; ---- advance phases ----
            LD      A,(frame)
            INC     A
            LD      (frame),A

; Low-frequency set
            LD      A,(phaseX0)
            LD      H,A
            LD      A,(stepX0)
            ADD     A,H
            AND     63
            LD      (phaseX0),A

            LD      A,(phaseY0)
            LD      H,A
            LD      A,(stepY0)
            ADD     A,H
            AND     63
            LD      (phaseY0),A

            LD      A,(phaseD0)
            LD      H,A
            LD      A,(stepD0)
            ADD     A,H
            AND     63
            LD      (phaseD0),A

; Higher-harmonics
            LD      A,(phaseX1)
            LD      H,A
            LD      A,(stepX1)
            ADD     A,H
            AND     63
            LD      (phaseX1),A

            LD      A,(phaseY1)
            LD      H,A
            LD      A,(stepY1)
            ADD     A,H
            AND     63
            LD      (phaseY1),A

; Radial phase
            LD      A,(phaseR)
            LD      H,A
            LD      A,(stepR)
            ADD     A,H
            AND     63
            LD      (phaseR),A

; Colour drift
            LD      A,(colPhase)
            LD      H,A
            LD      A,(stepC)
            ADD     A,H
            AND     7
            LD      (colPhase),A

            JP      MAIN_FRAME

; ================================================================
; Subroutines
; ================================================================

; Build RADIAL_BUF: for y=0..15, x=0..31
; radial(x,y) ˜ ((dx^2>>1) + (dy^2>>1)) & 63, with
;   dx = |x-16| (0..16), dy = |y-8| (0..8)
; Uses sq16[0..16] and sq8[0..8].
BUILD_RADIAL:
            LD      DE,RADIAL_BUF
            LD      A,0
            LD      (ybuild),A
            LD      A,16
            LD      (rows_bld),A

BR_YROW:
; dyAbs = |y-8|
            LD      A,(ybuild)
            LD      H,A
            LD      A,H
            CP      8
            JP      C,BR_YLOW
            LD      A,H
            SUB     8
            JP      BR_YABS_OK
BR_YLOW:
            LD      A,8
            SUB     H
BR_YABS_OK:
; dy2 = sq8[dyAbs]
            LD      BC,sq8
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)
            LD      (dy2_row),A

; build 32 columns
            LD      A,0
            LD      (xbuild),A
            LD      A,32
            LD      (cols_bld),A

BR_XCOL:
; dxAbs = |x-16|
            LD      A,(xbuild)
            LD      H,A
            LD      A,H
            CP      16
            JP      C,BR_XLOW
            LD      A,H
            SUB     16
            JP      BR_XABS_OK
BR_XLOW:
            LD      A,16
            SUB     H
BR_XABS_OK:
; dx2 = sq16[dxAbs]
            LD      BC,sq16
            LD      L,A
            LD      H,0
            ADD     HL,BC
            LD      A,(HL)            ; A = dx2 0..256
            SRL     A                 ; dx2 >> 1
            LD      H,A

; dy2 >> 1
            LD      A,(dy2_row)
            SRL     A

; sum = (dx2>>1) + (dy2>>1), compress to 0..63
            ADD     A,H
            AND     63
            LD      (DE),A
            INC     DE

; xbuild++
            LD      A,(xbuild)
            INC     A
            LD      (xbuild),A

; cols_bld--
            LD      A,(cols_bld)
            DEC     A
            LD      (cols_bld),A
            OR      A
            JP      NZ,BR_XCOL

; next row
            LD      A,(ybuild)
            INC     A
            LD      (ybuild),A

            LD      A,(rows_bld)
            DEC     A
            LD      (rows_bld),A
            OR      A
            JP      NZ,BR_YROW
            RET

; Wait for frame start using FS (bit7) via reads in $6800..$6FFF
;WAIT_VSYNC:
; Wait for FS=0
;WV_W0:
   ;         LD      A,($6800)
  ;          AND     128
 ;           Jr      NZ,WV_W0
; Wait for FS=1
;WV_W1:
  ;          LD      A,($6800)
 ;           AND     128
;            Jr      Z,WV_W1
;            RET

; ================================================================
; Data (all DB/DEFB at the very end)
; ================================================================

; MODE(0) background (bit4 CSS; bit3 A/G=0)
; 0  -> green background
; 16 -> orange background
css_init    DEFB    0

; Phases and speeds
phaseX0     DEFB    0
phaseY0     DEFB    0
phaseD0     DEFB    0
phaseX1     DEFB    0
phaseY1     DEFB    0
phaseR      DEFB    0
colPhase    DEFB    0
frame       DEFB    0

stepX0      DEFB    2
stepY0      DEFB    2
stepD0      DEFB    1
stepX1      DEFB    3
stepY1      DEFB    3
stepR       DEFB    2
stepC       DEFB    1

; Runtime temps
yidx        DEFB    0
xidx        DEFB    0
rows_left   DEFB    0
cols_left   DEFB    0
c1_row      DEFB    0
c0_pix      DEFB    0
c2_pix      DEFB    0
c3_pix      DEFB    0
c4_pix      DEFB    0
c5_pix      DEFB    0
sumA_half   DEFB    0
col_cur     DEFB    0

; Radial pointer shadow
rad_lo      DEFB    0
rad_hi      DEFB    0

; Build-radial temps
ybuild      DEFB    0
xbuild      DEFB    0
rows_bld    DEFB    0
cols_bld    DEFB    0
dy2_row     DEFB    0

; Smooth 3-bit sine (64 entries, 0..7)
sine3
            DEFB 0,0,0,1,1,1,2,2
            DEFB 2,3,3,3,4,4,4,5
            DEFB 5,5,6,6,6,7,7,7
            DEFB 7,7,6,6,6,5,5,5
            DEFB 4,4,4,3,3,3,2,2
            DEFB 2,1,1,1,0,0,0,0
            DEFB 0,0,1,1,1,2,2,2
            DEFB 3,3,3,2,2,1,1,0

; Squares for radial build
; sq16[n] = n*n for n=0..16 (8-bit fit pre-shifted later)
sq16
            DEFB 0,1,4,9,16,25,36,49
            DEFB 64,81,100,121,144,169,196,225
            DEFB 0                     ; 16*16=256 -> store 0 (we shift >>1 later)

; sq8[n] = n*n for n=0..8
sq8
            DEFB 0,1,4,9,16,25,36,49,64

; ================================================================
; End of file
; ================================================================

; ============================================================
; VZ200/VZ300 - MODE(1) Fractional-Zoom Chessboard (FAST, correct)
; JP only (no JR), no DJNZ, A-only for (nn), DI at start.
; ORG $8000, SP=$F000. MODE(1) latch bit3 @ $6800.
; VRAM $7000-$77FF (128x64, 2bpp).
;
; Method:
;   y_acc += Scale ; if carry then YBit ^= 1    (YBit kept in C)
;   x_acc += Scale ; if carry then XBit ^= 1    (XBit kept in RAM)
;   colourbit = XBit XOR YBit (0=yellow, 1=red)
;   Pack 4 pixels -> 1 byte (H) and store to (DE). DE is write pointer.
;
; 2bpp colour mapping (per pixel pair):
;   00=green  01=yellow  10=blue  11=red
;
; FIXES vs original z2f.asm:
;   FIX 1 - ScaleUp overflow: ADD A,STEP_EQU can wrap 252->0 (byte overflow).
;           Added JP C,ClampMax immediately after ADD to catch carry-out,
;           before CP MAXP1. Original only checked CP MAXP1 which was
;           never reached when A had already wrapped to 0.
;   FIX 2 - ScaleDown underflow: Added defensive pre-check; if Scale <= STEP
;           clamp immediately rather than SUB-and-check-after, preventing
;           a wrapped result ($FE etc.) from escaping into MainLoop.
;   FIX 3 - Rows counter initialised to 64 but checked for zero AT TOP
;           of loop (before body). Moved decrement-and-check to bottom
;           so all 64 rows are rendered with a clean DEC/JP NZ pattern,
;           eliminating the OR A / JP Z overhead and one redundant load.
; ============================================================

                ORG     $8000

; ------------ Tunable constants ------------
STEP_EQU        EQU     4        ; per-frame zoom delta
MIN_SCALE       EQU     4        ; coarsest (lowest) scale value
MAX_SCALE       EQU     252      ; finest  (highest) scale value
MAXP1           EQU     253      ; MAX_SCALE + 1  (used in CP after ADD)

Start:
                DI
                LD      SP,$F000

; Enter MODE(1)
                LD      A,8
                LD      ($6800),A

; Clear VRAM to $00 (all green/buff pixels)
                XOR     A
                CALL    FillVRAM

; Init scale and direction
                LD      A,64
                LD      (Scale),A
                LD      A,1
                LD      (ScaleDir),A

; ============================================================
; Main animation loop
; ============================================================
MainLoop:
                LD      DE,$7000              ; VRAM write pointer

; Cache Scale for this frame into L (L used as fast add operand)
                LD      A,(Scale)
                LD      L,A                   ; L = Scale

; Reset vertical accumulator; YBit lives in C for fast access
                XOR     A
                LD      (y_acc),A
                LD      C,A                   ; C = YBit = 0

; 64 rows loop - use B as row counter here reloaded each row
; (B is also reused as byte counter in ByteLoop; RowLoop reloads it)
                LD      A,64
                LD      (Rows),A

RowLoop:
; ---- y_acc += Scale ; if carry then YBit ^= 1 ----
                LD      A,(y_acc)
                ADD     A,L
                LD      (y_acc),A
                JP      NC,NoYToggle
                LD      A,C
                XOR     1
                LD      C,A
NoYToggle:

; Reset horizontal accumulator and XBit at left edge of each row
                XOR     A
                LD      (x_acc),A
                LD      (XBit),A

; 32 bytes per row
                LD      B,32

ByteLoop:
; Build one output byte (4 pixels) in H
                XOR     A
                LD      H,A

; ------------- Pixel 0 (bits 7..6) -------------
                LD      A,(x_acc)
                ADD     A,L
                LD      (x_acc),A
                JP      NC,P0_NoXToggle
                LD      A,(XBit)
                XOR     1
                LD      (XBit),A
P0_NoXToggle:
                LD      A,(XBit)
                XOR     C
                OR      A
                JP      Z,P0_Y
                LD      A,H
                OR      $C0                   ; 11 = red
                LD      H,A
                JP      P0_D
P0_Y:
                LD      A,H
                OR      $40                   ; 01 = yellow
                LD      H,A
P0_D:

; ------------- Pixel 1 (bits 5..4) -------------
                LD      A,(x_acc)
                ADD     A,L
                LD      (x_acc),A
                JP      NC,P1_NoXToggle
                LD      A,(XBit)
                XOR     1
                LD      (XBit),A
P1_NoXToggle:
                LD      A,(XBit)
                XOR     C
                OR      A
                JP      Z,P1_Y
                LD      A,H
                OR      $30                   ; 11 = red
                LD      H,A
                JP      P1_D
P1_Y:
                LD      A,H
                OR      $10                   ; 01 = yellow
                LD      H,A
P1_D:

; ------------- Pixel 2 (bits 3..2) -------------
                LD      A,(x_acc)
                ADD     A,L
                LD      (x_acc),A
                JP      NC,P2_NoXToggle
                LD      A,(XBit)
                XOR     1
                LD      (XBit),A
P2_NoXToggle:
                LD      A,(XBit)
                XOR     C
                OR      A
                JP      Z,P2_Y
                LD      A,H
                OR      $0C                   ; 11 = red
                LD      H,A
                JP      P2_D
P2_Y:
                LD      A,H
                OR      $04                   ; 01 = yellow
                LD      H,A
P2_D:

; ------------- Pixel 3 (bits 1..0) -------------
                LD      A,(x_acc)
                ADD     A,L
                LD      (x_acc),A
                JP      NC,P3_NoXToggle
                LD      A,(XBit)
                XOR     1
                LD      (XBit),A
P3_NoXToggle:
                LD      A,(XBit)
                XOR     C
                OR      A
                JP      Z,P3_Y
                LD      A,H
                OR      $03                   ; 11 = red
                LD      H,A
                JP      P3_D
P3_Y:
                LD      A,H
                OR      $01                   ; 01 = yellow
                LD      H,A
P3_D:

; Store packed 4-pixel byte to VRAM
                LD      A,H
                LD      (DE),A
                INC     DE

; Next byte in this row
                DEC     B
                JP      NZ,ByteLoop

; ---- Next row ----
; FIX 3: decrement Rows here, loop while non-zero (clean DEC/JP NZ)
                LD      A,(Rows)
                DEC     A
                LD      (Rows),A
                JP      NZ,RowLoop

; ============================================================
; End-of-frame: update Scale by +/-STEP_EQU and clamp
; ============================================================
EndFrame:
                LD      A,(ScaleDir)
                OR      A
                JP      Z,ScaleDown

; ---- Scale up ----
ScaleUp:
                LD      A,(Scale)
; FIX 1: check for byte overflow BEFORE comparing with MAXP1.
;        If ADD produces carry (e.g. 252+4 wraps to 0), jump straight
;        to clamp. Without this, Scale=0 escaped into MainLoop.
                ADD     A,STEP_EQU
                JP      C,ClampMax            ; carry = byte wrapped past 255
                CP      MAXP1
                JP      C,SU_Store            ; A < MAXP1, value is safe
ClampMax:
                LD      A,MAX_SCALE
                LD      (Scale),A
                LD      A,0
                LD      (ScaleDir),A
                JP      MainLoop
SU_Store:
                LD      (Scale),A
                JP      MainLoop

; ---- Scale down ----
ScaleDown:
; FIX 2: pre-check - if Scale <= MIN_SCALE, clamp immediately.
;        This prevents SUB from producing a wrapped result (e.g. $FE)
;        that passes the post-SUB CP check and escapes into MainLoop.
                LD      A,(Scale)
                CP      MIN_SCALE
                JP      Z,ClampMin            ; already at minimum
                JP      C,ClampMin            ; below minimum (defensive)
                SUB     STEP_EQU
                CP      MIN_SCALE
                JP      NC,SD_Store           ; result >= MIN_SCALE, safe
ClampMin:
                LD      A,MIN_SCALE
                LD      (Scale),A
                LD      A,1
                LD      (ScaleDir),A
                JP      MainLoop
SD_Store:
                LD      (Scale),A
                JP      MainLoop

; ============================================================
; FillVRAM: fill all 2048 bytes of MODE(1) VRAM with value in A
; Entry: A = fill byte
; Uses:  HL, DE, BC (all clobbered)
; ============================================================
FillVRAM:
                LD      HL,$7000
                LD      (HL),A
                LD      DE,$7001
                LD      BC,2047
                LDIR
                RET

; ============================================================
; DATA - all DB at end of file
; ============================================================
Scale:          DB      64
ScaleDir:       DB      1

y_acc:          DB      0
x_acc:          DB      0
XBit:           DB      0
Rows:           DB      0
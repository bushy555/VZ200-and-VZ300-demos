; ================================================================
; VZ200/VZ300 MODE(1) 128x64 — Classic Plasma Demo
; (FASTEST, NO HORIZONTAL OR VERTICAL DRIFT)
; ================================================================
;
; Three-wave sine interference plasma with 4x4 ordered dithering.
; Drift eliminated by:
;   - Wave3 = SinTab[t], cached once per frame (w3_frame)  -> no diag drift
;   - Wave2 = SinTab[y*4], static per row (no t term)      -> no vertical drift
;   - Wave1 = SinTab[(t + x*2) & $FF]                      -> lively animation
;
; Inner loop cost: 1 SinTab lookup per pixel (wave1) + dither + ColorMap.
;
; MC6847 MODE(1) colors (CSS=0):
;   0=Green, 1=Yellow, 2=Blue/Cyan, 3=Red/Orange
;
; Strict PASMO rules:
;   ORG $8000, SP $F000; JP-only; A-for-(nn); all DEFB/DEFW at end.
; ================================================================
        ORG     $8000
        JP      Start

; ---- EQU (no DB/DW) -------------------------------------------
VRAM        EQU $7000
LATCH       EQU $6800
ROWS        EQU 64
ROW_BYTES   EQU 32            ; 128 pixels / 4 per byte

; ================================================================
Start:
        LD      SP,$F000
        LD      A,8
	di
        LD      (LATCH),A     ; enter MODE(1)
        XOR     A
        LD      (time),A      ; time = 0

; ================================================================
; MainLoop — render frame, advance time, repeat forever
; ================================================================
MainLoop:
        CALL    RenderFrame
        LD      A,(time)
        ADD     A,3           ; time += 3 (keeps animation lively)
        LD      (time),A
        JP      MainLoop

; ================================================================
; RenderFrame
; Outer loop: y = 0..63
; ================================================================
RenderFrame:
        ; ---- wave3 = SinTab[t], cached once per frame ----
        LD      A,(time)
        LD      H,0
        LD      L,A
        LD      DE,SinTab
        ADD     HL,DE
        LD      A,(HL)
        LD      (w3_frame),A

        XOR     A
        LD      (ycur),A      ; y = 0

RowLoop:
        LD      A,(ycur)
        CP      ROWS
        JP      NC,FrameDone

; ---- wave2 = SinTab[y*4] (static per row, no time term) ----
        LD      A,(ycur)
        ADD     A,A
        ADD     A,A           ; A = y*4
        LD      H,0
        LD      L,A
        LD      DE,SinTab
        ADD     HL,DE
        LD      A,(HL)
        LD      (b_row),A     ; b_row = SinTab[y*4]

; ---- p1 start = t (wave1 phase) ----
        LD      A,(time)
        LD      (p1),A

; ---- Preload Bayer values for this y row ----
        LD      A,(ycur)
        AND     3             ; A = y%4
        ADD     A,A
        ADD     A,A           ; A = (y%4)*4
        LD      H,0
        LD      L,A
        LD      DE,BayerLUT
        ADD     HL,DE         ; HL = &BayerLUT[(y%4)*4]

        LD      A,(HL)
        LD      (bay0),A
        INC     HL
        LD      A,(HL)
        LD      (bay1),A
        INC     HL
        LD      A,(HL)
        LD      (bay2),A
        INC     HL
        LD      A,(HL)
        LD      (bay3),A

; ---- Set VRAM destination pointer for this row ----
        LD      A,(ycur)
        LD      H,0
        LD      L,A
        ADD     HL,HL         ; HL = y*2 (word index)
        LD      DE,RowBaseTbl
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      (vdst),DE     ; vdst = VRAM row base

; ---- Inner loop: 32 bytes per row ----
        LD      C,ROW_BYTES   ; C = byte counter (preserved by CalcColor)

ByteLoop:
        ; Pixel 0 (bits 7:6)
        LD      A,(bay0)
        LD      (cur_bay),A
        CALL    CalcColor
        LD      H,0
        LD      L,A
        LD      DE,PShift0
        ADD     HL,DE
        LD      A,(HL)
        LD      (acc_byte),A

        ; Pixel 1 (bits 5:4)
        LD      A,(bay1)
        LD      (cur_bay),A
        CALL    CalcColor
        LD      H,0
        LD      L,A
        LD      DE,PShift1
        ADD     HL,DE
        LD      A,(HL)
        LD      B,A
        LD      A,(acc_byte)
        OR      B
        LD      (acc_byte),A

        ; Pixel 2 (bits 3:2)
        LD      A,(bay2)
        LD      (cur_bay),A
        CALL    CalcColor
        LD      H,0
        LD      L,A
        LD      DE,PShift2
        ADD     HL,DE
        LD      A,(HL)
        LD      B,A
        LD      A,(acc_byte)
        OR      B
        LD      (acc_byte),A

        ; Pixel 3 (bits 1:0)
        LD      A,(bay3)
        LD      (cur_bay),A
        CALL    CalcColor
        LD      B,A
        LD      A,(acc_byte)
        OR      B

        ; Write packed byte
        LD      HL,(vdst)
        LD      (HL),A
        INC     HL
        LD      (vdst),HL

        DEC     C
        JP      NZ,ByteLoop

        ; Next row
        LD      A,(ycur)
        INC     A
        LD      (ycur),A
        JP      RowLoop

FrameDone:
        RET

; ================================================================
; CalcColor — fast hot path (1 SinTab lookup per pixel)
; IN:  p1       = wave1 phase (RAM), advances by +2 per pixel
;      b_row    = wave2 value for this row (static, no t)
;      w3_frame = wave3 for frame (SinTab[t])
;      cur_bay  = Bayer dither amount (0..30)
; OUT: A = color 0..3
; Mod: A, B, D, E, H, L   |  Preserves: C
; ================================================================
CalcColor:
        ; wave1 = SinTab[p1]
        LD      A,(p1)
        LD      E,A
        LD      D,0
        LD      HL,SinTab
        ADD     HL,DE
        LD      B,(HL)            ; B = SinTab[p1]

        ; raw = wave1 + w3_frame + b_row
        LD      A,B               ; A = wave1
        LD      D,A
        LD      A,(w3_frame)
        ADD     A,D               ; A = wave1 + w3
        LD      D,A
        LD      A,(b_row)
        ADD     A,D               ; A = raw

        ; dithered = raw + Bayer (saturate on carry)
        LD      D,A
        LD      A,(cur_bay)
        ADD     A,D
        JP      NC,.no_clamp
        LD      A,255
.no_clamp:
        ; color = ColorMap[dithered]
        LD      E,A
        LD      D,0
        LD      HL,ColorMap
        ADD     HL,DE
        LD      A,(HL)            ; A = color 0..3

        ; Advance p1 += 2
        LD      D,A
        LD      A,(p1)
        ADD     A,2
        LD      (p1),A
        LD      A,D
        RET

; ================================================================
; DATA — all DEFB/DEFW after code (PASMO strict rule)
; ================================================================
; VRAM row base addresses: VRAM + y*32, y = 0..63
RowBaseTbl:
        DEFW $7000,$7020,$7040,$7060
        DEFW $7080,$70A0,$70C0,$70E0
        DEFW $7100,$7120,$7140,$7160
        DEFW $7180,$71A0,$71C0,$71E0
        DEFW $7200,$7220,$7240,$7260
        DEFW $7280,$72A0,$72C0,$72E0
        DEFW $7300,$7320,$7340,$7360
        DEFW $7380,$73A0,$73C0,$73E0
        DEFW $7400,$7420,$7440,$7460
        DEFW $7480,$74A0,$74C0,$74E0
        DEFW $7500,$7520,$7540,$7560
        DEFW $7580,$75A0,$75C0,$75E0
        DEFW $7600,$7620,$7640,$7660
        DEFW $7680,$76A0,$76C0,$76E0
        DEFW $7700,$7720,$7740,$7760
        DEFW $7780,$77A0,$77C0,$77E0

; ---- SinTab ----
; 256-entry sine table, range 0..85.
SinTab:
        DEFB 42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57
        DEFB 58,59,60,61,62,63,64,65,66,66,67,68,69,70,71,71
        DEFB 72,73,73,74,75,76,76,77,77,78,78,79,79,80,80,81
        DEFB 81,82,82,82,83,83,83,83,84,84,84,84,84,84,84,84
        DEFB 85,84,84,84,84,84,84,84,84,83,83,83,83,82,82,82
        DEFB 81,81,80,80,79,79,78,78,77,77,76,76,75,74,73,73
        DEFB 72,71,71,70,69,68,67,66,66,65,64,63,62,61,60,59
        DEFB 58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43
        DEFB 42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27
        DEFB 26,25,24,23,22,21,20,19,18,18,17,16,15,14,13,13
        DEFB 12,11,11,10,9,8,8,7,7,6,6,5,5,4,4,3
        DEFB 3,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0
        DEFB 0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2
        DEFB 3,3,4,4,5,5,6,6,7,7,8,8,9,10,11,11
        DEFB 12,13,13,14,15,16,17,18,18,19,20,21,22,23,24,25
        DEFB 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41

; ---- ColorMap ----
; raw (0..255) -> color (0..3)
ColorMap:
        DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1
        DEFB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2
        DEFB 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
        DEFB 2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
        DEFB 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
        DEFB 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
        DEFB 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3

; ---- BayerLUT ----
; 4x4 ordered dither values (0..30) row-major
BayerLUT:
        DEFB  0,16, 4,20   ; y%4=0: x%4=0..3
        DEFB 24, 8,28,12   ; y%4=1
        DEFB  6,22, 2,18   ; y%4=2
        DEFB 30,14,26,10   ; y%4=3

; ---- Pixel placement shift tables ----
PShift0: DEFB 0, 64,128,192   ; color << 6
PShift1: DEFB 0, 16, 32, 48   ; color << 4
PShift2: DEFB 0,  4,  8, 12   ; color << 2
; Pixel 3 uses bits 1:0 directly.

; ---- Variables ----
time:       DEFB 0   ; animation phase (0..255)
w3_frame:   DEFB 0   ; SinTab[t] cached once per frame
ycur:       DEFB 0   ; current row
b_row:      DEFB 0   ; vertical wave value for this row (static, no t)
p1:         DEFB 0   ; wave1 phase; +2 per pixel
bay0:       DEFB 0
bay1:       DEFB 0
bay2:       DEFB 0
bay3:       DEFB 0
cur_bay:    DEFB 0
acc_byte:   DEFB 0
vdst:       DEFW 0

; ================================================================
; End of file
; ================================================================
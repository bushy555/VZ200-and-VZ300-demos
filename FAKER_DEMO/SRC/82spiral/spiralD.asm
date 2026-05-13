; ==============================================================
; VZ200/VZ300 MODE(1) - ROTATING SPIRAL DEMO
;
; Archimedean spiral, 3 turns, outer radius ~20px, centre (64,32).
; Single-pixel red line that rotates to give a hypnotic effect.
;
; MATHS (all integer, no floating point):
;   384 steps, angle_step=2 per step: 384*2=768=3*256 = 3 full turns
;   r_fp += 13 per step, r = r_fp_hi: after 384 steps r = 384*13/256 = 19.5
;   x = 64 + r * cos(angle) / 128          [MUL_S8_U8]
;   y = 32 + (r*43/64) * sin(angle) / 128  [2:3 pixel aspect correction]
;   cos(angle) = sin(angle+64) via SINE_Q quarter-wave table
;   PHASE increments 8/frame => full rotation in 32 frames
;
; FRAME CYCLE:
;   1. Clear bounding box: rows 18..46, byte cols 11..21 (11 bytes each)
;   2. PHASE += 8
;   3. Redraw spiral (384 steps, ~136 pixel writes)
;
; RULES: ORG $8000, JP-only, SP=$F000, LD A,(nn)/LD (nn),A for byte
;   vars only. All DB/DEFS at end.
; ==============================================================

            ORG     $8000
            JP      Start

VRAM        EQU     $7000
LATCH       EQU     $6800
CX          EQU     64
CY          EQU     32
PHASE_INC   EQU     8
R_STEP      EQU     26;20;13
ANGLE_STEP  EQU     2
BB_Y0       EQU     18
BB_Y1       EQU     46
BB_C0       EQU     11
BB_C1       EQU     21
BB_COLS     EQU     BB_C1-BB_C0+1   ; = 11

; ===================== Start ==========================
Start:
	di
            LD      A,8
            LD      (LATCH),A
            ; Clear VRAM
            LD      HL,VRAM
            LD      DE,VRAM+1
            LD      BC,2047
            XOR     A
            LD      (HL),A
            LDIR

            LD      HL,$9000
            LD      DE,$9000+1
            LD      BC,2047
            XOR     A
            LD      (HL),A
            LDIR

            XOR     A
            LD      (PHASE),A
            CALL    DrawSpiral

MainLoop:
    ;        CALL    ClearBox
            LD      A,(PHASE)
            ADD     A,PHASE_INC
            LD      (PHASE),A
            CALL    DrawSpiral
	ld	hl, $9000
	ld	de, $7000
	ld	bc, 2048
	ldir
            LD      HL,$9000
            LD      DE,$9000+1
            LD      BC,2047
            XOR     A
            LD      (HL),A
            LDIR

            JP      MainLoop

; ==============================================================
; ClearBox: zero bytes BB_C0..BB_C1 for rows BB_Y0..BB_Y1
; ==============================================================
ClearBox:
            LD      A,BB_Y0
            LD      (YTMP),A
CB_Row:
            LD      A,(YTMP)
            CP      BB_Y1+1
            JP      NC,CB_Done
            CALL    GetRowBase      ; A=y -> HL = VRAM row base
            LD      A,BB_C0
            ADD     A,L
            LD      L,A
            JP      NC,CB_NC
            INC     H
CB_NC:
            LD      B,BB_COLS
CB_Byte:
            LD      (HL),$00
            INC     HL
            DEC     B
            JP      NZ,CB_Byte
            LD      HL,YTMP
            INC     (HL)
            JP      CB_Row
CB_Done:    RET

; ==============================================================
; DrawSpiral: 384 steps, draws colour 3 (red) pixels
; 3 outer loops of 128 inner steps each
; ==============================================================
DrawSpiral:
            XOR     A
            LD      (RFPLO),A
            LD      (RFPHI),A
            LD      A,(PHASE)
            LD      (ANGACC),A
            LD      A,3
            LD      (OCTR),A

DS_Outer:
            LD      B,128
DS_Inner:
            PUSH    BC

            ; -- cos(angle) --
            LD      A,(ANGACC)
            ADD     A,64            ; cos = sin(angle+64)
            CALL    SineFetch       ; A = cos (signed byte)
            LD      (CTMP),A

            ; -- sin(angle) --
            LD      A,(ANGACC)
            CALL    SineFetch       ; A = sin (signed byte)
            LD      (STMP),A

            ; -- dx = cos * r / 128 --
            LD      A,(RFPHI)       ; A = r (unsigned 0..19)
            LD      B,A             ; B = r
            LD      A,(CTMP)        ; A = cos (signed)
            CALL    MUL_S8_U8       ; A = cos*r/128 (signed)
            ADD     A,CX
            LD      (XTMP),A

            ; -- r_y = r * 43 / 64  (aspect: *2/3 approx) --
            LD      A,(RFPHI)       ; A = r
            LD      B,43
            CALL    MUL_U8_U8_64    ; A = r*43/64 (unsigned, 0..13)
            LD      B,A             ; B = r_y

            ; -- dy = sin * r_y / 128 --
            LD      A,(STMP)        ; A = sin (signed)
            CALL    MUL_S8_U8       ; A = sin*r_y/128 (signed)
            ADD     A,CY
            LD      (YTMP),A

            ; -- range check --
            LD      A,(XTMP)
            CP      128
            JP      NC,DS_Skip      ; x >= 128 (catches neg wraparound too)
            LD      A,(YTMP)
            CP      64
            JP      NC,DS_Skip

            ; -- plot red pixel at (XTMP, YTMP) --
            LD      A,(XTMP)
            LD      B,A
            LD      A,(YTMP)
            LD      C,A
            CALL    PlotRed

DS_Skip:
            ; -- advance r_fp --
            LD      A,(RFPLO)
            ADD     A,R_STEP
            LD      (RFPLO),A
            LD      A,(RFPHI)
            ADC     A,0
            LD      (RFPHI),A
            ; -- advance angle --
            LD      A,(ANGACC)
            ADD     A,ANGLE_STEP
            LD      (ANGACC),A

            POP     BC
            DEC     B
            JP      NZ,DS_Inner
            LD      HL,OCTR
            DEC     (HL)
            JP      NZ,DS_Outer
            RET

; ==============================================================
; PlotRed: colour 3 (bits 11) at B=x, C=y
; Uses VPTMP to save VRAM byte address across table lookups.
; Trashes A, D, E, H, L. Preserves B, C.
; ==============================================================
PlotRed:
            ; Step 1: VRAM byte address -> save in VPTMP
            LD      A,C
            CALL    GetRowBase      ; HL = $7000 + 32*y (B unchanged)
            LD      A,B
            SRL     A
            SRL     A               ; A = x >> 2  (byte column)
            ADD     A,L
            LD      L,A
            JP      NC,PR_NC
            INC     H
PR_NC:
            ; Save VRAM addr in VPTMP (byte by byte - no LD (nn),HL)
            LD      A,L
            LD      (VPTMP),A
            LD      A,H
            LD      (VPTMP+1),A

            ; Step 2: subpixel = x & 3
            LD      A,B
            AND     3
            LD      E,A
            LD      D,0

            ; Step 3: set-bits from CBITS3[subpix]
            LD      HL,CBITS3
            ADD     HL,DE
            LD      B,(HL)          ; B = set bits

            ; Step 4: clear mask from CMASK3[subpix]
            LD      HL,CMASK3
            ADD     HL,DE
            LD      C,(HL)          ; C = clear mask

            ; Step 5: restore VRAM addr and RMW
            LD      A,(VPTMP)
            LD      L,A
            LD      A,(VPTMP+1)
            LD      H,A
            LD      A,(HL)
            AND     C
            OR      B
            LD      (HL),A
            RET

; ==============================================================
; GetRowBase: A=y -> HL = $7000 + 32*y
; Trashes A, D, E, H, L. Preserves B, C.
; ==============================================================
GetRowBase:
            LD      L,A
            LD      H,0
            ADD     HL,HL           ; HL = y*2
            LD      DE,YTAB
            ADD     HL,DE           ; HL = &YTAB[y*2]
            LD      E,(HL)
            INC     HL
            LD      D,(HL)
            EX      DE,HL           ; HL = VRAM row base
            RET

; ==============================================================
; SineFetch: A=angle(0..255) -> A = sin(angle), signed byte
; Trashes B, C, D, E, H, L.
; ==============================================================
SineFetch:
            LD      B,A
            AND     63              ; B=full angle, A=offset within quadrant
            LD      C,A
            LD      A,B
            AND     192             ; isolate quadrant bits
            CP      64
            JP      Z,SF_Q1
            CP      128
            JP      Z,SF_Q2
            CP      192
            JP      Z,SF_Q3
            ; Q0: 0..63, ascending positive
            LD      A,C
            JP      SF_Pos
SF_Q1:      ; Q1: 64..127, descending positive
            LD      A,63
            SUB     C
            JP      SF_Pos
SF_Q2:      ; Q2: 128..191, ascending negative
            LD      A,C
            JP      SF_Neg
SF_Q3:      ; Q3: 192..255, descending negative
            LD      A,63
            SUB     C
            JP      SF_Neg
SF_Pos:
            LD      HL,SINE_Q
            LD      E,A
            LD      D,0
            ADD     HL,DE
            LD      A,(HL)
            RET
SF_Neg:
            LD      HL,SINE_Q
            LD      E,A
            LD      D,0
            ADD     HL,DE
            LD      A,(HL)
            CPL
            INC     A               ; two's complement negate
            RET

; ==============================================================
; MUL_S8_U8: A=signed(-127..127), B=unsigned(0..43) -> A=A*B/128
; Round: add 64 to product before >>7
; Trashes B, C, D, E, H, L.
; ==============================================================
MUL_S8_U8:
            OR      A
            JP      P,MU_Pos
            CPL
            INC     A               ; A = |A|
            LD      C,1             ; negative flag
            JP      MU_Calc
MU_Pos:     LD      C,0
MU_Calc:
            LD      E,B             ; E = unsigned multiplier
            LD      D,0
            LD      H,0
            LD      L,0
            LD      B,8
MU_Loop:
            BIT     0,A
            JP      Z,MU_Sk
            ADD     HL,DE
MU_Sk:
            SRL     A
            SLA     E
            RL      D
            DEC     B
            JP      NZ,MU_Loop
            ; Round then >>7
            LD      A,L
            ADD     A,64
            LD      L,A
            LD      A,H
            ADC     A,0
            LD      H,A
            LD      B,7
MU_Sh:      SRA     H
            RR      L
            DEC     B
            JP      NZ,MU_Sh
            ; Apply sign
            LD      A,C
            OR      A
            JP      Z,MU_Done
            LD      A,L
            CPL
            LD      L,A
            LD      A,H
            CPL
            LD      H,A
            INC     HL
MU_Done:    LD      A,L
            RET

; ==============================================================
; MUL_U8_U8_64: A=unsigned, B=unsigned -> A = (A*B+32)/64
; Used for r_y = r*43/64 (aspect correction ~*2/3)
; Trashes B, C, D, E, H, L.
; ==============================================================
MUL_U8_U8_64:
            LD      E,B
            LD      D,0
            LD      H,0
            LD      L,0
            LD      B,8
M64_Loop:
            BIT     0,A
            JP      Z,M64_Sk
            ADD     HL,DE
M64_Sk:
            SRL     A
            SLA     E
            RL      D
            DEC     B
            JP      NZ,M64_Loop
            ; Round then >>6
            LD      A,L
            ADD     A,32
            LD      L,A
            LD      A,H
            ADC     A,0
            LD      H,A
            LD      B,6
M64_Sh:     SRL     H
            RR      L
            DEC     B
            JP      NZ,M64_Sh
            LD      A,L
            RET

; ==============================================================
; DATA SECTION
; ==============================================================
PHASE:      DB      0
RFPLO:      DB      0
RFPHI:      DB      0
ANGACC:     DB      0
OCTR:       DB      0
CTMP:       DB      0
STMP:       DB      0
XTMP:       DB      0
YTMP:       DB      0
VPTMP:      DW      0       ; VRAM byte ptr (lo at VPTMP, hi at VPTMP+1)

; Colour 3 (RED = bits 11) set/clear masks per subpixel position
CBITS3:     DB      $C0,$30,$0C,$03     ; set bits
CMASK3:     DB      $3F,$CF,$F3,$FC     ; clear mask

; VRAM row base table: YTAB[y*2] = lo, YTAB[y*2+1] = hi of ($7000+32*y)
YTAB:
            DB $00,$90,$20,$90,$40,$90,$60,$90
            DB $80,$90,$A0,$90,$C0,$90,$E0,$90
            DB $00,$91,$20,$91,$40,$91,$60,$91
            DB $80,$91,$A0,$91,$C0,$91,$E0,$91
            DB $00,$92,$20,$92,$40,$92,$60,$92
            DB $80,$92,$A0,$92,$C0,$92,$E0,$92
            DB $00,$93,$20,$93,$40,$93,$60,$93
            DB $80,$93,$A0,$93,$C0,$93,$E0,$93
            DB $00,$94,$20,$94,$40,$94,$60,$94
            DB $80,$94,$A0,$94,$C0,$94,$E0,$94
            DB $00,$95,$20,$95,$40,$95,$60,$95
            DB $80,$95,$A0,$95,$C0,$95,$E0,$95
            DB $00,$96,$20,$96,$40,$96,$60,$96
            DB $80,$96,$A0,$96,$C0,$96,$E0,$96
            DB $00,$97,$20,$97,$40,$97,$60,$97
            DB $80,$97,$A0,$97,$C0,$97,$E0,$97

; Quarter sine: SINE_Q[i] = round(127*sin(i*pi/128)), i=0..63
SINE_Q:
            DB   0,  3,  6,  9, 12, 16, 19, 22
            DB  25, 28, 31, 34, 37, 40, 43, 46
            DB  49, 52, 54, 57, 59, 62, 64, 67
            DB  71, 73, 75, 77, 80, 82, 84, 87
            DB  90, 92, 94, 96, 98,100,102,104
            DB 106,107,109,110,112,113,114,116
            DB 117,118,119,120,121,122,123,124
            DB 125,125,126,126,126,127,127,127

; ==============================================================
; End of file
; ==============================================================

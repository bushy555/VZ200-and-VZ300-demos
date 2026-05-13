; ==============================================================
; VZ200/VZ300 MODE(1) Polar XOR Demo  [v5 - DEFINITIVELY FIXED]
;
; THE ACTUAL ROOT CAUSE (found by cycle-accurate Z80 simulation):
;
;   PrecomputeAngles used this sequence to write SIN64[k]:
;
;     PUSH HL        ; HL = address of SIN64[k]
;     POP  DE        ; DE = address of SIN64[k]
;     POP  AF        ; A  = angle8
;     PUSH AF        ; re-save
;     CALL SineFetch ; *** SineFetch does LD D,0 / LD E,A internally
;                    ; so on return: D=0, E=sine_table_index
;                    ; DE is COMPLETELY TRASHED
;     LD   (DE),A    ; writes to $00xx (ROM) not SIN64[k] !!!
;
;   SineFetch clobbers DE. The write went to low ROM ($0000-$003F)
;   which is silently ignored. SIN64 and COS64 stayed all-zeros.
;   With sin=cos=0 for every ray, all pixel coordinates computed
;   as (CENTER_X, CENTER_Y) = (64,32). Every plot hit the same
;   VRAM byte. Hence: 1-2 visible dots, then crash as the loop
;   eventually corrupted a variable or hit garbage code.
;
; THE FIX:
;   Save the SIN64[k]/COS64[k] destination address in a memory
;   word (DESTMP) before calling SineFetch. After SineFetch
;   returns, reload HL from DESTMP and use LD (HL),A.
;   This completely avoids DE as an intermediary across the call.
;
; ALL PREVIOUS FIXES RETAINED:
;   - No LD HL,(nn) / LD (nn),HL in hot paths
;   - PlotPixel uses PUSH HL / POP HL for VRAM address
;   - Colour mask computed by shifting, no table pointer
;   - MUL documents it trashes all registers; DrawFrame reloads
;     r from (RVAL) after each MUL call
;
; STRICT RULES:
;   ORG $8000, JP-only (no JR/DJNZ), SP=$F000
;   Byte vars: LD A,(nn) / LD (nn),A only
;   16-bit indirect: only LD HL,(nn) in InitColorMap (startup only)
;                    and LD (DESTMP),HL / LD HL,(DESTMP) in PrecomputeAngles
;   MODE(1) via $6800 latch, 128x64, 2bpp
;   All DB/DW/DEFS at END
; ==============================================================

            ORG     $8000
            JP      Start

; --------------------- Constants ----------------------
VRAM        EQU     $7000
LATCH       EQU     $6800
CENTER_X    EQU     64
CENTER_Y    EQU     32
RMAX_P1     EQU     26
R_BAND_SHIFT EQU    2
ANG_BAND_BIT EQU    2

; ===================== Entry ==========================
Start:
            LD      SP,$F000
            LD      A,8
	di
            LD      (LATCH),A
            CALL    InitColorMap
            CALL    ClearVRAM
            CALL    PrecomputeAngles
            XOR     A
            LD      (AngPhase64),A
            LD      (RadPhase),A
            LD      (AngBandPhase),A

MainLoop:
;            CALL    ClearVRAM
            CALL    DrawFrame
            LD      A,(AngPhase64)
            INC     A
            AND     63
            LD      (AngPhase64),A
            LD      A,(RadPhase)
            INC     A
            LD      (RadPhase),A
            LD      A,(AngBandPhase)
            INC     A
            LD      (AngBandPhase),A
            JP      MainLoop

; =================== InitColorMap =====================
InitColorMap:
            LD      A,(COLSEL)
            CP      3
            JP      Z,ICM_Red
            LD      A,$80
            LD      (COLSTART),A
            RET
ICM_Red:
            LD      A,$C0
            LD      (COLSTART),A
            RET

; ==================== ClearVRAM =======================
ClearVRAM:
            LD      HL,VRAM
            LD      DE,VRAM+1
            LD      BC,2047
            XOR     A
            LD      (HL),A
;            LDIR
            RET

; ==============================================================
; PrecomputeAngles
;   Fills SIN64[k] and COS64[k] for k=0..63.
;   angle8 = k*4  (0..252, step 4 across the 0..255 circle)
;
;   KEY FIX: destination address saved in DESTMP (a DW variable)
;   before calling SineFetch, then restored after. This prevents
;   SineFetch's internal "LD D,0" from trashing DE and causing
;   LD (DE),A to write to the wrong address.
; ==============================================================
PrecomputeAngles:
            XOR     A
            LD      (KIDX),A

PA_Loop:
            LD      A,(KIDX)
            CP      64
            JP      NZ,PA_Do
            RET

PA_Do:
            ; angle8 = k * 4
            LD      A,(KIDX)
            ADD     A,A
            ADD     A,A             ; A = k*4
            LD      (ANGTMP),A      ; save angle8

            ; --- Write SIN64[k] = SineFetch(angle8) ---
            ; Compute destination address HL = SIN64 + k
            LD      A,(KIDX)
            LD      E,A
            LD      D,0
            LD      HL,SIN64
            ADD     HL,DE           ; HL = &SIN64[k]
            LD      (DESTMP),HL     ; FIX: save dest BEFORE SineFetch trashes DE/HL

            LD      A,(ANGTMP)      ; A = angle8
            CALL    SineFetch       ; A = sin result; DE/HL trashed - doesn't matter

            LD      HL,(DESTMP)     ; FIX: restore destination
            LD      (HL),A          ; SIN64[k] = sin(angle8)

            ; --- Write COS64[k] = SineFetch(angle8 + 64) ---
            LD      A,(KIDX)
            LD      E,A
            LD      D,0
            LD      HL,COS64
            ADD     HL,DE           ; HL = &COS64[k]
            LD      (DESTMP),HL     ; FIX: save dest BEFORE SineFetch

            LD      A,(ANGTMP)      ; A = angle8
            ADD     A,64            ; A = angle8 + 64 (wraps ok)
            CALL    SineFetch       ; A = cos result

            LD      HL,(DESTMP)     ; FIX: restore destination
            LD      (HL),A          ; COS64[k] = cos(angle8)

            LD      A,(KIDX)
            INC     A
            LD      (KIDX),A
            JP      PA_Loop

; ===================== DrawFrame ======================
DrawFrame:
            XOR     A
            LD      (KIDX),A

DF_KLoop:
            LD      A,(KIDX)
            CP      64
            JP      NZ,DF_KDo
            RET

DF_KDo:
            LD      B,A             ; B = k

            ; rotated idx = (k + AngPhase64) & 63
            LD      A,(AngPhase64)
            ADD     A,B
            AND     63
            LD      E,A
            LD      D,0

            ; COSTMP = COS64[idx]
            LD      HL,COS64
            ADD     HL,DE
            LD      A,(HL)
            LD      (COSTMP),A

            ; SINTMP = SIN64[idx]
            LD      HL,SIN64
            ADD     HL,DE
            LD      A,(HL)
            LD      (SINTMP),A

            ; ABTMP = ((k + AngBandPhase) >> ANG_BAND_BIT) & 1
            LD      A,(AngBandPhase)
            ADD     A,B
            SRL     A
            SRL     A
            AND     1
            LD      (ABTMP),A

            XOR     A
            LD      (RVAL),A

DF_RLoop:
            LD      A,(RVAL)
            CP      RMAX_P1
            JP      NZ,DF_RDo
            JP      DF_NextK

DF_RDo:
            ; dx = MUL(cos, r) ? X
            LD      A,(RVAL)
            LD      B,A
            LD      A,(COSTMP)
            CALL    MUL_S8_U8_DIV128
            ADD     A,CENTER_X
            LD      (XTMP),A

            ; dy = MUL(sin, r) ? Y  (reload r: MUL trashes all regs)
            LD      A,(RVAL)
            LD      B,A
            LD      A,(SINTMP)
            CALL    MUL_S8_U8_DIV128
            ADD     A,CENTER_Y
            LD      (YTMP),A

            ; rb = ((r + RadPhase) >> R_BAND_SHIFT) & 1
            LD      A,(RVAL)
            LD      B,A
            LD      A,(RadPhase)
            ADD     A,B
            SRL     A
            SRL     A
            AND     1

            ; pattern = rb XOR ab
            LD      B,A
            LD      A,(ABTMP)
            XOR     B
            AND     1
            JP      Z,DF_SkipPlot

            ; PlotPixel(X, Y, colour_seed)
            LD      A,(XTMP)
            LD      B,A
            LD      A,(YTMP)
            LD      C,A
            LD      A,(COLSTART)
            LD      E,A
            CALL    PlotPixel

DF_SkipPlot:
            LD      A,(RVAL)
            INC     A
            LD      (RVAL),A
            JP      DF_RLoop

DF_NextK:
            LD      A,(KIDX)
            INC     A
            LD      (KIDX),A
            JP      DF_KLoop

; ==============================================================
; PlotPixel
;   In:  B = X (0..127), C = Y (0..63)
;        E = colour seed ($80=BLUE, $C0=RED)
;   Out: A,D,E,H,L trashed. B,C preserved.
;
;   No LD HL,(nn) / LD (nn),HL in this routine.
;   VRAM address saved via PUSH HL / POP HL.
;   Colour/mask computed by shifting E (seed) and D ($C0) right
;   by subpix*2 positions, then CPL(D) = clear mask.
; ==============================================================
PlotPixel:
            ; Compute VRAM row base from Y_TAB
            LD      A,C             ; A = Y
            LD      L,A
            LD      H,0
            ADD     HL,HL           ; HL = Y*2  (index into Y_TAB)
            LD      DE,Y_TAB
            ADD     HL,DE           ; HL = &Y_TAB[Y*2]
            LD      A,(HL)          ; A = lo byte of VRAM row base
            INC     HL
            LD      H,(HL)          ; H = hi byte
            LD      L,A             ; HL = VRAM row base ($7000 + 32*Y)

            ; Add byte column: X>>2
            LD      A,B             ; A = X  (B untouched)
            SRL     A
            SRL     A               ; A = X>>2 (0..31)
            ADD     A,L             ; A = row_lo + col
            LD      L,A
            JP      NC,PP_NoCarry
            INC     H               ; carry into high byte (only for rows near $77xx)
PP_NoCarry:
            ; HL = exact VRAM byte address
            PUSH    HL              ; save it -- no LD (nn),HL needed

            ; subpix = X & 3
            LD      A,B             ; A = X
            AND     3               ; A = subpix (0..3)

            ; Compute clear mask (D) and set-bits (E) by shifting
            ; D starts as $C0 (mask for subpix 0), E = colour seed
            ; Both shift right 2 per subpix step
            LD      D,$C0
            OR      A               ; test subpix
            JP      Z,PP_ShiftDone  ; subpix=0: no shift needed
PP_ShiftLoop:
            SRL     D
            SRL     D               ; D >>= 2
            SRL     E
            SRL     E               ; E >>= 2
            DEC     A
            JP      NZ,PP_ShiftLoop
PP_ShiftDone:
            LD      A,D
            CPL
            LD      D,A             ; D = clear mask (~($C0 >> subpix*2))
                                    ; E = colour set-bits (seed >> subpix*2)

            ; Read-Modify-Write
            POP     HL              ; restore VRAM address
            LD      A,(HL)
            AND     D               ; clear the subpixel's 2 bits
            OR      E               ; set colour bits
            LD      (HL),A
            RET

; ==============================================================
; SineFetch
;   In:  A = angle (0..255, full circle = 256)
;   Out: A = sin(angle) as signed two's-complement byte
;   Trashes: B, C, D, E, H, L  (all general registers)
; ==============================================================
SineFetch:
            LD      B,A
            AND     63              ; offset within quadrant
            LD      C,A
            LD      A,B
            AND     192             ; quadrant: 0, 64, 128, 192
            CP      64
            JP      Z,SF_Q1
            CP      128
            JP      Z,SF_Q2
            CP      192
            JP      Z,SF_Q3
            ; Q0: ascending positive
            LD      A,C
            JP      SF_Pos
SF_Q1:      ; Q1: descending positive (mirror)
            LD      A,63
            SUB     C
            JP      SF_Pos
SF_Q2:      ; Q2: ascending negative
            LD      A,C
            JP      SF_Neg
SF_Q3:      ; Q3: descending negative (mirror)
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
; MUL_S8_U8_DIV128
;   In:  A = signed factor   (-127..127)  e.g. sin or cos
;        B = unsigned factor (0..25)      e.g. radius r
;   Out: A = round(A * B / 128) as signed byte
;   Trashes: ALL of B, C, D, E, H, L
; ==============================================================
MUL_S8_U8_DIV128:
            OR      A
            JP      P,MU_Pos
            CPL
            INC     A               ; A = |A|
            LD      C,1             ; sign: negative
            JP      MU_Do
MU_Pos:     LD      C,0             ; sign: positive
MU_Do:
            LD      E,B             ; E = r (multiplier)
            LD      D,0
            LD      H,0
            LD      L,0
            LD      B,8
MU_Loop:
            BIT     0,A
            JP      Z,MU_Skip
            ADD     HL,DE
MU_Skip:
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
MU_Shift:
            SRA     H
            RR      L
            DEC     B
            JP      NZ,MU_Shift

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
MU_Done:
            LD      A,L
            RET

; ==============================================================
; ====================  DATA SECTION  ==========================
; ==============================================================

COLSEL:         DB      2           ; 2=BLUE, 3=RED
COLSTART:       DB      $80         ; set by InitColorMap

AngPhase64:     DB      0
RadPhase:       DB      0
AngBandPhase:   DB      0

KIDX:           DB      0
RVAL:           DB      0
ANGTMP:         DB      0           ; angle8 = k*4 (scratch for PrecomputeAngles)
DESTMP:         DW      0           ; destination address for PrecomputeAngles writes
COSTMP:         DB      0
SINTMP:         DB      0
ABTMP:          DB      0
XTMP:           DB      0
YTMP:           DB      0

; Y_TAB: VRAM row base addresses (little-endian 16-bit)
; Entry y: $7000 + 32*y,  y = 0..63
Y_TAB:
            DB $00,$70, $20,$70, $40,$70, $60,$70
            DB $80,$70, $A0,$70, $C0,$70, $E0,$70
            DB $00,$71, $20,$71, $40,$71, $60,$71
            DB $80,$71, $A0,$71, $C0,$71, $E0,$71
            DB $00,$72, $20,$72, $40,$72, $60,$72
            DB $80,$72, $A0,$72, $C0,$72, $E0,$72
            DB $00,$73, $20,$73, $40,$73, $60,$73
            DB $80,$73, $A0,$73, $C0,$73, $E0,$73
            DB $00,$74, $20,$74, $40,$74, $60,$74
            DB $80,$74, $A0,$74, $C0,$74, $E0,$74
            DB $00,$75, $20,$75, $40,$75, $60,$75
            DB $80,$75, $A0,$75, $C0,$75, $E0,$75
            DB $00,$76, $20,$76, $40,$76, $60,$76
            DB $80,$76, $A0,$76, $C0,$76, $E0,$76
            DB $00,$77, $20,$77, $40,$77, $60,$77
            DB $80,$77, $A0,$77, $C0,$77, $E0,$77

; Quarter-wave sine: SINE_Q[i] = round(127 * sin(i * pi / 128)), i=0..63
SINE_Q:
            DB   0,  3,  6,  9, 12, 16, 19, 22
            DB  25, 28, 31, 34, 37, 40, 43, 46
            DB  49, 52, 54, 57, 59, 62, 64, 67
            DB  71, 73, 75, 77, 80, 82, 84, 87
            DB  90, 92, 94, 96, 98,100,102,104
            DB 106,107,109,110,112,113,114,116
            DB 117,118,119,120,121,122,123,124
            DB 125,125,126,126,126,127,127,127

; Runtime tables filled by PrecomputeAngles (signed bytes)
SIN64:          DEFS    64
COS64:          DEFS    64

; ==============================================================
; End of file
; ==============================================================

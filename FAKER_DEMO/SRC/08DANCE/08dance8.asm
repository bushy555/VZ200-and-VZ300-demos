; ============================================================
; VZ200 MODE(1) DANCING SINE CURVE DEMO
; Converted from DANCESIN.CPP (PC DOS VGA, josh83) to Z80 ASM
; Strict PASMO / VZ200 rules compliant
; ============================================================
;
; ORIGINAL C ALGORITHM (PC 320x200 VGA):
;   Loop b = 3..360 (degrees), per frame counter a:
;     c = b * pi / 180       (angle in radians for this curve point)
;     d = a * pi / 180       (slow time angle, advances each frame)
;     Y = 100 + 20*sin(2c+d) + 15*sin(c+2d) + 20*sin(c/2+d)
;     X = 160 + 50*sin(c+2d) + 25*sin(2c+d/2) - 50*sin(c+d)
;   Erase previous frame, draw new frame, loop.
;
; VZ200 ADAPTATION:
;   Screen: 128x64 pixels MODE(1), vs PC 320x200.
;   256 curve points (b=0..255, one per 8-bit table step).
;   c index = b directly (8-bit, wraps to give 256 steps per circle).
;   d index = FrameAngle (8-bit, incremented each frame).
;   Sin table: 256 entries, signed value * 64, stored two's complement.
;   Amplitudes scaled ~0.4x from PC original:
;     Y = 32 + (8*sin(2c+d) + 6*sin(c+2d) + 8*sin(c/2+d))  / 64
;     X = 64 + (20*sin(c+2d) + 10*sin(2c+d/2) - 20*sin(c+d)) / 64
;   Simulated coordinate ranges across all frames and curve points:
;     X: 14..108  (safe within 0..127)
;     Y: 11..52   (safe within 0..63)
;   Erase: re-plot previous positions in colour 0 (clears the 2-bit pixel pair).
;   Draw:  plot new positions in colour 3 (red/orange = 2-bit 11b).
;   Previous positions stored in PrevX, PrevY (256 bytes each).
;
; FIXED-POINT MULTIPLY / DIVIDE:
;   Sin table value S: signed byte -64..+64 (two's complement storage).
;   To compute amplitude * S: sign-extend S to 16-bit, then use shift-add.
;   To divide accumulator by 64: arithmetic shift right 6 (SRA H / RR L x6).
;
; VRAM PIXEL ADDRESSING:
;   Byte addr = $7000 + Y*32 + (X SHR 2)
;   Pixel slot = X AND 3:
;     Slot 0 -> bits 7:6  draw OR $C0  erase AND $3F
;     Slot 1 -> bits 5:4  draw OR $30  erase AND $CF
;     Slot 2 -> bits 3:2  draw OR $0C  erase AND $F3
;     Slot 3 -> bits 1:0  draw OR $03  erase AND $FC
;
; ============================================================

        ORG     $8000

START:
	di

        LD      A,8
        LD      ($6800),A           ; enter MODE(1) 128x64

        CALL    CLEAR_VRAM

        ; Initialise PrevX/PrevY to screen centre so first erase is harmless
        LD      HL,PrevX
        LD      B,0                 ; B=0 means 256 iterations with DJNZ
        LD      A,64
INIT_PX:
        LD      (HL),A
        INC     HL
        DJNZ    INIT_PX

        LD      HL,PrevY
        LD      B,0
        LD      A,32
INIT_PY:
        LD      (HL),A
        INC     HL
        DJNZ    INIT_PY

        XOR     A
        LD      (FrameAngle),A

; ------------------------------------------------------------
; MAIN LOOP
; ------------------------------------------------------------

MAIN_LOOP:

        ; ---- DRAW PASS: compute and draw
 ; Precompute d-derived indices once per frame
 LD A,(FrameAngle)
 LD (DVal),A
 ADD A,A
 LD (Idx2D),A
 LD A,(FrameAngle)
 SRL A
 LD (IdxDov2),A
; all 256 new positions ----
        LD      A,(FrameAngle)
        LD      (DVal),A            ; latch d for this entire frame

        LD      HL,PrevX
        LD      (PtrPX),HL
        LD      HL,PrevY
        LD      (PtrPY),HL

        XOR     A
        LD      (CurveB),A          ; b = 0

DRAW_LOOP:
        LD      A,(CurveB)
        CALL    CALC_XY             ; returns C=X, D=Y

        ; Store into previous-position arrays for next frame erase
        LD      HL,(PtrPX)
        LD      (HL),C
        INC     HL
        LD      (PtrPX),HL

        LD      HL,(PtrPY)
        LD      (HL),D
        INC     HL
        LD      (PtrPY),HL



;        LD      E,1                 ; flag: draw
        CALL    PLOT_PIX

        LD      A,(CurveB)
        INC     A
        LD      (CurveB),A
        JP      NZ,DRAW_LOOP        ; loop until B wraps 255->0 (256 points done)

        ; Advance frame angle
        LD      A,(FrameAngle)
        INC     A
        LD      (FrameAngle),A



;	ld	hl, $A000
;	ld	de, $7000
;	ld	bc, 2048
;	ldir

 LD HL,$A000
 LD DE,$7000
 LD BC,2048
Copy64_loop:
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    jp      pe, Copy64_loop

 ; ----------------------------------------------------------------
 ; 2) Restore background into buffer ($b000)
 ;    This also erases any stars and cube from the previous frame.
 ; ----------------------------------------------------------------
;
;	ld	hl, $A000
;	ld	de, $A001
;	ld	(hl), 85
;	ld	bc, 2048
;	ldir


 LD HL, $A000
 LD DE, $A001
 LD (hl), 85
 LD BC,2048
Copy64_loop2:
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    jp      pe, Copy64_loop2



        JP      MAIN_LOOP

; ============================================================
; CALC_XY
; Compute screen coordinates for one curve point.
; Entry:  A = b = c index (0..255)
;         (DVal) = d index for this frame (0..255)
; Exit:   C = X (14..108), D = Y (11..52)
; Clobbers: A, B, DE, HL
;
; Formula with fixed-point sin (table values are sin*64):
;   YSum = 8*sin(2c+d) + 6*sin(c+2d) + 8*sin(c/2+d)
;   Y    = 32 + YSum/64
;   XSum = 20*sin(c+2d) + 10*sin(2c+d/2) - 20*sin(c+d)
;   X    = 64 + XSum/64
; ============================================================

CALC_XY:
        LD      (TmpC),A            ; save c index

        ; Precompute angle indices
        ADD     A,A                 ; 2c mod 256
        LD      (Idx2C),A

        LD      A,(DVal)
        ADD     A,A                 ; 2d mod 256
        LD      (Idx2D),A

        LD      A,(TmpC)
        SRL     A                   ; c/2
        LD      (IdxCov2),A

        LD      A,(DVal)
        SRL     A                   ; d/2
        LD      (IdxDov2),A

        ; ---- Y accumulation ----

        ; Term Y1: 8 * sin(2c + d)
        LD      A,(Idx2C)
        LD      B,A
        LD      A,(DVal)
        ADD     A,B                 ; index = 2c+d
        CALL    SINLOOK             ; A = signed sin value (-64..+64)
        CALL    MUL8_A              ; HL = 8 * signed(A)
        LD      (Accum),HL

        ; Term Y2: 6 * sin(c + 2d)
        LD      A,(TmpC)
        LD      B,A
        LD      A,(Idx2D)
        ADD     A,B                 ; index = c+2d
        CALL    SINLOOK
        CALL    MUL6_A              ; HL = 6 * signed(A)
        LD      DE,(Accum)
        ADD     HL,DE
        LD      (Accum),HL

        ; Term Y3: 8 * sin(c/2 + d)
        LD      A,(IdxCov2)
        LD      B,A
        LD      A,(DVal)
        ADD     A,B                 ; index = c/2+d
        CALL    SINLOOK
        CALL    MUL8_A
        LD      DE,(Accum)
        ADD     HL,DE
        LD      (Accum),HL

        ; Y = 32 + Accum/64
        LD      HL,(Accum)
        CALL    ASR6_HL             ; signed divide by 64
        LD      A,L
        ADD     A,32
        LD      (TmpY),A            ; BUG FIX: save Y to memory, NOT D.
                                    ; MUL routines (MUL20_A, MUL10_A, MUL6_A) all
                                    ; execute LD D,H / LD E,L internally to save
                                    ; intermediate shift values. D is therefore
                                    ; clobbered during the entire X computation
                                    ; phase that follows. Y is reloaded into D
                                    ; from TmpY at the end of CALC_XY.

        ; ---- X accumulation ----

        ; Term X1: 20 * sin(c + 2d)
        LD      A,(TmpC)
        LD      B,A
        LD      A,(Idx2D)
        ADD     A,B                 ; index = c+2d
        CALL    SINLOOK
        CALL    MUL20_A             ; HL = 20 * signed(A)
        LD      (Accum),HL

        ; Term X2: 10 * sin(2c + d/2)
        LD      A,(Idx2C)
        LD      B,A
        LD      A,(IdxDov2)
        ADD     A,B                 ; index = 2c+d/2
        CALL    SINLOOK
        CALL    MUL10_A             ; HL = 10 * signed(A)
        LD      DE,(Accum)
        ADD     HL,DE
        LD      (Accum),HL

        ; Term X3: subtract 20 * sin(c + d)
        LD      A,(TmpC)
        LD      B,A
        LD      A,(DVal)
        ADD     A,B                 ; index = c+d
        CALL    SINLOOK
        CALL    MUL20_A             ; HL = 20 * signed(A)
        LD      DE,(Accum)
        ; Accum = Accum - HL  -->  DE - HL
        EX      DE,HL               ; HL = Accum, DE = 20*sin(c+d)
        AND     A                   ; clear carry explicitly before SBC
        SBC     HL,DE               ; HL = Accum - 20*sin(c+d)
        LD      (Accum),HL

        ; X = 64 + Accum/64
        LD      HL,(Accum)
        CALL    ASR6_HL
        LD      A,L
        ADD     A,64
        LD      C,A                 ; C = X coordinate

        ; Reload Y - D was clobbered by MUL routines during X computation
        LD      A,(TmpY)
        LD      D,A                 ; D = Y coordinate (restored from memory)

        RET

; ============================================================
; SINLOOK
; Look up SinTable[A], return signed byte in A.
; The table stores two's complement: positive 0..64, negative 192..255.
; This is directly usable as a signed byte by the multiply routines
; (they sign-extend bit 7).
; Entry:  A = index (0..255)
; Exit:   A = raw table byte (two's complement signed)
; Clobbers: HL
; ============================================================

SINLOOK:
        LD      HL,SinTable
        LD      E,A
        LD      D,0
        ADD     HL,DE               ; HL = &SinTable[A]
        LD      A,(HL)              ; A = raw signed byte
        RET

; ============================================================
; MUL8_A
; HL = 8 * signed(A)   using shift-add, sign-extended.
; A is a two's complement byte (-64..+64 stored as 0..64, 192..255).
; We sign-extend to 16-bit first, then shift left 3.
; ============================================================

MUL8_A:
        LD      L,A
        LD      H,0
        BIT     7,L                 ; test sign bit
        JP      Z,MUL8_POS
        LD      H,$FF               ; negative: sign extend
MUL8_POS:
        ADD     HL,HL               ; *2
        ADD     HL,HL               ; *4
        ADD     HL,HL               ; *8
        RET

; ============================================================
; MUL6_A
; HL = 6 * signed(A)   =  4A + 2A
; ============================================================

MUL6_A:
        LD      L,A
        LD      H,0
        BIT     7,L
        JP      Z,MUL6_POS
        LD      H,$FF
MUL6_POS:
        ADD     HL,HL               ; *2
        LD      D,H
        LD      E,L                 ; save 2A
        ADD     HL,HL               ; *4
        ADD     HL,DE               ; *4 + *2 = *6
        RET

; ============================================================
; MUL10_A
; HL = 10 * signed(A)  =  8A + 2A
; ============================================================

MUL10_A:
        LD      L,A
        LD      H,0
        BIT     7,L
        JP      Z,MUL10_POS
        LD      H,$FF
MUL10_POS:
        ADD     HL,HL               ; *2
        LD      D,H
        LD      E,L                 ; save 2A
        ADD     HL,HL               ; *4
        ADD     HL,HL               ; *8
        ADD     HL,DE               ; *8 + *2 = *10
        RET

; ============================================================
; MUL20_A
; HL = 20 * signed(A)  =  16A + 4A
; ============================================================

MUL20_A:
        LD      L,A
        LD      H,0
        BIT     7,L
        JP      Z,MUL20_POS
        LD      H,$FF
MUL20_POS:
        ADD     HL,HL               ; *2
        ADD     HL,HL               ; *4
        LD      D,H
        LD      E,L                 ; save 4A
        ADD     HL,HL               ; *8
        ADD     HL,HL               ; *16
        ADD     HL,DE               ; *16 + *4 = *20
        RET

; ============================================================
; ASR6_HL
; Arithmetic shift right 6 on HL (signed divide by 64).
; Uses SRA H (propagates sign) then RR L (rotates carry in).
; Applied 6 times.
; Clobbers: flags
; ============================================================

ASR6_HL:
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        RET

; ============================================================
; PLOT_PIX
; Plot or erase one MODE(1) pixel.
; Entry:  C = X (0..127), D = Y (0..63), E = 1 draw / 0 erase
; Clobbers: A, B, DE, HL
; ============================================================

PLOT_PIX:
        ; Compute HL = Y*32 + X/4
        LD      H,0
        LD      L,D                 ; HL = Y
        ADD     HL,HL               ; Y*2
        ADD     HL,HL               ; Y*4
        ADD     HL,HL               ; Y*8
        ADD     HL,HL               ; Y*16
        ADD     HL,HL               ; Y*32

        LD      A,C
        AND     $03
        LD      B,A                 ; B = pixel slot (0..3)

        LD      A,C
        SRL     A
        SRL     A                   ; A = X/4
        LD      D,0
        LD      E,A
        ADD     HL,DE               ; HL = Y*32 + X/4

        LD      DE,$A000
        ADD     HL,DE               ; HL = VRAM byte address

        ; Reload colour flag from stack-free approach:
        ; We saved E before clobbering it above. But E was clobbered by LD E,A.
        ; We must save E (colour flag) before computing the address.
        ; PROBLEM: E is used as colour flag on entry, but also as low byte of DE
        ; for the X/4 offset. Fix: save colour flag in memory before PLOT_PIX
        ; address computation overwrites E.
        ; The caller sets E before CALL. We save it at entry using B (slot uses B
        ; after the AND). Save colour to a temp byte instead.
        ;
        ; REVISED ENTRY PROTOCOL: colour flag saved to PlotColour on entry.
        ; See PlotColour usage below.
;        LD      A,(PlotColour)      ; retrieve saved colour flag
;        OR      A
;        JP      Z,PP_ERASE

PP_DRAW:
        LD      A,B
        OR      A
        JP      Z,PD_S0
        DEC     A
        JP      Z,PD_S1
        DEC     A
        JP      Z,PD_S2
PD_S3:
        LD      A,(HL)
        OR      $03
        LD      (HL),A
        RET
PD_S2:
        LD      A,(HL)
        OR      $0C
        LD      (HL),A
        RET
PD_S1:
        LD      A,(HL)
        OR      $30
        LD      (HL),A
        RET
PD_S0:
        LD      A,(HL)
        OR      $C0
        LD      (HL),A
        RET

PP_ERASE:
        LD      A,B
        OR      A
        JP      Z,PE_S0
        DEC     A
        JP      Z,PE_S1
        DEC     A
        JP      Z,PE_S2
PE_S3:
        LD      A,(HL)
        AND     $FC
        LD      (HL),A
        RET
PE_S2:
        LD      A,(HL)
        AND     $F3
        LD      (HL),A
        RET
PE_S1:
        LD      A,(HL)
        AND     $CF
        LD      (HL),A
        RET
PE_S0:
        LD      A,(HL)
        AND     $3F
        LD      (HL),A
        RET

; ============================================================
; PLOT_DRAW wrapper
; Saves E (colour flag) to PlotColour then calls PLOT_PIX.
; E is clobbered inside PLOT_PIX during address computation.
; Entry: C=X, D=Y, E=colour (0=erase, 1=draw)
; ============================================================

PLOT_DRAW:
        LD      A,E
        LD      (PlotColour),A
        JP      PLOT_PIX

; ============================================================
; CLEAR_VRAM
; Zero fill $7000..$77FF (2048 bytes, all green/buff)
; ============================================================

CLEAR_VRAM:
	exx
        LD      HL,$7000
        LD      DE,$7001
        LD      BC,2047
        XOR     A
        LD      (HL),A
        LDIR
	exx
        RET

; ============================================================
; DATA - all DB / DW / DS at end of file
; ============================================================

FrameAngle:     DB  0           ; frame counter / d index
DVal:           DB  0           ; d latched for current frame
TmpC:           DB  0           ; c index (curve point b)
TmpY:           DB  0           ; Y coordinate saved across X computation
Idx2C:          DB  0           ; 2*c mod 256
Idx2D:          DB  0           ; 2*d mod 256
IdxCov2:        DB  0           ; c/2
IdxDov2:        DB  0           ; d/2
CurveB:         DB  0           ; current curve point counter
PlotColour:     DB  0           ; 0=erase, 1=draw (saved from E before PLOT_PIX)

Accum:          DW  0           ; 16-bit signed accumulator for XY terms

PtrPX:          DW  0           ; running pointer into PrevX
PtrPY:          DW  0           ; running pointer into PrevY

; Previous frame X and Y positions (256 entries each)
PrevX:          DS  256, 64     ; initialised to X centre (64)
PrevY:          DS  256, 32     ; initialised to Y centre (32)

; ============================================================
; SinTable: 256 entries, sin(i * 2*PI / 256) * 64
; Two's complement unsigned byte storage:
;   Positive (0..64):    stored as-is
;   Negative (-1..-64):  stored as 256+value (192..255)
; ============================================================

SinTable:
        DB    0,   2,   3,   5,   6,   8,   9,  11,  12,  14,  16,  17,  19,  20,  22,  23
        DB   24,  26,  27,  29,  30,  32,  33,  34,  36,  37,  38,  39,  41,  42,  43,  44
        DB   45,  46,  47,  48,  49,  50,  51,  52,  53,  54,  55,  56,  56,  57,  58,  59
        DB   59,  60,  60,  61,  61,  62,  62,  62,  63,  63,  63,  64,  64,  64,  64,  64
        DB   64,  64,  64,  64,  64,  64,  63,  63,  63,  62,  62,  62,  61,  61,  60,  60
        DB   59,  59,  58,  57,  56,  56,  55,  54,  53,  52,  51,  50,  49,  48,  47,  46
        DB   45,  44,  43,  42,  41,  39,  38,  37,  36,  34,  33,  32,  30,  29,  27,  26
        DB   24,  23,  22,  20,  19,  17,  16,  14,  12,  11,   9,   8,   6,   5,   3,   2
        DB    0, 254, 253, 251, 250, 248, 247, 245, 244, 242, 240, 239, 237, 236, 234, 233
        DB  232, 230, 229, 227, 226, 224, 223, 222, 220, 219, 218, 217, 215, 214, 213, 212
        DB  211, 210, 209, 208, 207, 206, 205, 204, 203, 202, 201, 200, 200, 199, 198, 197
        DB  197, 196, 196, 195, 195, 194, 194, 194, 193, 193, 193, 192, 192, 192, 192, 192
        DB  192, 192, 192, 192, 192, 192, 193, 193, 193, 194, 194, 194, 195, 195, 196, 196
        DB  197, 197, 198, 199, 200, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210
        DB  211, 212, 213, 214, 215, 217, 218, 219, 220, 222, 223, 224, 226, 227, 229, 230
        DB  232, 233, 234, 236, 237, 239, 240, 242, 244, 245, 247, 248, 250, 251, 253, 254

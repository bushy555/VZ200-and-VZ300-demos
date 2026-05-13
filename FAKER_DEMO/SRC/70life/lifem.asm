; =====================================================================================
; Conway's Game of Life - VZ200/VZ300 (MODE(1), 128x64, 2bpp)
; "Option A" fast interior solver (byte-at-a-time, 3x3 sliding window)
; Strict PASMO rules: JP-only, A-for-absolute, one instruction per line, all data at end
; Source: VIDEO $7000..$77FF ; Dest: BUFFER $9000..$97FF
; ORG $8000 ; SP $F000 ; MODE(1) via ($6800)
; =====================================================================================

                ORG     $8000
                LD      SP,$F000
                DI
                LD      A,8
                LD      ($6800),A

; -----------------------------------------------------------------------------
; Clear VIDEO and BUFFER
; -----------------------------------------------------------------------------
                CALL    CLSVIDEO
                CALL    CLSBUFFER

; -----------------------------------------------------------------------------
; Seed random live pixels directly into VIDEO, then sync BUFFER once
; -----------------------------------------------------------------------------
                LD      B,8
SEED_PASS:
                PUSH    BC
                LD      B,255
SEED_DOT:
                PUSH    BC
                CALL    RNG8
                AND     127
                LD      (xaxis),A
                CALL    RNG8
                AND     63
                LD      (yaxis),A
                LD      D,2
                CALL    PUTPIXELVIDEO_FAST
                POP     BC
                DEC     B
                JP      NZ,SEED_DOT
                POP     BC
                DEC     B
                JR      NZ,SEED_PASS

; Copy initial VIDEO -> BUFFER so borders start identical
                LD      HL,$7000
                LD      DE,$9000
                LD      BC,2048
                LDIR

; =====================================================================================
; MAIN LOOP  (read: VIDEO, write: BUFFER, then blit BUFFER->VIDEO)
; =====================================================================================
MAIN_LOOP:

; Initialize row bases for y=1 (prev row = 0, curr = 1, next = 2)
                LD      HL,$7000
                LD      (p_base),HL
                LD      DE,$7000+32
                LD      (c_base),DE
                LD      HL,$7000+64
                LD      (n_base),HL

; Initialize destination base to row 0 ($9000); we bump by +32 at each row start
                LD      HL,$9000
                LD      (dst_base),HL

; ycount = 62 rows (1..62)
                LD      A,62
                LD      (ycount),A

ROW_Y:

; ------------------------- set destination row base = dst_base + 32 -------------------
                LD      IY,(dst_base)
                LD      DE,32
                ADD     IY,DE
                LD      (dst_base),IY

; IY now points to dest row base. We will write bytes 1..30.
; Set write pointer = IY + 1
                INC     IY

; ------------------------- initialize 3x3 byte windows for bx=1 ----------------------
; prev row window (L,C,R) and read pointer
                LD      HL,(p_base)
                LD      A,(HL)
                LD      (pL),A
                INC     HL
                LD      A,(HL)
                LD      (pC),A
                INC     HL
                LD      A,(HL)
                LD      (pR),A
                INC     HL
                LD      (p_ptr),HL

; curr row window (L,C,R) and read pointer
                LD      HL,(c_base)
                LD      A,(HL)
                LD      (cL),A
                INC     HL
                LD      A,(HL)
                LD      (cC),A
                INC     HL
                LD      A,(HL)
                LD      (cR),A
                INC     HL
                LD      (c_ptr),HL

; next row window (L,M,R) and read pointer   ; (nM is "next middle" byte)
                LD      HL,(n_base)
                LD      A,(HL)
                LD      (nL),A
                INC     HL
                LD      A,(HL)
                LD      (nM),A
                INC     HL
                LD      A,(HL)
                LD      (nR),A
                INC     HL
                LD      (n_ptr),HL

; ------------------------- byte-x loop: 30 interior bytes (1..30) --------------------
                LD      B,30

BYTE_X:

; -------- OUTB = 0 -------------------------------------------------------------------
                XOR     A
                LD      (OUTB),A

; ======================== Pixel p=0 (bits 7..6) ======================================
;                XOR     A
                LD      C,0

                LD      A,(pL)
                AND     $03
                JR      Z,p0_abL_skip
                INC     C
p0_abL_skip:
                LD      A,(pC)
                AND     $C0
                JR      Z,p0_ab_skip
                INC     C
p0_ab_skip:
                LD      A,(pC)
                AND     $30
                JR      Z,p0_abR_skip
                INC     C
p0_abR_skip:
                LD      A,(cL)
                AND     $03
                JR      Z,p0_L_skip
                INC     C
p0_L_skip:
                LD      A,(cC)
                AND     $30
                JR      Z,p0_R_skip
                INC     C
p0_R_skip:
                LD      A,(nL)
                AND     $03
                JR      Z,p0_beL_skip
                INC     C
p0_beL_skip:
                LD      A,(nM)
                AND     $C0
                JR      Z,p0_be_skip
                INC     C
p0_be_skip:
                LD      A,(nM)
                AND     $30
                JR      Z,p0_beR_skip
                INC     C
p0_beR_skip:

; current state at p=0 (cC mask $C0)
                LD      A,(cC)
                AND     $C0
                JR      Z,p0_cur_dead
                LD      E,1
                JR      p0_rule
p0_cur_dead:
                LD      E,0
p0_rule:
                LD      A,C
                CP      3
                JR      Z,p0_alive
                CP      2
                JR      NZ,p0_dead
                LD      A,E
                OR      A
                JR      Z,p0_dead
p0_alive:
                LD      A,(OUTB)
                OR      $80
                LD      (OUTB),A
p0_dead:

; ======================== Pixel p=1 (bits 5..4) ======================================
;                XOR     A
                LD      C,0

                LD      A,(pC)
                AND     $C0
                JR      Z,p1_abL_skip
                INC     C
p1_abL_skip:
                LD      A,(pC)
                AND     $30
                JR      Z,p1_ab_skip
                INC     C
p1_ab_skip:
                LD      A,(pC)
                AND     $0C
                JR      Z,p1_abR_skip
                INC     C
p1_abR_skip:
                LD      A,(cC)
                AND     $C0
                JR      Z,p1_L_skip
                INC     C
p1_L_skip:
                LD      A,(cC)
                AND     $0C
                JR      Z,p1_R_skip
                INC     C
p1_R_skip:
                LD      A,(nM)
                AND     $C0
                JR      Z,p1_beL_skip
                INC     C
p1_beL_skip:
                LD      A,(nM)
                AND     $30
                JR      Z,p1_be_skip
                INC     C
p1_be_skip:
                LD      A,(nM)
                AND     $0C
                JR      Z,p1_beR_skip
                INC     C
p1_beR_skip:

; current state at p=1 (cC mask $30)
                LD      A,(cC)
                AND     $30
                JR      Z,p1_cur_dead
                LD      E,1
                JR      p1_rule
p1_cur_dead:
                LD      E,0
p1_rule:
                LD      A,C
                CP      3
                JR      Z,p1_alive
                CP      2
                JR      NZ,p1_dead
                LD      A,E
                OR      A
                JR      Z,p1_dead
p1_alive:
                LD      A,(OUTB)
                OR      $20
                LD      (OUTB),A
p1_dead:

; ======================== Pixel p=2 (bits 3..2) ======================================
;                XOR     A
                LD      C,0

                LD      A,(pC)
                AND     $30
                JR      Z,p2_abL_skip
                INC     C
p2_abL_skip:
                LD      A,(pC)
                AND     $0C
                JR      Z,p2_ab_skip
                INC     C
p2_ab_skip:
                LD      A,(pC)
                AND     $03
                JR      Z,p2_abR_skip
                INC     C
p2_abR_skip:
                LD      A,(cC)
                AND     $30
                JR      Z,p2_L_skip
                INC     C
p2_L_skip:
                LD      A,(cC)
                AND     $03
                JR      Z,p2_R_skip
                INC     C
p2_R_skip:
                LD      A,(nM)
                AND     $30
                JR      Z,p2_beL_skip
                INC     C
p2_beL_skip:
                LD      A,(nM)
                AND     $0C
                JR      Z,p2_be_skip
                INC     C
p2_be_skip:
                LD      A,(nM)
                AND     $03
                JR      Z,p2_beR_skip
                INC     C
p2_beR_skip:

; current state at p=2 (cC mask $0C)
                LD      A,(cC)
                AND     $0C
                JR      Z,p2_cur_dead
                LD      E,1
                JR      p2_rule
p2_cur_dead:
                LD      E,0
p2_rule:
                LD      A,C
                CP      3
                JR      Z,p2_alive
                CP      2
                JR      NZ,p2_dead
                LD      A,E
                OR      A
                JR      Z,p2_dead
p2_alive:
                LD      A,(OUTB)
                OR      $08
                LD      (OUTB),A
p2_dead:

; ======================== Pixel p=3 (bits 1..0) ======================================
;                XOR     A
                LD      C,0

                LD      A,(pC)
                AND     $0C
                JR      Z,p3_abL_skip
                INC     C
p3_abL_skip:
                LD      A,(pC)
                AND     $03
                JR      Z,p3_ab_skip
                INC     C
p3_ab_skip:
                LD      A,(pR)
                AND     $C0
                JR      Z,p3_abR_skip
                INC     C
p3_abR_skip:
                LD      A,(cC)
                AND     $0C
                JR      Z,p3_L_skip
                INC     C
p3_L_skip:
                LD      A,(cR)
                AND     $C0
                JR      Z,p3_R_skip
                INC     C
p3_R_skip:
                LD      A,(nM)
                AND     $0C
                JR      Z,p3_beL_skip
                INC     C
p3_beL_skip:
                LD      A,(nM)
                AND     $03
                JR      Z,p3_be_skip
                INC     C
p3_be_skip:
                LD      A,(nR)
                AND     $C0
                JR      Z,p3_beR_skip
                INC     C
p3_beR_skip:

; current state at p=3 (cC mask $03)
                LD      A,(cC)
                AND     $03
                JR      Z,p3_cur_dead
                LD      E,1
                JR      p3_rule
p3_cur_dead:
                LD      E,0
p3_rule:
                LD      A,C
                CP      3
                JR      Z,p3_alive
                CP      2
                JR      NZ,p3_dead
                LD      A,E
                OR      A
                JR      Z,p3_dead
p3_alive:
                LD      A,(OUTB)
                OR      $02
                LD      (OUTB),A
p3_dead:

; ------------------------ write OUTB to BUFFER at (IY+0) -----------------------------
                LD      A,(OUTB)
                LD      (IY+0),A

; ------------------------ decrement B; if zero, finish row (no slide) ----------------
                DEC     B
                JR      Z,END_ROW

; ------------------------ slide 3x windows right by 1 byte ---------------------------
; prev row
                LD      A,(pC)
                LD      (pL),A
                LD      A,(pR)
                LD      (pC),A
                LD      HL,(p_ptr)
                LD      A,(HL)
                LD      (pR),A
                INC     HL
                LD      (p_ptr),HL

; curr row
                LD      A,(cC)
                LD      (cL),A
                LD      A,(cR)
                LD      (cC),A
                LD      HL,(c_ptr)
                LD      A,(HL)
                LD      (cR),A
                INC     HL
                LD      (c_ptr),HL

; next row (uses nM)
                LD      A,(nM)
                LD      (nL),A
                LD      A,(nR)
                LD      (nM),A
                LD      HL,(n_ptr)
                LD      A,(HL)
                LD      (nR),A
                INC     HL
                LD      (n_ptr),HL

; advance destination write pointer to next byte
                INC     IY

; loop back for next byte
                JP      BYTE_X

; ------------------------ end of row: advance bases for next y -----------------------
END_ROW:
; prev <- curr
; curr <- next
; next <- next + 32
                LD      HL,(c_base)
                LD      (p_base),HL
                LD      HL,(n_base)
                LD      (c_base),HL
                LD      DE,32
                ADD     HL,DE
                LD      (n_base),HL

; next row?
                LD      A,(ycount)
                DEC     A
                LD      (ycount),A
                JP      NZ,ROW_Y

; =====================================================================================
; Blit BUFFER ($9000) -> VIDEO ($7000) 2048 bytes using 32×(64*LDI)
; =====================================================================================
                LD      HL,$9000
                LD      DE,$7000
                LD      BC,2048

BLIT_2048:
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
                LDI
                LDI
                LDI
                LDI

                JP      PE,BLIT_2048

; Next generation
                JP      MAIN_LOOP

; =====================================================================================
; Support routines
; =====================================================================================

CLSVIDEO:
                LD      HL,$7000
                LD      DE,$7001
                LD      (HL),0
                LD      BC,2048
                LDIR
                RET

CLSBUFFER:
                LD      HL,$9000
                LD      DE,$9001
                LD      (HL),0
                LD      BC,2048
                LDIR
                RET

; RNG8: quick 8-bit pseudo random
RNG8:
                LD      A,R
                RRCA
                RRCA
                NEG
seed:           EQU     $+1
                XOR     0
                RRCA
                LD      (seed),A
                RET

; PUTPIXELVIDEO_FAST
; Inputs: (xaxis),(yaxis), D=colour(0..3)
; Writes a 2-bit pixel into $7000 VRAM
PUTPIXELVIDEO_FAST:
                PUSH    DE
                LD      A,(yaxis)
                LD      H,A
                LD      A,(xaxis)
                LD      L,A
                LD      C,D

                SLA     L
                SRL     H
                RR      L
                SRL     H
                RR      L
                SRL     H
                RR      L

                AND     3
                INC     A

                LD      B,%11111100
ppv_shift:
                RRC     B
                RRC     B
                RRC     C
                RRC     C
                DEC     A
                JP      NZ,ppv_shift

                LD      A,H
                OR      $70
                LD      H,A
                LD      A,(HL)
                AND     B
                OR      C
                LD      (HL),A

                POP     DE
                RET

; =====================================================================================
; ==============================  DATA & VARIABLES  ===================================
; =====================================================================================

pL:             DB      0
pC:             DB      0
pR:             DB      0
cL:             DB      0
cC:             DB      0
cR:             DB      0
nL:             DB      0
nM:             DB      0
nR:             DB      0

p_ptr:          DW      0
c_ptr:          DW      0
n_ptr:          DW      0

p_base:         DW      0
c_base:         DW      0
n_base:         DW      0

dst_base:       DW      0
ycount:         DB      0
OUTB:           DB      0

xaxis:          DB      0
yaxis:          DB      0

; =====================================================================================
; End of file
; =====================================================================================
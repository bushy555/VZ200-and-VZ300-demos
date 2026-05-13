
; ============================================================
; VZ200/VZ300 MODE(1) Full-Screen Roto-Zoomer (FAST + FIXED)
; PASMO rules: JP only (no JR), no DJNZ, A-only (nn), ORG $8000,
; SP $F000, DI at start, MODE(1) latch bit3 @ $6800,
; VRAM $7000-$77FF (128x64, 2bpp).
; ============================================================

                ORG     $8000

Start:
                DI
                LD      SP,$F000

; Enter MODE(1)
                LD      A,8
                LD      ($6800),A

; Clear VRAM
                XOR     A
                CALL    FillVRAM

; Build 64x64 texture once
                CALL    BuildTexture

; Build RowPtr[64] = absolute addresses of Texture + k*64  (CORRECT)
                CALL    BuildRowPtr

; Init angle, speed, scale
                XOR     A
                LD      (Angle),A
                LD      A,1
                LD      (AngSpeed),A
                LD      A,6
                LD      (ScaleShift),A

; ============================================================
; Main loop
; ============================================================
MainLoop:
; angle = (angle + AngSpeed) & 63
                LD      A,(Angle)
                LD      H,A
                LD      A,(AngSpeed)
                ADD     A,H
                AND     63
                LD      (Angle),A

; Frame parameters
                CALL    ComputeSteps
                CALL    ComputeStartUV

; Urow,Vrow = start UV
                LD      A,(U0Lo)
                LD      (UrowLo),A
                LD      A,(U0Hi)
                LD      (UrowHi),A
                LD      A,(V0Lo)
                LD      (VrowLo),A
                LD      A,(V0Hi)
                LD      (VrowHi),A

; DE = VRAM start
                LD      DE,$7000

; 64 rows
                LD      A,64
                LD      (Y_Rem),A

RowLoop:
                LD      A,(Y_Rem)
                OR      A
                JP      Z,FrameDone

; Ucur,Vcur = row start
                LD      A,(UrowLo)
                LD      (UcurLo),A
                LD      A,(UrowHi)
                LD      (UcurHi),A
                LD      A,(VrowLo)
                LD      (VcurLo),A
                LD      A,(VrowHi)
                LD      (VcurHi),A

; 32 bytes per row
                LD      A,32
                LD      (XBytes_Rem),A

ByteLoop:
                LD      A,(XBytes_Rem)
                OR      A
                JP      Z,NextRow

; Accumulate 4 pixels in AccByte
                XOR     A
                LD      (AccByte),A

; ============================================================
; Pixel 0 (bits 7..6)  ---- uses P0 table
; ============================================================
; Build BC = RowPtr[v] + u
                LD      A,(VcurHi)
                AND     63
                LD      C,A
                LD      B,0
                LD      HL,RowPtrLo
                ADD     HL,BC
                LD      A,(HL)               ; RowBaseLo
                LD      (RowBaseLo),A
                LD      HL,RowPtrHi
                ADD     HL,BC
                LD      A,(HL)               ; RowBaseHi
                LD      (RowBaseHi),A

                LD      A,(UcurHi)
                AND     63
                LD      L,A                  ; L = uIndex
                LD      A,(RowBaseLo)
                ADD     A,L
                LD      C,A
                LD      A,(RowBaseHi)
                ADC     A,0
                LD      B,A

                LD      A,(BC)
                AND     3                    ; 0..3 colour
; A = colour index -> OR pre-shifted nibble
                LD      L,A
                LD      H,0
                LD      HL,P0
                ADD     HL,HL                ; index *2?  <<-- STOP
; Simpler: re-fetch A (index), index P0 directly via BC
                LD      A,(VcurHi)           ; dummy re-use to restore HL? No.
; We'll index via BC scratch:
                ; Recompute small index cleanly:
                LD      A,(BC)               ; <-- (BC) was used; we need A=colour again.
                AND     3
                LD      C,A
                LD      B,0
                LD      HL,P0
                ADD     HL,BC
                LD      A,(HL)
                LD      H,A
                LD      A,(AccByte)
                OR      H
                LD      (AccByte),A

; Step Ucur += Ax / Vcur += Ay
                LD      A,(UcurLo)
                LD      L,A
                LD      A,(AxLo)
                ADD     A,L
                LD      (UcurLo),A
                LD      A,(UcurHi)
                LD      L,A
                LD      A,(AxHi)
                ADC     A,L
                LD      (UcurHi),A

                LD      A,(VcurLo)
                LD      L,A
                LD      A,(AyLo)
                ADD     A,L
                LD      (VcurLo),A
                LD      A,(VcurHi)
                LD      L,A
                LD      A,(AyHi)
                ADC     A,L
                LD      (VcurHi),A

; ============================================================
; Pixel 1 (bits 5..4)  ---- uses P1 table
; ============================================================
; BC = RowPtr[v] + u
                LD      A,(VcurHi)
                AND     63
                LD      C,A
                LD      B,0
                LD      HL,RowPtrLo
                ADD     HL,BC
                LD      A,(HL)
                LD      (RowBaseLo),A
                LD      HL,RowPtrHi
                ADD     HL,BC
                LD      A,(HL)
                LD      (RowBaseHi),A

                LD      A,(UcurHi)
                AND     63
                LD      L,A
                LD      A,(RowBaseLo)
                ADD     A,L
                LD      C,A
                LD      A,(RowBaseHi)
                ADC     A,0
                LD      B,A

                LD      A,(BC)
                AND     3
                LD      C,A
                LD      B,0
                LD      HL,P1
                ADD     HL,BC
                LD      A,(HL)
                LD      H,A
                LD      A,(AccByte)
                OR      H
                LD      (AccByte),A

; Ucur += Ax ; Vcur += Ay
                LD      A,(UcurLo)
                LD      L,A
                LD      A,(AxLo)
                ADD     A,L
                LD      (UcurLo),A
                LD      A,(UcurHi)
                LD      L,A
                LD      A,(AxHi)
                ADC     A,L
                LD      (UcurHi),A

                LD      A,(VcurLo)
                LD      L,A
                LD      A,(AyLo)
                ADD     A,L
                LD      (VcurLo),A
                LD      A,(VcurHi)
                LD      L,A
                LD      A,(AyHi)
                ADC     A,L
                LD      (VcurHi),A

; ============================================================
; Pixel 2 (bits 3..2)  ---- uses P2 table
; ============================================================
                LD      A,(VcurHi)
                AND     63
                LD      C,A
                LD      B,0
                LD      HL,RowPtrLo
                ADD     HL,BC
                LD      A,(HL)
                LD      (RowBaseLo),A
                LD      HL,RowPtrHi
                ADD     HL,BC
                LD      A,(HL)
                LD      (RowBaseHi),A

                LD      A,(UcurHi)
                AND     63
                LD      L,A
                LD      A,(RowBaseLo)
                ADD     A,L
                LD      C,A
                LD      A,(RowBaseHi)
                ADC     A,0
                LD      B,A

                LD      A,(BC)
                AND     3
                LD      C,A
                LD      B,0
                LD      HL,P2
                ADD     HL,BC
                LD      A,(HL)
                LD      H,A
                LD      A,(AccByte)
                OR      H
                LD      (AccByte),A

; Ucur += Ax ; Vcur += Ay
                LD      A,(UcurLo)
                LD      L,A
                LD      A,(AxLo)
                ADD     A,L
                LD      (UcurLo),A
                LD      A,(UcurHi)
                LD      L,A
                LD      A,(AxHi)
                ADC     A,L
                LD      (UcurHi),A

                LD      A,(VcurLo)
                LD      L,A
                LD      A,(AyLo)
                ADD     A,L
                LD      (VcurLo),A
                LD      A,(VcurHi)
                LD      L,A
                LD      A,(AyHi)
                ADC     A,L
                LD      (VcurHi),A

; ============================================================
; Pixel 3 (bits 1..0)  ---- uses P3 table
; ============================================================
                LD      A,(VcurHi)
                AND     63
                LD      C,A
                LD      B,0
                LD      HL,RowPtrLo
                ADD     HL,BC
                LD      A,(HL)
                LD      (RowBaseLo),A
                LD      HL,RowPtrHi
                ADD     HL,BC
                LD      A,(HL)
                LD      (RowBaseHi),A

                LD      A,(UcurHi)
                AND     63
                LD      L,A
                LD      A,(RowBaseLo)
                ADD     A,L
                LD      C,A
                LD      A,(RowBaseHi)
                ADC     A,0
                LD      B,A

                LD      A,(BC)
                AND     3
                LD      C,A
                LD      B,0
                LD      HL,P3
                ADD     HL,BC
                LD      A,(HL)
                LD      H,A
                LD      A,(AccByte)
                OR      H
                LD      (AccByte),A

; ===== write byte =====
                LD      A,(AccByte)
                LD      (DE),A
                INC     DE

; next column
                LD      A,(XBytes_Rem)
                SUB     1
                LD      (XBytes_Rem),A
                JP      ByteLoop

NextRow:
; Urow += Bx ; Vrow += By
                LD      A,(UrowLo)
                LD      L,A
                LD      A,(BxLo)
                ADD     A,L
                LD      (UrowLo),A
                LD      A,(UrowHi)
                LD      L,A
                LD      A,(BxHi)
                ADC     A,L
                LD      (UrowHi),A

                LD      A,(VrowLo)
                LD      L,A
                LD      A,(ByLo)
                ADD     A,L
                LD      (VrowLo),A
                LD      A,(VrowHi)
                LD      L,A
                LD      A,(ByHi)
                ADC     A,L
                LD      (VrowHi),A

; DE += 32 (next VRAM row)
                LD      HL,32
                ADD     HL,DE
                EX      DE,HL

; Rows--
                LD      A,(Y_Rem)
                SUB     1
                LD      (Y_Rem),A
                JP      RowLoop

FrameDone:
                JP      MainLoop

; ============================================================
; Subroutines (per-frame or once)
; ============================================================

; FillVRAM: fill $7000..$77FF with A
FillVRAM:
                LD      HL,$7000
                LD      (HL),A
                LD      DE,$7001
                LD      BC,2047
                LDIR
                RET

; ComputeSteps: Ax/Ay/Bx/By from Angle & ScaleShift (8.8 signed)
ComputeSteps:
                LD      A,(Angle)
                ADD     A,16
                AND     63
                LD      (TmpIdx),A
; Ax
                LD      A,(TmpIdx)
                LD      E,A
                XOR     A
                LD      D,A
                LD      HL,Sin64U
                ADD     HL,DE
                LD      A,(HL)
                SUB     32
                LD      H,A
                XOR     A
                LD      L,A
                LD      A,(ScaleShift)
                LD      (ShCnt),A
CS1:
                LD      A,(ShCnt)
                OR      A
                JP      Z,CS1D
                SRA     H
                RR      L
                LD      A,(ShCnt)
                SUB     1
                LD      (ShCnt),A
                JP      CS1
CS1D:
                LD      A,L
                LD      (AxLo),A
                LD      A,H
                LD      (AxHi),A
; Ay
                LD      A,(Angle)
                LD      E,A
                XOR     A
                LD      D,A
                LD      HL,Sin64U
                ADD     HL,DE
                LD      A,(HL)
                SUB     32
                LD      H,A
                XOR     A
                LD      L,A
                LD      A,(ScaleShift)
                LD      (ShCnt),A
CS2:
                LD      A,(ShCnt)
                OR      A
                JP      Z,CS2D
                SRA     H
                RR      L
                LD      A,(ShCnt)
                SUB     1
                LD      (ShCnt),A
                JP      CS2
CS2D:
                LD      A,L
                LD      (AyLo),A
                LD      A,H
                LD      (AyHi),A
; Bx = -Ay ; By = Ax
                LD      A,(AyLo)
                XOR     $FF
                ADD     A,1
                LD      (BxLo),A
                LD      A,(AyHi)
                XOR     $FF
                ADC     A,0
                LD      (BxHi),A

                LD      A,(AxLo)
                LD      (ByLo),A
                LD      A,(AxHi)
                LD      (ByHi),A
                RET

; ComputeStartUV:
;   U0 = (32<<8) - Ax*64 - Bx*32
;   V0 = (32<<8) - Ay*64 - By*32
ComputeStartUV:
; U0
                LD      A,(AxLo)
                LD      L,A
                LD      A,(AxHi)
                LD      H,A
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                LD      B,H
                LD      C,L
                LD      HL,$2000
                XOR     A
                SBC     HL,BC

                LD      A,(BxLo)
                LD      L,A
                LD      A,(BxHi)
                LD      H,A
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                LD      B,H
                LD      C,L
                XOR     A
                SBC     HL,BC
                LD      A,L
                LD      (U0Lo),A
                LD      A,H
                LD      (U0Hi),A
; V0
                LD      A,(AyLo)
                LD      L,A
                LD      A,(AyHi)
                LD      H,A
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                LD      B,H
                LD      C,L
                LD      HL,$2000
                XOR     A
                SBC     HL,BC

                LD      A,(ByLo)
                LD      L,A
                LD      A,(ByHi)
                LD      H,A
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                ADD     HL,HL
                LD      B,H
                LD      C,L
                XOR     A
                SBC     HL,BC
                LD      A,L
                LD      (V0Lo),A
                LD      A,H
                LD      (V0Hi),A
                RET

; ------------------------------------------------------------
; BuildRowPtr (CORRECT):
;   RowPtrLo[k] = LOW(Texture + k*64)
;   RowPtrHi[k] = HIGH(Texture + k*64)
; Uses BC as the running pointer; E=index; RowBuildRem=count.
; ------------------------------------------------------------
BuildRowPtr:
                LD      BC,Texture           ; BC = Texture base
                XOR     A
                LD      (RowPtrIdx),A
                LD      A,64
                LD      (RowBuildRem),A
BRP_Loop:
                LD      A,(RowBuildRem)
                OR      A
                JP      Z,BRP_Done

                LD      A,(RowPtrIdx)        ; E = index 0..63
                LD      E,A
                LD      D,0

; write low byte
                LD      HL,RowPtrLo
                ADD     HL,DE
                LD      A,C
                LD      (HL),A

; write high byte
                LD      HL,RowPtrHi
                ADD     HL,DE
                LD      A,B
                LD      (HL),A

; BC += 64
                LD      A,C
                ADD     A,64
                LD      C,A
                LD      A,B
                ADC     A,0
                LD      B,A

; idx++, rem--
                LD      A,(RowPtrIdx)
                ADD     A,1
                LD      (RowPtrIdx),A
                LD      A,(RowBuildRem)
                SUB     1
                LD      (RowBuildRem),A
                JP      BRP_Loop
BRP_Done:
                RET

; ------------------------------------------------------------
; BuildTexture (unchanged approach; sinusoidal pattern)
; ------------------------------------------------------------
BuildTexture:
                XOR     A
                LD      (Ty),A
                LD      A,64
                LD      (TyRem),A
BTY_Loop:
                LD      A,(TyRem)
                OR      A
                JP      Z,BT_Done

; Row base pointer = Texture + ty*64 (reuse RowOff tables)
                LD      A,(Ty)
                AND     63
                LD      (TmpV),A

                LD      A,(TmpV)
                LD      E,A
                LD      D,0
                LD      HL,RowOffLo
                ADD     HL,DE
                LD      A,(HL)
                LD      (RowLoTmp),A

                LD      A,(TmpV)
                LD      E,A
                LD      D,0
                LD      HL,RowOffHi
                ADD     HL,DE
                LD      A,(HL)
                LD      (RowHiTmp),A

                LD      A,LOW Texture
                LD      L,A
                LD      A,HIGH Texture
                LD      H,A
                LD      A,(RowLoTmp)
                LD      C,A
                LD      A,(RowHiTmp)
                LD      B,A
                ADD     HL,BC
                LD      A,L
                LD      (TexPtrLo),A
                LD      A,H
                LD      (TexPtrHi),A

; pY6 = ty*6
                LD      A,(Ty)
                LD      H,A
                ADD     A,H
                ADD     A,H
                ADD     A,A
                LD      (pY6),A

; tx loop (0..63)
                XOR     A
                LD      (Tx),A
                LD      A,64
                LD      (TxRem),A
                XOR     A
                LD      (pX4),A
; pXY5 = ty*5
                LD      A,(Ty)
                LD      H,A
                ADD     A,H
                ADD     A,H
                ADD     A,A
                SUB     H
                LD      (pXY5),A

BTX_Loop:
                LD      A,(TxRem)
                OR      A
                JP      Z,BT_NextRow

; a = (sin(pX4)>>6)&3
                LD      A,(pX4)
                LD      E,A
                LD      D,0
                LD      HL,Sin256U
                ADD     HL,DE
                LD      A,(HL)
                SUB     128
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                AND     3
                LD      B,A

; b = (sin(pY6)>>6)&3
                LD      A,(pY6)
                LD      E,A
                LD      D,0
                LD      HL,Sin256U
                ADD     HL,DE
                LD      A,(HL)
                SUB     128
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                AND     3
                LD      C,A

; c = (sin(pXY5)>>6)&3
                LD      A,(pXY5)
                LD      E,A
                LD      D,0
                LD      HL,Sin256U
                ADD     HL,DE
                LD      A,(HL)
                SUB     128
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                SRA     A
                AND     3
                XOR     B
                XOR     C

; write texel
                LD      A,(TexPtrLo)
                LD      L,A
                LD      A,(TexPtrHi)
                LD      H,A
                LD      (HL),A
                LD      A,(TexPtrLo)
                ADD     A,1
                LD      (TexPtrLo),A
                LD      A,(TexPtrHi)
                ADC     A,0
                LD      (TexPtrHi),A

; advance phases & counters
                LD      A,(pX4)
                ADD     A,4
                LD      (pX4),A
                LD      A,(pXY5)
                ADD     A,5
                LD      (pXY5),A

                LD      A,(Tx)
                ADD     A,1
                LD      (Tx),A
                LD      A,(TxRem)
                SUB     1
                LD      (TxRem),A
                JP      BTX_Loop

BT_NextRow:
                LD      A,(Ty)
                ADD     A,1
                LD      (Ty),A
                LD      A,(TyRem)
                SUB     1
                LD      (TyRem),A
                JP      BTY_Loop
BT_Done:
                RET

; ============================================================
; ---------------------- DATA (END) --------------------------
; ============================================================

; Control
Angle:          DB 0
AngSpeed:       DB 1
ScaleShift:     DB 6

; Step vectors (8.8 signed)
AxLo:           DB 0
AxHi:           DB 0
AyLo:           DB 0
AyHi:           DB 0
BxLo:           DB 0
BxHi:           DB 0
ByLo:           DB 0
ByHi:           DB 0

; Start + per-row/current UV (8.8)
U0Lo:           DB 0
U0Hi:           DB 0
V0Lo:           DB 0
V0Hi:           DB 0
UrowLo:         DB 0
UrowHi:         DB 0
VrowLo:         DB 0
VrowHi:         DB 0
UcurLo:         DB 0
UcurHi:         DB 0
VcurLo:         DB 0
VcurHi:         DB 0

; VRAM / loops
Y_Rem:          DB 0
XBytes_Rem:     DB 0
AccByte:        DB 0

; Row pointer builder
RowPtrIdx:      DB 0
RowBuildRem:    DB 0

; Row pointer tables (absolute Texture row addresses)
RowPtrLo:       DEFS 64
RowPtrHi:       DEFS 64
RowBaseLo:      DB 0
RowBaseHi:      DB 0

; 64x64 texture (1 byte/texel, values 0..3)
Texture:        DEFS 4096

; Pixel pack tables (2-bit colour at the proper nibble)
P0:             DB $00,$40,$80,$C0   ; bits 7..6
P1:             DB $00,$10,$20,$30   ; bits 5..4
P2:             DB $00,$04,$08,$0C   ; bits 3..2
P3:             DB $00,$01,$02,$03   ; bits 1..0

; --- BuildTexture helpers (row offsets and temps) ---
RowOffLo:
                DB 0,64,128,192,0,64,128,192,0,64,128,192,0,64,128,192
                DB 0,64,128,192,0,64,128,192,0,64,128,192,0,64,128,192
                DB 0,64,128,192,0,64,128,192,0,64,128,192,0,64,128,192
                DB 0,64,128,192,0,64,128,192,0,64,128,192,0,64,128,192
RowOffHi:
                DB 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
                DB 4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7
                DB 8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11
                DB 12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15

TmpV:           DB 0
RowLoTmp:       DB 0
RowHiTmp:       DB 0
TmpIdx:         DB 0
ShCnt:          DB 0
Ty:             DB 0
TyRem:          DB 0
Tx:             DB 0
TxRem:          DB 0
TexPtrLo:       DB 0
TexPtrHi:       DB 0
pY6:            DB 0
pX4:            DB 0
pXY5:           DB 0

; Sinus tables
Sin64U:
                DB 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63
                DB 63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,32
                DB 28,25,22,19,16,13,11,8,6,4,3,2,1,1,0,0
                DB 0,0,1,1,2,3,4,6,8,11,13,16,19,22,25,28
Sin256U:
                DB 128,131,134,137,140,143,146,149,152,156,159,162,165,168,171,174
                DB 177,180,183,186,188,191,194,197,199,202,204,207,209,212,214,216
                DB 219,221,223,225,227,229,231,233,234,236,238,239,241,242,244,245
                DB 246,247,248,249,250,251,251,252,253,253,254,254,254,254,255,255
                DB 255,255,255,254,254,254,253,253,252,251,251,250,249,248,247,246
                DB 245,244,242,241,239,238,236,234,233,231,229,227,225,223,221,219
                DB 216,214,212,209,207,204,202,199,197,194,191,188,186,183,180,177
                DB 174,171,168,165,162,159,156,152,149,146,143,140,137,134,131,128
                DB 124,121,118,115,112,109,106,103,100,96,93,90,87,84,81,78
                DB 75,72,69,66,64,61,58,55,53,50,48,45,43,40,38,36
                DB 33,31,29,27,25,23,21,19,18,16,14,13,11,10,8,7
                DB 6,5,4,3,2,1,1,0,0,0,0,0,0,0,0,0
                DB 0,0,0,0,0,1,1,2,3,4,5,6,7,8,10,11
                DB 13,14,16,18,19,21,23,25,27,29,31,33,36,38,40,43
                DB 45,48,50,53,55,58,61,64,66,69,72,75,78,81,84,87
                DB 90,93,96,100,103,106,109,112,115,118,121,124
; ============================================================
; End of source
; ============================================================

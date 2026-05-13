ORG $8000
; ============================================================================
; VZ200/VZ300 MODE(1) Wireframe Two-Ship Demo - BLUE background
; STRICT PASMO: ORG $8000; SP=$F000; JP (no JR); A-for-Absolute (nn) only via A;
; legal 16-bit direct loads/stores; (HL)/(IX+d)/(IY+d) allowed; ALL DB/DW at END.
; Video: MODE(1) 128x64, 2bpp; VRAM $7000-$77FF; latch $6800.
;
; Sequence:
;   Phase 0: Ship1 (Cobra MkIII, 10v/14e) rotates for exactly 5 full Y-axis
;             rotations (64 steps/rev x 5 = 320 frames at SpeedY=1).
;   Phase 1: Ship1 implodes to screen centre over 32 frames (ShrinkScale 31..0).
;   Phase 2: Switch to Ship2 (Arrowhead Fighter, 8v/13e). Seed all vertices at
;             centre. Grow from point to full size over 32 frames (GrowScale 0..31).
;   Phase 3: Ship2 rotates for exactly 5 full Y-axis rotations (320 frames).
;   Phase 4: Ship2 implodes to screen centre over 32 frames.
;   Phase 5: Final erase then hold starfield forever.
;
;   Stars scroll continuously throughout all phases.
; ============================================================================

IO_LATCH    EQU     $6800
STACK_TOP   EQU     $F000
SCR_CX      EQU     64
SCR_CY      EQU     32
NSTARS      EQU     20

; Ship1 geometry constants
S1_NVERT    EQU     10
S1_NEDGE    EQU     14

; Ship2 geometry constants
S2_NVERT    EQU     8
S2_NEDGE    EQU     13

; 320 frames = 5 full rotations at SpeedY=1, 64 steps/rev
ROT_FRAMES_HI  EQU  0           ; 320 = $0140
ROT_FRAMES_LO  EQU  130

; ----------------------------------------------------------------------------
; Entry / Setup  -  Ship1 active
; ----------------------------------------------------------------------------
START
            DI
            LD      SP,STACK_TOP

            LD      A,8
            LD      (IO_LATCH),A

            CALL    ClearScreenM1_Blue
            CALL    InitStars

            XOR     A
            LD      (AngleY),A
            LD      (AngleX),A
            LD      A,1
            LD      (SpeedY),A
            LD      A,1
            LD      (SpeedX),A

            ; Phase = 0 (Ship1 rotating)
            XOR     A
            LD      (Phase),A

            ; RotCount = 320
            LD      A,ROT_FRAMES_HI
            LD      (RotCountHi),A
            LD      A,ROT_FRAMES_LO
            LD      (RotCountLo),A

            ; ShrinkScale = 31
            LD      A,31
            LD      (ShrinkScale),A

            ; Activate Ship1: set runtime geometry params
            CALL    ActivateShip1

            CALL    TransformAll
            CALL    CopyCurrToPrev

; ----------------------------------------------------------------------------
; Main Loop
; ----------------------------------------------------------------------------
MainLoop
            CALL    UpdateStars

            ; Erase previous frame
            LD      A,2
            LD      (DrawColor),A
            CALL    DrawWirePrev

            ; Dispatch on Phase
            LD      A,(Phase)
            OR      A
            JP      NZ,ML_NotP0

; ---- PHASE 0: Ship1 rotate ------------------------------------------------
            LD      A,(AngleY)
            LD      H,A
            LD      A,(SpeedY)
            ADD     A,H
            AND     63
            LD      (AngleY),A

            LD      A,(AngleX)
            LD      H,A
            LD      A,(SpeedX)
            ADD     A,H
            AND     63
            LD      (AngleX),A

            CALL    TransformAll

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            ; Decrement 16-bit RotCount
            LD      A,(RotCountHi)
            LD      B,A
            LD      A,(RotCountLo)
            OR      B
            JP      Z,ML_P0_RotDone

            LD      A,(RotCountLo)
            SUB     1
            LD      (RotCountLo),A
            JP      NC,ML_Blit
            LD      A,(RotCountHi)
            SUB     1
            LD      (RotCountHi),A
            JP      ML_Blit

ML_P0_RotDone
            LD      A,1
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 1: Ship1 shrink ------------------------------------------------
ML_NotP0
            LD      A,(Phase)
            CP      1
            JP      NZ,ML_NotP1

            LD      A,(AngleY)
            LD      H,A
            LD      A,(SpeedY)
            ADD     A,H
            AND     63
            LD      (AngleY),A

            LD      A,(AngleX)
            LD      H,A
            LD      A,(SpeedX)
            ADD     A,H
            AND     63
            LD      (AngleX),A

            CALL    TransformAll
            CALL    ShrinkVertices

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            LD      A,(ShrinkScale)
            OR      A
            JP      Z,ML_P1_ShrinkDone
            SUB     1
            LD      (ShrinkScale),A
            JP      ML_Blit

ML_P1_ShrinkDone
            ; The erase at the top of this iteration has already wiped the
            ; last shrunken frame. Switch to Ship2, seed vertices at centre,
            ; and prepare grow-in.
            CALL    ActivateShip2

            ; Reset angles so Ship2 starts from a clean orientation
            XOR     A
            LD      (AngleY),A
            LD      (AngleX),A

            ; Seed Curr and Prev at centre so first erase is harmless
            CALL    SeedVerticesCentre

            ; GrowScale starts at 0 (invisible point)
            XOR     A
            LD      (GrowScale),A

            LD      A,2
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 2: Ship2 grow (fade-in) ----------------------------------------
ML_NotP1
            LD      A,(Phase)
            CP      2
            JP      NZ,ML_NotP2

            ; Keep spinning during grow-in
            LD      A,(AngleY)
            LD      H,A
            LD      A,(SpeedY)
            ADD     A,H
            AND     63
            LD      (AngleY),A

            LD      A,(AngleX)
            LD      H,A
            LD      A,(SpeedX)
            ADD     A,H
            AND     63
            LD      (AngleX),A

            CALL    TransformAll
            CALL    GrowVertices        ; scale CurrX/Y toward centre by (32-GrowScale)/32

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            ; Increment GrowScale toward 31
            LD      A,(GrowScale)
            CP      31
            JP      Z,ML_P2_GrowDone
            ADD     A,1
            LD      (GrowScale),A
            JP      ML_Blit

ML_P2_GrowDone
            ; Full size reached - begin Ship2 rotation
            LD      A,ROT_FRAMES_HI
            LD      (RotCountHi),A
            LD      A,ROT_FRAMES_LO
            LD      (RotCountLo),A
            LD      A,3
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 3: Ship2 rotate ------------------------------------------------
ML_NotP2
            LD      A,(Phase)
            CP      3
            JP      NZ,ML_NotP3

            LD      A,(AngleY)
            LD      H,A
            LD      A,(SpeedY)
            ADD     A,H
            AND     63
            LD      (AngleY),A

            LD      A,(AngleX)
            LD      H,A
            LD      A,(SpeedX)
            ADD     A,H
            AND     63
            LD      (AngleX),A

            CALL    TransformAll

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            ; Decrement RotCount
            LD      A,(RotCountHi)
            LD      B,A
            LD      A,(RotCountLo)
            OR      B
            JP      Z,ML_P3_RotDone

            LD      A,(RotCountLo)
            SUB     1
            LD      (RotCountLo),A
            JP      NC,ML_Blit
            LD      A,(RotCountHi)
            SUB     1
            LD      (RotCountHi),A
            JP      ML_Blit

ML_P3_RotDone
            ; Begin Ship2 shrink
            LD      A,31
            LD      (ShrinkScale),A
            LD      A,4
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 4: Ship2 shrink ------------------------------------------------
ML_NotP3
            LD      A,(Phase)
            CP      4
            JP      NZ,ML_Phase5

            LD      A,(AngleY)
            LD      H,A
            LD      A,(SpeedY)
            ADD     A,H
            AND     63
            LD      (AngleY),A

            LD      A,(AngleX)
            LD      H,A
            LD      A,(SpeedX)
            ADD     A,H
            AND     63
            LD      (AngleX),A

            CALL    TransformAll
            CALL    ShrinkVertices

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            LD      A,(ShrinkScale)
            OR      A
            JP      Z,ML_P4_ShrinkDone
            SUB     1
            LD      (ShrinkScale),A
            JP      ML_Blit

ML_P4_ShrinkDone
            LD      A,5
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 5: idle - starfield only ---------------------------------------
ML_Phase5
            CALL    Blit
ML_Phase5_Idle
            CALL    UpdateStars
            CALL    Blit
            JP      ML_Phase5_Idle

ML_Blit
            CALL    Blit
            JP      MainLoop

; ============================================================================
; ActivateShip1
; Set all runtime geometry variables for Ship1 (Cobra MkIII, 10v/14e)
; ============================================================================
ActivateShip1
            LD      A,S1_NVERT
            LD      (ActiveNVert),A
            LD      A,S1_NEDGE
            LD      (ActiveNEdge),A
            LD      HL,S1_ModelX
            LD      (ModelXPtr),HL
            LD      HL,S1_ModelY
            LD      (ModelYPtr),HL
            LD      HL,S1_ModelZ
            LD      (ModelZPtr),HL
            LD      HL,S1_EdgePairs
            LD      (EdgePairsPtr),HL
            RET

; ============================================================================
; ActivateShip2
; Set all runtime geometry variables for Ship2 (Arrowhead, 8v/13e)
; ============================================================================
ActivateShip2
            LD      A,S2_NVERT
            LD      (ActiveNVert),A
            LD      A,S2_NEDGE
            LD      (ActiveNEdge),A
            LD      HL,S2_ModelX
            LD      (ModelXPtr),HL
            LD      HL,S2_ModelY
            LD      (ModelYPtr),HL
            LD      HL,S2_ModelZ
            LD      (ModelZPtr),HL
            LD      HL,S2_EdgePairs
            LD      (EdgePairsPtr),HL
            RET

; ============================================================================
; SeedVerticesCentre
; Write SCR_CX/SCR_CY into CurrX/Y[0..ActiveNVert-1] then copy to Prev.
; Called when switching ships so the first erase pass is harmless.
; ============================================================================
SeedVerticesCentre
            LD      A,(ActiveNVert)
            LD      (ShrinkRem),A
            XOR     A
            LD      (ShrinkI),A
SVC_Loop
            LD      A,(ShrinkRem)
            OR      A
            JP      Z,SVC_Done
            LD      A,(ShrinkI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,CurrX
            ADD     HL,DE
            LD      A,SCR_CX
            LD      (HL),A
            LD      HL,CurrY
            ADD     HL,DE
            LD      A,SCR_CY
            LD      (HL),A
            LD      A,(ShrinkI)
            ADD     A,1
            LD      (ShrinkI),A
            LD      A,(ShrinkRem)
            SUB     1
            LD      (ShrinkRem),A
            JP      SVC_Loop
SVC_Done
            CALL    CopyCurrToPrev
            RET

; ============================================================================
; Blit: copy offscreen buffer $b000 to VRAM $7000 (2048 bytes)
; ============================================================================
Blit
            LD      HL,$b000
            LD      DE,$7000
            LD      BC,2048
Blit_Loop
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
            JP      PE,Blit_Loop
            RET

; ============================================================================
; ShrinkVertices
; For each vertex i (0..ActiveNVert-1):
;   new_sx = SCR_CX + (CurrX[i]-SCR_CX) * ShrinkScale / 32
;   new_sy = SCR_CY + (CurrY[i]-SCR_CY) * ShrinkScale / 32
; ShrinkScale=31 => almost full size; ShrinkScale=0 => all at centre.
; ============================================================================
ShrinkVertices
            LD      A,(ActiveNVert)
            LD      (ShrinkRem),A
            XOR     A
            LD      (ShrinkI),A
SV_Loop
            LD      A,(ShrinkRem)
            OR      A
            JP      Z,SV_Done

            LD      A,(ShrinkI)
            LD      E,A
            XOR     A
            LD      D,A

            ; --- X axis ---
            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(HL)
            SUB     SCR_CX
            LD      B,A
            LD      A,(ShrinkScale)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            CALL    SAR5
            LD      A,L
            ADD     A,SCR_CX
            LD      (ShrinkBufX),A

            LD      A,(ShrinkI)
            LD      E,A
            XOR     A
            LD      D,A

            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(ShrinkBufX)
            LD      (HL),A

            ; --- Y axis ---
            LD      HL,CurrY
            ADD     HL,DE
            LD      A,(HL)
            SUB     SCR_CY
            LD      B,A
            LD      A,(ShrinkScale)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            CALL    SAR5
            LD      A,L
            ADD     A,SCR_CY

            LD      HL,CurrY
            ADD     HL,DE
            LD      (HL),A

            LD      A,(ShrinkI)
            ADD     A,1
            LD      (ShrinkI),A
            LD      A,(ShrinkRem)
            SUB     1
            LD      (ShrinkRem),A
            JP      SV_Loop
SV_Done
            RET

; ============================================================================
; GrowVertices
; Identical formula to ShrinkVertices but reads GrowScale instead.
; TransformAll has stored full-size projected coords in CurrX/Y.
; We then pull them back toward centre by (32-GrowScale)/32 - i.e. the scale
; factor applied is GrowScale/32, so:
;   GrowScale=0  => point at centre (invisible)
;   GrowScale=31 => 31/32 of full size (nearly full)
; ============================================================================
GrowVertices
            LD      A,(ActiveNVert)
            LD      (ShrinkRem),A
            XOR     A
            LD      (ShrinkI),A
GV_Loop
            LD      A,(ShrinkRem)
            OR      A
            JP      Z,GV_Done

            LD      A,(ShrinkI)
            LD      E,A
            XOR     A
            LD      D,A

            ; --- X axis ---
            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(HL)
            SUB     SCR_CX
            LD      B,A
            LD      A,(GrowScale)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            CALL    SAR5
            LD      A,L
            ADD     A,SCR_CX
            LD      (ShrinkBufX),A

            LD      A,(ShrinkI)
            LD      E,A
            XOR     A
            LD      D,A

            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(ShrinkBufX)
            LD      (HL),A

            ; --- Y axis ---
            LD      HL,CurrY
            ADD     HL,DE
            LD      A,(HL)
            SUB     SCR_CY
            LD      B,A
            LD      A,(GrowScale)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            CALL    SAR5
            LD      A,L
            ADD     A,SCR_CY

            LD      HL,CurrY
            ADD     HL,DE
            LD      (HL),A

            LD      A,(ShrinkI)
            ADD     A,1
            LD      (ShrinkI),A
            LD      A,(ShrinkRem)
            SUB     1
            LD      (ShrinkRem),A
            JP      GV_Loop
GV_Done
            RET

; ============================================================================
; ClearScreenM1_Blue
; ============================================================================
ClearScreenM1_Blue
            LD      HL,RowClr32_M1_Blue
            LD      DE,$b000
            LD      BC,32
            LDIR
            LD      HL,$b000
            LD      DE,$b020
            LD      A,63
            LD      (RowCopyRem),A
CSB_RowLoop
            LD      A,(RowCopyRem)
            OR      A
            JP      Z,CSB_Done
            LD      BC,32
            LDIR
            LD      A,(RowCopyRem)
            DEC     A
            LD      (RowCopyRem),A
            JP      CSB_RowLoop
CSB_Done
            RET

; ============================================================================
; LCG_Next: 16-bit LCG  new = old*2053 + 13849 (mod 65536)
; ============================================================================
LCG_Next
            LD      HL,(RSeed)
            LD      D,H
            LD      E,L
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,DE
            ADD     HL,DE
            ADD     HL,DE
            ADD     HL,DE
            ADD     HL,DE
            LD      DE,13849
            ADD     HL,DE
            LD      (RSeed),HL
            RET

; ============================================================================
; InitStars
; ============================================================================
InitStars
            LD      HL,$ACE1
            LD      (RSeed),HL
            XOR     A
            LD      (StarI),A
            LD      A,NSTARS
            LD      (StarRem),A
InitS_Loop
            LD      A,(StarRem)
            OR      A
            JP      Z,InitS_Done
            CALL    LCG_Next
            LD      A,H
            AND     127
            LD      (TmpA),A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarX
            ADD     HL,DE
            LD      A,(TmpA)
            LD      (HL),A
            CALL    LCG_Next
            LD      A,H
            AND     63
            LD      (TmpA),A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarY
            ADD     HL,DE
            LD      A,(TmpA)
            LD      (HL),A
            CALL    LCG_Next
            LD      A,L
            AND     3
            ADD     A,1
            CP      4
            JP      C,InitS_SpdOK
            LD      A,3
InitS_SpdOK
            LD      (TmpA),A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarSpd
            ADD     HL,DE
            LD      A,(TmpA)
            LD      (HL),A
            LD      A,1
            LD      (DrawColor),A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarX
            ADD     HL,DE
            LD      A,(HL)
            LD      (px),A
            LD      HL,StarY
            ADD     HL,DE
            LD      A,(HL)
            LD      (py),A
            CALL    PlotPixel_M1
            LD      A,(StarI)
            ADD     A,1
            LD      (StarI),A
            LD      A,(StarRem)
            SUB     1
            LD      (StarRem),A
            JP      InitS_Loop
InitS_Done
            RET

; ============================================================================
; UpdateStars
; ============================================================================
UpdateStars
            XOR     A
            LD      (StarI),A
            LD      A,NSTARS
            LD      (StarRem),A
UpdS_Loop
            LD      A,(StarRem)
            OR      A
            JP      Z,UpdS_Done
            LD      A,2
            LD      (DrawColor),A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarX
            ADD     HL,DE
            LD      A,(HL)
            LD      (px),A
            LD      HL,StarY
            ADD     HL,DE
            LD      A,(HL)
            LD      (py),A
            CALL    PlotPixel_M1
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarSpd
            ADD     HL,DE
            LD      A,(HL)
            LD      C,A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarX
            ADD     HL,DE
            LD      A,(HL)
            SUB     C
            JP      NC,UpdS_StoreX
            ADD     A,128
UpdS_StoreX
            LD      (HL),A
            LD      (px),A
            LD      A,1
            LD      (DrawColor),A
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarY
            ADD     HL,DE
            LD      A,(HL)
            LD      (py),A
            CALL    PlotPixel_M1
            LD      A,(StarI)
            ADD     A,1
            LD      (StarI),A
            LD      A,(StarRem)
            SUB     1
            LD      (StarRem),A
            JP      UpdS_Loop
UpdS_Done
            RET

; ============================================================================
; TransformAll: rotate ActiveNVert vertices using current model pointers
; ============================================================================
TransformAll
            LD      A,(AngleY)
            ADD     A,16
            AND     63
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin64U
            ADD     HL,DE
            LD      A,(HL)
            SUB     32
            LD      (CosY),A

            LD      A,(AngleY)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin64U
            ADD     HL,DE
            LD      A,(HL)
            SUB     32
            LD      (SinY),A

            LD      A,(AngleX)
            ADD     A,16
            AND     63
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin64U
            ADD     HL,DE
            LD      A,(HL)
            SUB     32
            LD      (CosX),A

            LD      A,(AngleX)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin64U
            ADD     HL,DE
            LD      A,(HL)
            SUB     32
            LD      (SinX),A

            XOR     A
            LD      (VertIndex),A
            LD      A,(ActiveNVert)
            LD      (VertRem),A
TA_Loop
            LD      A,(VertRem)
            OR      A
            JP      Z,TA_Done

            LD      A,(VertIndex)
            LD      E,A
            XOR     A
            LD      D,A

            ; Load model coords via runtime pointers
            LD      HL,(ModelXPtr)
            ADD     HL,DE
            LD      A,(HL)
            LD      (vx),A

            LD      HL,(ModelYPtr)
            ADD     HL,DE
            LD      A,(HL)
            LD      (vy),A

            LD      HL,(ModelZPtr)
            ADD     HL,DE
            LD      A,(HL)
            LD      (vz),A

            ; x1 = (vx*CosY + vz*SinY) >> 5
            LD      A,(vx)
            LD      B,A
            LD      A,(CosY)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            PUSH    HL
            LD      A,(vz)
            LD      B,A
            LD      A,(SinY)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            EX      DE,HL
            POP     HL
            ADD     HL,DE
            CALL    SAR5
            LD      A,L
            LD      (x1),A

            ; z1 = (-vx*SinY + vz*CosY) >> 5
            LD      A,(vx)
            LD      B,A
            LD      A,(SinY)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            XOR     A
            SUB     L
            LD      L,A
            LD      A,0
            SBC     A,H
            LD      H,A
            PUSH    HL
            LD      A,(vz)
            LD      B,A
            LD      A,(CosY)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            EX      DE,HL
            POP     HL
            ADD     HL,DE
            CALL    SAR5
            LD      A,L
            LD      (z1),A

            ; y2 = (vy*CosX - z1*SinX) >> 5
            LD      A,(vy)
            LD      B,A
            LD      A,(CosX)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            PUSH    HL
            LD      A,(z1)
            LD      B,A
            LD      A,(SinX)
            LD      C,A
            LD      A,B
            CALL    Mul8s
            XOR     A
            SUB     L
            LD      L,A
            LD      A,0
            SBC     A,H
            LD      H,A
            EX      DE,HL
            POP     HL
            ADD     HL,DE
            CALL    SAR5
            LD      A,L
            LD      (y2),A

            LD      A,(x1)
            ADD     A,SCR_CX
            LD      (sx_screen),A

            LD      A,(y2)
            LD      B,A
            LD      A,SCR_CY
            SUB     B
            LD      (sy_screen),A

            LD      A,(VertIndex)
            LD      E,A
            XOR     A
            LD      D,A

            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(sx_screen)
            LD      (HL),A

            LD      HL,CurrY
            ADD     HL,DE
            LD      A,(sy_screen)
            LD      (HL),A

            LD      A,(VertIndex)
            ADD     A,1
            LD      (VertIndex),A
            LD      A,(VertRem)
            SUB     1
            LD      (VertRem),A
            JP      TA_Loop
TA_Done
            RET

; ============================================================================
; DrawWireCurr: draw ActiveNEdge edges from CurrX/Y via EdgePairsPtr
; ============================================================================
DrawWireCurr
            XOR     A
            LD      (EdgeIndex),A
            LD      A,(ActiveNEdge)
            LD      (EdgeRem),A
DWC_Loop
            LD      A,(EdgeRem)
            OR      A
            JP      Z,DWC_Done

            LD      A,(EdgeIndex)
            ADD     A,A
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,(EdgePairsPtr)
            ADD     HL,DE
            LD      A,(HL)
            LD      (e_v0),A
            INC     HL
            LD      A,(HL)
            LD      (e_v1),A

            LD      A,(e_v0)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(HL)
            LD      (x0),A
            LD      HL,CurrY
            ADD     HL,DE
            LD      A,(HL)
            LD      (y0),A

            LD      A,(e_v1)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,CurrX
            ADD     HL,DE
            LD      A,(HL)
            LD      (x1s),A
            LD      HL,CurrY
            ADD     HL,DE
            LD      A,(HL)
            LD      (y1s),A

            CALL    DrawLine

            LD      A,(EdgeIndex)
            ADD     A,1
            LD      (EdgeIndex),A
            LD      A,(EdgeRem)
            SUB     1
            LD      (EdgeRem),A
            JP      DWC_Loop
DWC_Done
            RET

; ============================================================================
; DrawWirePrev: draw ActiveNEdge edges from PrevX/Y via EdgePairsPtr
; ============================================================================
DrawWirePrev
            XOR     A
            LD      (EdgeIndex),A
            LD      A,(ActiveNEdge)
            LD      (EdgeRem),A
DWP_Loop
            LD      A,(EdgeRem)
            OR      A
            JP      Z,DWP_Done

            LD      A,(EdgeIndex)
            ADD     A,A
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,(EdgePairsPtr)
            ADD     HL,DE
            LD      A,(HL)
            LD      (e_v0),A
            INC     HL
            LD      A,(HL)
            LD      (e_v1),A

            LD      A,(e_v0)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,PrevX
            ADD     HL,DE
            LD      A,(HL)
            LD      (x0),A
            LD      HL,PrevY
            ADD     HL,DE
            LD      A,(HL)
            LD      (y0),A

            LD      A,(e_v1)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,PrevX
            ADD     HL,DE
            LD      A,(HL)
            LD      (x1s),A
            LD      HL,PrevY
            ADD     HL,DE
            LD      A,(HL)
            LD      (y1s),A

            CALL    DrawLine

            LD      A,(EdgeIndex)
            ADD     A,1
            LD      (EdgeIndex),A
            LD      A,(EdgeRem)
            SUB     1
            LD      (EdgeRem),A
            JP      DWP_Loop
DWP_Done
            RET

; ============================================================================
; CopyCurrToPrev: copy ActiveNVert bytes CurrX->PrevX and CurrY->PrevY
; ============================================================================
CopyCurrToPrev
            LD      A,(ActiveNVert)
            LD      C,A
            XOR     A
            LD      B,A
            LD      HL,CurrX
            LD      DE,PrevX
            LDIR
            LD      A,(ActiveNVert)
            LD      C,A
            XOR     A
            LD      B,A
            LD      HL,CurrY
            LD      DE,PrevY
            LDIR
            RET

; ============================================================================
; Mul8s: signed 8x8 -> 16-bit in HL.  A = multiplicand, C = multiplier
; ============================================================================
Mul8s
            LD      B,A
            XOR     A
            LD      (MulNeg),A
            LD      A,B
            BIT     7,A
            JP      Z,M1_Pos
            XOR     $FF
            ADD     A,1
            LD      D,A
            LD      A,(MulNeg)
            XOR     1
            LD      (MulNeg),A
            LD      A,D
M1_Pos
            LD      E,A
            XOR     A
            LD      D,A
            LD      A,C
            BIT     7,A
            JP      Z,M2_Pos
            XOR     $FF
            ADD     A,1
            LD      C,A
            LD      A,(MulNeg)
            XOR     1
            LD      (MulNeg),A
M2_Pos
            XOR     A
            LD      H,A
            LD      L,A
            LD      B,8
UM_Loop
            BIT     0,C
            JP      Z,UM_AddSkip
            ADD     HL,DE
UM_AddSkip
            SRL     C
            SLA     E
            RL      D
            DEC     B
            JP      NZ,UM_Loop
            LD      A,(MulNeg)
            OR      A
            JP      Z,UM_Done
            XOR     A
            SUB     L
            LD      L,A
            LD      A,0
            SBC     A,H
            LD      H,A
UM_Done
            RET

; ============================================================================
; SAR5: arithmetic right shift HL by 5 (sign extend from bit 15)
; ============================================================================
SAR5
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

; ============================================================================
; DrawLine: Bresenham line from (x0,y0) to (x1s,y1s)
; ============================================================================
DrawLine
            LD      A,(x0)
            LD      (lx),A
            LD      A,(y0)
            LD      (ly),A
            LD      A,(x1s)
            LD      (rx),A
            LD      A,(y1s)
            LD      (ry),A

            LD      A,(rx)
            LD      B,A
            LD      A,(lx)
            LD      C,A
            LD      A,B
            SUB     C
            LD      (dx),A
            BIT     7,A
            JP      Z,DL_dxPos
            XOR     $FF
            ADD     A,1
            LD      (dx),A
            LD      A,$FF
            LD      (stepx),A
            JP      DL_dxDone
DL_dxPos
            LD      A,1
            LD      (stepx),A
DL_dxDone
            LD      A,(ry)
            LD      B,A
            LD      A,(ly)
            LD      C,A
            LD      A,B
            SUB     C
            LD      (dy),A
            BIT     7,A
            JP      Z,DL_dyPos
            XOR     $FF
            ADD     A,1
            LD      (dy),A
            LD      A,$FF
            LD      (stepy),A
            JP      DL_dyDone
DL_dyPos
            LD      A,1
            LD      (stepy),A
DL_dyDone
            LD      A,(dx)
            LD      B,A
            LD      A,(dy)
            CP      B
            JP      C,DL_XMajor

            LD      A,(dy)
            LD      (count),A
            LD      A,(dy)
            SRL     A
            LD      (err),A
DL_YLoop
            LD      A,(lx)
            LD      (px),A
            LD      A,(ly)
            LD      (py),A
            CALL    PlotPixel_M1
            LD      A,(count)
            OR      A
            JP      Z,DL_Done
            LD      A,(ly)
            LD      D,A
            LD      A,(stepy)
            ADD     A,D
            LD      (ly),A
            LD      A,(err)
            LD      D,A
            LD      A,(dx)
            LD      E,A
            LD      A,D
            SUB     E
            LD      (err),A
            LD      A,(err)
            BIT     7,A
            JP      Z,DL_YSkipX
            LD      B,A
            LD      A,(lx)
            LD      D,A
            LD      A,(stepx)
            LD      E,A
            LD      A,D
            ADD     A,E
            LD      (lx),A
            LD      A,B
            LD      D,A
            LD      A,(dy)
            ADD     A,D
            LD      (err),A
DL_YSkipX
            LD      A,(count)
            SUB     1
            LD      (count),A
            JP      DL_YLoop

DL_XMajor
            LD      A,(dx)
            LD      (count),A
            LD      A,(dx)
            SRL     A
            LD      (err),A
DL_XLoop
            LD      A,(lx)
            LD      (px),A
            LD      A,(ly)
            LD      (py),A
            CALL    PlotPixel_M1
            LD      A,(count)
            OR      A
            JP      Z,DL_Done
            LD      A,(lx)
            LD      D,A
            LD      A,(stepx)
            LD      E,A
            LD      A,D
            ADD     A,E
            LD      (lx),A
            LD      A,(err)
            LD      D,A
            LD      A,(dy)
            LD      E,A
            LD      A,D
            SUB     E
            LD      (err),A
            LD      A,(err)
            BIT     7,A
            JP      Z,DL_XSkipY
            LD      B,A
            LD      A,(ly)
            LD      D,A
            LD      A,(stepy)
            ADD     A,D
            LD      (ly),A
            LD      A,B
            LD      D,A
            LD      A,(dx)
            ADD     A,D
            LD      (err),A
DL_XSkipY
            LD      A,(count)
            SUB     1
            LD      (count),A
            JP      DL_XLoop
DL_Done
            RET

; ============================================================================
; PlotPixel_M1: plot pixel at (px,py) in DrawColor
; ============================================================================
PlotPixel_M1
            LD      A,(py)
            CP      64
            JP      NC,PP_Return
            LD      A,(px)
            CP      128
            JP      NC,PP_Return
            LD      A,(py)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,RowTable_Mode1
            ADD     HL,DE
            ADD     HL,DE
            LD      E,(HL)
            INC     HL
            LD      D,(HL)
            EX      DE,HL
            LD      A,(px)
            SRL     A
            SRL     A
            LD      E,A
            XOR     A
            LD      D,A
            ADD     HL,DE
            LD      A,(HL)
            LD      (pixByte),A
            PUSH    HL
            LD      A,(px)
            AND     3
            LD      (pidx),A
            LD      A,(pidx)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,ClearMaskTable
            ADD     HL,DE
            LD      A,(HL)
            LD      B,A
            LD      A,(pixByte)
            AND     B
            LD      (pixByte),A
            LD      A,(pidx)
            ADD     A,A
            ADD     A,A
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,SetMaskTable
            ADD     HL,DE
            LD      A,(DrawColor)
            LD      C,A
            XOR     A
            LD      B,A
            ADD     HL,BC
            LD      A,(HL)
            LD      B,A
            LD      A,(pixByte)
            OR      B
            POP     HL
            LD      (HL),A
PP_Return
            RET

; ============================================================================
; DATA SECTION
; ============================================================================

; State machine
; 0=Ship1 rotate  1=Ship1 shrink
; 2=Ship2 grow    3=Ship2 rotate  4=Ship2 shrink  5=idle
Phase           DEFB    0

; Active geometry - updated by ActivateShip1 / ActivateShip2
ActiveNVert     DEFB    S1_NVERT
ActiveNEdge     DEFB    S1_NEDGE
ModelXPtr       DW      S1_ModelX
ModelYPtr       DW      S1_ModelY
ModelZPtr       DW      S1_ModelZ
EdgePairsPtr    DW      S1_EdgePairs

; Rotation countdown (16-bit)
RotCountHi      DEFB    ROT_FRAMES_HI
RotCountLo      DEFB    ROT_FRAMES_LO

; Shrink/grow scale registers
ShrinkScale     DEFB    31
GrowScale       DEFB    0

; Shared scratch for Shrink / Grow / Seed loops
ShrinkI         DEFB    0
ShrinkRem       DEFB    0
ShrinkBufX      DEFB    0

; Angles and speeds
AngleY          DEFB    0
AngleX          DEFB    0
SpeedY          DEFB    1
SpeedX          DEFB    1

; Trig scratch
SinY            DEFB    0
CosY            DEFB    0
SinX            DEFB    0
CosX            DEFB    0

; Per-vertex transform scratch
vx              DEFB    0
vy              DEFB    0
vz              DEFB    0
x1              DEFB    0
z1              DEFB    0
y2              DEFB    0
sx_screen       DEFB    0
sy_screen       DEFB    0

; 2D screen coords - allocated for the larger ship (10 vertices)
CurrX           DEFB    0,0,0,0,0,0,0,0,0,0
CurrY           DEFB    0,0,0,0,0,0,0,0,0,0
PrevX           DEFB    0,0,0,0,0,0,0,0,0,0
PrevY           DEFB    0,0,0,0,0,0,0,0,0,0

; Loop helpers
VertIndex       DEFB    0
VertRem         DEFB    0
EdgeIndex       DEFB    0
EdgeRem         DEFB    0
RowCopyRem      DEFB    0

e_v0            DEFB    0
e_v1            DEFB    0

x0              DEFB    0
y0              DEFB    0
x1s             DEFB    0
y1s             DEFB    0
lx              DEFB    0
ly              DEFB    0
rx              DEFB    0
ry              DEFB    0
dx              DEFB    0
dy              DEFB    0
stepx           DEFB    0
stepy           DEFB    0
err             DEFB    0
count           DEFB    0
px              DEFB    0
py              DEFB    0
pixByte         DEFB    0
pidx            DEFB    0

MulNeg          DEFB    0
DrawColor       DEFB    1

RowClr32_M1_Blue
            DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA

ClearMaskTable
            DEFB $3F,$CF,$F3,$FC

SetMaskTable
            DEFB $00,$40,$80,$C0
            DEFB $00,$10,$20,$30
            DEFB $00,$04,$08,$0C
            DEFB $00,$01,$02,$03

Sin64U
            DEFB 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63
            DEFB 63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,32
            DEFB 28,25,22,19,16,13,11,8,6,4,3,2,1,1,0,0
            DEFB 0,0,1,1,2,3,4,6,8,11,13,16,19,22,25,28

RowTable_Mode1
            DW $b000,$b020,$b040,$b060,$b080,$b0A0,$b0C0,$b0E0
            DW $b100,$b120,$b140,$b160,$b180,$b1A0,$b1C0,$b1E0
            DW $b200,$b220,$b240,$b260,$b280,$b2A0,$b2C0,$b2E0
            DW $b300,$b320,$b340,$b360,$b380,$b3A0,$b3C0,$b3E0
            DW $b400,$b420,$b440,$b460,$b480,$b4A0,$b4C0,$b4E0
            DW $b500,$b520,$b540,$b560,$b580,$b5A0,$b5C0,$b5E0
            DW $b600,$b620,$b640,$b660,$b680,$b6A0,$b6C0,$b6E0
            DW $b700,$b720,$b740,$b760,$b780,$b7A0,$b7C0,$b7E0

; ----------------------------------------------------------------------------
; Ship1: Cobra MkIII  (10 vertices, 14 edges)
; Source: elite6.asm
; Vertex: 0=Nose tip, 1=Front-left, 2=Front-right, 3=Dorsal ridge,
;         4=Left wingtip, 5=Right wingtip, 6=Left engine rear,
;         7=Right engine rear, 8=Left engine front, 9=Right engine front
; ----------------------------------------------------------------------------
S1_ModelX   DEFB      0, -14,  14,   0, -38,  38, -22,  22, -18,  18
S1_ModelY   DEFB     -2,  -4,  -4,   6,  -2,  -2,  -2,  -2,  -2,  -2
S1_ModelZ   DEFB    -30, -18, -18, -10,   8,   8,  20,  20,   8,   8

S1_EdgePairs
            DEFB 0,1, 0,2, 1,2, 1,4, 2,5, 0,3
            DEFB 4,8, 5,9, 8,6, 9,7, 6,7, 8,9
            DEFB 3,8, 3,9

; ----------------------------------------------------------------------------
; Ship2: Arrowhead Fighter  (8 vertices, 13 edges)
; Source: elite4a.asm  -  "arrowhead nose + canopy + twin fins" silhouette
; Vertex: 0=Nose tip, 1=Left-front lower, 2=Right-front lower,
;         3=Top-front canopy, 4=Left mid/wing root, 5=Right mid/wing root,
;         6=Top rear spine, 7=Tail point
; Edges: 0-1 nose-left  0-2 nose-right  0-3 canopy strut
;        1-2 front bottom  1-4 left side  2-5 right side
;        3-6 dorsal spine  4-6 left rear up  5-6 right rear up
;        6-7 spine to tail  4-5 rear wing edge  5-7 right wing-tail
;        4-7 left wing-tail
; ----------------------------------------------------------------------------
S2_ModelX   DEFB    0,  -12,  12,   0,  -24,  24,   0,   0
S2_ModelY   DEFB    0,   -6,  -6,  10,   -2,  -2,  12,   0
S2_ModelZ   DEFB  -44,  -12, -12, -12,   10,  10,  14,  36

S2_EdgePairs
            DEFB 0,1, 0,2, 0,3, 1,2, 1,4, 2,5
            DEFB 3,6, 4,6, 5,6, 6,7, 4,5, 5,7, 4,7

; Star data (20 entries each)
StarX       DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarY       DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarSpd     DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
RSeed       DW   $ACE1
StarI       DEFB 0
StarRem     DEFB 0
TmpA        DEFB 0

END

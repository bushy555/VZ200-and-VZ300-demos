ORG $8000
; ============================================================================
; VZ200/VZ300 MODE(1) Wireframe Space Station Demo - BLUE background
; STRICT PASMO: ORG $8000; SP=$F000; JP (no JR); A-for-Absolute (nn) only via A;
; legal 16-bit direct loads/stores; (HL)/(IX+d)/(IY+d) allowed; ALL DB/DW at END.
; Video: MODE(1) 128x64, 2bpp; VRAM $7000-$77FF; latch $6800.
;
; Space Station geometry (56 vertices, 98 edges):
;   Vertices 0-23:  12-segment toroidal ring (top/bottom pairs, radius 24)
;   Vertices 24-36: Central tower (antenna tip, cap, upper body, lower body)
;   Vertices 37-45: Parabolic dish (8-point rim + hub)
;   Vertices 46-53: Twin solar panels (left 4 + right 4)
;   Vertices 54-55: Docking probe (collar + tip)
;
; Edges 0-35:   Toroidal ring (3 per segment x 12 segments)
; Edges 36-59:  Tower structure (spire, cap, body panels)
; Edges 60-76:  Dish (8 rim + 8 spokes + mast connection)
; Edges 77-88:  Solar panels (outlines + diagonals + arms)
; Edges 89-93:  Docking probe (4 collar struts + shaft)
; Edges 94-97:  Ring-to-tower support struts (4 cardinal struts)
;
; Sequence (loops forever):
;   Phase 0: Grow from point to full size (32 frames).
;   Phase 1: Rotate for 320 frames (5 full Y-axis rotations).
;   Phase 2: Shrink back to point (32 frames). Then repeat.
;   Stars scroll continuously throughout.
; ============================================================================

IO_LATCH    EQU     $6800
STACK_TOP   EQU     $F000
SCR_CX      EQU     64
SCR_CY      EQU     32
NSTARS      EQU     20

SS_NVERT    EQU     56
SS_NEDGE    EQU     98

; 320 frames = 5 full rotations (64 steps/rev x 5)
ROT_FRAMES_HI  EQU  1
ROT_FRAMES_LO  EQU  64

; ----------------------------------------------------------------------------
; Entry / Setup
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
            XOR     A
            LD      (SpeedX),A

            ; Phase 0: grow-in
            XOR     A
            LD      (Phase),A
            LD      (GrowScale),A

            ; Activate Space Station geometry
            CALL    ActivateStation

            ; Seed all vertices at screen centre for harmless first erase
            CALL    SeedVerticesCentre

; ----------------------------------------------------------------------------
; Main Loop
; ----------------------------------------------------------------------------
MainLoop
            CALL    UpdateStars

            ; Erase previous frame into offscreen buffer
            LD      A,2
            LD      (DrawColor),A
            CALL    DrawWirePrev

            ; Advance rotation angles (every frame, all phases)
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

            ; Compute full-size projected vertices
            CALL    TransformAll

            ; Dispatch on phase
            LD      A,(Phase)
            OR      A
            JP      NZ,ML_NotP0

; ---- PHASE 0: Grow (fade-in) -----------------------------------------------
            CALL    GrowVertices

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            LD      A,(GrowScale)
            CP      31
            JP      Z,ML_P0_GrowDone
            ADD     A,1
            LD      (GrowScale),A
            JP      ML_Blit

ML_P0_GrowDone
            LD      A,ROT_FRAMES_HI
            LD      (RotCountHi),A
            LD      A,ROT_FRAMES_LO
            LD      (RotCountLo),A
            LD      A,1
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 1: Rotate -------------------------------------------------------
ML_NotP0
            LD      A,(Phase)
            CP      1
            JP      NZ,ML_NotP1

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            ; Decrement 16-bit RotCount
            LD      A,(RotCountHi)
            LD      B,A
            LD      A,(RotCountLo)
            OR      B
            JP      Z,ML_P1_RotDone

            LD      A,(RotCountLo)
            SUB     1
            LD      (RotCountLo),A
            JP      NC,ML_Blit
            LD      A,(RotCountHi)
            SUB     1
            LD      (RotCountHi),A
            JP      ML_Blit

ML_P1_RotDone
            LD      A,31
            LD      (ShrinkScale),A
            LD      A,2
            LD      (Phase),A
            JP      ML_Blit

; ---- PHASE 2: Shrink (fade-out) then loop ----------------------------------
ML_NotP1
            CALL    ShrinkVertices

            LD      A,1
            LD      (DrawColor),A
            CALL    DrawWireCurr
            CALL    CopyCurrToPrev

            LD      A,(ShrinkScale)
            OR      A
            JP      Z,ML_P2_ShrinkDone
            SUB     1
            LD      (ShrinkScale),A
            JP      ML_Blit

ML_P2_ShrinkDone
            ; Re-seed, reset grow, loop back
            CALL    SeedVerticesCentre
            XOR     A
            LD      (GrowScale),A
            LD      (AngleY),A
            LD      (Phase),A
            JP      ML_Blit

ML_Blit
            CALL    Blit
            JP      MainLoop

; ============================================================================
; ActivateStation
; ============================================================================
ActivateStation
            LD      A,SS_NVERT
            LD      (ActiveNVert),A
            LD      A,SS_NEDGE
            LD      (ActiveNEdge),A
            LD      HL,SS_ModelX
            LD      (ModelXPtr),HL
            LD      HL,SS_ModelY
            LD      (ModelYPtr),HL
            LD      HL,SS_ModelZ
            LD      (ModelZPtr),HL
            LD      HL,SS_EdgePairs
            LD      (EdgePairsPtr),HL
            RET

; ============================================================================
; SeedVerticesCentre
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
; LCG_Next
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
; TransformAll
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
; DrawWireCurr
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
; DrawWirePrev
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
; CopyCurrToPrev
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
; Mul8s: signed 8x8 -> 16-bit in HL.  A=multiplicand, C=multiplier
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
; SAR5: arithmetic right-shift HL by 5
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
; DrawLine: Bresenham from (x0,y0) to (x1s,y1s)
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
; PlotPixel_M1
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

; State: 0=grow  1=rotate  2=shrink
Phase           DEFB    0

; Active geometry pointers
ActiveNVert     DEFB    SS_NVERT
ActiveNEdge     DEFB    SS_NEDGE
ModelXPtr       DW      SS_ModelX
ModelYPtr       DW      SS_ModelY
ModelZPtr       DW      SS_ModelZ
EdgePairsPtr    DW      SS_EdgePairs

; Rotation countdown (16-bit)
RotCountHi      DEFB    ROT_FRAMES_HI
RotCountLo      DEFB    ROT_FRAMES_LO

; Scale registers
ShrinkScale     DEFB    31
GrowScale       DEFB    0

; Shared scratch
ShrinkI         DEFB    0
ShrinkRem       DEFB    0
ShrinkBufX      DEFB    0

; Angles and speeds
AngleY          DEFB    0
AngleX          DEFB    0
SpeedY          DEFB    1
SpeedX          DEFB    0

; Trig
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

; 2D screen coords - 56 vertices
CurrX   DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
CurrY   DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PrevX   DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PrevY   DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

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

; ============================================================================
; SPACE STATION MODEL DATA
;
; Coordinate system:  X = left/right,  Y = up/down,  Z = front/back
; Projection:  sx = x_rotated/32 + 64,  sy = 32 - y_rotated/32
; Safe ranges: X model +-40 (ring+panels), Y model -20..+27 (probe..dish hub)
;
; TOROIDAL RING  (vertices 0-23)
;   12 segments, 30 degrees apart, radius 24.
;   Vertices interleaved: even = top rim (Y=+3), odd = bottom rim (Y=-3).
;   Segment i: top = vertex 2i, bottom = vertex 2i+1.
;   Coordinates computed as: X=round(24*sin(i*30)), Z=round(24*cos(i*30))
;
; CENTRAL TOWER  (vertices 24-36)
;   24: Antenna mast tip           (0, +20,  0)
;   25-28: Upper cap square 8x8   (+-4, +15, +-4)
;   29-32: Upper body square 12x12 (+-6, +5, +-6)
;   33-36: Lower body square 8x8  (+-4, -8, +-4)
;
; PARABOLIC DISH  (vertices 37-45)
;   37-44: 8-point rim, radius 9, at Y=+22
;   45: Dish hub / focal mast tip (0, +27, 0)
;
; SOLAR PANELS  (vertices 46-53)
;   Left panel:  46-49  X=-28..-40, Y=+5..-5, Z=+3
;   Right panel: 50-53  X=+28..+40, Y=+5..-5, Z=+3
;
; DOCKING PROBE  (vertices 54-55)
;   54: Docking collar centre  (0, -14, 0)
;   55: Probe tip              (0, -20, 0)
; ============================================================================

SS_ModelX
            ; Ring top/bottom pairs (24 vertices, indices 0-23)
            DEFB   0,  0, 12, 12, 21, 21, 24, 24, 21, 21, 12, 12
            DEFB   0,  0,-12,-12,-21,-21,-24,-24,-21,-21,-12,-12
            ; Tower (13 vertices, indices 24-36)
            DEFB   0, -4,  4,  4, -4, -6,  6,  6, -6, -4,  4,  4, -4
            ; Dish rim + hub (9 vertices, indices 37-45)
            DEFB   0,  6,  9,  6,  0, -6, -9, -6,  0
            ; Solar panels L then R (8 vertices, indices 46-53)
            DEFB -28,-28,-40,-40, 28, 28, 40, 40
            ; Docking probe (2 vertices, indices 54-55)
            DEFB   0,  0

SS_ModelY
            ; Ring top/bottom pairs
            DEFB   3, -3,  3, -3,  3, -3,  3, -3,  3, -3,  3, -3
            DEFB   3, -3,  3, -3,  3, -3,  3, -3,  3, -3,  3, -3
            ; Tower
            DEFB  20, 15, 15, 15, 15,  5,  5,  5,  5, -8, -8, -8, -8
            ; Dish
            DEFB  22, 22, 22, 22, 22, 22, 22, 22, 27
            ; Solar panels
            DEFB   5, -5,  5, -5,  5, -5,  5, -5
            ; Docking
            DEFB -14,-20

SS_ModelZ
            ; Ring top/bottom pairs
            DEFB  24, 24, 21, 21, 12, 12,  0,  0,-12,-12,-21,-21
            DEFB -24,-24,-21,-21,-12,-12,  0,  0, 12, 12, 21, 21
            ; Tower
            DEFB   0,  4,  4, -4, -4,  6,  6, -6, -6,  4,  4, -4, -4
            ; Dish (octagonal rim at 45-degree intervals, radius 9)
            DEFB   9,  6,  0, -6, -9, -6,  0,  6,  0
            ; Solar panels (slightly in front, Z=+3)
            DEFB   3,  3,  3,  3,  3,  3,  3,  3
            ; Docking
            DEFB   0,  0

SS_EdgePairs
            ; ----------------------------------------------------------
            ; RING: 36 edges (3 per segment x 12 segments)
            ; Each segment i has: top-bottom strut, top arc, bottom arc
            ; ----------------------------------------------------------
            DEFB  0, 1,  0, 2,  1, 3   ; seg 0: strut, top 0->2, bot 1->3
            DEFB  2, 3,  2, 4,  3, 5   ; seg 1
            DEFB  4, 5,  4, 6,  5, 7   ; seg 2
            DEFB  6, 7,  6, 8,  7, 9   ; seg 3
            DEFB  8, 9,  8,10,  9,11   ; seg 4
            DEFB 10,11, 10,12, 11,13   ; seg 5
            DEFB 12,13, 12,14, 13,15   ; seg 6
            DEFB 14,15, 14,16, 15,17   ; seg 7
            DEFB 16,17, 16,18, 17,19   ; seg 8
            DEFB 18,19, 18,20, 19,21   ; seg 9
            DEFB 20,21, 20,22, 21,23   ; seg 10
            DEFB 22,23, 22, 0, 23, 1   ; seg 11 (wraps to seg 0)

            ; ----------------------------------------------------------
            ; TOWER: 24 edges
            ; ----------------------------------------------------------
            ; Spire: antenna tip (24) to upper cap corners (25-28)
            DEFB 24,25, 24,26, 24,27, 24,28
            ; Upper cap square
            DEFB 25,26, 26,27, 27,28, 28,25
            ; Cap to upper body: corners 25-28 to body 29-32
            DEFB 25,29, 26,30, 27,31, 28,32
            ; Upper body square (29-32)
            DEFB 29,30, 30,31, 31,32, 32,29
            ; Upper body to lower body: 29-32 to 33-36
            DEFB 29,33, 30,34, 31,35, 32,36
            ; Lower body square (33-36)
            DEFB 33,34, 34,35, 35,36, 36,33

            ; ----------------------------------------------------------
            ; DISH: 17 edges
            ; ----------------------------------------------------------
            ; Rim octagon (37-44)
            DEFB 37,38, 38,39, 39,40, 40,41
            DEFB 41,42, 42,43, 43,44, 44,37
            ; 8 spokes to hub (45)
            DEFB 37,45, 38,45, 39,45, 40,45
            DEFB 41,45, 42,45, 43,45, 44,45
            ; Mast: antenna tip (24) to dish hub (45)
            DEFB 24,45

            ; ----------------------------------------------------------
            ; SOLAR PANELS: 12 edges
            ; ----------------------------------------------------------
            ; Left panel (46=inner-top, 47=inner-bot, 48=outer-top, 49=outer-bot)
            DEFB 46,47  ; inner vertical
            DEFB 48,49  ; outer vertical
            DEFB 46,48  ; top horizontal
            DEFB 47,49  ; bottom horizontal
            DEFB 46,49  ; diagonal brace
            DEFB 29,46  ; arm: upper-body-BL (29) to panel inner-top
            ; Right panel (50=inner-top, 51=inner-bot, 52=outer-top, 53=outer-bot)
            DEFB 50,51
            DEFB 52,53
            DEFB 50,52
            DEFB 51,53
            DEFB 50,53  ; diagonal brace
            DEFB 30,50  ; arm: upper-body-BR (30) to panel inner-top

            ; ----------------------------------------------------------
            ; DOCKING PROBE: 5 edges
            ; ----------------------------------------------------------
            ; 4 lower body corners (33-36) converge to collar (54)
            DEFB 33,54, 34,54, 35,54, 36,54
            ; Collar (54) to probe tip (55)
            DEFB 54,55

            ; ----------------------------------------------------------
            ; RING-TO-TOWER SUPPORT STRUTS: 4 edges
            ; Connect the 4 cardinal ring top vertices to tower upper body
            ; Ring v0  (0 deg, front)  -> tower upper-BL (29)
            ; Ring v6  (90 deg, right) -> tower upper-BR (30)
            ; Ring v12 (180 deg, back) -> tower upper-FR (31)
            ; Ring v18 (270 deg, left) -> tower upper-FL (32)
            ; ----------------------------------------------------------
            DEFB  0,29,  6,30, 12,31, 18,32

; Star data
StarX       DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarY       DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarSpd     DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
RSeed       DW   $ACE1
StarI       DEFB 0
StarRem     DEFB 0
TmpA        DEFB 0

END

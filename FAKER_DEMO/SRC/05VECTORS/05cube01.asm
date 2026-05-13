ORG $8000
; ======================================================================
; VZ200/VZ300 MODE(1) Wireframe Cube + Scrolling Stars
; - Checkerboard background from ROM table, restored each frame
; - 20 yellow stars (color=1) scroll right-to-left across background
; - Stars are drawn onto the buffer AFTER background restore each frame
;   so no explicit star-erase is needed; the background wipe does it.
; - Rotating cube drawn in color=2 on top of stars
; STRICT: ORG $8000; SP=$F000; JP not JR; A-for-absolute (nn) only;
;         all DB/DW at the end; VRAM $7000-$77FF; latch $6800.
; ======================================================================

; ----------------------- Constants (EQU) -------------------------------
IO_LATCH  EQU $6800
VRAM_BASE EQU $7000
STACK_TOP EQU $F000
SCR_CX    EQU 64
SCR_CY    EQU 32
NSTARS    EQU 20

; -------------------------- Entry / Setup ------------------------------
START
 DI
 LD SP,STACK_TOP
 ; MODE(1)
 LD A,24
 LD (IO_LATCH),A

 ; Clear buffer to $00
 CALL ClearScreenM1

 ; Initialise and draw stars onto the buffer
 CALL InitStars

 ; Init angles / speeds
 XOR A
 LD (AngleY),A
 LD (AngleX),A
 LD A,1
 LD (SpeedY),A
 LD A,1
 LD (SpeedX),A

 ; Draw color = 2 for the cube
 LD A,2
 LD (DrawColor),A

 ; Compute first frame and seed Prev=Curr
 CALL TransformAll
 CALL CopyCurrToPrev

; ----------------------------- Main Loop ------------------------------
MainLoop
 ; toggle frame parity
 LD A,(FrameToggle)
 XOR 1
 LD (FrameToggle),A

 ; ----------------------------------------------------------------
 ; 1) Blit current buffer ($b000) to VRAM ($7000)
 ; ----------------------------------------------------------------
 LD HL,$b000
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
 LD HL,background
 LD DE,$b000
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

 ; ----------------------------------------------------------------
 ; 3) Update scrolling stars (move X left, draw yellow on buffer)
 ;    No explicit erase needed - background restore above handles it.
 ; ----------------------------------------------------------------
 CALL UpdateStars

 ; ----------------------------------------------------------------
 ; 4) Erase previous cube (color=0) using PrevX/PrevY
 ; ----------------------------------------------------------------
 XOR A
 LD (DrawColor),A
 CALL DrawWirePrev

 ; ----------------------------------------------------------------
 ; 5) Update rotation angles
 ; ----------------------------------------------------------------
 LD A,(AngleY)
 LD H,A
 LD A,(SpeedY)
 ADD A,H
 AND 63
 LD (AngleY),A

 LD A,(AngleX)
 LD H,A
 LD A,(SpeedX)
 ADD A,H
 AND 63
 LD (AngleX),A

 ; ----------------------------------------------------------------
 ; 6) Recompute cube vertices
 ; ----------------------------------------------------------------
 CALL TransformAll

 ; ----------------------------------------------------------------
 ; 7) Draw new cube (color=2)
 ; ----------------------------------------------------------------
 LD A,2
 LD (DrawColor),A
 CALL DrawWireCurr

 ; ----------------------------------------------------------------
 ; 8) Save current as previous
 ; ----------------------------------------------------------------
 CALL CopyCurrToPrev

 JP MainLoop

; ======================================================================
; ClearScreenM1: fill buffer $b000 with $00 x 2048
; ======================================================================
ClearScreenM1

 	LD   	(SavedSP),SP
  	ld 	sp, $B000+2048
 	ld 	hl,0
	ld 	b, 64           
ClrLoop:push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl         
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl
    	push 	hl         
    	djnz 	ClrLoop
 	LD   	SP, (SavedSP)
 RET





; ======================================================================
; LCG_Next: 16-bit LCG  new = old*2053 + 13849 (mod 65536)
; Result in HL, also stored to RSeed.
; ======================================================================
LCG_Next
            LD      HL,(RSeed)
            LD      D,H
            LD      E,L
            ; HL = old << 11
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
            ; HL += old * 5
            ADD     HL,DE
            ADD     HL,DE
            ADD     HL,DE
            ADD     HL,DE
            ADD     HL,DE
            ; HL += 13849
            LD      DE,13849
            ADD     HL,DE
            LD      (RSeed),HL
            RET

; ======================================================================
; InitStars: assign random X, Y, speed to all NSTARS stars.
; Stars are drawn yellow (color=1) onto the current buffer.
; Called once at startup after ClearScreenM1.
; ======================================================================
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
            ; X = rnd_hi & 127
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
            ; Y = rnd_hi & 63
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
            ; Speed = (rnd_lo & 3) + 1, clamp to 3
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
            ; Draw initial star yellow (color=1)
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
            ; next star
            LD      A,(StarI)
            ADD     A,1
            LD      (StarI),A
            LD      A,(StarRem)
            SUB     1
            LD      (StarRem),A
            JP      InitS_Loop
InitS_Done
            RET

; ======================================================================
; UpdateStars: move each star left by its speed (wrap at 0->127),
; then draw it yellow (color=1) onto the buffer.
; No explicit erase: the background restore at the top of MainLoop
; already cleared the old star positions.
; ======================================================================
UpdateStars
            XOR     A
            LD      (StarI),A
            LD      A,NSTARS
            LD      (StarRem),A
UpdS_Loop
            LD      A,(StarRem)
            OR      A
            JP      Z,UpdS_Done
            ; Move X left by speed, wrap 0 -> 127
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarSpd
            ADD     HL,DE
            LD      A,(HL)
            LD      C,A             ; C = speed
            LD      A,(StarI)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,StarX
            ADD     HL,DE
            LD      A,(HL)
            SUB     C
            JP      NC,UpdS_StoreX
            ADD     A,128           ; wrap: if underflowed, add 128
UpdS_StoreX
            LD      (HL),A
            LD      (px),A
            ; Draw star yellow (color=1)
            LD      A,0
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
            ; next star
            LD      A,(StarI)
            ADD     A,1
            LD      (StarI),A
            LD      A,(StarRem)
            SUB     1
            LD      (StarRem),A
            JP      UpdS_Loop
UpdS_Done
            RET

; ======================================================================
; TransformAll: sin/cos lookup then model -> screen (CurrX/CurrY)
; ======================================================================
TransformAll
 ; ---- trig for Y ----
 LD A,(AngleY)
 ADD A,16
 AND 63
 LD E,A
 XOR A
 LD D,A
 LD HL,Sin64U
 ADD HL,DE
 LD A,(HL)
 SUB 32
 LD (CosY),A

 LD A,(AngleY)
 LD E,A
 XOR A
 LD D,A
 LD HL,Sin64U
 ADD HL,DE
 LD A,(HL)
 SUB 32
 LD (SinY),A

 ; ---- trig for X ----
 LD A,(AngleX)
 ADD A,16
 AND 63
 LD E,A
 XOR A
 LD D,A
 LD HL,Sin64U
 ADD HL,DE
 LD A,(HL)
 SUB 32
 LD (CosX),A

 LD A,(AngleX)
 LD E,A
 XOR A
 LD D,A
 LD HL,Sin64U
 ADD HL,DE
 LD A,(HL)
 SUB 32
 LD (SinX),A

 ; i = 0..7
 XOR A
 LD (VertIndex),A
 LD A,8
 LD (VertRem),A

TA_Loop
 LD A,(VertRem)
 OR A
 JP Z,TA_Done

 ; ---- load vertex i ----
 LD A,(VertIndex)
 LD E,A
 XOR A
 LD D,A

 LD HL,ModelX
 ADD HL,DE
 LD A,(HL)
 LD (vx),A

 LD HL,ModelY
 ADD HL,DE
 LD A,(HL)
 LD (vy),A

 LD HL,ModelZ
 ADD HL,DE
 LD A,(HL)
 LD (vz),A

 ; ---- x1 = (x*cy + z*sy)>>5 ----
 LD A,(vx)
 LD B,A
 LD A,(CosY)
 LD C,A
 LD A,B
 CALL Mul8s

 PUSH HL
 LD A,(vz)
 LD B,A
 LD A,(SinY)
 LD C,A
 LD A,B
 CALL Mul8s
 EX DE,HL
 POP HL
 ADD HL,DE
 CALL SAR4
 LD A,L
 LD (x1),A

 ; ---- z1 = (-x*sy + z*cy)>>5 ----
 LD A,(vx)
 LD B,A
 LD A,(SinY)
 LD C,A
 LD A,B
 CALL Mul8s
 XOR A
 SUB L
 LD L,A
 LD A,0
 SBC A,H
 LD H,A
 PUSH HL
 LD A,(vz)
 LD B,A
 LD A,(CosY)
 LD C,A
 LD A,B
 CALL Mul8s
 EX DE,HL
 POP HL
 ADD HL,DE
 CALL SAR4
 LD A,L
 LD (z1),A

 ; ---- y2 = (y*cx - z1*sx)>>5 ----
 LD A,(vy)
 LD B,A
 LD A,(CosX)
 LD C,A
 LD A,B
 CALL Mul8s
 PUSH HL
 LD A,(z1)
 LD B,A
 LD A,(SinX)
 LD C,A
 LD A,B
 CALL Mul8s
 XOR A
 SUB L
 LD L,A
 LD A,0
 SBC A,H
 LD H,A
 EX DE,HL
 POP HL
 ADD HL,DE
 CALL SAR4
 LD A,L
 LD (y2),A

 ; ---- screen coords ----
 LD A,(x1)
 ADD A,SCR_CX
 LD (sx_screen),A

 LD A,(y2)
 LD B,A
 LD A,SCR_CY
 SUB B
 LD (sy_screen),A

 ; store to CurrX/CurrY
 LD A,(VertIndex)
 LD E,A
 XOR A
 LD D,A

 LD HL,CurrX
 ADD HL,DE
 LD A,(sx_screen)
 LD (HL),A

 LD HL,CurrY
 ADD HL,DE
 LD A,(sy_screen)
 LD (HL),A

 ; next vertex
 LD A,(VertIndex)
 ADD A,1
 LD (VertIndex),A
 LD A,(VertRem)
 SUB 1
 LD (VertRem),A
 JP TA_Loop

TA_Done
 RET

; ======================================================================
; DrawWireCurr / DrawWirePrev
; ======================================================================
DrawWireCurr
 XOR A
 LD (EdgeIndex),A
 LD A,12
 LD (EdgeRem),A
DWC_Loop
 LD A,(EdgeRem)
 OR A
 JP Z,DWC_Done

 LD A,(EdgeIndex)
 ADD A,A
 LD E,A
 XOR A
 LD D,A
 LD HL,EdgePairs
 ADD HL,DE
 LD A,(HL)
 LD (e_v0),A
 INC HL
 LD A,(HL)
 LD (e_v1),A

 LD A,(e_v0)
 LD E,A
 XOR A
 LD D,A
 LD HL,CurrX
 ADD HL,DE
 LD A,(HL)
 LD (x0),A
 LD HL,CurrY
 ADD HL,DE
 LD A,(HL)
 LD (y0),A

 LD A,(e_v1)
 LD E,A
 XOR A
 LD D,A
 LD HL,CurrX
 ADD HL,DE
 LD A,(HL)
 LD (x1s),A
 LD HL,CurrY
 ADD HL,DE
 LD A,(HL)
 LD (y1s),A

 CALL DrawLine

 LD A,(EdgeIndex)
 ADD A,1
 LD (EdgeIndex),A
 LD A,(EdgeRem)
 SUB 1
 LD (EdgeRem),A
 JP DWC_Loop
DWC_Done
 RET

DrawWirePrev
 XOR A
 LD (EdgeIndex),A
 LD A,12
 LD (EdgeRem),A
DWP_Loop
 LD A,(EdgeRem)
 OR A
 JP Z,DWP_Done

 LD A,(EdgeIndex)
 ADD A,A
 LD E,A
 XOR A
 LD D,A
 LD HL,EdgePairs
 ADD HL,DE
 LD A,(HL)
 LD (e_v0),A
 INC HL
 LD A,(HL)
 LD (e_v1),A

 LD A,(e_v0)
 LD E,A
 XOR A
 LD D,A
 LD HL,PrevX
 ADD HL,DE
 LD A,(HL)
 LD (x0),A
 LD HL,PrevY
 ADD HL,DE
 LD A,(HL)
 LD (y0),A

 LD A,(e_v1)
 LD E,A
 XOR A
 LD D,A
 LD HL,PrevX
 ADD HL,DE
 LD A,(HL)
 LD (x1s),A
 LD HL,PrevY
 ADD HL,DE
 LD A,(HL)
 LD (y1s),A

 CALL DrawLine

 LD A,(EdgeIndex)
 ADD A,1
 LD (EdgeIndex),A
 LD A,(EdgeRem)
 SUB 1
 LD (EdgeRem),A
 JP DWP_Loop
DWP_Done
 RET

; ======================================================================
; CopyCurrToPrev
; ======================================================================
CopyCurrToPrev
 LD HL,CurrX
 LD DE,PrevX
 LD BC,8
 LDIR
 LD HL,CurrY
 LD DE,PrevY
 LD BC,8
 LDIR
 RET

; ======================================================================
; Mul8s: signed 8x8 -> 16 in HL
; ======================================================================
Mul8s
 LD B,A
 XOR A
 LD (MulNeg),A
 LD A,B

 BIT 7,A
 JP Z,M1_Pos
 XOR $FF
 ADD A,1
 LD D,A
 LD A,(MulNeg)
 XOR 1
 LD (MulNeg),A
 LD A,D
M1_Pos
 LD E,A
 XOR A
 LD D,A

 LD A,C
 BIT 7,A
 JP Z,M2_Pos
 XOR $FF
 ADD A,1
 LD C,A
 LD A,(MulNeg)
 XOR 1
 LD (MulNeg),A
M2_Pos

 XOR A
 LD H,A
 LD L,A
 LD B,8
UM_Loop
 BIT 0,C
 JP Z,UM_AddSkip
 ADD HL,DE
UM_AddSkip
 SRL C
 SLA E
 RL D
 DEC B
 JP NZ,UM_Loop

 LD A,(MulNeg)
 OR A
 JP Z,UM_Done
 XOR A
 SUB L
 LD L,A
 LD A,0
 SBC A,H
 LD H,A
UM_Done
 RET

; ======================================================================
; SAR5: arithmetic right shift HL by 5
; ======================================================================
SAR4
 SRA H
 RR L
 SRA H
 RR L
 SRA H
 RR L
 SRA H
 RR L
 SRA H
 RR L
 RET

; ======================================================================
; DrawLine: robust major-axis Bresenham
; ======================================================================
DrawLine
 LD A,(x0)
 LD (lx),A
 LD A,(y0)
 LD (ly),A
 LD A,(x1s)
 LD (rx),A
 LD A,(y1s)
 LD (ry),A

 LD A,(rx)
 LD B,A
 LD A,(lx)
 LD C,A
 LD A,B
 SUB C
 LD (dx),A
 BIT 7,A
 JP Z,DL_dxPos
 XOR $FF
 ADD A,1
 LD (dx),A
 LD A,$FF
 LD (stepx),A
 JP DL_dxDone
DL_dxPos
 LD A,1
 LD (stepx),A
DL_dxDone

 LD A,(ry)
 LD B,A
 LD A,(ly)
 LD C,A
 LD A,B
 SUB C
 LD (dy),A
 BIT 7,A
 JP Z,DL_dyPos
 XOR $FF
 ADD A,1
 LD (dy),A
 LD A,$FF
 LD (stepy),A
 JP DL_dyDone
DL_dyPos
 LD A,1
 LD (stepy),A
DL_dyDone

 LD A,(dx)
 LD B,A
 LD A,(dy)
 CP B
 JP C,DL_XMajor

 LD A,(dy)
 LD (count),A
 LD A,(dy)
 SRL A
 LD (err),A
DL_YLoop
 LD A,(lx)
 LD (px),A
 LD A,(ly)
 LD (py),A
 CALL PlotPixel_M1

 LD A,(count)
 OR A
 JP Z,DL_Done

 LD A,(ly)
 LD D,A
 LD A,(stepy)
 ADD A,D
 LD (ly),A

 LD A,(err)
 LD D,A
 LD A,(dx)
 LD E,A
 LD A,D
 SUB E
 LD (err),A

 LD A,(err)
 BIT 7,A
 JP Z,DL_YSkipX
 LD B,A
 LD A,(lx)
 LD D,A
 LD A,(stepx)
 LD E,A
 LD A,D
 ADD A,E
 LD (lx),A
 LD A,B
 LD D,A
 LD A,(dy)
 ADD A,D
 LD (err),A
DL_YSkipX
 LD A,(count)
 SUB 1
 LD (count),A
 JP DL_YLoop

DL_XMajor
 LD A,(dx)
 LD (count),A
 LD A,(dx)
 SRL A
 LD (err),A
DL_XLoop
 LD A,(lx)
 LD (px),A
 LD A,(ly)
 LD (py),A
 CALL PlotPixel_M1

 LD A,(count)
 OR A
 JP Z,DL_Done

 LD A,(lx)
 LD D,A
 LD A,(stepx)
 LD E,A
 LD A,D
 ADD A,E
 LD (lx),A

 LD A,(err)
 LD D,A
 LD A,(dy)
 LD E,A
 LD A,D
 SUB E
 LD (err),A

 LD A,(err)
 BIT 7,A
 JP Z,DL_XSkipY
 LD B,A
 LD A,(ly)
 LD D,A
 LD A,(stepy)
 ADD A,D
 LD (ly),A
 LD A,B
 LD D,A
 LD A,(dx)
 ADD A,D
 LD (err),A
DL_XSkipY
 LD A,(count)
 SUB 1
 LD (count),A
 JP DL_XLoop

DL_Done
 RET

; ======================================================================
; PlotPixel_M1
; Inputs: px,py (0..127, 0..63), DrawColor (0..3)
; ======================================================================
PlotPixel_M1
 LD A,(py)
 CP 64
 JP NC,PP_Return

 LD A,(px)
 CP 128
 JP NC,PP_Return

 LD A,(py)
 LD E,A
 XOR A
 LD D,A
 LD HL,RowTable_Mode1
 ADD HL,DE
 ADD HL,DE
 LD E,(HL)
 INC HL
 LD D,(HL)
 EX DE,HL

 LD A,(px)
 SRL A
 SRL A
 LD E,A
 XOR A
 LD D,A
 ADD HL,DE

 LD A,(HL)
 LD (pixByte),A
 PUSH HL

 LD A,(px)
 AND 3
 LD (pidx),A

 LD A,(pidx)
 LD E,A
 XOR A
 LD D,A
 LD HL,ClearMaskTable
 ADD HL,DE
 LD A,(HL)
 LD B,A

 LD A,(pixByte)
 AND B
 LD (pixByte),A

 LD A,(pidx)
 ADD A,A
 ADD A,A
 LD E,A
 XOR A
 LD D,A
 LD HL,SetMaskTable
 ADD HL,DE
 LD A,(DrawColor)
 LD C,A
 XOR A
 LD B,A
 ADD HL,BC
 LD A,(HL)
 LD B,A

 LD A,(pixByte)
 OR B
 POP HL
 LD (HL),A

PP_Return
 RET

; ======================================================================
; DATA
; ======================================================================

; Angles and speeds
AngleY        DEFB 0
AngleX        DEFB 0
SpeedY        DEFB 1
SpeedX        DEFB 1

; Trig scratch
SinY          DEFB 0
CosY          DEFB 0
SinX          DEFB 0
CosX          DEFB 0

; Per-vertex scratch
vx            DEFB 0
vy            DEFB 0
vz            DEFB 0
x1            DEFB 0
z1            DEFB 0
y2            DEFB 0
sx_screen     DEFB 0
sy_screen     DEFB 0

; Current and previous screen coords (8 vertices)
CurrX         DEFB 0,0,0,0,0,0,0,0
CurrY         DEFB 0,0,0,0,0,0,0,0
PrevX         DEFB 0,0,0,0,0,0,0,0
PrevY         DEFB 0,0,0,0,0,0,0,0

; Loop helpers
VertIndex     DEFB 0
VertRem       DEFB 0
EdgeIndex     DEFB 0
EdgeRem       DEFB 0
RowCopyRem    DEFB 0

; Edge-pair temps
e_v0          DEFB 0
e_v1          DEFB 0

; Line drawer temps
x0            DEFB 0
y0            DEFB 0
x1s           DEFB 0
y1s           DEFB 0
lx            DEFB 0
ly            DEFB 0
rx            DEFB 0
ry            DEFB 0
dx            DEFB 0
dy            DEFB 0
stepx         DEFB 0
stepy         DEFB 0
err           DEFB 0
count         DEFB 0
px            DEFB 0
py            DEFB 0
pixByte       DEFB 0
pidx          DEFB 0
SavedSP		defw 0

; Multiply helper
MulNeg        DEFB 0

; Drawing color (0..3)
DrawColor     DEFB 2

; Star data (NSTARS = 20 entries each)
StarX         DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarY         DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarSpd       DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
RSeed         DW   $ACE1
StarI         DEFB 0
StarRem       DEFB 0
TmpA          DEFB 0
FrameToggle	defb 0

; MODE(1) row clear buffer (32 bytes of $00)
RowClr32_M1
 DEFB $00,$00,$00,$00,$00,$00,$00,$00
 DEFB $00,$00,$00,$00,$00,$00,$00,$00
 DEFB $00,$00,$00,$00,$00,$00,$00,$00
 DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Clear masks p=0..3
ClearMaskTable
 DEFB $3F,$CF,$F3,$FC

; Set masks indexed by (p*4 + color)
SetMaskTable
 DEFB $00,$40,$80,$C0
 DEFB $00,$10,$20,$30
 DEFB $00,$04,$08,$0C
 DEFB $00,$01,$02,$03

; 64-entry unsigned sinusoid 0..63
Sin64U
 DEFB 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63
 DEFB 63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,32
 DEFB 28,25,22,19,16,13,11,8,6,4,3,2,1,1,0,0
 DEFB 0,0,1,1,2,3,4,6,8,11,13,16,19,22,25,28

; MODE(1) buffer row base addresses (pointing to $b000 offscreen buffer)
RowTable_Mode1
 DW $B000,$B020,$B040,$B060,$B080,$B0A0,$B0C0,$B0E0
 DW $B100,$B120,$B140,$B160,$B180,$B1A0,$B1C0,$B1E0
 DW $B200,$B220,$B240,$B260,$B280,$B2A0,$B2C0,$B2E0
 DW $B300,$B320,$B340,$B360,$B380,$B3A0,$B3C0,$B3E0
 DW $B400,$B420,$B440,$B460,$B480,$B4A0,$B4C0,$B4E0
 DW $B500,$B520,$B540,$B560,$B580,$B5A0,$B5C0,$B5E0
 DW $B600,$B620,$B640,$B660,$B680,$B6A0,$B6C0,$B6E0
 DW $B700,$B720,$B740,$B760,$B780,$B7A0,$B7C0,$B7E0

; ----------------------------- Model ----------------------------------
ModelX  DEFB -28, 28, -28, 28, -20, 20, -20, 20
ModelY  DEFB -20,-20,  20, 20, -28,-28,  28, 28
ModelZ  DEFB -28,-28, -28,-28,  28, 28,  28, 28

; Wireframe edges (12 pairs)
EdgePairs
 DEFB 0,1, 1,3, 3,2, 2,0
 DEFB 4,5, 5,7, 7,6, 6,4
 DEFB 0,4, 1,5, 2,6, 3,7

; Checkerboard background (2048 bytes, 64 rows x 32 bytes)
; $FF = 11 11 11 11 (color 3 in all 4 pixels)
; $55 = 01 01 01 01 (color 1 in all 4 pixels)
background:
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55

 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF

 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55

 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF

 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55
 db  $FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55

 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF
 db  $55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF,$55,$55,$55,$55,$FF,$FF,$FF,$FF

END

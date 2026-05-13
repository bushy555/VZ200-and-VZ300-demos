; ============================================================================
; VZ200/VZ300 MODE(1) Vector Ship + Perspective + Backface + Parallax Stars
; Strict PASMO rules:
;   ORG $8000; SP $F000; JP only (no JR); A-for-Absolute (nn);
;   legal Z80 16-bit directs; (HL)/(IX+d)/(IY+d) allowed; one instruction/line;
;   ALL DB/DW AT END; MODE(1) VRAM safety; 32-byte row stride.
; Video:
;   MODE(1) 128x64, 2bpp; VRAM $7000–$77FF; latch $6800.
; Background: BLUE ($AA per VRAM byte). Stars = Yellow (color=1).
; ============================================================================

ORG $8000

; --------------------------------------------
; Constants / Equates
; --------------------------------------------
IO_LATCH      EQU $6800
VRAM_BASE     EQU $7000
STACK_TOP     EQU $F000

SCR_CX        EQU 64
SCR_CY        EQU 32

DEPTH_BIAS    EQU 160	; 96
VIEW_GAIN     EQU 64	; 96

NSTARS        EQU 28

; --------------------------------------------
; Entry / Setup
; --------------------------------------------
START
 DI


 ; Enter MODE(1)
 LD A,8
 LD (IO_LATCH),A

 ; Clear screen to BLUE ($AA)
 CALL ClearScreenM1_Blue

 ; Init stars and draw them (Yellow)
 CALL InitStars

 ; Init angles and speeds
 XOR A
 LD (AngleY),A
 LD (AngleX),A
 LD A,1
 LD (SpeedY),A
 LD A,1
 LD (SpeedX),A

 CALL CopyCurrToPrev

; --------------------------------------------
; Main loop
; --------------------------------------------
MainLoop
 ; 0) Stars: erase, move, redraw



 CALL UpdateStars


 ; 2) Update angles
; LD A,(AngleY)
; LD H,A
; LD A,(SpeedY)
; ADD A,H
; AND 63
; LD (AngleY),A;

; LD A,(AngleX)
; LD H,A
; LD A,(SpeedX)
; ADD A,H
; AND 63
; LD (AngleX),A



	LD 	hl,0x6800
sync2:	BIT 	7,(hl)			; fancy wait retrace.
	jr	NZ,sync2

;	LD 	hl,0x6800
;sync3:	BIT 	7,(hl)			; fancy wait retrace.
;	jr	Z,sync3




	ld	hl, $b000
	ld	de, $7000
	ld	bc, 2048
	ldir

 	LD 	HL, $b000
 	ld	de, $b001
 	ld 	a, 170
 	ld 	(hl), a
 	ld 	bc, 2048
 	ldir

	ld	de, $b000 + 32*27+14
	ld	hl, L1
	ld	bc, 5
	ldir
	ld	de, $b000 + 32*28+14
	ld	hl, L2
	ld	bc, 5
	ldir
	ld	de, $b000 + 32*29+14
	ld	hl, L3
	ld	bc, 5
	ldir
	ld	de, $b000 + 32*30+14
	ld	hl, L4
	ld	bc, 5
	ldir
	ld	de, $b000 + 32*31+14
	ld	hl, L5
	ld	bc, 5
	ldir
	ld	de, $b000 + 32*32+14
	ld	hl, L6
	ld	bc, 5
	ldir



	
; ; small delay
; LD BC,$0600
;DelayLoop
; DEC BC
; LD A,B
; OR C
; JP NZ,DelayLoop

 JP MainLoop

; --------------------------------------------
; Screen clear (MODE1): seed 32 bytes at $7000 with $AA then LDIR to 63 rows
; --------------------------------------------
ClearScreenM1_Blue
 LD HL,$b000
 ld	de, $b001
 ld a, 170
 ld (hl), a
 ld bc, 2048
 ldir

 RET



; --------------------------------------------
; Linear Congruential Generator: 16-bit state -> next in HL
; new = old * 2053 + 13849  (mod 65536)
; --------------------------------------------
;
; KEEP
;
LCG_Next
 LD HL,(RSeed)
 ; keep old in DE
 LD D,H
 LD E,L

 ; HL = old << 11
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL

 ; HL += old * 5
 ADD HL,DE
 ADD HL,DE
 ADD HL,DE
 ADD HL,DE
 ADD HL,DE

 ; HL += 13849
 LD DE,13849
 ADD HL,DE

 LD (RSeed),HL
 RET




; --------------------------------------------
; InitStars: fill X/Y/Spd via LCG and draw Yellow pixels
; --------------------------------------------
;
; KEEP
;
InitStars
 LD HL,$ACE1
 LD (RSeed),HL

 XOR A
 LD (StarI),A
 LD A,NSTARS
 LD (StarRem),A
InitS_Loop
 LD A,(StarRem)
 OR A
 JP Z,InitS_Done

 ; X = rnd_hi & 127
 CALL LCG_Next
 LD A,H
 AND 127
 LD (TmpA),A
 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarX
 ADD HL,DE
 LD A,(TmpA)
 LD (HL),A

 ; Y = rnd_hi & 63
 CALL LCG_Next
 LD A,H
 AND 63
 LD (TmpA),A
 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarY
 ADD HL,DE
 LD A,(TmpA)
 LD (HL),A

 ; Spd = ((rnd_lo & 3) + 1), clamp to 3
 CALL LCG_Next
 LD A,L
 AND 3
 ADD A,1
 CP 4
 JP C,InitS_SpdOK
 LD A,3
InitS_SpdOK
 LD (TmpA),A
 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarSpd
 ADD HL,DE
 LD A,(TmpA)
 LD (HL),A

 ; Draw initial star in Yellow
 LD A,1
 LD (DrawColor),A

 ; px = X
 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarX
 ADD HL,DE
 LD A,(HL)
 LD (px),A

 ; py = Y
 LD HL,StarY
 ADD HL,DE
 LD A,(HL)
 LD (py),A

 CALL PlotPixel_M1

 ; next star
 LD A,(StarI)
 ADD A,1
 LD (StarI),A
 LD A,(StarRem)
 SUB 1
 LD (StarRem),A
 JP InitS_Loop
InitS_Done
 RET

; --------------------------------------------
; UpdateStars: erase in Blue, move with wrap, redraw in Yellow
; --------------------------------------------
;
; KEEP
;
UpdateStars
 XOR A
 LD (StarI),A
 LD A,NSTARS
 LD (StarRem),A
UpdS_Loop
 LD A,(StarRem)
 OR A
 JP Z,UpdS_Done

 ; Erase old position (Blue=2)
 LD A,2
 LD (DrawColor),A

 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarX
 ADD HL,DE
 LD A,(HL)
 LD (px),A
 LD HL,StarY
 ADD HL,DE
 LD A,(HL)
 LD (py),A
 CALL PlotPixel_M1

 ; Move X left by speed with wrap [0..127]
 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarX
 ADD HL,DE
 LD A,(HL)
 LD (TmpA),A

 LD HL,StarSpd
 ADD HL,DE
 LD A,(HL)
 LD C,A

 LD A,(TmpA)
 SUB C
 JP NC,UpdS_StoreX
 ADD A,128
UpdS_StoreX
 LD (TmpA),A

 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarX
 ADD HL,DE
 LD A,(TmpA)
 LD (HL),A

 ; Redraw in Yellow
 LD A,1
 LD (DrawColor),A

 LD A,(StarI)
 LD E,A
 XOR A
 LD D,A
 LD HL,StarX
 ADD HL,DE
 LD A,(HL)
 LD (px),A
 LD HL,StarY
 ADD HL,DE
 LD A,(HL)
 LD (py),A
 CALL PlotPixel_M1

 ; Next
 LD A,(StarI)
 ADD A,1
 LD (StarI),A
 LD A,(StarRem)
 SUB 1
 LD (StarRem),A
 JP UpdS_Loop
UpdS_Done
 RET








; --------------------------------------------
; Area tests (front-facing if area > 0) for Curr/Prev
; --------------------------------------------
;AreaCurr_Positive
 CALL LoadCurrVerts
 JP Area_Common

AreaPrev_Positive
 CALL LoadPrevVerts
 JP Area_Common

LoadCurrVerts
 LD A,(fv0)
 LD E,A
 XOR A
 LD D,A
 LD HL,CurrX
 ADD HL,DE
 LD A,(HL)
 LD (ax),A
 LD HL,CurrY
 ADD HL,DE
 LD A,(HL)
 LD (ay),A

 LD A,(fv1)
 LD E,A
 XOR A
 LD D,A
 LD HL,CurrX
 ADD HL,DE
 LD A,(HL)
 LD (bx),A
 LD HL,CurrY
 ADD HL,DE
 LD A,(HL)
 LD (by),A

 LD A,(fv2)
 LD E,A
 XOR A
 LD D,A
 LD HL,CurrX
 ADD HL,DE
 LD A,(HL)
 LD (cx),A
 LD HL,CurrY
 ADD HL,DE
 LD A,(HL)
 LD (cy),A
 RET

LoadPrevVerts
 LD A,(fv0)
 LD E,A
 XOR A
 LD D,A
 LD HL,PrevX
 ADD HL,DE
 LD A,(HL)
 LD (ax),A
 LD HL,PrevY
 ADD HL,DE
 LD A,(HL)
 LD (ay),A

 LD A,(fv1)
 LD E,A
 XOR A
 LD D,A
 LD HL,PrevX
 ADD HL,DE
 LD A,(HL)
 LD (bx),A
 LD HL,PrevY
 ADD HL,DE
 LD A,(HL)
 LD (by),A

 LD A,(fv2)
 LD E,A
 XOR A
 LD D,A
 LD HL,PrevX
 ADD HL,DE
 LD A,(HL)
 LD (cx),A
 LD HL,PrevY
 ADD HL,DE
 LD A,(HL)
 LD (cy),A
 RET

Area_Common
 ; x1-x0
 LD A,(bx)
 LD B,A
 LD A,(ax)
 LD C,A
 LD A,B
 SUB C
 LD (dx1),A

 ; y1-y0
 LD A,(by)
 LD B,A
 LD A,(ay)
 LD C,A
 LD A,B
 SUB C
 LD (dy1),A

 ; x2-x0
 LD A,(cx)
 LD B,A
 LD A,(ax)
 LD C,A
 LD A,B
 SUB C
 LD (dx2),A

 ; y2-y0
 LD A,(cy)
 LD B,A
 LD A,(ay)
 LD C,A
 LD A,B
 SUB C
 LD (dy2),A

 ; t1 = dx1 * dy2
 LD A,(dy2)
 LD C,A
 LD A,(dx1)
 CALL Mul8s
 PUSH HL

 ; t2 = dy1 * dx2
 LD A,(dx2)
 LD C,A
 LD A,(dy1)
 CALL Mul8s
 EX DE,HL
 POP HL

 ; area = t1 - t2
 OR A
 SBC HL,DE

 ; area > 0 ?
 LD A,H
 BIT 7,A
 JP NZ,Area_NegOrZero
 LD A,H
 OR L
 JP Z,Area_NegOrZero
 LD A,1
 LD (AreaSign),A
 RET
Area_NegOrZero
 XOR A
 LD (AreaSign),A
 RET

; --------------------------------------------
; Bresenham line with optional 1-pixel thickness (ThickFlag=1)
; --------------------------------------------
DrawLineThick
 LD A,0
 LD (ThickFlag),A
 CALL DrawLine
 XOR A
 LD (ThickFlag),A
 RET

DrawLine
 LD A,(x0)
 LD (lx),A
 LD A,(y0)
 LD (ly),A
 LD A,(x1s)
 LD (rx),A
 LD A,(y1s)
 LD (ry),A

 ; dx/stepx
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

 ; dy/stepy
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

 ; Choose major axis
 LD A,(dx)
 LD B,A
 LD A,(dy)
 CP B
 JP C,DL_XMajor

 ; ------- Y-major -------
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
 LD A,(ThickFlag)
 OR A
 JP Z,DL_YNoThick
 LD A,(px)
 ADD A,1
 LD (px),A
 CALL PlotPixel_M1
DL_YNoThick
 LD A,(count)
 OR A
 JP Z,DL_Done

 ; step Y
 LD A,(ly)
 LD D,A
 LD A,(stepy)
 ADD A,D
 LD (ly),A

 ; err -= dx
 LD A,(err)
 LD D,A
 LD A,(dx)
 LD E,A
 LD A,D
 SUB E
 LD (err),A

 ; if err < 0: step X and err += dy
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

 ; ------- X-major -------
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
 LD A,(ThickFlag)
 OR A
 JP Z,DL_XNoThick
 LD A,(py)
 ADD A,1
 LD (py),A
 CALL PlotPixel_M1
DL_XNoThick
 LD A,(count)
 OR A
 JP Z,DL_Done

 ; step X
 LD A,(lx)
 LD D,A
 LD A,(stepx)
 LD E,A
 LD A,D
 ADD A,E
 LD (lx),A

 ; err -= dy
 LD A,(err)
 LD D,A
 LD A,(dy)
 LD E,A
 LD A,D
 SUB E
 LD (err),A

 ; if err < 0: step Y and err += dx
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

; --------------------------------------------
; PlotPixel_M1: px,py (0..127,0..63), DrawColor (0..3)
; --------------------------------------------
PlotPixel_M1
 ; y bounds
 LD A,(py)
 CP 64
 JP NC,PP_Return
 ; x bounds
 LD A,(px)
 CP 128
 JP NC,PP_Return

 ; Row base from table
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

 ; + (px >> 2)
 LD A,(px)
 SRL A
 SRL A
 LD E,A
 XOR A
 LD D,A
 ADD HL,DE

 ; Fetch, mask clear 2-bit field, then set color bits
 LD A,(HL)
 LD (pixByte),A
 PUSH HL

 LD A,(px)
 AND 3
 XOR 3                    ; FIX: MC6847 pixel 0 = MSB (bits 7:6), invert sub-byte index
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

; --------------------------------------------
; Copy Curr -> Prev (8 vertices)
; --------------------------------------------
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

; --------------------------------------------
; Signed 8x8 -> 16 multiply in HL
; Inputs: A=m1(s8), C=m2(s8)
; --------------------------------------------
Mul8s
 LD B,A
 XOR A
 LD (MulNeg),A

 ; abs(m1)
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

 ; abs(m2)
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

; --------------------------------------------
; Unsigned division: HL / C -> A = quotient (0..255)
; Repeat-subtract (adequate for our ranges).
; --------------------------------------------
DivU16ByU8
 XOR A
 LD E,A
DV_Check
 LD A,H
 OR A
 JP NZ,DV_Sub
 LD A,L
 CP C
 JP C,DV_Done
DV_Sub
 LD A,L
 SUB C
 LD L,A
 LD A,H
 SBC A,0
 LD H,A
 LD A,E
 ADD A,1
 LD E,A
 JP DV_Check
DV_Done
 LD A,E
 RET

; --------------------------------------------
; Arithmetic right shift HL by 5 bits
; --------------------------------------------
SAR5
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

; ============================================================================
; =============================== DATA SECTION ===============================
; ============================================================================

; Angles / speeds
AngleY           DEFB 0
AngleX           DEFB 0
SpeedY           DEFB 1
SpeedX           DEFB 1

; Trig scratch
SinY             DEFB 0
CosY             DEFB 0
SinX             DEFB 0
CosX             DEFB 0

; Per-vertex scratch
vx               DEFB 0
vy               DEFB 0
vz               DEFB 0
x1               DEFB 0
z1               DEFB 0
y2               DEFB 0
zcam             DEFB 0
sx_screen        DEFB 0
sy_screen        DEFB 0

; Current and previous 2D coords (8 vertices)
CurrX            DEFB 0,0,0,0,0,0,0,0
CurrY            DEFB 0,0,0,0,0,0,0,0
PrevX            DEFB 0,0,0,0,0,0,0,0
PrevY            DEFB 0,0,0,0,0,0,0,0

; Face iteration
FaceI            DEFB 0
FaceRem          DEFB 0
fv0              DEFB 0
fv1              DEFB 0
fv2              DEFB 0
AreaSign         DEFB 0

; Area temps
ax               DEFB 0
ay               DEFB 0
bx               DEFB 0
by               DEFB 0
cx               DEFB 0
cy               DEFB 0
dx1              DEFB 0
dy1              DEFB 0
dx2              DEFB 0
dy2              DEFB 0
TmpOfs           DEFB 0

; Line drawer temps
x0               DEFB 0
y0               DEFB 0
x1s              DEFB 0
y1s              DEFB 0
lx               DEFB 0
ly               DEFB 0
rx               DEFB 0
ry               DEFB 0
dx               DEFB 0
dy               DEFB 0
stepx            DEFB 0
stepy            DEFB 0
err              DEFB 0
count            DEFB 0
px               DEFB 0
py               DEFB 0
pixByte          DEFB 0
pidx             DEFB 0
ThickFlag        DEFB 0

; Mul/div helpers
MulNeg           DEFB 0
TmpA             DEFB 0
TmpSgn           DEFB 0

; Draw color (0..3)
DrawColor        DEFB 1

; MODE(1) clear row = $AA * 32 (BLUE)
RowClr32_M1_Blue
                 DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
                 DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
                 DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
                 DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA

; Clear masks for 2-bit field p=0..3
ClearMaskTable   DEFB $FC,$F3,$CF,$3F

; Set masks indexed by (p*4 + color), color=0..3
SetMaskTable
                 DEFB $00,$01,$02,$03
                 DEFB $00,$04,$08,$0C
                 DEFB $00,$10,$20,$30
                 DEFB $00,$40,$80,$C0

; Unsigned sinusoid 0..63 (use value-32 for signed)
Sin64U
                 DEFB 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63
                 DEFB 63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,32
                 DEFB 28,25,22,19,16,13,11,8,6,4,3,2,1,1,0,0
                 DEFB 0,0,1,1,2,3,4,6,8,11,13,16,19,22,25,28

; MODE(1) row base addresses (64 rows)
RowTable_Mode1
                 DW $b000,$b020,$b040,$b060,$b080,$b0A0,$b0C0,$b0E0
                 DW $b100,$b120,$b140,$b160,$b180,$b1A0,$b1C0,$b1E0
                 DW $b200,$b220,$b240,$b260,$b280,$b2A0,$b2C0,$b2E0
                 DW $b300,$b320,$b340,$b360,$b380,$b3A0,$b3C0,$b3E0
                 DW $b400,$b420,$b440,$b460,$b480,$b4A0,$b4C0,$b4E0
                 DW $b500,$b520,$b540,$b560,$b580,$b5A0,$b5C0,$b5E0
                 DW $b600,$b620,$b640,$b660,$b680,$b6A0,$b6C0,$b6E0
                 DW $b700,$b720,$b740,$b760,$b780,$b7A0,$b7C0,$b7E0

; Ship model (8 vertices)
; 0 Nose, 1 L-front lower, 2 R-front lower, 3 Top canopy,
; 4 Left mid, 5 Right mid, 6 Top rear, 7 Tail
ModelX           DEFB  0,-12, 12,  0,-24, 24,  0,  0
ModelY           DEFB  0, -6, -6, 10, -2, -2, 12,  0
ModelZ           DEFB -44,-12,-12,-12, 10, 10, 14, 36

; Triangulated faces (CCW for front-face)
FaceTriples      DEFB 0,1,3, 0,3,2, 1,4,3, 3,5,2
                 DEFB 3,6,4, 3,5,6, 6,7,4, 6,5,7

; Parallax stars (filled at runtime)
StarX            DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarY            DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
StarSpd          DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
RSeed            DW $ACE1
StarI            DEFB 0
StarRem          DEFB 0

; Loop/misc helpers
RowCopyRem       DEFB 0
VertIndex        DEFB 0
VertRem          DEFB 0
FaceTmp          DEFB 0
e0               DEFB 0
e1               DEFB 0



L1: db  %10101010,%10101010,%10101111,%11101010,%10101010
L2: db  %10101010,%10101010,%10110101,%01111111,%10101010
L3: db  %11101110,%11101111,%11010101,%01010101,%01011110
L4: db  %11101110,%11101111,%11010101,%01010101,%01010111
L5: db  %10101010,%10101010,%11010101,%01010101,%01101010
L6: db  %10101010,%10101010,%10111111,%11111111,%11101010

      
;	..........RRR........
;	.........RYYYRRR.........
;	RBRBRBRRRYYYYYYYYYR...........
;	RBRBRBRRRYYYYYYYYYYR...........
;	........RYYYYYYYYYR........
;	.........RRRRRRRRR.......




END

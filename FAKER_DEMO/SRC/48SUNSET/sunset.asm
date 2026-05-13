; VZ200 256x192 mono plasma demo (Australian Graphics Mod)
; Safe routine: draws only within X=10..240, Y=10..180
; PASMO-compatible: all arithmetic through A

        ORG $8000

Start:
        ; Enter 256x192 mono hi-res using Australian Graphics Mod
        LD A,28
        OUT (32),A
        LD A,8
        LD ($6800),A

        LD A,29
        OUT (32),A
        LD A,8
        LD ($6800),A

        LD A,30
        OUT (32),A
        LD A,8
        LD ($6800),A

        CALL ClearVRAM_All

        XOR A
        LD (PhaseX),A
        LD (PhaseY),A
        LD A,1
        LD (SpeedX),A
        LD A,3
        LD (SpeedY),A

MainLoop:
        CALL WaitVSync
        CALL RenderSafePlasma
        CALL UpdatePhases
        JP MainLoop

; --- Wait for vertical sync ---
WaitVSync:
        LD HL,$6800
wv0:    BIT 7,(HL)
        JR NZ,wv0
        LD HL,$6800
wv1:    BIT 7,(HL)
        JR Z,wv1
        RET

; --- Clear VRAM across all banks ---
ClearVRAM_All:
        LD A,28
        OUT (32),A
        LD HL,$7000
        LD DE,$7001
        LD BC,$0800
        XOR A
        LD (HL),A
        LDIR

        LD A,29
        OUT (32),A
        LD HL,$7000
        LD DE,$7001
        LD BC,$0800
        XOR A
        LD (HL),A
        LDIR

        LD A,30
        OUT (32),A
        LD HL,$7000
        LD DE,$7001
        LD BC,$0800
        XOR A
        LD (HL),A
        LDIR
        RET

; --- Render plasma within safe bounds ---
RenderSafePlasma:
        LD B,170              ; 170 rows (Y=10..180)
        LD A,10
        LD (CurY),A

RowLoop:
        LD A,(CurY)
        ; Select bank
        CP 64
        JR C,bank28
        CP 128
        JR C,bank29
        LD A,30
        OUT (32),A
        JR bankSetDone
bank29: LD A,29
        OUT (32),A
        JR bankSetDone
bank28: LD A,28
        OUT (32),A
bankSetDone:

        ; Precompute sin(y+PhaseY)
        LD A,(PhaseY)
        LD B,A
        LD A,(CurY)
        ADD A,B
        LD L,A
        LD H,0
        LD DE,SIN_TABLE
        ADD HL,DE
        LD A,(HL)
        LD (SinY),A

        ; Row base = $7000 + 32*(y&63)
        LD A,(CurY)
        AND 63
        LD L,A
        LD H,0
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD DE,$7000
        ADD HL,DE
	ld a, l
        LD (RowBaseL),a
	ld	a, h
        LD (RowBaseH),a

        ; Iterate X=10..240
        LD C,231
        LD A,10
        LD (CurX),A

ColLoop:
        ; sin(x+PhaseX)
        LD A,(PhaseX)
        LD B,A
        LD A,(CurX)
        ADD A,B
        LD L,A
        LD H,0
        LD DE,SIN_TABLE
        ADD HL,DE
        LD A,(HL)
        LD (SinX),A

        ; v = sinX + sinY
        LD A,(SinX)
        LD B,A
        LD A,(SinY)
        ADD A,B

	ld	b, a        ; threshold compare
        LD a,(PhaseX)
        SUB B
        JP M,ClearPixel

SetPixel:
        CALL ComputeAddrMask
        LD A,(HL)
        OR D
        LD (HL),A
        JR NextPixel

ClearPixel:
        CALL ComputeAddrMask
        LD A,D
        CPL
        LD D,A
        LD A,(HL)
        AND D
        LD (HL),A

NextPixel:
        LD A,(CurX)
        INC A
        LD (CurX),A
        DEC C
        JR NZ,ColLoop

        ; Next row
        LD A,(CurY)
        INC A
        LD (CurY),A
        DEC B
        JP NZ,RowLoop
        RET

; --- Compute address and bit mask for current (CurX, CurY) ---
; Returns HL = address, D = mask
ComputeAddrMask:
        ; HL = RowBase + (CurX>>3)

        LD a,(RowBaseL)
	ld	 l,a
        LD a,(RowBaseH)
	ld	h, a
        LD A,(CurX)
        SRL A
        SRL A
        SRL A
        LD E,A
        LD D,0
        ADD HL,DE

        ; mask = 1 << (7 - (CurX & 7))
        LD A,(CurX)
        AND 7
        LD B,A
        LD A,128
ShiftMask2:
        CP 0
        JR Z,maskReady2
        SRL A
        DEC B
        JR NZ,ShiftMask2
maskReady2:
        LD D,A
        RET

; --- Update phases ---
UpdatePhases:
        LD A,(PhaseX)
        LD B,A
        LD A,(SpeedX)
        ADD A,B
        LD (PhaseX),A

        LD A,(PhaseY)
        LD B,A
        LD A,(SpeedY)
        ADD A,B
        LD (PhaseY),A
        RET

; --- Data ---
PhaseX:   DB 0
PhaseY:   DB 0
SpeedX:   DB 0
SpeedY:   DB 0
CurY:     DB 0
CurX:     DB 0
SinX:     DB 0
SinY:     DB 0
RowBaseL: DB 0
RowBaseH: DB 0

; --
; --- 256-entry sine table (-127..+127) ---
SIN_TABLE:
DB   0,   3,   6,   9,  12,  16,  19,  22,  25,  28,  31,  34,  37,  40,  43,  46
DB  49,  52,  55,  58,  61,  64,  67,  70,  73,  76,  79,  82,  85,  88,  91,  94
DB  97, 100, 103, 106, 108, 111, 114, 116, 119, 121, 124, 126, 127, 127, 127, 127
DB 127, 126, 124, 121, 119, 116, 114, 111, 108, 106, 103, 100,  97,  94,  91,  88
DB  85,  82,  79,  76,  73,  70,  67,  64,  61,  58,  55,  52,  49,  46,  43,  40
DB  37,  34,  31,  28,  25,  22,  19,  16,  12,   9,   6,   3,   0,  -3,  -6,  -9
DB -12, -16, -19, -22, -25, -28, -31, -34, -37, -40, -43, -46, -49, -52, -55, -58
DB -61, -64, -67, -70, -73, -76, -79, -82, -85, -88, -91, -94, -97,-100,-103,-106
DB-108,-111,-114,-116,-119,-121,-124,-126,-127,-127,-127,-127,-127
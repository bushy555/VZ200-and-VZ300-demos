
; ===============================================================
; VZ200/VZ300 MODE(1) Fast Roto-Zoomer with Prebaked Checkerboard
; Author: M365 Copilot for David Maunder
; Assembler: PASMO
; ORG: $8000, SP: $8FF0 (safe across VZ200/300 without a pack)
; ===============================================================

buffer equ $a000
        ORG $8000
Start:
        DI
        LD SP,$8FF0

; Enter MODE(1)
        LD A,8
        LD ($6800),A

; Init angle and speed
        XOR A
        LD (Angle),a
        LD A,2
        LD (AngSpeed),A

MainLoop:
        LD A,(Angle)
        LD H,A
        LD A,(AngSpeed)
        ADD A,H
        AND 63
        LD (Angle),A

        CALL ComputeSteps_Fast
        CALL ComputeStartUV

        ; seed per-row accumulators
        LD A,(U0Lo)
        LD (UrowLo),A
        LD A,(U0Hi)
        LD (UrowHi),A
        LD A,(V0Lo)
        LD (VrowLo),A
        LD A,(V0Hi)
        LD (VrowHi),A

        ; DE = $7000
;      	LD DE, $7000
       	LD DE, buffer

        LD A,64
        LD (Y_Rem),A

RowLoop:
        LD A,(Y_Rem)
        OR A
        JP Z,FrameDone

        ; copy row accumulators -> current
        LD A,(UrowLo)
        LD (UcurLo),A
        LD A,(UrowHi)
        LD (UcurHi),A
        LD A,(VrowLo)
        LD (VcurLo),A
        LD A,(VrowHi)
        LD (VcurHi),A

        LD A,32
        LD (XBytes_Rem),A

ByteLoop:
        LD A,(XBytes_Rem)
        OR A
        JP Z,NextRow

        XOR A
        LD (AccByte),A

        ; ----- sample 0 (fixed) -----
        LD A,(VcurHi)
        AND 63
        LD L,A
        LD H,0
        ADD HL,HL
        LD BC,RowPtrWords
        ADD HL,BC
        LD A,(HL)
        LD C,A
        INC HL
        LD A,(HL)
        LD B,A
        LD H,B
        LD L,C
        LD A,(UcurHi)
        AND 63
        LD C,A
        LD A,L
        ADD A,C
        LD L,A
        LD A,H
        ADC A,0
        LD H,A
        LD A,(HL)
        AND 3
        LD C,A
        LD A,(AccByte)
        ADD A,A
        ADD A,A
        OR C
        LD (AccByte),A

        ; step U,V
        LD A,(UcurLo)
        LD C,A
        LD A,(AxLo)
        ADD A,C
        LD (UcurLo),A
        LD A,(UcurHi)
        LD C,A
        LD A,(AxHi)
        ADC A,C
        LD (UcurHi),A
        LD A,(VcurLo)
        LD C,A
        LD A,(AyLo)
        ADD A,C
        LD (VcurLo),A
        LD A,(VcurHi)
        LD C,A
        LD A,(AyHi)
        ADC A,C
        LD (VcurHi),A

        ; ----- sample 1 (fixed) -----
        LD A,(VcurHi)
        AND 63
        LD L,A
        LD H,0
        ADD HL,HL
        LD BC,RowPtrWords
        ADD HL,BC
        LD A,(HL)
        LD C,A
        INC HL
        LD A,(HL)
        LD B,A
        LD H,B
        LD L,C
        LD A,(UcurHi)
        AND 63
        LD C,A
        LD A,L
        ADD A,C
        LD L,A
        LD A,H
        ADC A,0
        LD H,A
        LD A,(HL)
        AND 3
        LD C,A
        LD A,(AccByte)
        ADD A,A
        ADD A,A
        OR C
        LD (AccByte),A

        ; step
        LD A,(UcurLo)
        LD C,A
        LD A,(AxLo)
        ADD A,C
        LD (UcurLo),A
        LD A,(UcurHi)
        LD C,A
        LD A,(AxHi)
        ADC A,C
        LD (UcurHi),A
        LD A,(VcurLo)
        LD C,A
        LD A,(AyLo)
        ADD A,C
        LD (VcurLo),A
        LD A,(VcurHi)
        LD C,A
        LD A,(AyHi)
        ADC A,C
        LD (VcurHi),A

        ; ----- sample 2 (fixed) -----
        LD A,(VcurHi)
        AND 63
        LD L,A
        LD H,0
        ADD HL,HL
        LD BC,RowPtrWords
        ADD HL,BC
        LD A,(HL)
        LD C,A
        INC HL
        LD A,(HL)
        LD B,A
        LD H,B
        LD L,C
        LD A,(UcurHi)
        AND 63
        LD C,A
        LD A,L
        ADD A,C
        LD L,A
        LD A,H
        ADC A,0
        LD H,A
        LD A,(HL)
        AND 3
        LD C,A
        LD A,(AccByte)
        ADD A,A
        ADD A,A
        OR C
        LD (AccByte),A

        ; step
        LD A,(UcurLo)
        LD C,A
        LD A,(AxLo)
        ADD A,C
        LD (UcurLo),A
        LD A,(UcurHi)
        LD C,A
        LD A,(AxHi)
        ADC A,C
        LD (UcurHi),A
        LD A,(VcurLo)
        LD C,A
        LD A,(AyLo)
        ADD A,C
        LD (VcurLo),A
        LD A,(VcurHi)
        LD C,A
        LD A,(AyHi)
        ADC A,C
        LD (VcurHi),A

        ; ----- sample 3 (fixed) -----
        LD A,(VcurHi)
        AND 63
        LD L,A
        LD H,0
        ADD HL,HL
        LD BC,RowPtrWords
        ADD HL,BC
        LD A,(HL)
        LD C,A
        INC HL
        LD A,(HL)
        LD B,A
        LD H,B
        LD L,C
        LD A,(UcurHi)
        AND 63
        LD C,A
        LD A,L
        ADD A,C
        LD L,A
        LD A,H
        ADC A,0
        LD H,A
        LD A,(HL)
        AND 3
        LD C,A
        LD A,(AccByte)
        ADD A,A
        ADD A,A
        OR C
        LD (AccByte),A

        ; write composed byte to VRAM (DE intact)
        LD A,(AccByte)
        LD (DE),A

        ; DE++
        LD A,E
        ADD A,1
        LD E,A
        LD A,D
        ADC A,0
        LD D,A

        ; columns--
        LD A,(XBytes_Rem)
        SUB 1
        LD (XBytes_Rem),A
        JP ByteLoop

NextRow:
        ; Urow += Bx ; Vrow += By
        LD A,(UrowLo)
        LD C,A
        LD A,(BxLo)
        ADD A,C
        LD (UrowLo),A
        LD A,(UrowHi)
        LD C,A
        LD A,(BxHi)
        ADC A,C
        LD (UrowHi),A
        LD A,(VrowLo)
        LD C,A
        LD A,(ByLo)
        ADD A,C
        LD (VrowLo),A
        LD A,(VrowHi)
        LD C,A
        LD A,(ByHi)
        ADC A,C
        LD (VrowHi),A

        LD A,(Y_Rem)
        SUB 1
        LD (Y_Rem),A
        JP RowLoop

FrameDone:



	ld hl,buffer
	ld de, $7000
	ld bc, 2048
	ldir

        JP MainLoop

; ---------- ComputeSteps_Fast and ComputeStartUV ----------
; (unchanged from your file)
; ---------------------------------------------------------
; ===============================================================
; ComputeSteps_Fast
; Ax = 4*cos(a), Ay = 4*sin(a), Bx = -Ay, By = Ax
; cos(a) = Sin64U[(a+16)&63] - 32
; sin(a) = Sin64U[a] - 32
; Values are 8.8 signed fixed-point.
; ===============================================================
ComputeSteps_Fast:
; Ax
        LD A,(Angle)
        ADD A,16
        AND 63
        LD E,A
        XOR A
        LD D,A
        LD HL,Sin64U
        ADD HL,DE
        LD A,(HL)
        SUB 32
        LD L,A
        LD H,$00
        BIT 7,A
        JP Z,CSF_NoNegAx
        LD H,$FF
CSF_NoNegAx:
        ADD HL,HL
        ADD HL,HL
        LD A,L
        LD (AxLo),A
        LD A,H
        LD (AxHi),A

; Ay
        LD A,(Angle)
        LD E,A
        XOR A
        LD D,A
        LD HL,Sin64U
        ADD HL,DE
        LD A,(HL)
        SUB 32
        LD L,A
        LD H,$00
        BIT 7,A
        JP Z,CSF_NoNegAy
        LD H,$FF
CSF_NoNegAy:
        ADD HL,HL
        ADD HL,HL
        LD A,L
        LD (AyLo),A
        LD A,H
        LD (AyHi),A

; Bx = -Ay
        LD A,(AyLo)
        XOR $FF
        ADD A,1
        LD (BxLo),A
        LD A,(AyHi)
        XOR $FF
        ADC A,0
        LD (BxHi),A

; By = Ax
        LD A,(AxLo)
        LD (ByLo),A
        LD A,(AxHi)
        LD (ByHi),A
        RET

; ===============================================================
; ComputeStartUV
; U0 = (32<<8) - Ax*64 - Bx*32
; V0 = (32<<8) - Ay*64 - By*32
; Uses SBC HL,qq with carry cleared before each subtraction.
; ===============================================================
ComputeStartUV:
; ---- U0 ----
; BC = Ax * 64
        LD A,(AxLo)
        LD L,A
        LD A,(AxHi)
        LD H,A
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD B,H
        LD C,L
; DE = Bx * 32
        LD A,(BxLo)
        LD L,A
        LD A,(BxHi)
        LD H,A
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD D,H
        LD E,L
; HL = $2000 - BC - DE
        LD HL,$2000
        XOR A
        SBC HL,BC
        XOR A
        SBC HL,DE
        LD A,L
        LD (U0Lo),A
        LD A,H
        LD (U0Hi),A

; ---- V0 ----
; BC = Ay * 64
        LD A,(AyLo)
        LD L,A
        LD A,(AyHi)
        LD H,A
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD B,H
        LD C,L
; DE = By * 32
        LD A,(ByLo)
        LD L,A
        LD A,(ByHi)
        LD H,A
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD D,H
        LD E,L
; HL = $2000 - BC - DE
        LD HL,$2000
        XOR A
        SBC HL,BC
        XOR A
        SBC HL,DE
        LD A,L
        LD (V0Lo),A
        LD A,H
        LD (V0Hi),A
        RET

; ===============================================================
; ======================= DATA SECTION =========================
; ===============================================================
; Control
Angle:      DB 0
AngSpeed:   DB 2

; Step vectors 8.8 signed
AxLo:       DB 0
AxHi:       DB 0
AyLo:       DB 0
AyHi:       DB 0
BxLo:       DB 0
BxHi:       DB 0
ByLo:       DB 0
ByHi:       DB 0

; Start and per-row/current UV (8.8)
U0Lo:       DB 0
U0Hi:       DB 0
V0Lo:       DB 0
V0Hi:       DB 0
UrowLo:     DB 0
UrowHi:     DB 0
VrowLo:     DB 0
VrowHi:     DB 0
UcurLo:     DB 0
UcurHi:     DB 0
VcurLo:     DB 0
VcurHi:     DB 0

; Loop helpers
Y_Rem:      DB 0
XBytes_Rem: DB 0
AccByte:    DB 0

; 64-entry sinusoid unsigned (0..63), period 64
; cos(a) = Sin64U[(a+16)&63] - 32
; sin(a) = Sin64U[a] - 32
Sin64U:
        DB 32,35,38,41,44,47,49,52,54,56,58,60,61,62,63,63
        DB 63,63,62,61,60,58,56,54,52,49,47,44,41,38,35,32
        DB 28,25,22,19,16,13,11,8,6,4,3,2,1,1,0,0
        DB 0,0,1,1,2,3,4,6,8,11,13,16,19,22,25,28

; 64x64 Prebaked Checkerboard Texture (8x8 squares)
; Values 1 (yellow) and 3 (red), 2-bit samples
Texture:
      defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$001,$040,$000,$000,$000,$015,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$050,$000,$000,$000,$050,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$005,$055,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$014,$000,$000,$005,$040,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$001,$055,$055,$050,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$001,$054,$000,$000,$000
 defb  $000,$000,$000,$000,$005,$055,$000,$000,$000,$000,$000,$015,$055,$055,$054,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$015,$055,$040,$000,$000
 defb  $000,$000,$000,$000,$055,$055,$040,$000,$000,$000,$000,$005,$055,$055,$055,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$014,$000,$055,$055,$050,$000,$000
 defb  $000,$000,$000,$001,$055,$055,$055,$054,$000,$000,$000,$005,$055,$055,$055,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$001,$050,$055,$055,$050,$054,$000
 defb  $000,$000,$000,$015,$055,$055,$055,$055,$040,$000,$000,$005,$055,$055,$055,$040
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$015,$055,$040,$001,$054
 defb  $000,$000,$000,$055,$055,$055,$055,$055,$040,$000,$000,$001,$055,$055,$055,$040
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$001,$054,$000,$000,$000
 defb  $000,$000,$001,$055,$055,$055,$055,$055,$000,$000,$000,$000,$055,$055,$055,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$001,$000,$000,$010,$000,$000
 defb  $000,$000,$001,$055,$055,$055,$055,$054,$000,$000,$000,$000,$001,$055,$054,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$005,$000,$010,$014,$000,$000
 defb  $000,$000,$001,$055,$055,$055,$050,$000,$000,$000,$000,$000,$000,$005,$040,$000
 defb  $000,$055,$055,$040,$000,$000,$000,$000,$000,$000,$050,$000,$010,$001,$000,$000
 defb  $000,$000,$000,$055,$055,$055,$050,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $005,$055,$055,$055,$000,$000,$000,$000,$000,$000,$040,$000,$010,$000,$040,$000
 defb  $000,$000,$000,$005,$055,$055,$040,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $015,$055,$055,$055,$050,$000,$000,$000,$000,$000,$000,$000,$040,$000,$000,$000
 defb  $000,$000,$000,$000,$015,$055,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $015,$0D5,$0D5,$0FF,$055,$03F,$000,$00C,$00C,$003,$0FC,$003,$0FC,$00C,$00F,$0F0
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$005,$000,$000,$000,$000,$000
 defb  $057,$057,$057,$055,$0D5,$0C0,$0C0,$030,$0F0,$00C,$000,$00C,$00C,$030,$030,$00C
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$055,$040,$05A,$040,$000,$000,$000,$000
 defb  $05F,$0FD,$05F,$0FF,$057,$040,$000,$0FF,$000,$03F,$0C0,$03F,$0F0,$000,$00F,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$0AA,$091,$0AA,$051,$055,$000,$000,$000
 defb  $035,$075,$075,$05D,$05D,$04C,$003,$003,$000,$0C0,$000,$0C3,$000,$003,$000,$0C0
 defb  $000,$000,$000,$000,$000,$000,$005,$056,$0AA,$0A6,$0AA,$096,$0AA,$054,$000,$000
 defb  $0D5,$0D5,$0D5,$075,$057,$0F0,$00C,$000,$0C0,$03F,$0C3,$000,$0C0,$000,$0FF,$000
 defb  $000,$000,$000,$000,$000,$000,$05A,$0AA,$0AA,$056,$0AA,$09A,$0AA,$0A5,$040,$000
 defb  $005,$055,$055,$055,$054,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$001,$06A,$0AA,$0A5,$0A9,$06A,$0AA,$0AA,$0AA,$050,$000
 defb  $005,$055,$055,$055,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$001,$0A9,$055,$05A,$0AA,$095,$055,$0AA,$0AA,$0A5,$050
 defb  $002,$0A5,$056,$0A8,$000,$080,$000,$020,$00A,$0A0,$000,$080,$082,$0AA,$080,$008
 defb  $000,$000,$000,$000,$000,$006,$0A5,$000,$055,$069,$0AA,$0A4,$05A,$095,$0AA,$0A4
 defb  $008,$019,$008,$000,$002,$000,$000,$080,$020,$008,$002,$002,$000,$020,$000,$020
 defb  $000,$000,$000,$000,$000,$006,$050,$00A,$006,$094,$06A,$0A9,$015,$040,$06A,$090
 defb  $020,$020,$02A,$000,$008,$000,$002,$000,$082,$000,$00A,$0A8,$000,$080,$000,$080
 defb  $000,$000,$000,$000,$000,$001,$000,$019,$086,$0A5,$05A,$0AA,$05A,$094,$015,$040
 defb  $080,$080,$080,$000,$020,$000,$008,$002,$000,$080,$020,$020,$002,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$026,$099,$059,$005,$06A,$0AA,$0A9,$040,$002
 defb  $0AA,$000,$02A,$080,$00A,$0A0,$020,$000,$0AA,$000,$080,$080,$008,$000,$008,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$00A,$01A,$0A9,$000,$015,$05A,$0AA,$050,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$016,$0A5,$000,$000,$005,$05A,$090,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$069,$059,$000,$000,$000,$005,$040,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$06A,$0A5,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$05A,$094,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$065,$064,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$0AA,$090,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$01F,$0FC,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$06A,$050,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$01F,$0FC,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$095,$090,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$010,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$0AA,$090,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$011,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$06A,$050,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$054,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$001,$095,$090,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$010,$000,$000,$000,$007,$0F0,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$006,$0AA,$040,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$010,$000,$000,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$006,$0AA,$040,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$000,$010,$000,$000,$000,$055,$040,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$005,$0A9,$040,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$000,$005,$055,$040,$000,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$006,$056,$040,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$005,$054,$000,$000,$010,$000,$000,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$01A,$0A9,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$000,$000,$010,$000,$000,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$01A,$0A9,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$000,$000,$010,$000,$000,$001,$055,$050,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$016,$0A5,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$000,$000,$010,$000,$008,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$000,$019,$059,$000,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$000,$015,$055,$050,$0AA,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$001,$06A,$0AA,$050,$000,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$015,$055,$000,$000,$010,$000,$05A,$000,$004,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$000,$0FF,$0FF,$0FF,$0FF,$0F0,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$00E,$000,$010,$002,$0AA,$085,$055,$054,$000,$007
 defb  $000,$000,$000,$000,$000,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$000,$000,$000,$000,$000
 defb  $000,$000,$000,$000,$000,$040,$03F,$080,$010,$001,$06A,$080,$004,$000,$000,$01F
 defb  $000,$000,$000,$000,$00F,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FC,$000,$000,$000,$000
 defb  $000,$000,$015,$050,$001,$055,$029,$085,$055,$042,$0A9,$081,$055,$050,$000,$040
 defb  $000,$000,$000,$003,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0C0,$000,$000,$000
 defb  $000,$000,$000,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$000
 defb  $000,$000,$000,$03F,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FC,$000,$000,$000
 defb  $000,$000,$000,$005,$055,$045,$045,$045,$045,$045,$045,$045,$045,$045,$055,$040
 defb  $000,$000,$00F,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$000,$000,$000
 defb  $000,$000,$000,$000,$015,$054,$054,$054,$054,$054,$054,$054,$054,$054,$055,$000
 defb  $000,$000,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0C0,$000,$000
 defb  $000,$000,$000,$000,$001,$055,$055,$055,$055,$055,$055,$055,$055,$055,$054,$000
 defb  $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$06A,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
 defb  $0AA,$0AA,$06A,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0AA
 defb  $09A,$0AA,$0AA,$0AA,$0A6,$0AA,$096,$0AA,$0AA,$06A,$0AA,$0AA,$0AA,$0AA,$0A9,$0AA
 defb  $0AA,$0AA,$095,$0AA,$0AA,$09A,$0AA,$0AA,$0AA,$0A9,$0AA,$0AA,$0A5,$05A,$0AA,$0AA
 defb  $0A5,$06A,$06A,$0AA,$0A9,$06A,$0AA,$0AA,$0AA,$095,$0AA,$0AA,$06A,$0AA,$0AA,$055
 defb  $0AA,$0AA,$0AA,$0AA,$0AA,$0A5,$056,$0AA,$0AA,$0AA,$055,$0AA,$0AA,$0AA,$0AA,$09A
 defb  $0AA,$0AA,$095,$0AA,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0AA,$0AA,$095,$0AA,$0AA,$0AA
 defb  $0AA,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0AA,$06A,$0AA,$0AA,$0AA,$0AA,$06A,$0AA,$0A5
 defb  $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0A5,$06A,$0AA,$06A,$0AA,$0AA,$0AA,$0AA,$0AA
 defb  $0AA,$0A9,$0AA,$0AA,$0A5,$06A,$0AA,$0AA,$095,$0AA,$0AA,$0AA,$0AA,$095,$0AA,$0AA
 defb  $0A6,$0AA,$0AA,$0AA,$0AA,$0AA,$06A,$0AA,$0AA,$0AA,$095,$0AA,$0AA,$09A,$0AA,$0AA
 defb  $0AA,$0AA,$055,$0AA,$0AA,$0AA,$0A9,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0AA,$0AA,$0AA
 defb  $0A9,$05A,$0AA,$0A9,$0AA,$0AA,$095,$06A,$0A6,$0AA,$0AA,$0A9,$0AA,$0A5,$05A,$0A9
 defb  $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$055,$0AA,$06A,$0A5,$06A,$0AA,$0AA,$0A6,$0AA
 defb  $0AA,$0AA,$0A6,$0AA,$055,$0AA,$0AA,$0AA,$0A9,$05A,$0AA,$0AA,$05A,$0AA,$0AA,$0AA
 defb  $055,$06A,$0A9,$0AA,$0AA,$09A,$0AA,$0AA,$0AA,$096,$0AA,$0AA,$0AA,$0AA,$0A9,$06A
 defb  $06A,$0AA,$0A9,$06A,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0AA,$0A6,$0AA
 defb  $0AA,$0AA,$0AA,$056,$0AA,$0A5,$06A,$0A9,$0AA,$0AA,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA
 defb  $095,$06A,$0AA,$0AA,$0AA,$0AA,$0A9,$056,$0AA,$0AA,$0A5,$06A,$0AA,$0AA,$0A9,$06A
 defb  $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$055,$0AA,$0AA,$0AA,$0A9,$05A,$0AA,$0A9



        ; Rows 10..63 elided here to keep this message short
        ; (unchanged from your file)
; Absolute row pointers (64 words) - Texture + k*64
RowPtrWords:
        DW Texture+0*64, Texture+1*64, Texture+2*64, Texture+3*64
        DW Texture+4*64, Texture+5*64, Texture+6*64, Texture+7*64
        DW Texture+8*64, Texture+9*64, Texture+10*64, Texture+11*64
        DW Texture+12*64, Texture+13*64, Texture+14*64, Texture+15*64
        DW Texture+16*64, Texture+17*64, Texture+18*64, Texture+19*64
        DW Texture+20*64, Texture+21*64, Texture+22*64, Texture+23*64
        DW Texture+24*64, Texture+25*64, Texture+26*64, Texture+27*64
        DW Texture+28*64, Texture+29*64, Texture+30*64, Texture+31*64
        DW Texture+32*64, Texture+33*64, Texture+34*64, Texture+35*64
        DW Texture+36*64, Texture+37*64, Texture+38*64, Texture+39*64
        DW Texture+40*64, Texture+41*64, Texture+42*64, Texture+43*64
        DW Texture+44*64, Texture+45*64, Texture+46*64, Texture+47*64
        DW Texture+48*64, Texture+49*64, Texture+50*64, Texture+51*64
        DW Texture+52*64, Texture+53*64, Texture+54*64, Texture+55*64
        DW Texture+56*64, Texture+57*64, Texture+58*64, Texture+59*64
        DW Texture+60*64, Texture+61*64, Texture+62*64, Texture+63*64
        END

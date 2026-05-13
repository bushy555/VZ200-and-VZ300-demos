; plasma - kind of
; ==============================================================

            ORG     $8000
            JP      Start

VRAM        EQU     $7000
BUFFER	    equ     $9000
LATCH       EQU     $6800
ROLTAB_HI   EQU     $89         ; high byte of ROLTAB address
DCOUNT      EQU     10;$200        ; delay loop count (tune for speed)

; ==============================================================
; Start: initialise MODE(1), copy image to VRAM, then animate
; ==============================================================
Start:
            di

            ; Enable MODE(1) graphics
            LD      A,24
            LD      (LATCH),A

            ; Copy spiral image to VRAM ($7000..$77FF)
            LD      HL,SPIRAL_IMAGE
            LD      DE,BUFFER
            LD      BC,2048
            LDIR

; ==============================================================
; MainLoop: delay then rotate all VRAM bytes through ROLTAB
; ==============================================================
MainLoop:
            ; Delay loop (adjust DCOUNT for animation speed)
;            LD      BC,DCOUNT
Delay:
 ;           DEC     BC
  ;          LD      A,B
   ;         OR      C
    ;        JP      NZ,Delay

            ; Colour rotation: transform all 2048 VRAM bytes
            ; For each byte: A = ROLTAB[A]
            ; D = high byte of ROLTAB (page $89), E = byte value
            LD      HL,BUFFER ; VRAM         ; HL = VRAM pointer
            LD      D,ROLTAB_HI     ; D = ROLTAB page (constant throughout)
            LD      BC,2048         ; byte count

RotLoop:
            LD      A,(HL)          ; read VRAM byte
            LD      E,A             ; E = old byte (low address into ROLTAB)
            LD      A,(DE)          ; A = ROLTAB[old_byte] (D=ROLTAB_HI, E=byte)
            LD      (HL),A          ; write transformed byte
            INC     HL              ; advance VRAM pointer
            DEC     BC
            LD      A,B
            OR      C
            JP      NZ,RotLoop

	
	LD 	hl,0x6800
sync2:	BIT 	7,(hl)			; fancy wait retrace.
	jr	NZ,sync2

	LD 	hl,0x6800
sync3:	BIT 	7,(hl)			; fancy wait retrace.
	jr	Z,sync3


;	ld	hl, BUFFER
;	ld	de, VRAM
;	ld	bc, 2048
;	ldir



	ld	hl, BUFFER
	ld	de, VRAM
 	LD 	B, 128          ; 128 iterations of 16 LDIs = 2048 bytes

CPYLOOP:LDI 
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
	ldi
	LDI 
	DJNZ CPYLOOP



            JP      MainLoop

; ==============================================================
; SPIRAL_IMAGE: pre-rendered 128x64 spiral, 2bpp, 2048 bytes
; Colour bands cycle: 00=green -> 01=yellow -> 10=blue -> 11=red
; Generated with Floyd-Steinberg error diffusion at boundaries.
; Pixel aspect (2:3) corrected so spiral looks round on screen.
; ==============================================================
SPIRAL_IMAGE:
GFX_DATA:

SCREEN2_DITHER_DIAG:
; ============================================
; Screen 5: Checkerboard Storm
; MC6847 CSS0 MODE1 128x64 - 32 bytes/row
; Color: 00=Green 01=Yellow 10=Blue 11=Red
; Total: 2048 bytes
; ============================================

CHECKERBOARD_STORM
    DB $A8,$AA,$00,$00,$2A,$A8,$00,$2A,$AA,$2A,$AA,$82,$AA,$82,$A8,$00,$FF,$FF,$D5,$55,$5F,$FF,$F5,$7F,$5F,$F5,$55,$7F,$55,$55,$7F,$F5  ; row 00
    DB $A8,$A8,$80,$00,$AA,$A0,$00,$2A,$AA,$AA,$80,$0A,$82,$AA,$AA,$00,$FF,$FF,$F5,$55,$5F,$FF,$F5,$FF,$5F,$D5,$D5,$FD,$5D,$55,$FF,$D5  ; row 01
    DB $A0,$02,$00,$00,$AA,$A0,$00,$2A,$A8,$2A,$00,$2A,$80,$0A,$AA,$80,$7F,$FF,$F5,$55,$57,$D5,$5D,$57,$DF,$D7,$57,$FD,$75,$57,$FF,$D5  ; row 02
    DB $A0,$02,$00,$00,$AA,$A0,$00,$2A,$A0,$22,$80,$2A,$A0,$82,$AA,$80,$5F,$FF,$FD,$55,$57,$55,$5D,$5F,$D7,$DF,$5F,$F5,$F5,$57,$FF,$55  ; row 03
    DB $20,$02,$80,$02,$AA,$A0,$00,$2A,$80,$AA,$A2,$A0,$AA,$AA,$AA,$00,$57,$FF,$FD,$55,$5F,$55,$7D,$7F,$D5,$7F,$7F,$F7,$D5,$5F,$FF,$5F  ; row 04
    DB $80,$02,$80,$02,$AA,$A0,$00,$0A,$0A,$AA,$AA,$A8,$0A,$AA,$A8,$00,$57,$FF,$FF,$55,$FF,$55,$F5,$D7,$D5,$FD,$7F,$DF,$55,$5F,$FD,$FF  ; row 05
    DB $28,$02,$28,$02,$AA,$A0,$00,$0A,$2A,$2A,$8A,$AA,$02,$AA,$A8,$00,$55,$FF,$FF,$5F,$FF,$55,$5F,$D5,$D5,$5D,$FF,$FF,$55,$7F,$F7,$FF  ; row 06
    DB $A0,$08,$AA,$02,$AA,$A0,$00,$08,$A8,$00,$02,$AA,$A8,$AA,$AA,$00,$55,$FF,$FF,$7F,$FF,$55,$5F,$55,$F5,$55,$FF,$FD,$55,$7F,$DF,$FF  ; row 07
    DB $AA,$00,$AA,$A2,$AA,$A8,$00,$00,$20,$A8,$2A,$02,$AA,$AA,$0A,$80,$55,$7F,$FD,$FF,$FD,$55,$55,$57,$F5,$7D,$FF,$FD,$55,$FD,$5F,$FF  ; row 08
    DB $2A,$80,$AA,$A8,$AA,$A8,$00,$00,$0A,$A0,$AA,$82,$AA,$A8,$00,$80,$55,$7F,$D5,$FF,$F7,$D5,$57,$FF,$7D,$F5,$5F,$F5,$55,$D5,$7F,$FD  ; row 09
    DB $AA,$00,$AA,$AA,$02,$AA,$08,$00,$8A,$80,$2A,$80,$AA,$20,$00,$28,$55,$75,$55,$DF,$57,$57,$57,$F5,$FF,$F5,$57,$F5,$5D,$55,$7F,$FD  ; row 10
    DB $AA,$A8,$AA,$AA,$00,$00,$2A,$00,$02,$00,$0A,$AA,$AA,$20,$00,$0A,$FF,$D5,$57,$75,$5F,$7D,$5F,$F5,$F7,$D5,$55,$7F,$FD,$55,$7F,$F5  ; row 11
    DB $AA,$AA,$2A,$AA,$80,$00,$2A,$80,$02,$80,$2A,$AA,$AA,$20,$00,$0A,$FF,$D5,$55,$55,$75,$D7,$F5,$FF,$D5,$D5,$55,$7F,$F5,$55,$FF,$55  ; row 12
    DB $AA,$AA,$82,$AA,$80,$00,$AA,$A0,$0A,$AA,$A0,$AA,$A8,$00,$00,$0A,$FF,$D5,$57,$D5,$57,$5F,$D5,$FD,$55,$F5,$55,$FF,$F5,$55,$F5,$75  ; row 13
    DB $2A,$AA,$80,$AA,$A0,$02,$AA,$A8,$0A,$02,$80,$A8,$A0,$02,$00,$0A,$FF,$55,$7F,$55,$55,$5F,$D7,$F5,$55,$F5,$55,$FF,$F5,$55,$D5,$F5  ; row 14
    DB $2A,$AA,$A0,$0A,$A8,$02,$A2,$AA,$08,$00,$00,$A8,$00,$02,$A0,$0A,$FF,$55,$FF,$55,$55,$7F,$5F,$FD,$57,$75,$57,$FF,$D5,$57,$57,$FF  ; row 15
    DB $0A,$AA,$A0,$00,$AA,$2A,$0A,$A8,$28,$00,$2A,$AA,$00,$02,$AA,$0A,$FF,$57,$FD,$75,$55,$D5,$D5,$DF,$D5,$7F,$57,$FF,$D5,$7F,$5F,$57  ; row 16
    DB $A0,$AA,$A8,$00,$02,$AA,$82,$8A,$AA,$00,$AA,$A8,$00,$02,$AA,$82,$FD,$5F,$FD,$D5,$DF,$57,$D5,$7F,$F5,$7F,$FF,$FF,$DF,$FF,$75,$55  ; row 17
    DB $A8,$02,$AA,$00,$02,$AA,$0A,$00,$AA,$00,$AA,$A0,$A8,$02,$AA,$80,$57,$FF,$F7,$57,$FD,$5F,$55,$7F,$D5,$FF,$F5,$55,$7F,$FF,$D5,$55  ; row 18
    DB $AA,$00,$2A,$80,$02,$AA,$AA,$00,$A0,$00,$0A,$80,$AA,$82,$AA,$80,$5F,$7F,$FF,$55,$FD,$5D,$55,$FF,$D5,$FF,$F5,$55,$7F,$FF,$D5,$F5  ; row 19
    DB $AA,$00,$02,$A0,$00,$A2,$AA,$00,$00,$00,$20,$00,$AA,$A2,$AA,$00,$5D,$FF,$FD,$57,$F5,$7D,$7F,$FF,$FF,$FF,$F5,$55,$7F,$FF,$D7,$F7  ; row 20
    DB $AA,$80,$00,$A8,$A8,$00,$AA,$82,$8A,$0A,$A0,$00,$AA,$A0,$AA,$00,$75,$F5,$FF,$57,$FF,$DF,$FD,$5F,$FD,$FF,$F5,$55,$5F,$FF,$FF,$F5  ; row 21
    DB $AA,$A0,$00,$0A,$AA,$00,$AA,$AA,$AA,$2A,$A0,$00,$AA,$A0,$08,$00,$7D,$57,$DD,$5F,$7D,$5F,$FD,$7F,$FD,$5F,$F5,$55,$5F,$FF,$FF,$F5  ; row 22
    DB $AA,$A8,$00,$02,$A8,$00,$20,$0A,$AA,$AA,$80,$02,$AA,$80,$02,$00,$FD,$55,$55,$75,$75,$5F,$FD,$FF,$FD,$55,$F5,$55,$5D,$FF,$5F,$FD  ; row 23
    DB $00,$AA,$80,$02,$A2,$AA,$80,$0A,$A0,$AA,$AA,$A8,$AA,$80,$0A,$AA,$F5,$55,$75,$55,$D5,$7F,$F7,$FF,$FD,$55,$55,$55,$55,$FD,$5F,$FF  ; row 24
    DB $00,$02,$A0,$A0,$80,$AA,$A0,$02,$80,$A8,$AA,$A8,$02,$00,$0A,$AA,$D5,$D5,$D7,$55,$D5,$7F,$FF,$57,$FD,$55,$57,$FF,$D5,$75,$77,$F5  ; row 25
    DB $00,$00,$22,$AA,$00,$AA,$A0,$00,$00,$A0,$AA,$A0,$00,$80,$2A,$AA,$D7,$57,$FF,$57,$55,$D5,$7F,$55,$7D,$55,$55,$FF,$55,$77,$D5,$55  ; row 26
    DB $00,$00,$0A,$AA,$00,$0A,$AA,$28,$02,$80,$AA,$A0,$02,$A8,$2A,$02,$5D,$55,$FF,$5F,$5F,$55,$FF,$55,$57,$55,$55,$FD,$5F,$D7,$5F,$D5  ; row 27
    DB $00,$00,$02,$A2,$AA,$A0,$0A,$A8,$02,$02,$AA,$80,$02,$AA,$A8,$00,$FD,$55,$FD,$7D,$FF,$57,$FF,$55,$55,$55,$55,$75,$FD,$57,$7F,$F7  ; row 28
    DB $00,$00,$AA,$80,$AA,$A0,$0A,$A0,$08,$02,$AA,$80,$0A,$A8,$08,$02,$5F,$57,$FF,$F7,$FF,$5F,$FF,$55,$55,$75,$55,$55,$75,$5D,$7F,$F5  ; row 29
    DB $00,$02,$A8,$00,$8A,$A0,$0A,$80,$20,$02,$AA,$00,$2A,$A8,$20,$00,$5F,$57,$DF,$D7,$FF,$7F,$FF,$D5,$55,$7F,$55,$55,$7D,$55,$5F,$55  ; row 30
    DB $AA,$0A,$AA,$A0,$A2,$A0,$2A,$82,$80,$0A,$80,$AA,$2A,$A0,$20,$00,$5D,$5D,$5D,$5F,$FF,$55,$55,$D5,$55,$5F,$FD,$55,$FF,$F5,$5D,$55  ; row 31
    DB $00,$00,$08,$00,$0A,$A2,$80,$00,$AA,$AA,$A8,$00,$A8,$0A,$80,$AA,$FD,$5F,$DF,$F5,$55,$7F,$FF,$F7,$FF,$FD,$55,$FD,$55,$57,$D5,$F5  ; row 32
    DB $00,$A8,$28,$00,$0A,$8A,$8A,$02,$AA,$2A,$A0,$00,$AA,$AA,$00,$82,$FD,$5F,$5F,$F5,$55,$5F,$FF,$FD,$7F,$FF,$7D,$7D,$55,$57,$55,$D7  ; row 33
    DB $02,$AA,$00,$0A,$0A,$80,$AA,$02,$A0,$AA,$A0,$02,$AA,$AA,$02,$02,$F5,$5D,$5F,$F5,$D5,$5F,$FF,$FF,$57,$FF,$FF,$D5,$FD,$7F,$5F,$DF  ; row 34
    DB $0A,$A8,$02,$0A,$82,$00,$A8,$0A,$80,$AA,$80,$02,$AA,$02,$0A,$02,$F5,$55,$5F,$F7,$55,$57,$FF,$FF,$D5,$FF,$FF,$55,$F5,$FF,$7F,$DF  ; row 35
    DB $2A,$A0,$02,$2A,$80,$02,$A8,$08,$02,$AA,$80,$0A,$A8,$02,$08,$20,$5F,$D5,$7F,$D5,$55,$55,$FF,$FF,$F5,$57,$FD,$57,$55,$7D,$FF,$5F  ; row 36
    DB $2A,$A8,$0A,$8A,$88,$0A,$A0,$00,$02,$AA,$00,$0A,$A0,$02,$02,$A0,$5F,$D5,$FD,$5D,$55,$55,$7F,$FF,$FD,$75,$FF,$5F,$55,$75,$7D,$5F  ; row 37
    DB $80,$AA,$AA,$80,$00,$2A,$AA,$80,$0A,$AA,$2A,$80,$80,$08,$00,$A0,$5F,$DD,$55,$7F,$55,$7F,$F5,$FF,$FF,$FF,$57,$FF,$D5,$55,$75,$5F  ; row 38
    DB $82,$AA,$82,$00,$0A,$AA,$AA,$00,$0A,$A2,$AA,$80,$28,$08,$00,$08,$55,$5F,$D5,$FF,$DF,$FF,$FD,$57,$FF,$FF,$55,$7F,$DF,$55,$55,$55  ; row 39
    DB $8A,$AA,$80,$00,$0A,$00,$AA,$00,$2A,$02,$AA,$00,$2A,$8A,$20,$0A,$D5,$7F,$F7,$FF,$5F,$FF,$FF,$55,$77,$FF,$57,$D5,$5F,$55,$55,$D5  ; row 40
    DB $00,$A2,$02,$A0,$28,$02,$A8,$00,$A0,$0A,$AA,$00,$AA,$0A,$00,$0A,$D5,$FF,$FF,$F5,$57,$FF,$FF,$D5,$7D,$FF,$DF,$D5,$5F,$57,$5F,$D5  ; row 41
    DB $80,$00,$82,$AA,$A8,$0A,$A0,$00,$80,$0A,$AA,$00,$A8,$08,$0A,$02,$D5,$FF,$DF,$D5,$55,$FF,$FF,$F5,$FF,$D5,$FF,$F5,$7F,$7F,$7F,$55  ; row 42
    DB $80,$02,$A2,$AA,$A0,$2A,$A0,$00,$00,$2A,$A8,$00,$AA,$88,$02,$A2,$F5,$FF,$55,$55,$55,$7F,$FF,$FF,$FF,$55,$F7,$F5,$F5,$FD,$FF,$55  ; row 43
    DB $02,$02,$A2,$A8,$A0,$AA,$80,$28,$00,$2A,$AA,$AA,$AA,$8A,$02,$80,$55,$7D,$7F,$55,$55,$5F,$FF,$FF,$FF,$57,$F5,$5D,$55,$D7,$FF,$55  ; row 44
    DB $0A,$A2,$88,$A0,$2A,$AA,$8A,$A8,$00,$2A,$8A,$AA,$2A,$02,$A2,$80,$55,$5F,$FF,$D5,$55,$7D,$55,$FF,$F5,$DF,$F5,$5D,$55,$57,$FD,$55  ; row 45
    DB $AA,$A0,$20,$00,$A8,$00,$AA,$A0,$00,$A0,$0A,$AA,$2A,$82,$AA,$82,$FF,$FF,$FF,$F5,$5F,$FF,$55,$FD,$55,$75,$F5,$7D,$55,$57,$FD,$5F  ; row 46
    DB $AA,$80,$A0,$00,$A0,$00,$AA,$A0,$00,$00,$0A,$AA,$A2,$A8,$A0,$A0,$FF,$7F,$FF,$FD,$FF,$FF,$D7,$FF,$55,$F5,$5D,$FD,$55,$5F,$F5,$FF  ; row 47
    DB $00,$00,$02,$02,$A0,$02,$AA,$80,$0A,$00,$0A,$AA,$82,$AA,$80,$00,$7D,$5F,$FF,$F5,$FF,$FF,$DF,$FD,$D5,$F5,$5F,$F5,$D5,$7F,$FF,$FD  ; row 48
    DB $00,$A0,$2A,$A2,$80,$02,$AA,$80,$2A,$00,$0A,$2A,$A8,$AA,$80,$00,$55,$57,$FF,$D5,$7F,$FF,$FF,$F5,$F5,$55,$55,$5F,$55,$FF,$FF,$FD  ; row 49
    DB $02,$80,$8A,$AA,$80,$02,$AA,$82,$AA,$00,$28,$28,$AA,$A8,$A2,$00,$55,$55,$FD,$55,$5F,$FF,$F5,$D5,$F5,$5F,$55,$5F,$57,$FD,$7F,$F5  ; row 50
    DB $02,$02,$2A,$80,$00,$0A,$AA,$AA,$AA,$0A,$AA,$A0,$AA,$A0,$02,$A8,$55,$55,$55,$55,$5F,$FF,$F5,$55,$5D,$7F,$D5,$7F,$57,$D5,$FF,$F5  ; row 51
    DB $A2,$AA,$AA,$00,$A8,$0A,$A0,$2A,$AA,$2A,$AA,$AA,$2A,$80,$00,$AA,$D5,$5F,$F5,$55,$57,$DF,$F7,$FD,$5F,$7D,$D5,$57,$D5,$55,$FF,$D5  ; row 52
    DB $AA,$AA,$00,$00,$AA,$A0,$00,$2A,$A0,$2A,$2A,$2A,$A2,$20,$00,$20,$5F,$FF,$FD,$55,$5D,$7F,$F7,$FD,$7F,$D5,$FD,$57,$F5,$57,$FF,$5F  ; row 53
    DB $8A,$AA,$00,$02,$AA,$A0,$00,$2A,$80,$08,$28,$0A,$A8,$02,$00,$00,$57,$FF,$FD,$55,$FD,$FF,$D7,$DF,$FF,$55,$F5,$5F,$D5,$5F,$FF,$FF  ; row 54
    DB $2A,$A8,$28,$02,$AA,$A0,$00,$0A,$00,$00,$00,$02,$A0,$02,$A0,$00,$57,$FF,$FF,$5F,$FD,$FF,$57,$7F,$D7,$57,$D5,$7F,$D5,$5F,$F7,$FF  ; row 55
    DB $80,$A8,$2A,$02,$AA,$A0,$00,$08,$00,$00,$0A,$AA,$A0,$00,$A8,$00,$55,$FF,$FF,$7F,$F5,$D7,$F7,$7F,$57,$F7,$55,$7F,$55,$7F,$D7,$FF  ; row 56
    DB $80,$00,$AA,$A2,$AA,$A0,$00,$0A,$00,$8A,$02,$AA,$00,$00,$2A,$00,$55,$FF,$FD,$FF,$DF,$5F,$FF,$57,$5F,$F5,$FD,$FD,$55,$7D,$5F,$FF  ; row 57
    DB $00,$00,$AA,$A8,$AA,$A8,$00,$2A,$82,$08,$00,$A8,$02,$80,$00,$00,$55,$7F,$D5,$FF,$FF,$7F,$FF,$57,$DF,$F7,$FF,$FD,$55,$D5,$5F,$FF  ; row 58
    DB $80,$00,$AA,$A8,$02,$A8,$0A,$AA,$A0,$08,$00,$20,$02,$A8,$00,$28,$55,$75,$55,$FF,$FD,$7F,$FF,$57,$D7,$D7,$F7,$F5,$5F,$55,$7F,$FF  ; row 59
    DB $00,$A8,$AA,$A8,$00,$00,$AA,$AA,$80,$2A,$2A,$A8,$00,$A8,$00,$2A,$FF,$D5,$55,$FF,$FD,$7F,$57,$5F,$D5,$5F,$D5,$5F,$FD,$55,$7F,$F7  ; row 60
    DB $02,$AA,$2A,$AA,$00,$00,$22,$A8,$A0,$A0,$2A,$00,$00,$A0,$00,$0A,$FF,$D5,$55,$FF,$F5,$DD,$57,$FF,$57,$DF,$55,$7F,$FD,$55,$7F,$57  ; row 61
    DB $AA,$AA,$02,$AA,$00,$00,$00,$82,$A8,$80,$08,$02,$00,$08,$00,$0A,$FF,$D5,$57,$7F,$DF,$7D,$5F,$D5,$5F,$D5,$55,$7F,$F5,$55,$F5,$5F  ; row 62
    DB $AA,$AA,$80,$AA,$80,$00,$0A,$8A,$AA,$A0,$08,$0A,$A8,$0A,$00,$0A,$FF,$D5,$55,$7F,$FD,$F5,$7F,$57,$FF,$5D,$55,$FF,$F5,$55,$D5,$55  ; row 63

; ==============================================================
; ROLTAB: 256-entry lookup table, PAGE-ALIGNED at $8900
; ROLTAB[b] = b with each 2-bit pixel value incremented mod 4
;   00->01->10->11->00  (green->yellow->blue->red->green)
; D = $89 throughout RotLoop, so LD A,(DE) indexes ROLTAB[E].
; VERIFIED: applying ROLTAB 4 times returns to original byte.
; ==============================================================
            ORG     $8900
ROLTAB:
    DB $55,$56,$57,$54,$59,$5A,$5B,$58,$5D,$5E,$5F,$5C,$51,$52,$53,$50
    DB $65,$66,$67,$64,$69,$6A,$6B,$68,$6D,$6E,$6F,$6C,$61,$62,$63,$60
    DB $75,$76,$77,$74,$79,$7A,$7B,$78,$7D,$7E,$7F,$7C,$71,$72,$73,$70
    DB $45,$46,$47,$44,$49,$4A,$4B,$48,$4D,$4E,$4F,$4C,$41,$42,$43,$40
    DB $95,$96,$97,$94,$99,$9A,$9B,$98,$9D,$9E,$9F,$9C,$91,$92,$93,$90
    DB $A5,$A6,$A7,$A4,$A9,$AA,$AB,$A8,$AD,$AE,$AF,$AC,$A1,$A2,$A3,$A0
    DB $B5,$B6,$B7,$B4,$B9,$BA,$BB,$B8,$BD,$BE,$BF,$BC,$B1,$B2,$B3,$B0
    DB $85,$86,$87,$84,$89,$8A,$8B,$88,$8D,$8E,$8F,$8C,$81,$82,$83,$80
    DB $D5,$D6,$D7,$D4,$D9,$DA,$DB,$D8,$DD,$DE,$DF,$DC,$D1,$D2,$D3,$D0
    DB $E5,$E6,$E7,$E4,$E9,$EA,$EB,$E8,$ED,$EE,$EF,$EC,$E1,$E2,$E3,$E0
    DB $F5,$F6,$F7,$F4,$F9,$FA,$FB,$F8,$FD,$FE,$FF,$FC,$F1,$F2,$F3,$F0
    DB $C5,$C6,$C7,$C4,$C9,$CA,$CB,$C8,$CD,$CE,$CF,$CC,$C1,$C2,$C3,$C0
    DB $15,$16,$17,$14,$19,$1A,$1B,$18,$1D,$1E,$1F,$1C,$11,$12,$13,$10
    DB $25,$26,$27,$24,$29,$2A,$2B,$28,$2D,$2E,$2F,$2C,$21,$22,$23,$20
    DB $35,$36,$37,$34,$39,$3A,$3B,$38,$3D,$3E,$3F,$3C,$31,$32,$33,$30
    DB $05,$06,$07,$04,$09,$0A,$0B,$08,$0D,$0E,$0F,$0C,$01,$02,$03,$00

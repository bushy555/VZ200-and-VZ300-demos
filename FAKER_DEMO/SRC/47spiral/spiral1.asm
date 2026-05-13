; ==============================================================
; VZ200/VZ300 MODE(1) - ANIMATED SPIRAL
;
; Displays a pre-rendered 128x64 spiral image with colour cycling.
; The spiral uses all 4 VZ200 graphics colours:
;   00 = green, 01 = yellow, 10 = blue, 11 = red
;
; Each frame, every VRAM byte is transformed through ROLTAB,
; which increments each 2-bit pixel value by 1 (mod 4).
; This cycles green->yellow->blue->red->green, making the
; spiral appear to rotate.
;
; ROLTAB sits at $8900 (a 256-byte page boundary).
; This allows the lookup: LD D,$89 / LD E,A / LD A,(DE)
; which transforms any byte in 2 instructions.
;
; ANIMATION SPEED:
;   Rotation loop: 2048 bytes * ~50 T-states = ~28ms at 3.58MHz
;   Delay: DCOUNT iterations * 24 T-states each
;   DCOUNT=2000: +13ms = ~41ms/frame = ~24fps (smooth, fast)
;   Increase DCOUNT to slow down.
;
; BUILD:
;   pasmo --bin vz_spiral_anim.asm spiral.bin
;   python make_vz.py spiral.bin spiral.vz 0x8000 0x8000
;
; RULES: ORG $8000, JP-only, SP=$F000, all DB/DEFS at end.
; ==============================================================

            ORG     $8000
            JP      Start

VRAM        EQU     $7000
BUFFER	    equ     $9000
LATCH       EQU     $6800
ROLTAB_HI   EQU     $89         ; high byte of ROLTAB address
DCOUNT      EQU     $2000        ; delay loop count (tune for speed)

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
            LD      BC,DCOUNT
Delay:
            DEC     BC
            LD      A,B
            OR      C
            JP      NZ,Delay

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


	ld	hl, BUFFER
	ld	de, VRAM
	ld	bc, 2048
	ldir



            JP      MainLoop

; ==============================================================
; SPIRAL_IMAGE: pre-rendered 128x64 spiral, 2bpp, 2048 bytes
; Colour bands cycle: 00=green -> 01=yellow -> 10=blue -> 11=red
; Generated with Floyd-Steinberg error diffusion at boundaries.
; Pixel aspect (2:3) corrected so spiral looks round on screen.
; ==============================================================
SPIRAL_IMAGE:
    DB $EE,$AA,$A6,$55,$54,$40,$00,$0C,$CF,$FF,$FF,$EE,$EE,$BA,$AA,$AB,$AB,$AE,$EF,$BF,$FF,$FC,$C0,$00,$04,$55,$55,$9A,$AA,$EF,$FF,$30  ; row  0
    DB $FB,$EA,$A9,$99,$55,$14,$40,$03,$33,$FF,$FE,$FE,$EE,$EE,$EF,$BA,$EE,$EE,$FB,$FF,$FF,$33,$33,$00,$44,$45,$59,$AA,$AB,$BF,$FC,$C0  ; row  1
    DB $BA,$AA,$99,$55,$51,$00,$00,$F3,$FF,$FF,$EE,$EB,$AA,$AA,$AA,$AA,$AA,$AA,$AE,$BB,$BF,$FF,$30,$00,$01,$15,$56,$5A,$AA,$EE,$FF,$33  ; row  2
    DB $BB,$AA,$99,$95,$44,$40,$0C,$CF,$3F,$FE,$EE,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$EA,$EB,$BF,$FF,$FF,$CC,$00,$44,$55,$65,$AA,$BB,$FF,$CC  ; row  3
    DB $AA,$A9,$95,$54,$40,$00,$33,$FF,$FF,$BB,$AA,$AA,$AA,$AA,$66,$66,$9A,$AA,$AA,$AA,$EA,$EF,$FC,$CC,$00,$04,$55,$59,$AA,$AE,$FF,$F3  ; row  4
    DB $BA,$A6,$55,$51,$04,$03,$3C,$FF,$EE,$EA,$AA,$AA,$99,$95,$99,$65,$65,$66,$6A,$AA,$AE,$EF,$FF,$F3,$30,$01,$11,$56,$5A,$AA,$EF,$F3  ; row  5
    DB $AA,$65,$55,$10,$00,$33,$CF,$FE,$EA,$AA,$AA,$99,$65,$59,$55,$56,$56,$56,$59,$AA,$AA,$AE,$BF,$FF,$C0,$00,$11,$55,$66,$AA,$EF,$FF  ; row  6
    DB $A9,$99,$55,$10,$00,$CF,$FF,$EE,$BA,$AA,$99,$65,$55,$55,$55,$55,$55,$55,$55,$59,$AA,$AA,$EE,$FF,$3F,$00,$04,$55,$66,$AA,$BB,$FF  ; row  7
    DB $9A,$55,$51,$00,$03,$3F,$FE,$EB,$AA,$A6,$65,$55,$55,$55,$15,$14,$55,$55,$56,$56,$5A,$AA,$AE,$FF,$F3,$30,$01,$15,$55,$9A,$AE,$FF  ; row  8
    DB $65,$95,$50,$40,$33,$FF,$FB,$AA,$AA,$65,$55,$55,$54,$41,$01,$04,$01,$11,$55,$55,$96,$6A,$AB,$AF,$FF,$C0,$00,$45,$56,$6A,$AB,$BF  ; row  9
    DB $99,$55,$04,$00,$3F,$FF,$EE,$AA,$99,$59,$55,$51,$01,$10,$10,$00,$40,$11,$11,$55,$55,$9A,$AA,$BB,$BF,$FC,$00,$11,$55,$9A,$AA,$EF  ; row 10
    DB $65,$54,$40,$03,$CF,$FE,$EA,$AA,$96,$55,$54,$44,$10,$00,$00,$00,$00,$00,$11,$15,$55,$65,$AA,$AB,$FF,$CF,$30,$01,$15,$59,$AA,$EF  ; row 11
    DB $55,$51,$00,$0C,$FF,$FB,$AA,$A9,$65,$55,$11,$00,$00,$00,$00,$00,$00,$00,$00,$04,$55,$56,$66,$AA,$BB,$FC,$C0,$04,$55,$59,$AA,$BB  ; row 12
    DB $55,$51,$00,$33,$FF,$EE,$AA,$96,$55,$51,$10,$00,$03,$33,$FF,$FF,$33,$00,$00,$40,$45,$55,$6A,$AB,$AF,$FF,$30,$00,$11,$59,$AA,$BB  ; row 13
    DB $55,$40,$00,$CF,$FE,$EA,$AA,$65,$55,$11,$00,$00,$CC,$FC,$CC,$CF,$FC,$F3,$00,$00,$11,$55,$55,$AA,$AE,$FF,$F3,$01,$15,$56,$6A,$AE  ; row 14
    DB $55,$11,$03,$3F,$FE,$EA,$A6,$55,$54,$40,$00,$33,$3F,$CF,$FF,$FF,$FF,$FC,$F3,$00,$00,$15,$59,$9A,$AB,$BF,$F3,$00,$04,$55,$9A,$AB  ; row 15
    DB $54,$40,$0C,$FF,$EE,$AA,$99,$55,$44,$00,$03,$3F,$FF,$FF,$FE,$FF,$FF,$FF,$FC,$C0,$01,$11,$55,$66,$AA,$EF,$FC,$C0,$05,$55,$66,$AA  ; row 16
    DB $44,$00,$33,$FF,$EB,$AA,$65,$55,$10,$00,$3C,$FF,$FF,$FB,$AE,$EB,$BF,$FF,$FF,$F3,$00,$04,$55,$66,$AA,$BB,$FF,$30,$01,$15,$9A,$AB  ; row 17
    DB $51,$10,$33,$FF,$BA,$A9,$95,$54,$40,$03,$33,$FF,$FE,$BA,$EA,$BA,$AA,$BB,$FF,$3C,$C0,$01,$15,$59,$AA,$BB,$FC,$C0,$04,$55,$59,$AA  ; row 18
    DB $10,$03,$3F,$FE,$EA,$A6,$55,$51,$00,$0C,$FF,$FF,$AE,$AA,$AA,$AA,$BB,$AE,$FF,$FF,$30,$00,$45,$56,$6A,$AE,$FF,$CC,$00,$45,$59,$AA  ; row 19
    DB $11,$00,$CF,$FE,$AA,$99,$55,$40,$00,$33,$FF,$EE,$EA,$AA,$AA,$AA,$AA,$AA,$AE,$FF,$CC,$00,$45,$55,$9A,$AE,$FF,$F0,$01,$15,$59,$AA  ; row 20
    DB $10,$0C,$FF,$FB,$AA,$95,$55,$10,$03,$3F,$FE,$EA,$AA,$AA,$66,$66,$66,$AA,$EB,$BF,$F3,$00,$04,$55,$6A,$AB,$BF,$CC,$C0,$45,$56,$AA  ; row 21
    DB $00,$03,$3F,$EE,$AA,$66,$54,$40,$03,$FF,$FB,$AE,$AA,$96,$59,$55,$99,$AA,$AB,$BF,$FF,$30,$04,$55,$96,$AA,$EF,$F3,$00,$11,$59,$6A  ; row 22
    DB $10,$0F,$FF,$EA,$A9,$95,$51,$00,$33,$3F,$EE,$AA,$99,$65,$55,$55,$55,$59,$AA,$BB,$FF,$30,$01,$15,$66,$AA,$FF,$FC,$00,$45,$56,$6A  ; row 23
    DB $00,$30,$FF,$BA,$A9,$95,$44,$00,$3F,$FF,$BA,$AA,$65,$55,$55,$55,$56,$66,$AA,$AE,$FF,$C0,$01,$15,$59,$AA,$BB,$F3,$00,$11,$55,$A6  ; row 24
    DB $00,$0F,$FF,$AE,$A6,$55,$44,$00,$CF,$FB,$AA,$A6,$55,$55,$51,$11,$55,$55,$6A,$AB,$BF,$3C,$00,$45,$59,$AA,$EF,$FC,$C0,$05,$56,$6A  ; row 25
    DB $00,$33,$FE,$EA,$A5,$55,$10,$03,$3F,$FE,$AA,$A5,$95,$51,$00,$40,$11,$55,$9A,$AB,$FF,$F3,$01,$15,$59,$AA,$BB,$FC,$C0,$11,$55,$9A  ; row 26
    DB $00,$CF,$FE,$EA,$99,$95,$10,$03,$FF,$EB,$AA,$65,$55,$44,$04,$01,$01,$15,$59,$AA,$BF,$F0,$00,$45,$56,$AA,$EF,$FC,$C0,$04,$55,$A6  ; row 27
    DB $00,$3F,$FE,$AA,$99,$54,$40,$0C,$FF,$FA,$AA,$59,$54,$00,$00,$00,$00,$55,$66,$AB,$BB,$FC,$C0,$11,$59,$6A,$BB,$FC,$C0,$11,$55,$6A  ; row 28
    DB $00,$CF,$FB,$BA,$95,$54,$40,$33,$FF,$AE,$A9,$95,$44,$40,$0F,$F3,$00,$11,$59,$AA,$EF,$CC,$00,$45,$56,$AA,$BB,$FF,$00,$04,$56,$66  ; row 29
    DB $03,$3F,$FB,$AA,$66,$54,$10,$0C,$FF,$EA,$A6,$55,$44,$00,$CC,$FF,$30,$45,$5A,$AA,$FF,$F3,$00,$15,$59,$9A,$BE,$F3,$30,$11,$55,$9A  ; row 30
    DB $00,$CF,$FB,$AA,$65,$51,$00,$3F,$FE,$BA,$A5,$55,$10,$03,$3F,$FF,$C0,$55,$65,$AA,$EF,$F3,$00,$45,$56,$6A,$EF,$FF,$00,$04,$55,$AA  ; row 31
    DB $03,$3F,$FA,$AA,$65,$54,$40,$C3,$FF,$AA,$99,$95,$00,$0C,$FF,$EA,$04,$45,$5A,$AB,$BF,$F0,$C0,$45,$56,$AA,$AE,$FC,$C0,$11,$55,$9A  ; row 32
    DB $03,$3F,$FE,$EA,$65,$51,$00,$3F,$FE,$EA,$A5,$54,$44,$0F,$FE,$EA,$55,$55,$A6,$AB,$BF,$CC,$00,$51,$59,$AA,$EF,$F3,$30,$05,$56,$6A  ; row 33
    DB $0C,$F3,$EB,$A9,$95,$51,$00,$CC,$FE,$BA,$99,$55,$00,$33,$FF,$AA,$95,$59,$AA,$AE,$FF,$F3,$01,$15,$59,$AA,$BF,$FC,$C0,$11,$55,$9A  ; row 34
    DB $00,$CF,$FA,$AA,$65,$54,$00,$33,$FB,$AA,$99,$54,$40,$0C,$FE,$EA,$99,$9A,$6A,$BB,$FF,$30,$01,$15,$66,$AA,$EF,$FC,$00,$44,$56,$6A  ; row 35
    DB $0C,$FF,$EE,$EA,$65,$51,$00,$3F,$FE,$EA,$99,$55,$10,$33,$FF,$BA,$AA,$AA,$AA,$EF,$FF,$00,$04,$55,$5A,$6B,$BF,$F3,$00,$15,$56,$6A  ; row 36
    DB $00,$CF,$FB,$AA,$65,$54,$40,$CC,$FE,$EA,$A5,$54,$40,$0C,$FF,$EA,$AA,$AA,$AE,$FF,$FC,$CC,$04,$55,$9A,$AA,$EF,$F3,$00,$44,$56,$9A  ; row 37
    DB $0C,$FF,$FA,$AA,$59,$51,$00,$0F,$FE,$EA,$99,$95,$10,$03,$3F,$FF,$BA,$AB,$BB,$EF,$F3,$00,$45,$55,$66,$AE,$FF,$CC,$00,$15,$59,$AA  ; row 38
    DB $00,$3F,$FE,$EA,$95,$54,$40,$33,$FF,$BA,$A6,$55,$44,$03,$3F,$FB,$EF,$FB,$FF,$FF,$30,$00,$11,$56,$6A,$AB,$FF,$F0,$01,$15,$59,$AA  ; row 39
    DB $03,$33,$EE,$AA,$66,$51,$00,$33,$FE,$EA,$A9,$55,$44,$00,$CC,$FF,$FE,$FF,$FF,$F3,$00,$01,$45,$56,$6A,$BB,$BF,$30,$00,$45,$5A,$6A  ; row 40
    DB $00,$CF,$FE,$EA,$99,$55,$10,$0C,$FF,$EE,$AA,$65,$51,$00,$03,$CF,$FF,$FF,$FF,$30,$C0,$04,$55,$59,$AA,$BB,$FF,$0C,$01,$55,$66,$AA  ; row 41
    DB $00,$CF,$FB,$AA,$99,$54,$40,$0C,$FF,$EA,$A9,$95,$54,$40,$00,$33,$3F,$FF,$CC,$C0,$00,$11,$55,$9A,$AA,$EF,$FC,$C0,$04,$55,$66,$AB  ; row 42
    DB $00,$3F,$FE,$EA,$A5,$55,$10,$03,$3F,$FE,$EA,$99,$55,$44,$00,$0C,$C0,$00,$30,$00,$01,$15,$55,$9A,$AB,$BF,$F3,$00,$11,$55,$9A,$AA  ; row 43
    DB $00,$C3,$FF,$BA,$9A,$55,$44,$03,$3F,$EE,$AA,$A6,$55,$51,$00,$00,$0C,$CC,$00,$00,$11,$55,$59,$AA,$AB,$FF,$F3,$00,$11,$55,$AA,$AE  ; row 44
    DB $00,$33,$FF,$AA,$A6,$55,$44,$00,$CF,$FF,$BA,$99,$95,$55,$50,$00,$00,$00,$00,$01,$15,$55,$5A,$6A,$BB,$BF,$CC,$00,$45,$56,$66,$AE  ; row 45
    DB $10,$0C,$FF,$EE,$A9,$95,$51,$00,$33,$FF,$BA,$AA,$65,$55,$15,$44,$10,$40,$11,$15,$55,$55,$A6,$AA,$EF,$FF,$30,$00,$55,$56,$6A,$BB  ; row 46
    DB $00,$0C,$FF,$BA,$AA,$65,$51,$00,$0C,$FF,$EE,$AA,$A6,$55,$54,$51,$44,$45,$44,$54,$55,$5A,$6A,$AE,$FF,$FC,$C0,$04,$45,$66,$AA,$EF  ; row 47
    DB $10,$03,$3F,$FB,$AA,$65,$54,$40,$0C,$FF,$FB,$BA,$A9,$A5,$55,$55,$55,$54,$55,$55,$56,$66,$AA,$BB,$BF,$F3,$00,$05,$55,$5A,$AA,$EF  ; row 48
    DB $10,$03,$FF,$FB,$AA,$99,$55,$10,$03,$33,$FF,$AA,$AA,$9A,$65,$55,$55,$55,$55,$56,$66,$AA,$AB,$BB,$FF,$C0,$00,$44,$55,$A6,$AB,$BF  ; row 49
    DB $44,$00,$33,$FB,$AA,$A6,$55,$44,$00,$3F,$FF,$FE,$AA,$A9,$99,$95,$55,$55,$56,$66,$AA,$AA,$AE,$FF,$FC,$CC,$00,$45,$56,$6A,$AE,$FF  ; row 50
    DB $11,$00,$CF,$FE,$EA,$A6,$55,$51,$00,$03,$3F,$EF,$EE,$AA,$AA,$6A,$66,$66,$A6,$9A,$6A,$AA,$FB,$FF,$F3,$00,$04,$55,$59,$AA,$AE,$FF  ; row 51
    DB $54,$00,$33,$FF,$EE,$A9,$95,$54,$40,$03,$3F,$FE,$FA,$EA,$AA,$AA,$A9,$A9,$AA,$AA,$AA,$AF,$BF,$FF,$30,$00,$11,$55,$66,$AA,$EF,$FF  ; row 52
    DB $45,$10,$0C,$FF,$BA,$AA,$99,$55,$10,$00,$C3,$FF,$FF,$BB,$AA,$AA,$AA,$AA,$AA,$AA,$BB,$EF,$FF,$F3,$00,$00,$45,$55,$9A,$AA,$EF,$FF  ; row 53
    DB $54,$40,$0C,$FF,$FE,$EA,$99,$55,$54,$40,$0C,$33,$FF,$EE,$EE,$AA,$AA,$AA,$AA,$AE,$EE,$FF,$FF,$33,$00,$04,$55,$56,$6A,$AB,$BF,$F3  ; row 54
    DB $55,$10,$03,$3F,$FB,$AA,$A6,$95,$44,$40,$00,$CF,$FF,$FF,$FB,$FB,$BB,$BB,$BB,$FB,$FF,$FF,$F3,$30,$00,$11,$55,$66,$AA,$AE,$FF,$F0  ; row 55
    DB $55,$44,$00,$33,$FF,$BA,$A9,$95,$55,$11,$00,$00,$CF,$FF,$FF,$EF,$EE,$EF,$BF,$BF,$FF,$FF,$30,$00,$01,$15,$55,$69,$AA,$EF,$FF,$33  ; row 56
    DB $55,$51,$00,$CC,$FF,$EE,$AA,$A6,$55,$51,$00,$0C,$30,$CF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$03,$00,$11,$55,$56,$9A,$AB,$BF,$FC,$C0  ; row 57
    DB $65,$51,$00,$03,$FF,$FB,$AA,$A6,$65,$54,$50,$00,$03,$33,$3F,$FF,$FF,$FF,$FF,$F3,$30,$C3,$00,$04,$55,$55,$66,$AA,$BB,$EF,$F3,$00  ; row 58
    DB $65,$55,$10,$0C,$3F,$FE,$EE,$AA,$65,$55,$45,$10,$00,$00,$C0,$33,$33,$33,$33,$0C,$C0,$00,$00,$45,$15,$55,$9A,$AA,$BB,$FF,$CC,$00  ; row 59
    DB $66,$55,$44,$00,$CF,$FF,$EA,$AA,$9A,$55,$55,$44,$40,$00,$03,$00,$CC,$CC,$C0,$C0,$00,$00,$11,$51,$55,$5A,$6A,$AB,$BF,$FC,$C0,$00  ; row 60
    DB $A5,$55,$44,$00,$03,$3F,$FE,$EA,$A9,$A5,$55,$54,$44,$00,$00,$00,$00,$00,$00,$00,$00,$04,$45,$15,$55,$A6,$AA,$AE,$FF,$FC,$C0,$01  ; row 61
    DB $AA,$65,$54,$40,$33,$FF,$FE,$EA,$AA,$69,$95,$55,$51,$51,$00,$00,$00,$00,$00,$00,$04,$45,$55,$55,$9A,$6A,$AA,$FB,$FF,$CC,$00,$04  ; row 62
    DB $A6,$95,$55,$10,$00,$0F,$FF,$FE,$EA,$AA,$65,$55,$55,$14,$51,$10,$04,$01,$04,$45,$51,$55,$55,$59,$9A,$AA,$AF,$BF,$FF,$30,$00,$45  ; row 63

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

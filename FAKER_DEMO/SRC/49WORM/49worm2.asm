; ==============================================================
; VZ200/VZ300 MODE(1) - ANIMATED CHECKERBOARD WORMHOLE
;
; A checkerboard tunnel receding to a vanishing point, rendered
; using the VZ200's 4 graphics colours in a log-polar mapping.
; The checker pattern appears to be pulled into the screen.
;
; COLOURS:  00=green  01=yellow  10=blue  11=red
; Pattern:  Light squares cycle green->yellow->blue->red outward.
;           Dark squares use the opposite colour pair (+2 mod 4),
;           giving green<->blue and yellow<->red contrast pairs.
;
; LOG-POLAR MAPPING:
;   Physical coordinates: pdx = (x-64)*2, pdy = (y-32)*3
;   (aspect correction: 2:3 pixel ratio makes circle look round)
;   r     = sqrt(pdx^2 + pdy^2)     (physical radius)
;   theta = atan2(pdy, pdx)         (angle)
;   u     = log(r) * 3.5            (radial index, ~14 rings visible)
;   v     = (theta/(2pi) + 1.5*log(r)/(2pi)) * 16  (spiral twist)
;   checker  = (floor(u) + floor(v)) & 1
;   colour   = (floor(u) + checker*2) & 3
;   Floyd-Steinberg error diffusion applied at ring boundaries.
;
; ANIMATION:
;   Each frame: every VRAM byte is transformed through ROLTAB.
;   ROLTAB increments each 2-bit pixel value by 1 mod 4.
;   Effect: all colour rings advance outward one step, making
;   the checker pattern appear to zoom toward the viewer.
;   Applying ROLTAB 4 times returns to the original image.
;
; ROLTAB is placed at $8900 (256-byte page boundary).
;   LD D,$89 stays constant; LD E,A / LD A,(DE) does the lookup.
;   This transforms each VRAM byte in just 2 instructions.
;
; SPEED:
;   Rotation loop: 2048 bytes * ~50 T-states = ~28ms at 3.58MHz
;   Delay DCOUNT=2000: ~14ms extra = ~42ms/frame = ~24fps
;   Reduce DCOUNT for faster zoom, increase to slow it down.
;   Set DCOUNT=0 for maximum speed.
;
; MEMORY MAP:
;   $7000-$77FF  VRAM (2048 bytes, hardware)
;   $8000-$8002  JP Start
;   $8003-$8038  Executable code (53 bytes)
;   $8040-$883F  WORMHOLE_IMAGE (2048 bytes)
;   $8840-$88FF  Zero padding (192 bytes, from ORG $8900)
;   $8900-$89FF  ROLTAB (256 bytes, page-aligned)
;
; BUILD:
;   pasmo --bin vz_wormhole.asm wormhole.bin
;   python make_vz.py wormhole.bin wormhole.vz 0x8000 0x8000
;   Load wormhole.vz in emulator, type SYSTEM, enter 32768.
;
; RULES: ORG $8000, JP-only (no JR/DJNZ), SP=$F000,
;   LD A,(nn)/LD (nn),A for byte vars only. All DB/DEFS at end.
; ==============================================================

            ORG     $8000
            JP      Start

; --------------------- Constants ----------------------
VRAM        EQU     $7000
BUFFER	    EQU     $9000
LATCH       EQU     $6800
ROLTAB_HI   EQU     $89         ; high byte of ROLTAB page address
DCOUNT      EQU     $750;$500        ; delay loop iterations (tune for speed)

; ==============================================================
; Start: set MODE(1), copy wormhole image to VRAM, then loop
; ==============================================================
Start:

            ; Enable MODE(1) graphics
            LD      A,8
            LD      (LATCH),A


	di
            ; Copy pre-rendered wormhole to VRAM ($7000..$77FF)
            LD      HL,WORMHOLE_IMAGE
            LD      DE,BUFFER
            LD      BC,2048
            LDIR

; ==============================================================
; MainLoop: delay, then rotate all VRAM bytes through ROLTAB.
; Each pass makes the tunnel appear to zoom one step inward.
; ==============================================================
MainLoop:
            ; Delay (controls animation speed)
            LD      BC,DCOUNT
Delay:
            DEC     BC
            LD      A,B
            OR      C
            JP      NZ,Delay

            ; Colour rotation across entire VRAM (2048 bytes)
            ; D = $89 (ROLTAB page, constant throughout loop)
            ; For each byte: E = old_byte, A = ROLTAB[E] = rotated byte
            LD      HL,BUFFER; VRAM
            LD      D,ROLTAB_HI
            LD      BC,2048

RotLoop:
            LD      A,(HL)          ; read current VRAM byte
            LD      E,A             ; E = byte value = ROLTAB index (lo byte)
            LD      A,(DE)          ; A = ROLTAB[byte]: each 2-bit pixel +1 mod 4
            LD      (HL),A          ; write rotated byte back
            INC     HL              ; advance to next VRAM byte
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

; FAST LDIR - Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
;========================================================================
; Copies exactly 2048 bytes

Copy2048_64LDI:
    ; 2048 / 64 = 32 iterations
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

            JP      MainLoop

; ==============================================================
; WORMHOLE_IMAGE
; 128x64 pixels, 2 bits/pixel = 2048 bytes (32 bytes per row)
; Pre-rendered log-polar checkerboard tunnel with Floyd-Steinberg
; error diffusion at colour ring boundaries.
;
; Pixel encoding within each byte (MSB first):
;   bits 7-6 = leftmost pixel,  bits 5-4 = next,
;   bits 3-2 = next,            bits 1-0 = rightmost pixel
;   Colour: 00=green 01=yellow 10=blue 11=red
; ==============================================================
WORMHOLE_IMAGE:
    DB $6F,$3F,$FF,$FF,$FF,$F1,$44,$44,$00,$00,$00,$00,$00,$02,$A8,$C0,$C0,$3A,$A0,$00,$00,$00,$AA,$AA,$EB,$B1,$47,$FF,$FF,$55,$55,$96  ; row  0
    DB $C0,$C3,$33,$FF,$FF,$55,$55,$11,$55,$11,$00,$00,$02,$A9,$AC,$00,$03,$00,$0E,$A0,$00,$00,$6E,$FE,$FE,$F5,$55,$7F,$FF,$66,$6A,$69  ; row  1
    DB $33,$3C,$CF,$33,$FD,$54,$44,$51,$00,$40,$10,$02,$AA,$9A,$AA,$B3,$30,$0C,$C0,$2A,$A0,$00,$0A,$AB,$AE,$E4,$51,$5F,$FC,$D6,$56,$66  ; row  2
    DB $CC,$CC,$F3,$FF,$D5,$45,$51,$11,$10,$04,$02,$AA,$A6,$A9,$99,$A4,$0C,$C0,$0C,$C6,$AA,$A0,$1B,$BA,$EE,$ED,$15,$55,$FF,$E5,$99,$99  ; row  3
    DB $CC,$CF,$3F,$FF,$55,$54,$44,$44,$04,$00,$2A,$AA,$69,$99,$99,$99,$6C,$CF,$30,$01,$9A,$AA,$02,$AB,$AB,$B9,$44,$45,$7F,$D5,$66,$66  ; row  4
    DB $CC,$F3,$FF,$FD,$54,$44,$44,$40,$4A,$A0,$2A,$A6,$99,$99,$99,$66,$65,$33,$3F,$F0,$69,$AA,$A8,$AA,$BA,$EE,$45,$55,$5F,$D9,$55,$99  ; row  5
    DB $CC,$CF,$CF,$D5,$55,$47,$BB,$AE,$AA,$00,$0C,$C3,$31,$96,$56,$55,$59,$5F,$CC,$3C,$E6,$9A,$AA,$2A,$AE,$BB,$11,$11,$55,$D5,$99,$66  ; row  6
    DB $CF,$3C,$FF,$55,$5B,$BB,$BA,$AA,$A0,$00,$C3,$3C,$F3,$F3,$55,$56,$55,$67,$3F,$CC,$C6,$66,$6A,$82,$AA,$AB,$11,$54,$55,$55,$56,$59  ; row  7
    DB $F3,$FF,$FD,$5F,$BE,$EE,$AE,$BA,$00,$0C,$33,$33,$CF,$FF,$FD,$FF,$FF,$D5,$7F,$FF,$F1,$99,$99,$80,$2B,$BA,$11,$05,$45,$75,$65,$95  ; row  8
    DB $CC,$CF,$FF,$FF,$EE,$EE,$EA,$A8,$00,$C3,$33,$FF,$FF,$D5,$55,$5F,$FF,$FF,$F5,$FC,$FF,$66,$6A,$60,$0A,$AB,$84,$51,$15,$7D,$55,$66  ; row  9
    DB $FF,$FD,$7F,$FE,$FB,$BA,$AA,$80,$0C,$33,$CF,$3C,$D5,$55,$55,$44,$EE,$EF,$FD,$55,$FC,$D5,$96,$90,$00,$AA,$90,$11,$51,$7F,$56,$55  ; row 10
    DB $CC,$55,$FF,$EF,$BB,$AE,$BA,$00,$C3,$3C,$FF,$F5,$55,$51,$10,$44,$46,$FA,$EF,$55,$57,$D9,$65,$9B,$00,$2A,$84,$44,$45,$3F,$D5,$65  ; row 11
    DB $D5,$55,$FF,$FB,$BA,$EA,$A8,$00,$19,$99,$55,$FF,$EE,$E4,$44,$11,$04,$AE,$EA,$C4,$55,$75,$59,$9B,$30,$0A,$C0,$11,$11,$7F,$D5,$56  ; row 12
    DB $59,$57,$FF,$BE,$EE,$AE,$80,$A6,$66,$55,$5F,$FE,$FB,$AE,$A8,$00,$00,$4A,$BB,$B1,$45,$5D,$55,$64,$CC,$00,$81,$04,$45,$3F,$F5,$65  ; row 13
    DB $55,$5F,$FE,$EE,$EB,$AA,$AA,$99,$95,$55,$FF,$EE,$EA,$EA,$AA,$0A,$AA,$82,$AA,$AC,$11,$17,$D6,$5B,$03,$00,$00,$10,$44,$7B,$FD,$55  ; row 14
    DB $56,$7F,$FF,$EE,$EA,$12,$AA,$69,$99,$97,$FF,$BB,$AE,$A8,$00,$00,$AA,$AA,$8A,$EA,$44,$53,$F5,$55,$F3,$30,$20,$01,$11,$3F,$BF,$55  ; row 15
    DB $55,$7F,$EE,$EE,$91,$02,$A6,$99,$55,$7F,$FB,$B8,$08,$00,$00,$CC,$C6,$66,$A0,$0A,$81,$15,$FF,$59,$33,$0C,$20,$10,$11,$EF,$FF,$55  ; row 16
    DB $55,$FF,$FE,$EC,$40,$0A,$A9,$96,$65,$F5,$11,$00,$2A,$A6,$5C,$CF,$F3,$66,$64,$00,$84,$00,$EF,$D5,$CC,$C0,$E8,$01,$04,$EE,$FF,$D5  ; row 17
    DB $55,$FF,$BB,$90,$00,$2A,$66,$65,$5D,$51,$10,$02,$AA,$65,$95,$5F,$3F,$F5,$66,$CC,$00,$11,$BF,$F5,$FC,$CC,$2A,$00,$41,$BF,$BF,$D5  ; row 18
    DB $57,$FF,$ED,$11,$10,$AA,$99,$9C,$F5,$54,$41,$2A,$A5,$95,$5F,$FF,$D5,$55,$55,$C0,$0A,$01,$BB,$BD,$CF,$33,$2A,$80,$11,$BB,$EF,$F5  ; row 19
    DB $57,$FE,$D1,$04,$00,$A9,$A4,$FF,$D5,$11,$00,$A8,$CF,$FD,$7F,$EE,$B9,$15,$F5,$7F,$CA,$80,$EE,$FF,$FF,$CC,$66,$80,$03,$BB,$BF,$F5  ; row 20
    DB $5F,$FD,$11,$10,$02,$AA,$4F,$3F,$55,$10,$18,$0C,$FC,$55,$44,$0B,$AA,$41,$3F,$D3,$3E,$A0,$2E,$FF,$7C,$F3,$AA,$A0,$46,$BB,$FB,$FD  ; row 21
    DB $5F,$D1,$44,$40,$42,$A4,$CC,$FD,$51,$1B,$A0,$CF,$3D,$50,$00,$2A,$80,$80,$4F,$FF,$CE,$68,$2B,$AD,$5F,$CC,$66,$A0,$0B,$BB,$BF,$BD  ; row 22
    DB $5D,$44,$44,$04,$0A,$83,$33,$FD,$56,$EA,$83,$33,$FF,$AE,$80,$A9,$90,$02,$0A,$E5,$FE,$6A,$AE,$F9,$5F,$F1,$9A,$A8,$0A,$EE,$EF,$FF  ; row 23
    DB $75,$55,$11,$10,$08,$33,$3F,$F5,$7B,$AA,$03,$15,$FB,$A8,$03,$FF,$55,$F1,$A2,$BD,$7D,$9A,$2A,$B9,$17,$CD,$A6,$68,$2E,$AE,$FB,$FD  ; row 24
    DB $D4,$51,$44,$00,$20,$30,$CC,$F7,$EE,$E8,$06,$57,$FA,$AA,$55,$D5,$5F,$FC,$68,$A9,$1D,$99,$0A,$E4,$57,$FE,$5A,$AA,$2B,$BB,$BE,$F1  ; row 25
    DB $D5,$44,$44,$44,$80,$CC,$FF,$FF,$EE,$A8,$99,$5F,$90,$A5,$7F,$AA,$02,$B5,$58,$29,$55,$66,$0A,$A5,$55,$F5,$A6,$6A,$AA,$BB,$BB,$D5  ; row 26
    DB $D4,$54,$44,$02,$80,$0C,$CF,$7F,$BB,$AA,$A6,$75,$02,$93,$50,$AB,$3A,$21,$57,$08,$17,$5B,$02,$E0,$45,$D9,$66,$AA,$AB,$AE,$EF,$95  ; row 27
    DB $45,$45,$10,$6A,$80,$CC,$F6,$7F,$BA,$0A,$65,$D4,$48,$3D,$20,$F7,$F5,$40,$37,$08,$1B,$54,$C2,$85,$15,$D6,$59,$98,$AA,$EB,$BF,$55  ; row 28
    DB $55,$51,$11,$AA,$00,$C3,$15,$FE,$EC,$0A,$97,$54,$20,$FE,$C5,$E8,$48,$FE,$3F,$F8,$1F,$D3,$02,$01,$15,$D5,$9A,$60,$2A,$BB,$B9,$14  ; row 29
    DB $54,$51,$12,$BA,$00,$33,$65,$FF,$B0,$6A,$4C,$53,$83,$7E,$95,$2E,$85,$9E,$AD,$CA,$2E,$DC,$C0,$11,$13,$D5,$99,$80,$2B,$AE,$E5,$55  ; row 30
    DB $55,$45,$1B,$AA,$03,$31,$95,$FB,$C4,$29,$3F,$5B,$81,$74,$B6,$28,$03,$C5,$21,$DA,$BB,$FC,$C2,$01,$1F,$D6,$59,$0C,$2A,$AE,$C4,$45  ; row 31
    DB $45,$14,$6E,$AE,$00,$39,$55,$FE,$40,$28,$CF,$7A,$A9,$90,$3C,$EC,$0A,$0F,$05,$66,$AF,$7C,$C6,$01,$3F,$D5,$64,$C0,$2A,$EB,$15,$55  ; row 32
    DB $55,$51,$BA,$EA,$03,$26,$65,$FD,$11,$20,$CF,$FE,$A9,$D2,$14,$3C,$0B,$E7,$83,$50,$B9,$7C,$EA,$04,$EF,$D6,$6C,$00,$2A,$B9,$11,$15  ; row 33
    DB $54,$47,$BB,$AA,$00,$66,$55,$F4,$44,$03,$3D,$FB,$2B,$DE,$AD,$94,$AD,$16,$AF,$40,$A5,$7C,$6A,$03,$BF,$D5,$4C,$CC,$2A,$E1,$11,$51  ; row 34
    DB $55,$5B,$BA,$AA,$02,$99,$99,$D5,$10,$20,$31,$FC,$08,$FF,$2F,$C8,$8A,$D4,$AF,$CE,$11,$76,$98,$1B,$EF,$D6,$CC,$00,$2A,$91,$14,$55  ; row 35
    DB $45,$3E,$EE,$EE,$89,$A6,$55,$D4,$44,$A0,$C5,$7D,$08,$37,$00,$57,$B7,$C2,$5F,$08,$45,$D9,$A8,$2E,$FF,$57,$CC,$C0,$AB,$04,$45,$45  ; row 36
    DB $D5,$FB,$BA,$AA,$AA,$66,$65,$D5,$46,$E0,$39,$74,$48,$35,$52,$2B,$3A,$81,$3E,$60,$57,$56,$6A,$BB,$BB,$7C,$CC,$0C,$A0,$11,$11,$55  ; row 37
    DB $D5,$BF,$BB,$BA,$AA,$A6,$54,$D5,$13,$A8,$26,$55,$4E,$09,$57,$A0,$2A,$BF,$66,$81,$BD,$66,$8A,$AE,$FF,$FF,$33,$00,$81,$04,$54,$55  ; row 38
    DB $D7,$FB,$BB,$AA,$2A,$69,$93,$F5,$52,$A8,$19,$9D,$4A,$8A,$7F,$FD,$55,$D5,$9A,$AE,$F5,$6B,$0A,$EF,$B7,$F3,$30,$32,$00,$41,$05,$45  ; row 39
    DB $DE,$FE,$FA,$EE,$0A,$99,$9F,$F5,$1F,$BA,$29,$9F,$5F,$A2,$A3,$D5,$7F,$CC,$0A,$EF,$D5,$30,$2A,$EE,$57,$FC,$CC,$08,$04,$11,$51,$57  ; row 40
    DB $FF,$EF,$BB,$A8,$0A,$A9,$93,$FD,$5B,$AA,$AA,$6F,$D6,$E8,$20,$01,$9A,$80,$AB,$BF,$FC,$C0,$AB,$B1,$5F,$CC,$C3,$A8,$01,$11,$15,$1D  ; row 41
    DB $DF,$FE,$FB,$B9,$02,$9A,$4C,$FD,$5E,$FB,$0A,$93,$FF,$FC,$40,$80,$AA,$00,$11,$5F,$F3,$02,$AC,$45,$5F,$F3,$3A,$A0,$00,$44,$45,$FD  ; row 42
    DB $DF,$EF,$BB,$A4,$02,$A9,$8F,$3F,$7F,$BA,$02,$AC,$3D,$FF,$10,$2A,$A8,$04,$55,$7F,$30,$08,$01,$15,$7F,$33,$AA,$A0,$11,$11,$5B,$FD  ; row 43
    DB $57,$FF,$EE,$E0,$40,$AA,$43,$CF,$FE,$EF,$80,$AB,$33,$57,$D5,$5F,$BF,$FB,$5F,$FC,$CA,$80,$14,$55,$FF,$39,$9A,$40,$04,$11,$BF,$F5  ; row 44
    DB $57,$FB,$FB,$94,$00,$AA,$33,$3C,$DF,$FB,$90,$28,$0C,$D5,$55,$45,$FE,$FD,$55,$66,$AA,$01,$11,$57,$FE,$66,$AA,$80,$41,$1E,$FF,$F5  ; row 45
    DB $55,$FF,$BE,$C1,$04,$29,$0C,$CF,$D7,$FE,$C4,$00,$30,$26,$57,$FF,$FD,$55,$66,$9A,$A0,$01,$15,$5D,$59,$9A,$6A,$00,$11,$BB,$EF,$D5  ; row 46
    DB $55,$FF,$EF,$90,$40,$0A,$03,$33,$D5,$FF,$91,$00,$80,$C9,$99,$B3,$F3,$32,$69,$AA,$00,$11,$47,$D5,$65,$9A,$A8,$01,$0E,$EF,$FF,$D5  ; row 47
    DB $55,$7E,$FB,$C4,$40,$02,$30,$33,$15,$7F,$D1,$44,$A8,$02,$A6,$64,$33,$0C,$00,$08,$0B,$BE,$FF,$55,$66,$A6,$A0,$01,$BB,$BE,$FF,$55  ; row 48
    DB $55,$7F,$FE,$51,$11,$02,$03,$0C,$E6,$57,$B4,$44,$6A,$A8,$AA,$AA,$40,$00,$0A,$AA,$EE,$EF,$F5,$56,$66,$6A,$A0,$2E,$BB,$EF,$FB,$55  ; row 49
    DB $59,$5F,$FF,$11,$04,$00,$00,$C3,$39,$55,$F5,$51,$1B,$AA,$A0,$AA,$A8,$2A,$AA,$AE,$EF,$FF,$D5,$59,$9A,$AA,$AA,$BB,$BB,$FF,$BD,$55  ; row 50
    DB $55,$57,$EF,$44,$41,$10,$80,$0C,$C5,$95,$5D,$45,$46,$EE,$A8,$00,$00,$0A,$AB,$BB,$BE,$FD,$55,$99,$A6,$40,$AA,$AB,$BE,$EF,$F5,$55  ; row 51
    DB $65,$55,$FE,$55,$14,$00,$A8,$00,$39,$99,$57,$55,$15,$BB,$BB,$90,$44,$11,$16,$FF,$FF,$D5,$56,$66,$C0,$0A,$AB,$BB,$BB,$FF,$D5,$65  ; row 52
    DB $56,$55,$FF,$44,$44,$44,$EA,$0C,$09,$96,$65,$F5,$54,$7E,$FB,$B1,$11,$11,$45,$11,$57,$FF,$CC,$CC,$00,$2A,$AA,$EE,$FE,$FF,$D5,$73  ; row 53
    DB $65,$95,$7F,$55,$44,$41,$AA,$80,$CE,$A6,$56,$FF,$D5,$5F,$EF,$EF,$C5,$54,$55,$55,$FF,$FC,$CC,$C0,$C0,$AA,$BB,$BB,$BF,$FB,$5F,$3F  ; row 54
    DB $59,$59,$5F,$51,$45,$10,$BA,$A8,$02,$66,$99,$4F,$FF,$D7,$FF,$FE,$FC,$55,$55,$FF,$FF,$33,$30,$0C,$0A,$AA,$EE,$EF,$EF,$BF,$FF,$CC  ; row 55
    DB $65,$95,$57,$55,$14,$45,$2B,$AA,$00,$A9,$99,$9C,$FF,$FF,$55,$FF,$FF,$DF,$FF,$FF,$CC,$CC,$0C,$C0,$2A,$AE,$BB,$BE,$FD,$5F,$F3,$F3  ; row 56
    DB $66,$59,$55,$55,$51,$44,$6E,$AA,$A0,$9A,$A6,$6B,$33,$3F,$F5,$55,$55,$55,$7F,$CC,$CC,$C3,$30,$02,$AA,$BB,$BB,$ED,$55,$7F,$FC,$CF  ; row 57
    DB $65,$95,$95,$D5,$15,$14,$6B,$BA,$AA,$2A,$6A,$99,$33,$CC,$F1,$55,$95,$95,$99,$93,$33,$30,$00,$2A,$AB,$AB,$B1,$14,$55,$FF,$33,$CC  ; row 58
    DB $66,$66,$55,$FD,$55,$45,$3E,$EE,$EA,$8A,$A9,$A9,$8C,$33,$3C,$E9,$66,$66,$66,$66,$AA,$AA,$02,$A8,$44,$44,$45,$55,$5F,$FF,$FC,$CC  ; row 59
    DB $66,$65,$66,$FF,$54,$54,$4E,$BA,$BA,$A0,$2A,$AA,$63,$33,$0C,$CE,$66,$66,$66,$9A,$66,$AA,$00,$00,$10,$45,$14,$55,$7F,$F3,$33,$33  ; row 60
    DB $69,$99,$95,$FF,$D5,$55,$5B,$EE,$EB,$A8,$02,$A6,$A8,$00,$C0,$30,$3A,$6A,$A9,$AA,$AA,$A0,$00,$11,$04,$51,$55,$45,$FF,$FF,$3C,$CC  ; row 61
    DB $99,$99,$66,$FF,$FD,$51,$16,$EE,$EE,$B9,$00,$02,$AA,$C0,$0C,$0C,$0C,$A6,$6A,$AA,$A0,$00,$01,$04,$51,$14,$45,$5F,$FF,$CC,$CC,$C3  ; row 62
    DB $6A,$66,$65,$B3,$FF,$55,$57,$FB,$BB,$BA,$10,$00,$02,$A0,$00,$C0,$C0,$02,$AA,$A0,$00,$00,$10,$44,$45,$45,$55,$7F,$FC,$F3,$CC,$CC  ; row 63
; ==============================================================
; ROLTAB - 256-entry colour rotation lookup table
; Placed at $8900 (page-aligned) for fast indexed lookup.
;
; ROLTAB[b] = byte b with every 2-bit pixel field incremented
; by 1 modulo 4:  00->01->10->11->00  (green->yellow->blue->red)
;
; Usage in RotLoop:
;   LD D,$89       ; D = ROLTAB page (set once before loop)
;   LD A,(HL)      ; read VRAM byte
;   LD E,A         ; byte value becomes low address byte
;   LD A,(DE)      ; fetch ROLTAB[byte] in one instruction
;   LD (HL),A      ; write back
;
; Applying ROLTAB once:  green->yellow->blue->red (zoom step +1)
; Applying ROLTAB twice: green->blue, yellow->red  (step +2)
; Applying ROLTAB four times: identity (full cycle complete)
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
; End of file

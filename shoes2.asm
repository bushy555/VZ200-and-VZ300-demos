; -------------------- putScaledSprite --------------------
; Draws a scaled sprite to the graph buffer.
;
; Version: 1.1
; Author: Badja <http://move.to/badja> <badja@alphalink.com.au>
; Date: 21 December 1999
;
; Modified by Eric Piel : LD and smaller and quicker < Eric.Piel@etu.utc.fr >
; Date: 19 May 2000
; Size: 156 bytes (161 bytes if XORing the sprite, 151 bytes if just Loading it)
;
; Input:
;   HL -> sprite
;    D = x-coordinate
;    E = y-coordinate
;    B = height of unscaled sprite
;    C = width of unscaled sprite (in bytes, so divide by 8)
;    A = scale factor ($01 to $00 <=> 0.4% to 100%)
;        eg: $80 is 50%
;
; Output:
;   The sprite is ORed to the graph buffer. To XOR the sprite
;   instead, add the following line near the top of your program:
;   #define _SS_XOR
;   To just load it insert:
;   #define _SS_LD
;
; Destroys:
;   AF, BC, DE, HL

;;   nyan_pic:
;;   mario64



        ORG    8000h

SPR_HEIGHT EQU 50		; symbolic constants
SPR_WIDTH  EQU 88
GRAFX_MEM_BUFFER	EQU	$B000
GRAFX_MEM_VIDEO		EQU	$7000
VIDEO_OFFSET		EQU	12 + 128 + 128

intro:	di
	ld 	a,8				; mode (1)
	ld 	($6800),a


	ld 	hl, GRAFX_MEM_VIDEO		; CLS VIDEO
	ld 	(hl), 0
	ld 	de, GRAFX_MEM_VIDEO + 1
	ld 	bc, 2048
	ldir
	ld 	hl, GRAFX_MEM_BUFFER		; CLS BUFFER
	ld 	(hl), 0
	ld 	de, GRAFX_MEM_BUFFER + 1
	ld 	bc, 2048
	ldir

aniloop:
	ld	a,  $04		; initial scale factor
	ld	bc, 64		; number of frames
gobig:	push	bc
	ld 	hl, GRAFX_MEM_BUFFER		; CLS BUFFER
	ld 	(hl), 0
	ld 	de, GRAFX_MEM_BUFFER + 1
	ld 	bc, 2048
	ldir
	push	af
	ld	d, 0
	ld	e, 0
	ld	b, SPR_HEIGHT
	ld	c, SPR_WIDTH/8
	ld	hl, picShoes
	call	putScaledSprite

	ld	hl, GRAFX_MEM_BUFFER		; MOVE BUFFER to VIDEO
	ld 	de, GRAFX_MEM_VIDEO
	ld	bc, 1024
	ldir
	ld	hl, GRAFX_MEM_BUFFER+1024	; MOVE BUFFER to VIDEO
	ld 	de, GRAFX_MEM_VIDEO+1024
	ld	bc, 1024
	ldir
	pop	af
	add	a, $02		; increase scale factor
	pop	bc
	djnz	gobig		; display next frame


	ld	a, $FF - $02		; initial scale factor
	ld	bc, 64		; number of frames
gosmall:push	bc
	ld 	hl, GRAFX_MEM_BUFFER		; CLS BUFFER
	ld 	(hl), 0
	ld 	de, GRAFX_MEM_BUFFER + 1
	ld 	bc, 2048
	ldir
	push	af
	ld	d, 0
	ld	e, 0
	ld	b, SPR_HEIGHT
	ld	c, SPR_WIDTH/8
	ld	hl, picShoes
	call	putScaledSprite
	ld	hl, GRAFX_MEM_BUFFER		; MOVE BUFFER to VIDEO
	ld 	de, GRAFX_MEM_VIDEO
	ld	bc, 1024
	ldir
	ld	hl, GRAFX_MEM_BUFFER+1024	; MOVE BUFFER to VIDEO
	ld 	de, GRAFX_MEM_VIDEO+1024
	ld	bc, 1024
	ldir
	pop	af
	add	a, $FF - $02		; increase scale factor
	pop	bc
	djnz	gosmall		; display next frame


	jr	aniloop


putScaledSprite:
	ld	(SS_SetScale1), a
	ld	(SS_SetScale2), a
	ld	a,d
	push	hl
	ld	d,0
	ld	h,d
	ld	l,e
	add	hl,de
	add	hl,de
	add	hl,hl
	add	hl,hl
	ld	de, GRAFX_MEM_BUFFER + VIDEO_OFFSET	;plotscreen to BUFFER
	add	hl,de
	ld	d,0
	ld	e,a
	srl	e
	srl	e
	srl	e
	add	hl,de
	and	%00000111
	ld	(SS_SetPreShift),a
	neg
	add	a,8
	ld	(SS_SetBitsLeft),a
	ex	de,hl
	ld	a,c
	ld	(SS_SetByteWidth),a
	sla	a
	sla	a
	sla	a
	ld	(SS_SetPixelWidth),a
	pop	hl
	ld	c,0
	push	bc
	jr	SS_DoRow
SS_SpriteLoop:
SS_SetScale1 equ $ + 1
	ld	a,0		; scale factor (self-modified)
	add	a,c
	ld	c,a
	push	bc
	jr	z,SS_DoRow
	jr	c,SS_DoRow
SS_SetByteWidth equ $ + 1
	ld	bc,$0000	; C equ byte width of sprite data (self-modified)
	add	hl,bc
	jr	SS_SkipRow
SS_DoRow:
	push	de

SS_SetPreShift equ $ + 2
	ld	bc,$0000	; B equ # bits before start of row (self-modified)
	ld	a,b
	or	a
	jr	z,SS_PutBitsLeft
	ld	a,(de)
SS_PreShift:
	rlca
	djnz	SS_PreShift
	ld	(de),a
SS_PutBitsLeft:
SS_SetBitsLeft equ $ + 1
	ld	b,$00		; # bits to copy into first byte (self-modified)
SS_SetPixelWidth equ $ + 1
	ld	a,$00		; pixel width of sprite data (self-modified)
	push	af
	jr	SS_DoPixel
SS_RowLoop:
	and	%00000111
	jr	nz,SS_SameByte
	inc	hl
SS_SameByte:
SS_SetScale2 equ $ + 1
	ld	a,0		; scale factor (self-modified)
	add	a,c
	ld	c,a
	jr	z,SS_DoPixel
	jr	nc,SS_SkipPixel
SS_DoPixel:
	ld	a,(de)
	rlc	(hl)
;#ifndef SS_LD
;	jr	nc,SS_LeaveBit
;#ifdef SS_XOR
;	bit	7,a
;	jr	z,SS_LeaveCarry
;	ccf
;SS_LeaveCarry:
;#endif
;#endif
	rla
;#ifndef SS_LD
;	jr	SS_DoneBit
;SS_LeaveBit:
;	rlca
;SS_DoneBit:
;#endif
	ld	(de),a
	djnz	SS_DoneByte
	ld	b,8
	inc	de
	jr	SS_DoneByte
SS_SkipPixel:
	rlc	(hl)
SS_DoneByte:
	pop	af
	dec	a
	push	af
	jr	nz,SS_RowLoop
SS_DoneRow:
	inc	hl
	bit	3,b
	jr	nz,SS_RowComplete
	ld	a,(de)
SS_PostShift:
	rlca
	djnz	SS_PostShift
	ld	(de),a
	inc	de
SS_RowComplete:
	pop	af
	ex	(sp),hl
;	ld	de,12		; spectrum
	ld	de,32		; VZ.. SHOES.
	add	hl,de
	ex	de,hl
	pop	hl
SS_SkipRow:
	pop	bc
	djnz	SS_SpriteLoop
	ret






picShoes:
 defb  %00000000,%00000000,%00000000,%00000000,%00000000,%01110000,%01111111,%11100000,%00000000,%00000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000001,%10011111,%11111111,%11111111,%11000000,%00000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000011,%11101111,%11111111,%11111111,%00100000,%00000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000011,%11110111,%11111101,%01011111,%11100000,%00000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000011,%11111111,%11101010,%10101111,%11100000,%00000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000001,%11111111,%11010101,%01011111,%11111000,%00000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000001,%11111111,%11111010,%10111100,%00000111,%10000000,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000011,%10000000,%00000111,%11100001,%00111000,%01110000,%00000000
 defb  %00000000,%00000000,%00000000,%00000111,%11011100,%00011111,%11111100,%00001111,%11111111,%10001000,%00000000
 defb  %00000000,%00000000,%00000000,%00011111,%00110011,%11111110,%00000011,%11111111,%11110000,%01110100,%00000000
 defb  %00000000,%00000000,%00000000,%00101010,%11100111,%11111100,%01111100,%00111111,%11110000,%00001100,%00000000
 defb  %00000000,%00000000,%00000000,%01110101,%11001111,%11111111,%11000011,%10001111,%11110000,%00001110,%00000000
 defb  %00000000,%00000000,%00000000,%11111011,%10011111,%11111111,%10001111,%11100011,%11110000,%00000110,%00000000
 defb  %00000000,%00000000,%00000000,%11110101,%10111101,%11111110,%00011110,%10111001,%11110000,%00000110,%00000000
 defb  %00000000,%00000000,%00000001,%11101011,%10111101,%11111110,%00111011,%01111000,%11110000,%00000000,%00000000
 defb  %00000000,%00000000,%00001110,%11110101,%10111010,%11111111,%11111111,%10111100,%11111000,%00000000,%00000000
 defb  %00000000,%00000000,%00110001,%10101011,%11111100,%11111111,%11111000,%00001111,%11111000,%00000000,%00000000
 defb  %00000000,%00000000,%01000011,%11110000,%11111010,%01111111,%11000010,%00111111,%11111000,%00000000,%00000000
 defb  %00000000,%00000000,%10000011,%10000011,%11111100,%01111110,%00011111,%00000001,%11111000,%00000000,%00000000
 defb  %00000000,%00000000,%10000011,%11111100,%01111110,%01111110,%00111101,%10111000,%11111100,%00000000,%00000000
 defb  %00000000,%00000000,%00000111,%00010011,%00111100,%11111111,%11111011,%00011111,%11111100,%00000000,%00000000
 defb  %00000000,%00000000,%00000110,%11001111,%10011110,%11111111,%11111100,%00111111,%11111100,%00000000,%00000000
 defb  %00000000,%00000000,%00001111,%00010011,%11011100,%11111111,%11000001,%11100111,%11111100,%00000000,%00000000
 defb  %00000000,%00000000,%00001100,%11111001,%11011111,%11111111,%00001110,%10101000,%11111100,%00000000,%00000000
 defb  %00000000,%00000000,%00011000,%00001111,%11011101,%11111111,%11111111,%11100111,%00111100,%00000000,%00000000
 defb  %00000000,%00000000,%00111111,%11100111,%11111011,%11111111,%11111100,%00001011,%11111110,%00000000,%00000000
 defb  %00000000,%00000000,%00100000,%11111111,%11110011,%11111111,%11100000,%11110101,%11111111,%00000000,%00000000
 defb  %00000000,%00000000,%11111100,%00011111,%11111011,%11111111,%10001111,%01000000,%00011111,%00000000,%00000000
 defb  %00000000,%00000111,%10000011,%11001111,%11110011,%11111111,%10011111,%11100011,%11100111,%10000000,%00000000
 defb  %00000000,%00011110,%01111100,%01111111,%11111011,%11111111,%11111111,%00000011,%10110011,%11000000,%00000000
 defb  %00000000,%01111000,%00000111,%11111111,%11110011,%11111111,%11111000,%01110101,%00011111,%11100000,%00000000
 defb  %00000011,%11000101,%01111011,%11111111,%11111001,%11111111,%11100111,%11101101,%11101111,%11111000,%00000000
 defb  %00000111,%11111111,%11111111,%11111111,%11111101,%11111111,%11001111,%11010000,%00000000,%11111110,%00000000
 defb  %00011000,%00000000,%01111111,%11111111,%11111001,%11111111,%11111110,%00000101,%11111110,%00111111,%00000000
 defb  %00111111,%11111111,%10001111,%11111111,%11111101,%11111111,%11111000,%01111110,%10101001,%10011111,%10000000
 defb  %00101001,%00100100,%11110000,%11111111,%11111001,%11111111,%11111111,%11111111,%11111111,%11111111,%11100000
 defb  %01010010,%01000100,%10011110,%01111111,%11111101,%11111111,%11111111,%11111111,%11000000,%00000111,%11110000
 defb  %01010010,%01000100,%10010111,%00111111,%11111001,%11111111,%11111110,%00000000,%00000000,%00000000,%01111000
 defb  %01001111,%11111111,%11100100,%10010101,%01010011,%11111111,%11000000,%00000000,%00011111,%11111100,%00011000
 defb  %00111111,%11111111,%11111001,%00101010,%10101011,%11111111,%10000000,%00000111,%11110100,%00100011,%11001100
 defb  %00000111,%11111111,%11111111,%11111111,%11110111,%11111111,%00001111,%11111100,%01000010,%00010001,%00111100
 defb  %00000000,%00000000,%00000000,%00000000,%00000111,%11111101,%11101000,%10001000,%10000010,%00001000,%10010100
 defb  %00000000,%00000000,%00000000,%00000000,%00000100,%00001110,%10001001,%00010000,%10000010,%00001000,%10001010
 defb  %00000000,%00000000,%00000000,%00000000,%00000100,%00001001,%00010001,%00010000,%10000010,%00010000,%10001010
 defb  %00000000,%00000000,%00000000,%00000000,%00000110,%00001000,%10010001,%00010000,%01000010,%11111111,%00010100
 defb  %00000000,%00000000,%00000000,%00000000,%00000001,%11101000,%10001000,%10001000,%11111111,%11111111,%11111000
 defb  %00000000,%00000000,%00000000,%00000000,%00000000,%00100100,%01000100,%01011111,%11111111,%11111111,%11110000
 defb  %00000000,%00000000,%00000000,%00000000,%00000000,%00010010,%00100111,%11111111,%11111111,%11111111,%11100000
 defb  %00000000,%00000000,%00000000,%00000000,%00000000,%00011111,%11111111,%11111111,%11111111,%11111111,%00000000
 defb  %00000000,%00000000,%00000000,%00000000,%00000000,%00000011,%11111111,%11111111,%11111111,%11110000,%00000000



.END

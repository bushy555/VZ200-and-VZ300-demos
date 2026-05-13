
video		equ	$7000

		org	$8000

;		ld	sp, $7FFF		; set stack safely away from scratch vars at $7800
		ld	a, 24
		ld	($6800), a
		di

; -- scroll state --------------------------------------------------------------
;
; 2bpp picture: 4 pixels/byte, 96 bytes/row, 64 rows  (384x64 pixels)
; Video RAM:    2bpp, 32 bytes/row, 64 rows            (128x64 pixels)
;
; One pixel = 2 bits.  Both RL passes done per row to avoid colour flicker.
;
; src_byte_col : source byte column being fed (0..95)
; src_bit_mask : mask for HIGH bit of current source pixel
;                sequence: $80 $20 $08 $02 (steps by 2 each pixel)
;                wrap $02->$80: advance src_byte_col
; carry_hi     : saved carry for pass1 (high bit of new pixel)
; carry_lo     : saved carry for pass2 (low  bit of new pixel)
;
; Both carry values are stored as 0 or 1 in RAM.
; Restored via: LD A,(carry_xx) / RRCA  -> carry = bit0 of A

src_byte_col	equ	$7800
src_bit_mask	equ	$7801
carry_hi	equ	$7802
carry_lo	equ	$7803

; -- intro: copy columns 0..31 of each source row into video RAM ---------------

intro:
		ld	b, 64
		ld	hl, picture
		ld	de, video
intro_row:
		push	bc
		ld	bc, 32
		ldir
		ld	bc, 64
		add	hl, bc			; skip remaining 64 source bytes
		pop	bc
		djnz	intro_row

		ld	a, 32
		ld	(src_byte_col), a
		ld	a, $80
		ld	(src_bit_mask), a

		call	delay_long


; -- main scroll loop ----------------------------------------------------------
; Each iteration = 1 pixel scrolled left.
; For each of 64 rows:
;   1. Fetch source byte for this row
;   2. Extract high bit of new pixel -> save to carry_hi
;   3. Extract low  bit of new pixel -> save to carry_lo
;   4. RL chain x32 using carry_hi  (pass 1)
;   5. RL chain x32 using carry_lo  (pass 2)
; Then advance src_bit_mask by 2 (next pixel's high bit position).

here1:
		ld	b, 64			; row counter

do_row:
		; -- row index ------------------------------------------------
		ld	a, 64
		sub	b			; A = row index (0..63)
		push	bc			; save row counter (B), don't care about C

		; -- source address: picture + row*96 + src_byte_col ----------
		ld	l, a
		ld	h, 0
		add	hl, hl			; *2
		add	hl, hl			; *4
		add	hl, hl			; *8
		add	hl, hl			; *16
		add	hl, hl			; *32
		ld	d, h
		ld	e, l			; DE = row*32
		add	hl, hl			; *64
		add	hl, de			; *96
		ld	de, picture
		add	hl, de			; picture + row*96
		ld	a, (src_byte_col)
		ld	e, a
		ld	d, 0
		add	hl, de			; picture + row*96 + src_byte_col
		ld	a, (hl)			; source byte for this row

		; -- extract high bit and low bit, save both to RAM -----------
		ld	c, a			; C = source byte (safe: not pushed, not popped)

		ld	a, (src_bit_mask)	; high bit mask
		and	c			; test high bit
		scf
		jr	nz, hi_set
		ccf
hi_set:		ld	a, 0
		jr	nc, hi_zero
		ld	a, 1
hi_zero:	ld	(carry_hi), a		; save: 0 or 1

		ld	a, (src_bit_mask)
		rrca				; shift mask right 1 -> low bit mask
		and	c			; test low bit
		scf
		jr	nz, lo_set
		ccf
lo_set:		ld	a, 0
		jr	nc, lo_zero
		ld	a, 1
lo_zero:	ld	(carry_lo), a		; save: 0 or 1

		; -- video address: video + row*32 ----------------------------
		; Recover row index: pop saved counter, recompute, push back
		pop	bc			; B = row counter
		push	bc
		ld	a, 64
		sub	b			; A = row index again
		ld	l, a
		ld	h, 0
		add	hl, hl
		add	hl, hl
		add	hl, hl
		add	hl, hl
		add	hl, hl			; HL = row*32
		ld	de, video
		add	hl, de			; HL = video + row*32

		; point to byte 31
		ld	a, l
		add	a, 31
		ld	l, a

		; -- PASS 1: feed high bit, RL chain byte31..byte0 ------------
		ld	a, (carry_hi)
		rrca				; carry = high bit

		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)			; byte 0

		; -- PASS 2: feed low bit, RL chain byte31..byte0 -------------
		; HL is now at byte 0. Reset to byte 31.
		ld	a, l
		add	a, 31
		ld	l, a

		ld	a, (carry_lo)
		rrca				; carry = low bit

		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)
		dec	l
		rl	(hl)			; byte 0

		; -- next row -------------------------------------------------
		pop	bc			; restore row counter
		dec	b
		jr	nz, dr_near
		jr	dr_done
dr_near:	jp	do_row

dr_done:
		; -- advance src_bit_mask by 2 positions (to next pixel's high bit)
		; sequence: $80->$20->$08->$02->$80 (wrap advances src_byte_col)
		ld	a, (src_bit_mask)
		rrca				; step 1: high bit -> low bit position
		rrca				; step 2: low bit -> next high bit position
		ld	(src_bit_mask), a
		cp	$80			; wrapped = consumed all 4 pixels of byte
		jr	nz, no_byte_adv
		ld	a, (src_byte_col)
		inc	a
		cp	96
		jr	nz, no_col_wrap
		xor	a
no_col_wrap:	ld	(src_byte_col), a
no_byte_adv:

		jp	here1


; -- delay_long ---------------------------------------------------------------
delay_long:
		push	bc
		push	hl
		push	de
		ld	bc, $ffff
delayb:		dec	bc
		ld	a, b
		or	c
		jr	nz, delayb
		pop	de
		pop	hl
		pop	bc
		ret


; -- picture data -------------------------------------------------------------
; VZ200 MC6847 Scrolling Landscape - 384x64 pixels
; CSS1: %00=BUFF  %01=CYAN  %10=MAGENTA  %11=ORANGE
; v8: Horizon band (row 36) replicated across all 3 sections
; 2 bits/pixel, 96 bytes/row x 64 rows = 6144 bytes

; ---- past


 include z0.inc


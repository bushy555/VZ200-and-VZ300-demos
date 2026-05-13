;	Fire routine - optimized for VZ200
;	Original: http://z80-heaven.wikidot.com/forum/t-675609/fire-animation-tutorial
;
;
;	3/5/26:	Originally hand written by me from the above and with the original fire tutorial routine 
;	written by some famous dude that I forget his name, on the newsgroups back in the turbo pascal
;	demo days (1994/1995 era). He had a brilliant 386 code routine, originally written in turbo pascal
;	and he slowly changed it into asm throughout his tutorial.  Alt.comp.pc.demos or something.
;	Anyway, I spent near on months on the things - heaps of years ago and finally got something working
;	in mode(0), then lots of time later in mode(1). But it was dead set slow, like really slow. But it worked.
;	Fast forward to 2026 and I gave it to claude, and claude said it was crap and gave the optimised version below.
;	My version was probably 2kb. This is 288 bytes.
;
;	anyway, cant really do too much with four colours eh.
;
;
;
;	www.claude.au says:
;
;	=======================================================================
;	OPTIMIZATIONS  (net saving: ~22 T-states per byte, ~15% faster loop)
;	=======================================================================
;
;	1. PAGE-ALIGNED TABLE  — saves ~23 T-states/byte
;	   ------------------------------------------------
;	   The pixel-mask table is placed at a $xx00 boundary so its high byte
;	   is a compile-time constant. Before the loop: ld h, table >> 8
;	   and H never changes during the lookup. In the loop:
;
;	   Original:  ld hl, table   ; 10
;	              add a, l       ;  4
;	              ld l, a        ;  4
;	              jr nc, $+3     ; 12 (taken) / 7 (not taken) avg ~9
;	              inc h          ;  4 (sometimes)
;	                             ; = ~27 T-states
;
;	   Optimized: ld l, a        ;  4   (H already = table>>8)
;	                             ; =  4 T-states
;
;	2. IX AS READ-AHEAD POINTER  — saves ~9 T-states/byte
;	   ---------------------------------------------------
;	   Original recomputed the source pointer every iteration:
;	     ld hl, 32   ; 10
;	     add hl, de  ; 11
;	     or  (hl)    ;  7   = 28 T-states, and trashes HL
;
;	   With IX = buffer+64 (32 ahead of DE = buffer+32):
;	     or  (ix+0)  ; 19   frees HL entirely for table duty
;	     inc ix      ; 10
;
;	   HL is now permanently the table pointer (H=const, L=index).
;	   The two optimizations combine cleanly with zero register juggling.
;
;	Register map inside Loop:
;	  A   scratch
;	  B   inner byte counter (192 -> djnz)
;	  C   outer column counter (6)
;	  DE  write pointer (buffer+32, incremented each byte)
;	  HL  table pointer (H = table>>8 constant, L = rand & 7)
;	  IX  read pointer  (buffer+64, always 32 ahead of DE)
;
;	=======================================================================

	org	$8000

buffer	equ	$9000

	di
	ld	a, $ff
	ld	($6800), a
	ld	(30779), a

	ld	a, 0
	ld	(222), a

Main:
	ld	de, buffer		; write pointer: row 0 (top of screen)
	ld	ix, buffer+32		; read pointer:  row 1 (always 32 ahead of DE)

	ld	h, table >> 8		; hoist table page -- H constant in loop

	; 63 rows written (rows 0..62), row 63 is fire seed (read-only)
	; 63 * 32 = 2016 bytes = 252 * 8
	ld	bc, $fc08		; b=252 (inner), c=8 (outer)

Loop:
	; --- Random number (unchanged from original) ---
	ld	a, r
	rrca
	rrca
	neg
seed2	equ	$ + 1
	xor	0
	rrca
	ld	(seed2), a
	and	7			; A = 0..7

	; --- Table lookup: H already = table>>8, just set L ---
	ld	l, a			; 4 T-states (was 27)
	ld	a, (hl)			; A = pixel mask

	; --- OR with source byte via IX, write result ---
	or	(ix+0)			; A |= byte from row below
	ld	(de), a			; write to current row

	; --- Advance both pointers ---
	inc	de
	inc	ix

	djnz	Loop
	dec	c
	jr	nz, Loop

	; --- Blit buffer to screen ---
	ld	hl, buffer
	ld	de, $7000
	ld	bc, 2048
	ldir

	jp	Main


;	-----------------------------------------------------------------------
;	Pixel-mask lookup table — MUST be at a $xx00 page boundary.
;	Placed at $8100. Code above must stay within $8000..$80FF.
;	If code grows past 256 bytes, change org to $8200 (and so on).
;	-----------------------------------------------------------------------

	org	$8100

table:
	defb	%10000000
	defb	%01000000
	defb	%00100000
	defb	%00010000
	defb	%00001000
	defb	%00000100
	defb	%00000010
	defb	%00000001
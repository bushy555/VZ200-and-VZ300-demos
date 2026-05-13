

 	org	$8000
	ld	a, $18
	ld	($6800), a
	di

	ld	hl, file
	ld	de, $7000
	ld	bc, 2048
	ldir


	ld	hl, 28672 + 32+32+32+32+10
	ld	a, 0
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	ld	bc, 28

	add	hl, bc
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a

	ld	bc, 26
	add	hl, bc
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a

	ld	bc, 28
	add	hl, bc
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a






here2:	ld	bc, 0		; C = Y-value offset in TABLE0
loopb:	push	bc	
	ld	hl, table0
	add	hl, bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)		; de = screen position. 
	ex	de, hl		; de --> hl. hl=scrn position
	push	hl
	pop	ix

	LD 	hl,0x6800
sync2:	BIT 	7,(hl)			; fancy wait retrace.
	jr	NZ,sync2




;	LD 	hl,0x6800
;sync3:	BIT 	7,(hl)			; fancy wait retrace.
;	jr	Z,sync3

;--------
	ld	bc,0		; This loop does 32x X-axis
loopd:	push	ix	
	pop 	hl		; get Y-axis of table0
	add	hl, bc		; add X-axis to HL/screen offset.
	ld	a, (hl)		; get value from screen !!
;	call	check

check:	cp	%10101010  ;BBBB --> RRRR
	jr	z, a1
	cp	%10101011 	; BBBR --> RRRB
	jr	z, a2
	cp	%10101110    ; BBRB --> RRBR
	jr	z, a3
	cp	%10101111     ; BBRR --> RRBB
	jr	z, a4
	cp	%10111010     ; BRBB --> RBRR
	jr	z, a5
	cp	%10111011    ; BRBR --> RBRB
	jr	z, a6
	cp	%10111110 	; BRRB --> RBBR
	jr	z, a7
	cp	%10111111 	; BRRR --> RBBB
	jr	z, a8
	cp	%11101010 	; RBBB --> BRRR
	jr	z, a9
	cp	%11101011 	; RBBR --> BRRB
	jr	z, a10
	cp	%11101110 	; RBRB --> BRBR
	jr	z, a11
	cp	%11101111 	; RBRR --> BRBB
	jr	z, a12
	cp	%11111010 	; RRBB --> BBRR
	jr	z, a13
	cp	%11111011 	; RRBR --> BBRB
	jr	z, a14
	cp	%11111110 	; RRRB --> BBBR
	jr	z, a15
	cp	%11111111  	; RRRR --> BBBB
	jr	z, a16

a1:	ld	a, %11111111	
	jp 	here3
a2:	ld	a, %11111110
	jp 	here3
a3:	ld	a, %11111011
	jp 	here3
a4:	ld	a, %11111010
	jp 	here3
a5:	ld	a, %11101111
	jp 	here3
a6:	ld	a, %11101110
	jp 	here3
a7:	ld	a, %11101011
	jp 	here3
a8:	ld	a, %11101010
	jp 	here3
a9:	ld	a, %10111111
	jp 	here3
a10:	ld	a, %10111110
	jp 	here3
a11:	ld	a, %10111011
	jp 	here3
a12:	ld	a, %10111010
	jp 	here3
a13:	ld	a, %10101111
	jp 	here3
a14:	ld	a, %10101110
	jp 	here3
a15:	ld	a, %10101011
	jp 	here3
a16:	ld	a, %10101010
;	jp 	here3
here3:
;	ret

	ld	(hl), a
	inc	c
	ld	a, c
	cp	32
	jp	nz, loopd
;---------
	pop	bc		; get next table Y-axis offset.
	inc	c
	inc	c
	ld	a, c
	cp	90
	jp	nz, loopb


	jp	here2




press_space:
loop4:	ld 	a, (0x68ef)	
	and	0x10
	jr	z,  You_pressed_space
	jr 	nz, loop4
You_pressed_space:
	nop
	nop



table:
;	defb              62
;	defb           42,61
;	defb  	    33,   60
;	defb     27,   41,59
;	defb  22,         58
;	defb           40,57
;	defb        32,   56
;	defb     26,   39,55
;	defb              54
;	defb  21,      38,53
;	defb        31,   52
;	defb     25,   37,51
;	defb              50
;	defb        30,   49
;	defb  20,      36,48
;	defb     24,      47
;	defb        29,   46
;	defb  19,      35,45
;	defb     23,      44
;	defb        28,34,43
;	defb	255
	
;---------------------------------------------
; Y-axis screen values, in order of processing.
; Change any of the order, and the effect will be stoofed!
; The above Y axis was hand calculated line by line. Took forever.
;---------------------------------------------
table0:
   defw    30656
   defw    30016
   defw    30624
   defw    29728
   defw    30592
   defw    29536
   defw    29984
   defw    30560
   defw    29376
   defw    30528
   defw    29952
   defw    30496
   defw    29696
   defw    30464
   defw    29504
   defw    29920
   defw    30432
   defw    30400
   defw    29344
   defw    29888
   defw    30368
   defw    29664
   defw    30336
   defw    29472
   defw    29856
   defw    30304
   defw    30272
   defw    29632
   defw    30240
   defw    29312
   defw    29824
   defw    30208
   defw    29440
   defw    30176
   defw    29600
   defw    30144
   defw    29280
   defw    29792
   defw    30112
   defw    29408
   defw    30080
   defw    29568
   defw    29760
   defw    30048


	defb	0, 0
table2:
	defb	%10101010, %11111111	; BBBB --> RRRR
	defb	%10101011, %11111110	; BBBR --> RRRB
	defb	%10101110, %11111011    ; BBRB --> RRBR
	defb	%10101111, %11111010    ; BBRR --> RRBB
	defb	%10111010, %11101111    ; BRBB --> RBRR
	defb	%10111011, %11101110    ; BRBR --> RBRB
	defb	%10111110, %11101011	; BRRB --> RBBR
	defb	%10111111, %11101010	; BRRR --> RBBB
	defb	%11101010, %10111111	; RBBB --> BRRR
	defb	%11101011, %10111110	; RBBR --> BRRB
	defb	%11101110, %10111011	; RBRB --> BRBR
	defb	%11101111, %10111010	; RBRR --> BRBB
	defb	%11111010, %10101111	; RRBB --> BBRR
	defb	%11111011, %10101110	; RRBR --> BBRB
	defb	%11111110, %10101011	; RRRB --> BBBR
	defb	%11111111, %10101010	; RRRR --> BBBB
	



; ==============================================================








;-------------------------------------------------------------

file:
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $0FE,$0AA,$0BF,$0FE,$0AA,$0FF,$0FF,$0EA,$0AA,$0BF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA
defb $0FA,$0AA,$0BF,$0FA,$0AA,$0FF,$0FF,$0FA,$0AA,$0AF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA
defb $0AB,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FE
defb $0EA,$0AA,$0FF,$0FA,$0AA,$0BF,$0FF,$0FA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA
defb $0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF
defb $0AA,$0AA,$0FF,$0FA,$0AA,$0BF,$0FF,$0FE,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0EA,$0AA
defb $0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF
defb $0FF,$0FF,$0AA,$0AF,$0FF,$0EA,$0AA,$0AB,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0BF,$0FF
defb $0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA
defb $0FF,$0FE,$0AA,$0AF,$0FF,$0EA,$0AA,$0AA,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA
defb $0FF,$0FA,$0AA,$0AF,$0FF,$0FA,$0AA,$0AA,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0BF
defb $0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE
defb $0FF,$0FA,$0AA,$0AF,$0FF,$0FA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AB
defb $0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0FF,$0EA,$0AA,$0AF,$0FF,$0FA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA
defb $0BF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0AA,$0BF,$0FF,$0FA,$0AA,$0AF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF
defb $0FE,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0FF,$0FF,$0FA,$0AA,$0AB,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF
defb $0FF,$0EA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA
defb $0AB,$0FF,$0FF,$0FA,$0AA,$0AB,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF
defb $0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA
defb $0AB,$0FF,$0FF,$0EA,$0AA,$0AB,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF
defb $0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA
defb $0AF,$0FF,$0FF,$0EA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA
defb $0AF,$0FF,$0FF,$0EA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF
defb $0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0FA,$0AA,$0AA,$0BF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA
defb $0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0EA,$0AA,$0AA,$0BF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA
defb $0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0EA,$0AA,$0AA,$0BF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0EA
defb $0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FE
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0EA,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0FE,$0AA,$0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF
defb $0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0FF
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AF
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA
defb $0FF,$0FF,$0FE,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FE,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AB,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF
defb $0AA,$0AA,$0AF,$0FF,$0FF,$0FF,$0FF,$0FA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0BF
defb $0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0FF,$0EA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
 ; ---------------------------------------------------------




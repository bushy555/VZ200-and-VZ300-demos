

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
	ld	d, h
	ld	e, l


	LD 	hl,0x6800
sync2:	BIT 	7,(hl)			; fancy wait retrace.
	jr	NZ,sync2




;	LD 	hl,0x6800
;sync3:	BIT 	7,(hl)			; fancy wait retrace.
;	jr	Z,sync3

	ld	bc,0		; This loop does 32x X-axis
loopd:	ld h, d ; push	de	
	ld l, e ; pop 	hl		; get Y-axis of table0

	add	hl, bc		; add X-axis to HL/screen offset.
	ld	a, (hl)		; get value from screen !!
	xor	$55

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
  defw    30048	;44
   defw    29760	;43
   defw    29568	;42
   defw    30080	;41
   defw    29408	;40
   defw    30112	;39
   defw    29792	;38
   defw    29280	;37
   defw    30144	;36
   defw    29600	;35
   defw    30176	;34
   defw    29440	;33
   defw    30208	;32
   defw    29824	;31
   defw    29312	;30
   defw    30240	;29
   defw    29632	;28
   defw    30272	;27
   defw    30304	;26
   defw    29856	;25
   defw    29472	;24
   defw    30336	;23
   defw    29664	;22
   defw    30368	;21
   defw    29888	;20
   defw    29344	;19
   defw    30400	;18
   defw    30432	;17
   defw    29920	;16
   defw    29504	;15
   defw    30464	;14
   defw    29696	;13
   defw    30496	;12
   defw    29952	;11
   defw    30528	;10
   defw    29376	;9	
   defw    30560	;8
   defw    29984	;7
   defw    29536	;6	
   defw    30592	;5
   defw    29728	;4
   defw    30624	;3
   defw    30016	;2
   defw    30656	;1



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




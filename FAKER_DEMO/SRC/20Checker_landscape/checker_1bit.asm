; Moving checkboard effect. REVERSED DIRECTION.
; Using Color,1 colour scheme.
;
; Assemble with PASMO & RBINARY.
; SJPLUSASM will work after changing defb to defb and def to dw.
; Sep 2021 by Dave.


; z3: video running playrow.   song 0. zx10 theme





latch	equ	$6800
origin 	equ	$8000
buffer	equ	$C000

 	org	origin
	ld	a, $18
	ld	(latch), a
	di

	ld	hl, file
	ld	de, $7000
	ld	bc, 2048
	ldir
	ld	ix, 0

; ====================================================
; Draw rough cloud as an after thought.
; Couldn't be bothered re-adding it into the below graphic.
; I am slack sometimes. Most of the time.
; ====================================================
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







;4-channel music generator ZX-10
;Original code JDeak (c)1989 Bytepack Bratislava
;Modified 1tracker version by Shiru 04'12

begin:	di
	ld hl,musicData
	call play
	ret				

play:
	di
	ld a,(hl)
	inc hl
	ld (speed+1),a
	dec a
	ld (speedCnt),a
	xor a
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (ch1order),de
	ld (de),a
	ld (sc1+3),a
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (ch2order),de
	ld (de),a
	ld (sc2+3),a
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (ch3order),de
	ld (de),a
	ld (sc3+3),a
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld (ch4order),de
	ld (de),a
	ld (sc4+3),a

	ld hl,adst
	ld de,sx
	ld bc,$0400
init0:
	ld (hl),c
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	djnz init0




; ============================================================

video:

here2:	ld	bc, 0		; C = Y-value offset in TABLE0
loopb:	push	bc	
	push	bc
	call	playRow
	pop	bc


	ld	hl, table0
	add	hl, bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)		; de = screen position. 
	ex	de, hl		; de --> hl. hl=scrn position
	push	hl
	pop	de



	ld	bc,0		; This loop does 32x X-axis
loopd:	push	de	
	pop 	hl		; get Y-axis of table0

	add	hl, bc		; add X-axis to HL/screen offset.
	ld	a, (hl)		; get value from screen !!
	xor	$55

	ld	(hl), a
	inc	c
	ld	a, c
	cp	32
	jp	nz, loopd

;	call	playRow

	pop	bc		; get next table Y-axis offset.
	inc	c
	inc	c
	ld	a, c
	cp	90

	jp	nz, loopb
	jp	here2






playRow:
	ld   iy,sc1
	ld   hl,adst
	ld   de,8
	ld   b,4
decay0:
	ld   a,(hl)
	or   a
	jr   z,decay1
	dec  (hl)
	sla  (iy+3)
	set  4,(iy+3)
decay1:
	add iy,de
	inc  hl
	inc  hl
	inc  hl
	djnz decay0


	ld a,(speedCnt)
	inc a
speed:
	cp 0
	jr nz,noNextRow

	ld   iy,sc1
	ld   hl,adst
	ld   b,4
nextRow0:
	push hl
	inc  hl
	ld   e,(hl)
	inc  hl
	ld   d,(hl)
	ld   a,(de)
	inc  de
	ld   (hl),d
	dec  hl
	ld   (hl),e
	cp   $e0
	jp nz,noNextOrder

	ld   de,12
	add  hl,de
	ld   c,(hl)
	inc  hl
	ld   a,(hl)
	or a
	sbc hl,de
	push hl
	ld l,c
	ld h,a
	ld   a,(hl)
	inc  hl
	cp   (hl)
	dec  hl
	jr   nz,porder1
	;xor  a			;loop channel
	;ld   (hl),a
	;jr   porder2
	pop hl			;exit at end of the song
	pop hl
	jp keyPressed

porder1:
	inc  (hl)
porder2:
	inc  a
	ex   de,hl
	ld   l,a
	ld   h,0
	add  hl,hl
	add  hl,de
	ld   e,(hl)
	inc  hl
	ld   d,(hl)
	pop  hl
	ld   a,(de)
	inc  de
	ld   (hl),d
	dec  hl
	ld   (hl),e

noNextOrder:
	ld   c,a
	and  31
	cp 2
	jr nc,nextRow2
	or a
	jr nz,nextRow1
	pop hl
	jr nextRow4
nextRow1:
	set  4,(iy+2)
	jr nextRow3
nextRow2:
	res  4,(iy+2)
nextRow3:
	ld   e,a
	ld   d,0
	ld   hl,frq			;note
	add  hl,de
	ld   a,(hl)
	ld   (iy+1),a
	ld   a,c			;duration
	rlca
	rlca
	rlca
	rlca
	and  14
	inc  a
	pop  hl
	ld   (hl),a
	ld   (iy+3),$1f
nextRow4:
	ld   de,8
	add  iy,de
	inc  hl
	inc  hl
	inc  hl
	djnz nextRow0

	xor a
noNextRow:
	ld (speedCnt),a


;	xor a
;	ld a,%10111111				;+ new keyhandler
;	out (1),a
;	in a,(1)				;read keyboard
;	cpl
;	bit 6,a

;//	jp   nz,keyPressed



	ld   hl,256
sc:	exx
sc0:	dec  c
	jp   nz,s1
sc1:	ld   c,0
	ld   l,0
l1:	dec  b
	jp   nz,s2
sc2:	ld   b,0
	ld   l,0
l2:	dec  e
	jp   nz,s3
sc3:	ld   e,0
	ld   l,0
l3:	dec  d
	jp   nz,s4
sc4:	ld   d,0
	ld   l,0
l4:	ld   a,l
	and $10
	sla  l
	push af
	bit 4,a
	jr z,$+$04
	ld	a, 33
	or	$18
	

	ld ($6800), a
	nop
	nop
	pop af
	exx
	dec  hl
	ld   a,h
	or   l
	exx
	jp   nz,sc0

	push af
	bit 4,a
	jr z,$+$04
	ld	a, 33
	or	$18


	ld ($6800), a
	nop
	nop
	pop af

	exx
	ret
;	jp   playRow

s1:	nop
	jp   l1
s2:	nop
	jp   l2
s3:	nop
	jp   l3
s4:	nop
	jp   l4


keyPressed:
	exx
	ei
	ret


; ================================================
; Original Y axis table with correct to do order.
; Should delete this; not used.
; ================================================
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


; =================================================
; Initial attempt at Y-axis lookup table.
; Couldn't quite get it to read correctly; gave up.
; Not used.
; =================================================
;table2:defb	%10101010, %11111111	; BBBB --> RRRR
;	defb	%10101011, %11111110	; BBBR --> RRRB
;	defb	%10101110, %11111011    ; BBRB --> RRBR
;	defb	%10101111, %11111010    ; BBRR --> RRBB
;	defb	%10111010, %11101111    ; BRBB --> RBRR
;	defb	%10111011, %11101110    ; BRBR --> RBRB
;	defb	%10111110, %11101011	; BRRB --> RBBR
;	defb	%10111111, %11101010	; BRRR --> RBBB
;	defb	%11101010, %10111111	; RBBB --> BRRR
;	defb	%11101011, %10111110	; RBBR --> BRRB
;	defb	%11101110, %10111011	; RBRB --> BRBR
;	defb	%11101111, %10111010	; RBRR --> BRBB
;	defb	%11111010, %10101111	; RRBB --> BBRR
;	defb	%11111011, %10101110	; RRBR --> BBRB
;	defb	%11111110, %10101011	; RRRB --> BBBR
;	defb	%11111111, %10101010	; RRRR --> BBBB
	

; ===========================================
; Checkerboard screen without the cloud.
; ===========================================

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

frq:
	defb   0,255,241,227,214,202,191,180
	defb 170,161,152,143,135,127,120,114
	defb 107,101, 95, 90, 85, 80, 76, 71
	defb  67, 63, 60, 57, 53, 50, 47, 45

sx:
	defb   $e0

adst:
	defb   0
	defw    0
	defb   0
	defw    0
	defb   0
	defw    0
	defb   0
	defw    0
	defb   0
ch1order:
	defw    0
	defb   0
ch2order:
	defw    0
	defb   0
ch3order:
	defw    0
	defb   0
ch4order:
	defw    0

speedCnt:
	defb 0

musicData:

; ===========================
;    ZX-10 THEME MUSIC DATA
; ===========================

musicData1
	defb $0a
	defw md1order0
	defw md1order1
	defw md1order2
	defw md1order3

md1order0
	defw $2c00
	defw md1pattern0
	defw md1pattern1
	defw md1pattern2
	defw md1pattern3
	defw md1pattern4
	defw md1pattern5
	defw md1pattern6
	defw md1pattern7
	defw md1pattern8
	defw md1pattern9
	defw md1pattern10
	defw md1pattern11
	defw md1pattern12
	defw md1pattern13
	defw md1pattern14
	defw md1pattern15
	defw md1pattern16
	defw md1pattern17
	defw md1pattern18
	defw md1pattern19
	defw md1pattern20
	defw md1pattern21
	defw md1pattern22
	defw md1pattern23
	defw md1pattern24
	defw md1pattern25
	defw md1pattern26
	defw md1pattern27
	defw md1pattern28
	defw md1pattern29
	defw md1pattern30
	defw md1pattern31
	defw md1pattern32
	defw md1pattern33
	defw md1pattern34
	defw md1pattern35
	defw md1pattern36
	defw md1pattern37
	defw md1pattern38
	defw md1pattern39
	defw md1pattern40
	defw md1pattern41
	defw md1pattern42
	defw md1pattern43
md1order1
	defw $2c00
	defw md1pattern44
	defw md1pattern45
	defw md1pattern46
	defw md1pattern47
	defw md1pattern48
	defw md1pattern49
	defw md1pattern50
	defw md1pattern51
	defw md1pattern52
	defw md1pattern53
	defw md1pattern54
	defw md1pattern55
	defw md1pattern56
	defw md1pattern57
	defw md1pattern58
	defw md1pattern59
	defw md1pattern60
	defw md1pattern61
	defw md1pattern62
	defw md1pattern63
	defw md1pattern64
	defw md1pattern65
	defw md1pattern66
	defw md1pattern67
	defw md1pattern68
	defw md1pattern69
	defw md1pattern70
	defw md1pattern71
	defw md1pattern72
	defw md1pattern73
	defw md1pattern74
	defw md1pattern75
	defw md1pattern76
	defw md1pattern77
	defw md1pattern54
	defw md1pattern78
	defw md1pattern79
	defw md1pattern80
	defw md1pattern81
	defw md1pattern82
	defw md1pattern83
	defw md1pattern84
	defw md1pattern85
	defw md1pattern86
md1order2
	defw $2c00
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
md1order3
	defw $2c00
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87
	defw md1pattern87

md1pattern0	defb $8f,$8f,$8f,$8f,$8f,$8d,$8d,$8f,$e0
md1pattern1	defb $94,$8f,$8f,$8f,$8d,$8d,$8f,$8f,$e0
md1pattern2	defb $8f,$8f,$8f,$8d,$8d,$8f,$8f,$8f,$e0
md1pattern3	defb $8f,$8f,$8f,$8d,$8d,$8f,$94,$8f,$e0
md1pattern4	defb $8f,$8f,$8d,$8d,$8f,$8f,$8f,$8f,$e0
md1pattern5	defb $8f,$8d,$8d,$8f,$83,$8f,$91,$8f,$e0
md1pattern6	defb $91,$8f,$8e,$8c,$8e,$8f,$91,$8e,$e0
md1pattern7	defb $8a,$8a,$88,$8f,$8f,$94,$8f,$8f,$e0
md1pattern8	defb $8f,$8a,$91,$96,$9a,$96,$91,$8e,$e0
md1pattern9	defb $91,$8f,$8f,$91,$93,$91,$8f,$8e,$e0
md1pattern10	defb $8c,$8e,$8f,$96,$8e,$8a,$8a,$88,$e0
md1pattern11	defb $8f,$8f,$98,$8f,$8f,$8f,$8a,$8a,$e0
md1pattern12	defb $8a,$8a,$96,$91,$9a,$91,$9b,$87,$e0
md1pattern13	defb $94,$9b,$8f,$91,$91,$96,$91,$94,$e0
md1pattern14	defb $88,$94,$98,$96,$8a,$9b,$87,$8f,$e0
md1pattern15	defb $9b,$93,$91,$98,$96,$91,$94,$93,$e0
md1pattern16	defb $91,$8a,$96,$87,$8f,$96,$8f,$91,$e0
md1pattern17	defb $91,$96,$91,$94,$88,$94,$98,$96,$e0
md1pattern18	defb $8a,$96,$87,$8f,$96,$93,$91,$98,$e0
md1pattern19	defb $96,$91,$94,$93,$91,$96,$96,$96,$e0
md1pattern20	defb $96,$96,$96,$83,$8f,$91,$8f,$91,$e0
md1pattern21	defb $8f,$8e,$8c,$8e,$8f,$91,$8e,$8a,$e0
md1pattern22	defb $8a,$88,$8f,$8f,$94,$8f,$8f,$8f,$e0
md1pattern23	defb $8a,$91,$96,$9a,$96,$91,$8e,$91,$e0
md1pattern24	defb $8f,$8f,$91,$93,$91,$8f,$8e,$8c,$e0
md1pattern25	defb $8e,$8f,$96,$8e,$8a,$8a,$88,$8f,$e0
md1pattern26	defb $8f,$98,$8f,$8f,$8f,$8a,$8a,$8a,$e0
md1pattern27	defb $8a,$96,$91,$9a,$91,$8f,$8f,$8f,$e0
md1pattern28	defb $8f,$8f,$8d,$8d,$8f,$94,$8f,$8f,$e0
md1pattern29	defb $8f,$8d,$8d,$8f,$8f,$8f,$8f,$8f,$e0
md1pattern30	defb $8d,$8d,$8f,$9b,$9b,$94,$96,$9b,$e0
md1pattern31	defb $99,$99,$9b,$8f,$94,$8f,$94,$99,$e0
md1pattern32	defb $99,$9b,$94,$99,$99,$98,$99,$99,$e0
md1pattern33	defb $9b,$83,$8f,$91,$8f,$91,$8f,$8e,$e0
md1pattern34	defb $8c,$8e,$8f,$91,$8e,$8a,$8a,$88,$e0
md1pattern35	defb $8f,$8f,$94,$8f,$8f,$8f,$8a,$91,$e0
md1pattern36	defb $96,$9a,$96,$91,$8e,$91,$8f,$8f,$e0
md1pattern37	defb $91,$93,$91,$8f,$8e,$8c,$8e,$8f,$e0
md1pattern38	defb $96,$8e,$8a,$8a,$88,$8f,$8f,$98,$e0
md1pattern39	defb $8f,$8f,$8f,$8a,$8a,$8a,$8a,$96,$e0
md1pattern40	defb $91,$9a,$91,$9b,$8f,$9d,$9b,$96,$e0
md1pattern41	defb $8f,$93,$98,$8e,$93,$8c,$94,$8f,$e0
md1pattern42	defb $94,$98,$8f,$8f,$8a,$91,$96,$9a,$e0
md1pattern43	defb $91,$8f,$00,$00,$00,$00,$00,$00,$e0
md1pattern44	defb $2f,$34,$33,$34,$38,$36,$34,$36,$e0
md1pattern45	defb $34,$33,$3f,$38,$36,$34,$2f,$34,$e0
md1pattern46	defb $33,$34,$38,$36,$34,$36,$2f,$34,$e0
md1pattern47	defb $33,$34,$38,$36,$34,$36,$34,$33,$e0
md1pattern48	defb $3f,$38,$36,$34,$2f,$34,$33,$34,$e0
md1pattern49	defb $38,$36,$34,$36,$23,$2f,$31,$33,$e0
md1pattern50	defb $36,$36,$33,$2f,$33,$2f,$36,$2e,$e0
md1pattern51	defb $2a,$2a,$2f,$38,$38,$38,$38,$2f,$e0
md1pattern52	defb $2f,$31,$3a,$3a,$3a,$36,$3a,$2e,$e0
md1pattern53	defb $3a,$36,$33,$36,$33,$36,$36,$33,$e0
md1pattern54	defb $2f,$33,$2f,$36,$2e,$2a,$2a,$2f,$e0
md1pattern55	defb $38,$38,$38,$38,$2f,$2f,$2f,$2e,$e0
md1pattern56	defb $2a,$2e,$36,$3a,$3a,$3a,$3b,$27,$e0
md1pattern57	defb $2f,$3b,$36,$36,$31,$36,$36,$34,$e0
md1pattern58	defb $28,$38,$38,$3a,$2a,$3f,$27,$34,$e0
md1pattern59	defb $3f,$33,$36,$38,$36,$36,$34,$33,$e0
md1pattern60	defb $31,$2f,$3b,$27,$34,$3b,$36,$36,$e0
md1pattern61	defb $31,$36,$36,$34,$28,$38,$38,$3a,$e0
md1pattern62	defb $2a,$3b,$27,$34,$3b,$33,$36,$38,$e0
md1pattern63	defb $36,$36,$34,$33,$31,$2f,$2f,$2f,$e0
md1pattern64	defb $2f,$2f,$2f,$23,$2f,$31,$33,$36,$e0
md1pattern65	defb $36,$33,$2f,$33,$2f,$36,$2e,$2a,$e0
md1pattern66	defb $2a,$2f,$38,$38,$38,$38,$2f,$2f,$e0
md1pattern67	defb $31,$3a,$3a,$3a,$36,$3a,$2e,$3a,$e0
md1pattern68	defb $36,$33,$36,$33,$36,$36,$33,$2f,$e0
md1pattern69	defb $33,$2f,$36,$2e,$2a,$2a,$2f,$38,$e0
md1pattern70	defb $38,$38,$38,$2f,$2f,$2f,$2e,$2a,$e0
md1pattern71	defb $2e,$36,$3a,$3a,$3a,$2f,$34,$33,$e0
md1pattern72	defb $34,$38,$36,$34,$36,$34,$33,$3f,$e0
md1pattern73	defb $38,$36,$34,$2f,$34,$33,$34,$38,$e0
md1pattern74	defb $36,$34,$36,$3b,$34,$38,$3b,$3f,$e0
md1pattern75	defb $36,$36,$3b,$34,$38,$2f,$3b,$36,$e0
md1pattern76	defb $34,$3b,$38,$3d,$3d,$38,$36,$34,$e0
md1pattern77	defb $3f,$23,$2f,$31,$33,$36,$36,$33,$e0
md1pattern78	defb $38,$38,$38,$38,$2f,$2f,$31,$3a,$e0
md1pattern79	defb $3a,$3a,$36,$3a,$2e,$3a,$36,$33,$e0
md1pattern80	defb $36,$33,$36,$36,$33,$2f,$33,$2f,$e0
md1pattern81	defb $36,$2e,$2a,$2a,$2f,$38,$38,$38,$e0
md1pattern82	defb $38,$2f,$2f,$2f,$2e,$2a,$2e,$36,$e0
md1pattern83	defb $3a,$3a,$3a,$3b,$2f,$3d,$3f,$36,$e0
md1pattern84	defb $36,$33,$38,$2e,$33,$33,$34,$38,$e0
md1pattern85	defb $34,$38,$38,$2f,$31,$31,$3a,$3a,$e0
md1pattern86	defb $3a,$36,$00,$00,$00,$00,$00,$00,$e0
md1pattern87	defb $00,$00,$00,$00,$00,$00,$00,$00,$e0


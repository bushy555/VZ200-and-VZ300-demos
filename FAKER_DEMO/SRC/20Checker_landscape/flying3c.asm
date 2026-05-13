; Moving checkboard effect. REVERSED DIRECTION.
; Using Color,1 colour scheme.
;
; Assemble with PASMO & RBINARY.
; SJPLUSASM will work after changing defb to db and def to dw.
; Sep 2021 by Dave.


latch	equ	$6800
video	equ	$7000
origin 	equ	$8000
buffer	equ	$C000

 	org	origin
	ld	a, $18
	ld	(latch), a
	di

	ld	hl, 16			; start ship at 16 offset.
	ld	(ship_x), hl

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Write screen to video buffer 1 ($C000)
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	ld	hl, file
	ld	de, $c000 
	ld	bc, 2048
	ldir


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Draw cloud as an afterthought.
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	ld	hl, $c000 + 32+32+32+32+10 
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
;	push	hl
;	pop	ix

	ld	a, l
	ld	ixl, a
	ld	a, h
	ld	ixh, a


;	LD 	hl,0x6800
;sync2:	BIT 	7,(hl)			; fancy wait retrace.
;	jr	NZ,sync2




;--------
	ld	bc,0		; This loop does 32x X-axis
loopd:	
	ld	a, ixl
	ld	l, a
	ld	a, ixh
	ld	h, a
;	push	ix	
;	pop 	hl		; get Y-axis of table0
	add	hl, bc		; add X-axis to HL/screen offset.
	ld	a, (hl)		; get value from screen !!
	xor	$55
	ld	(hl), a
	inc	c
	ld	a, c
	cp	32
	jp	nz, loopd
;---------


	ld	hl, $c000
	ld	de, $d000
	ld	bc, 2048
	ldir

;	call 	key_ship	; read keyboard; display ship.

key1:	ld 	a, (0x68fb)			; Z  - Left
	and 	$10
;	call	z, left
	jr	nz, key2
	ld	hl, (ship_x)
	dec	hl
	ld	(ship_x), hl	

key2:	ld 	a, (0x68fb)			; X  - right
	and 	$2
	jr	nz, key3
;	call	z, right
	ld	hl, (ship_x)
	inc	hl
	ld	(ship_x), hl	

key3:	call	display_ship2



; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Video wait synch.  Not needed in emu. Will be needed for real VZ.
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;	LD 	hl,0x6800
;sync2:	BIT 	7,(hl)			; fancy wait retrace.
;	jr	NZ,sync2
;	LD 	hl,0x6800
;sync3:	BIT 	7,(hl)			; fancy wait retrace.
;	jr	Z,sync3


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Copy from buffer2 ($c000) to video ($7000)
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	ld	hl, $d000
	ld	de, $7000
	ld	bc, 2048
	ldir

;	ld	hl, $c000
;	ld	de, $c000


	pop	bc		; get next table Y-axis offset.
	inc	c
	inc	c
	ld	a, c
	cp	90
	jp	nz, loopb


	jp	here2


;key_ship:
;key1:	ld 	a, (0x68fb)			; Z  - Left
;	and 	$10
;;	call	z, left
;	jr	nz, key2
;	ld	hl, (ship_x)
;	dec	hl
;	ld	(ship_x), hl	
;
;key2:	ld 	a, (0x68fb)			; X  - right
;	and 	$2
;	jr	nz, key3
;;	call	z, right
;	ld	hl, (ship_x)
;	inc	hl
;	ld	(ship_x), hl	;
;
;key3:	call	display_ship2
;	ret


;left:	ld	hl, (ship_x)
;	dec	hl
;	ld	(ship_x), hl	
;	ret
;right:	ld	hl, (ship_x)
;	inc	hl
;	ld	(ship_x), hl	
;	ret


display_ship1:
	ld	b, 26				; Y-Axis loop
	ld	de, $d000+(2048-(32*28))	; setting up destination of ship
	ld	hl, (ship_x)			; X-AXIS ship offset
	add	hl, de
	dec	hl
	dec	hl
	dec	hl
	dec	hl
	dec	hl
	dec	hl
	dec	hl


;	push	hl
;	pop	de


	ld	d, h
	ld	e, l

	ld	hl, ship1
shipl1:	push	bc
	ld	bc, 8
	ldir					; display X-axis on screen.

	push	hl
	ld	hl, 32-8
	add	hl, de

	ld	d, h
	ld	e, l

;	push	hl
;	pop	de
	pop	hl
	pop	bc
	djnz	shipl1				; Loop Y -times.
	ret


display_ship2:
	ld	b, 26				; Y-Axis loop
	ld	de, $d000+(2048-(32*28))	; setting up destination of ship
	ld	hl, (ship_x)			; X-AXIS ship offset
	add	hl, de
	inc	hl
	inc	hl
	inc	hl
	inc	hl

;	push	hl
;	pop	de

	ld	d, h
	ld	e, l

	ld	hl, ship2
shipl2:	push	bc
	ld	b, 8
l3:	ld	a, (hl)
	cp	170
	jp	z, a1
	cp	255
	jp	z, a1
	ld	a, (hl)
	jp	a2

a1:	ld	a, (de)
a2:	ld	(de), a
	inc	hl
	inc	de
	djnz	l3
;	ldir					; display X-axis on screen.
	push	hl
	ld	hl, 32-8
	add	hl, de

;	push	hl
;	pop	de

	ld	d, h
	ld	e, l
	pop	hl
	pop	bc
	djnz	shipl2				; Loop Y -times.
	ret


display_ship3:
	ld	b, 26				; Y-Axis loop
	ld	de, $d000+(2048-(32*28))	; setting up destination of ship
	ld	hl, (ship_x3)			; X-AXIS ship offset
	add	hl, de

	ld	d, h
	ld	e, l
;	push	hl
;	pop	de
	ld	hl, ship3
shipl3:	push	bc
	ld	bc, 11
	ldir					; display X-axis on screen.
	push	hl
	ld	hl, 32-11
	add	hl, de

	ld	d, h
	ld	e, l

;	push	hl
;	pop	de
	pop	hl
	pop	bc
	djnz	shipl3				; Loop Y -times.
	ret






table0:

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Checkerboard Y-Axis values. in order of processing.
; hand calculated line by line and took forever.
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
   defw    30048 + $5000	;44
   defw    29760 + $5000	;43
   defw    29568 + $5000	;42
   defw    30080 + $5000	;41
   defw    29408 + $5000	;40
   defw    30112 + $5000	;39
   defw    29792 + $5000	;38
   defw    29280 + $5000	;37
   defw    30144 + $5000	;36
   defw    29600 + $5000	;35
   defw    30176 + $5000	;34
   defw    29440 + $5000	;33
   defw    30208 + $5000	;32
   defw    29824 + $5000	;31
   defw    29312 + $5000	;30
   defw    30240 + $5000	;29
   defw    29632 + $5000	;28
   defw    30272 + $5000	;27
   defw    30304 + $5000	;26
   defw    29856 + $5000	;25
   defw    29472 + $5000	;24
   defw    30336 + $5000	;23
   defw    29664 + $5000	;22
   defw    30368 + $5000	;21
   defw    29888 + $5000	;20
   defw    29344 + $5000	;19
   defw    30400 + $5000	;18
   defw    30432 + $5000	;17
   defw    29920 + $5000	;16
   defw    29504 + $5000	;15
   defw    30464 + $5000	;14
   defw    29696 + $5000	;13
   defw    30496 + $5000	;12
   defw    29952 + $5000	;11
   defw    30528 + $5000	;10
   defw    29376 + $5000	;9	
   defw    30560 + $5000	;8
   defw    29984 + $5000	;7
   defw    29536 + $5000	;6	
   defw    30592 + $5000	;5
   defw    29728 + $5000	;4
   defw    30624 + $5000	;3
   defw    30016 + $5000	;2
   defw    30656 + $5000	;1


; 
	
ship_x :	defb	16
ship_x1:	defb	8
ship_x2:	defb	20
ship_x3:	defb	16

; SHIP1. 32x26
;
ship1: 
defb $0AA,$0AA,$09A,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0A6,$0AA,$0AA
defb $0AA,$0AA,$09A,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0A6,$0AA,$0AA
defb $0AA,$0AA,$09A,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA,$0AA,$09A,$0AA,$0AA,$0A6,$0AA,$0AA
defb $0AA,$055,$055,$055,$055,$055,$055,$0AA,$0A9,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$06A
defb $0A9,$0AA,$055,$0AA,$0AA,$055,$0AA,$06A,$0A9,$0AA,$055,$0AA,$0AA,$055,$0AA,$06A
defb $0A9,$0AA,$07D,$0AA,$0AA,$07D,$0AA,$06A,$0A9,$0AA,$0FF,$0AA,$0AA,$0FF,$0AA,$06A
defb $0A9,$0AA,$0BE,$0AA,$0AA,$0BE,$0AA,$06A,$0A9,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$06A
defb $0AA,$055,$055,$055,$055,$055,$055,$0AA,$0A9,$0AA,$0BA,$0AA,$0AA,$0AE,$0AA,$06A
defb $0AA,$057,$057,$055,$055,$0D5,$0D5,$0AA,$0AA,$0AA,$0BA,$0AA,$0AA,$0AE,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$055,$055,$055,$055,$055,$055,$0AA
defb $0A9,$055,$055,$055,$055,$055,$055,$06A,$0A9,$055,$055,$055,$055,$055,$055,$06A
defb $0A9,$055,$055,$055,$055,$055,$055,$06A,$0A9,$055,$055,$055,$055,$055,$055,$06A
defb $0A9,$055,$055,$055,$055,$055,$055,$06A,$0AA,$055,$055,$055,$055,$055,$055,$0AA

 ; ---------------------------------------------------------
; ---------------------------------------------------------
;
; SHIP2. 32x26
ship2: 
defb $0A9,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA,$0AA,$0AA,$06A,$0AA,$0A9,$0AA,$0AA,$0AA,$0AA
defb $0AA,$09A,$0AA,$0AA,$06A,$0AA,$0AA,$0AA,$0AA,$0A6,$0AA,$0AA,$09A,$0AA,$0AA,$0AA
defb $0AA,$0A9,$0AA,$0AA,$0A6,$0AA,$0AA,$0AA,$0AA,$0AA,$06A,$0AA,$0A9,$0AA,$0AA,$0AA
defb $095,$055,$055,$055,$055,$055,$05A,$0AA,$055,$055,$099,$055,$055,$099,$056,$0AA
defb $055,$056,$055,$095,$056,$055,$095,$0AA,$095,$055,$095,$065,$055,$095,$065,$06A
defb $0A5,$055,$065,$009,$055,$065,$009,$05A,$0A9,$055,$058,$002,$055,$058,$002,$056
defb $0AA,$055,$055,$005,$055,$055,$005,$055,$0AA,$095,$055,$054,$055,$055,$054,$055
defb $0AA,$0A5,$055,$045,$045,$055,$045,$046,$0AA,$0AA,$0AA,$0A8,$0AA,$0AA,$0A8,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA
defb $0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0AA,$0A2,$022,$022,$022,$022,$022,$02A,$0AA
defb $080,$000,$000,$000,$000,$000,$002,$0AA,$0A0,$000,$000,$000,$000,$000,$000,$0AA
defb $0A8,$000,$000,$000,$000,$000,$000,$02A,$0AA,$000,$000,$000,$000,$000,$000,$00A
defb $0AA,$080,$000,$000,$000,$000,$000,$002,$0AA,$0A8,$088,$088,$088,$088,$088,$08A

; ---------------------------------------------------------
;
; SHIP3. 42x26
ship3: 
defb $005,$055,$055,$041,$055,$055,$055,$055,$055,$055,$055,$005,$055,$055,$041,$055
defb $055,$055,$055,$055,$055,$055,$005,$055,$055,$041,$055,$055,$055,$055,$055,$055
defb $055,$005,$055,$055,$041,$055,$055,$055,$055,$055,$055,$055,$005,$055,$055,$041
defb $055,$055,$055,$055,$055,$055,$055,$005,$055,$055,$041,$055,$055,$055,$055,$000
defb $000,$000,$000,$000,$000,$000,$005,$055,$055,$050,$054,$015,$055,$055,$055,$055
defb $055,$005,$055,$055,$050,$054,$015,$041,$055,$055,$050,$055,$005,$055,$055,$050
defb $054,$015,$041,$055,$055,$050,$055,$005,$055,$055,$050,$054,$015,$040,$0A5,$055
defb $050,$0A5,$005,$055,$055,$050,$054,$015,$06A,$095,$055,$06A,$095,$005,$055,$055
defb $050,$054,$000,$0A0,$000,$000,$0A0,$000,$005,$055,$055,$050,$055,$055,$065,$055
defb $055,$065,$054,$055,$055,$055,$050,$000,$020,$020,$000,$020,$020,$005,$055,$055
defb $055,$055,$055,$065,$055,$055,$065,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055,$055
defb $055,$055,$055,$055,$055,$055,$055,$055,$000,$000,$000,$000,$000,$000,$000,$055
defb $055,$055,$055,$000,$000,$000,$000,$000,$000,$000,$055,$055,$055,$055,$000,$000
defb $000,$000,$000,$000,$000,$055,$055,$055,$055,$000,$000,$000,$000,$000,$000,$000
defb $055,$055,$055,$055,$000,$000,$000,$000,$000,$000,$000,$055,$055,$055,$055,$000
defb $000,$000,$000,$000,$000,$000,$055,$055,$055,$055,$000,$000,$000,$000,$000,$000
defb $000,$000
; ---------------------------------------------------------

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




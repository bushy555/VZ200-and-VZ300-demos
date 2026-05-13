;CHAOS1 - working random 3 point


; 	Rotating Chaos in hard-coded circle x,y co-ords.
;	128x64.	13/2/2022
;
;  optimsie rnd()
;  optimise x1/x2 etc into regs.
;

	ORG $8000

	ld 	a,8			; mode (1)
	ld 	($6800),a
	di

loop00:	ld	hl, $7000		; MODE(1) CLS
	ld	de, $7001
	xor	a
	ld	(hl), a
	ld	(de), a
	ld	bc, 2048
	ldir
	ld	hl, $9000		; Screen Buffer 
	ld	de, $9001		; At $9000
	xor	a
	ld	(hl), a
	ld	bc, 2047
	ldir
; ==================================
go:	

	ld	b, 61			; 60, 61, 62, 63, 64
	ld	hl, points
lp:
	ld	de, x1
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi

	exx
	call	chaos
	exx

	djnz	lp			; Loop points.

	jr	go
	





chaos:	
	ld	b, 0;255			; Will loop 500+ times
   	ld 	de, $7800
chaos2:	push	bc

rand1 equ $+1
	ld 	a, $A6
rand2 equ $+1
	ld 	hl, $8243
	inc 	l
	dec 	h
	add 	a, (hl)
	ld 	(rand2), hl
	rlca
;	rlca
	sub 	h
	add 	a, l
	ld 	(rand1), a

	cp	85	
	jr	c, next2		; 0,0	-JMP BELOW
	cp	170
	jr	nc, next		;	-JMP ABOVE
	ld	bc, (x2)
	add	ix, bc			; 128, 0
	ld	bc, (y2)
	add	iy, bc
	jr	calc
next:	ld	bc, (x3)		; (64, 63)
	add	ix, bc	
	ld	bc, (y3)	
	add	iy, bc
	jr	calc
next2:	ld	bc, (x1)		; (0,0)
	add	ix, bc
	ld	bc, (y1)
	add	iy, bc
calc:	ld	a, iyl					; DIV IY /2
	srl	a			; srl iyl
	ld	iyl, a
	ld	h, a

	ld	a, ixl					; DIV IX /2
	srl	a			; srl ixl
	ld	ixl, a
	ld	l, a

   	sla 	l                     ; calculate screen offset
   	srl 	h
   	rr 	l
  	srl 	h
   	rr 	l
   	srl 	h
   	rr 	l 

	ld	c, 3

   	and 	$03                   ; pixel offset   
   	inc 	a
   	ld 	b,a
   	ld 	a,$fc
pset1: 	rrca
   	rrca
   	rrc 	c
   	rrc 	c
   	djnz 	pset1
   	add 	hl,de			; de = $7800
   	and 	(hl)
   	or 	c
 	ld 	(hl),a
	pop	bc
	djnz	chaos2




;32 loops of 64 LDI's. FAST

	ld 	hl, $7800		; BLIT FROM $7800 BUffer to screen
	ld	de, $7000
	ld	bc, 2048

;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
; Copies exactly 2048 bytes
Copy2048_64LDI:
    ; 2048 / 64 = 32 iterations
Copy64_loop1:
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
    jp      pe, Copy64_loop1



	ld	hl, $9000		; MODE(1) CLS BUFFER at $9000
	ld	de, $7800
	ld	bc, 2048

;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
; Copies exactly 2048 bytes

    ; 2048 / 64 = 32 iterations
Copy64_loop2:
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
    jp      pe, Copy64_loop2
	ret


x1	defb	0
y1	defb	0
x2	defb	127
y2	defb	0
x3	defb	63
y3 	defb	63


;	Hard-coded three points : (x1, y1, x2, y2, x3, y3)
; 	61x three thirds of a circle.
;
points:	defb	63,0,91,46,35,47
	defb	64,0,91,47,35,46
	defb	65,0,90,48,34,45
	defb	66,0,90,49,34,44
	defb	67,0,89,50,33,43
	defb	68,1,89,51,33,42
	defb	69,1,88,52,32,41
	defb	70,1,87,53,32,40
	defb	71,1,86,54,32,39
	defb	72,1,85,55,32,38
	defb	73,1,84,55,32,37
	defb	74,2,83,56,31,36
	defb	75,2,82,57,31,35
	defb	76,3,81,58,31,34
	defb	77,3,80,58,31,33
	defb	78,4,79,59,31,32
	defb	79,4,78,59,31,31
	defb	80,5,77,60,31,30
	defb	81,5,76,60,31,29
	defb	82,6,75,61,31,28
	defb	83,7,74,61,31,27
	defb	84,8,73,62,32,26
	defb	85,8,72,62,32,25
	defb	86,9,71,62,32,24
	defb	87,10,70,62,32,23
	defb	88,11,69,62,32,22
	defb	89,12,68,62,33,21
	defb	89,13,67,63,33,20
	defb	90,14,66,63,34,19
	defb	90,15,65,63,34,18
	defb	91,16,64,63,35,17
	defb	91,17,63,63,35,16
	defb	91,18,62,63,36,15
	defb	92,19,61,63,36,14
	defb	93,20,60,63,37,13
	defb	93,21,59,63,37,12
	defb	94,22,58,62,38,11
	defb	94,23,57,62,39,10
	defb	94,24,56,62,40,9
	defb	94,25,55,62,41,8
	defb	94,26,54,62,42,8
	defb	95,27,53,62,43,7
	defb	95,28,52,61,44,6
	defb	95,29,51,61,45,5
	defb	95,30,50,60,46,5
	defb	95,31,49,60,47,4
	defb	95,32,48,59,48,4
	defb	95,33,47,59,49,3
	defb	95,34,46,58,50,3
	defb	95,35,45,58,51,2
	defb	95,36,44,57,52,2
	defb	95,37,43,56,53,1
	defb	94,37,42,55,54,1
	defb	94,38,41,55,55,1
	defb	94,39,40,54,56,1
	defb	94,40,39,53,57,1
	defb	94,41,38,52,58,1
	defb	93,42,37,51,59,0
	defb	93,43,37,50,60,0
	defb	92,44,36,49,61,0
	defb	91,45,36,48,62,0
	

	org $8000



begin:	di
	
	ld	a, 8		; COLOR,0

	ld	($6800), a
	ld	(30779), a

	ld	hl, PIC1
	call	display
	call	delay
	cALL	delay
	call	delay
	ld	hl, PIC2
	call	display
	call	delay2
	call	delay2

	ld	hl, PIC1
	call	display
	call	delay
	cALL	delay
	call	delay
	call	delay
	ld	hl, PIC2
	call	display
	call	delay2
	ld	hl, PIC1
	call	display
	call	delay


here:	jp	here



display:ld	a, 0
	out	(222), a
	ld	de, $7000
	ld	bc, 2048
	ldir
	ld	a, 1
	out	(222), a
	ld	de, $7000
	ld	bc, 2048
	ldir
	ld	a, 2
	out	(222), a
	ld	de, $7000
	ld	bc, 2048
	ldir

;	call	delay

;	call	key
	ret


delay:	LD 	BC,$d000
	jr	delay3
delay2:	ld	BC, $7000
delay3:	CALL 	0060H		; delay
	ret

key:
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   Press <S> to Start				
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
loop3:	ld 	a, (0x68fd)	
	and	0x02
	jr	z, You_Pressed_S
	jr 	nz, loop3
You_Pressed_S:

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   Press <SPACE> to Start				
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
loop4:	ld 	a, (0x68ef)	
	and	0x10
	jr	z,  You_pressed_space
	jr 	nz, loop4
You_pressed_space:
	ret





PIC1:
	include	"face1.inc"

PIC2:
	include	"face2.inc"

PIC3:
	include	"face3.inc"

PIC4:
	include	"face4.inc"



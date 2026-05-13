/*
3d.c
Demo using standard Wizard 3d and 4d math functions
Copyright© 2002, Mark Hamilton
Flickering (non paged graphics) port to Z88DK by Stefano Bodrato - Oct 2003

-shades !

To Compile:
1) Run once to setup environment:

z88dkenv.bat
------------ -------------------  c:\vz\z88dk\ being your path to Z88 dev kit.
SET Z80_OZFILES=C:\vz\z88dk\lib
SET ZCCCFG=C:\vz\z88dk\lib\config
SET PATH=C:\vz\z88dk\bin;%PATH%


2) _COM4.BAT
zcc +vz -vn %1.c -o %1.vz -lndos -llib3d -create-app



*/






//#include <oz.h>
#include <lib3d.h>
#include <graphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <vz.h>

#define MX	96/2
#define MY	64/2

Vector_t tri[4]
= {     { 0 ,  0,   20 },
	{  -20 ,  -20,   -20 },
	{   20 ,  -20,   -20 },
	{    0 ,   20,    -20 } };




int vz_line2(int x1, int y1, int x2, int y2, int c)
{
  #asm
	ld	hl, 2
	add	hl, sp
	ld	c, (hl)			// get C. C=colour
	inc	hl
	inc	hl
	ld	d, (hl)			// get Y2. d=Y2
	inc	hl
	inc	hl
	ld	e, (hl)			// get X2. e=X2
	inc	hl
	inc	hl
	ld	a, (hl)			// get Y1. temp make A=Y1
	inc	hl
	inc	hl
	ld	l, (hl)			// get X1. L=x1
	ld	h, a			// set h=Y1 from temp A.

   
   ; c = colour
   ; l = x1
   ; h = y1
   ; e = x2
   ; d = y2
   
asmentry:ld a,e
   	cp l
   	jr nc, line1
   	ex de,hl                  ; swap so that x1 < x2
line1:  ld a,e
   	sub l                     ; dx
   	ld e,a                    ; save dx
   	ld a,d
  	 sub h
   	jp c, lup                 ; negative (up)
ldn:	ld d,a                    ; save dy
   	cp e                      ; dy < dx ?
   	jr c, ldnx
ldny:	ld b,a                    ; count = dy
   	srl a                     ; /2 -> overflow
ldny1:	push af		; push return
   	push bc		; push colour
   	push hl		; push Y1/X1
;=============================

;; ----- void __CALLEE__ vz_plot_callee(int x, int y, int c)

   ; l = x
   ; h = y
   ; c = colour

   	ld a,l
   	sla l                     ; calculate screen offset
   	srl h
   	rr l
   	srl h
   	rr l
   	srl h
   	rr l
   	and $03                   ; pixel offset   
   	inc a
   	ld b,a
    	ld a,$fc
pset1:	rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset1
   	add hl, $b000
   	and (hl)
   	or c
   	ld (hl),a
;==================================   
   	pop hl
   	pop bc
   	pop af
   	dec b                     ; done?
   	ret m
   	inc h                     ; y++
   	sub e                     ; overflow -= dx
   	jr nc, ldny1
   	inc l                     ; x++
   	add a,d                   ; overflow += dy
   	jp ldny1
ldnx:	ld a,e                    ; get dx
   	ld b,a                    ; count = dx
   	srl a                     ; /2 -> overflow
ldnx1:	push af
   	push bc
   	push hl
;=============================

   ; l = x
   ; h = y
   ; c = colour

   	ld a,l
   	sla l                     ; calculate screen offset
   	srl h
   	rr l
   	srl h
   	rr l
   	srl h
   	rr l
   	and $03                   ; pixel offset   
   	inc a
   	ld b,a
      	ld a,$fc
pset2:	rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset2
   	add hl, $b000
   	and (hl)
   	or c
   	ld (hl),a
;==================================   
   	pop hl
   	pop bc
   	pop af
   	dec b                     ; done?
   	ret m
   	inc l                     ; x++
   	sub d                     ; overflow -= dy
   	jr nc, ldnx1
   	inc h                     ; y++
   	add a,e                   ; overflow += dx
   	jp ldnx1
lup:	neg                       ; make dy positive
   	ld d,a                    ; save dy
   	cp e                      ; dy < dx ?
   	jr c, lupx
lupy:	ld b,a                    ; count = dy
   	srl a                     ; /2 -> overflow
lupy1:	push af
   	push bc
   	push hl

;=============================

   ; l = x
   ; h = y
   ; c = colour

   	ld a,l
   	sla l                     ; calculate screen offset
   	srl h
   	rr l
   	srl h
   	rr l
   	srl h
   	rr l
   	and $03                   ; pixel offset   
   	inc a
   	ld b,a
   	ld a,$fc
pset3:  rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset3
   	add hl, $b000
   	and (hl)
   	or c
   	ld (hl),a
;==================================   
   	pop hl
   	pop bc
   	pop af
   	dec b                     ; done?
   	ret m
   	dec h                     ; y--
   	sub e                     ; overflow -= dx
   	jr nc, lupy1
   	inc l                     ; x++
   	add a,d                   ; overflow += dy
   	jp lupy1
lupx:	ld a,e                    ; get dx
   	ld b,a                    ; count = dx
   	srl a                     ; /2 -> overflow
lupx1:	push af
   	push bc
   	push hl

;=============================

   ; l = x
   ; h = y
   ; c = colour

   	ld a,l
   	sla l                     ; calculate screen offset
   	srl h
   	rr l
   	srl h
   	rr l
   	srl h
   	rr l
   	and $03                   ; pixel offset   
   	inc a
   	ld b,a
   	ld a,$fc
pset4:  rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset4
   	add hl, $b000
   	and (hl)
   	or c
   	ld (hl),a
;==================================   
   	pop hl
   	pop bc
   	pop af
      	dec b                     ; done?
   	ret m
	inc l                     ; x++
   	sub d                     ; overflow -= dy
   	jr nc, lupx1
   	dec h                     ; y--
   	add a,e                   ; overflow += dx
   	jp lupx1
   #endasm
}








void main(void)
{
	static Vector_t rot;
	static Vector_t t;
	static Cam_t mycam;
	static Point_t p[4];
	static unsigned c = 0;
	static int i;
	static int zf = 150;

	vz_mode(1);

	#asm
	ld	hl, $b000	//fast CLS buffer
	ld	de, $b001
	ld	(hl), 0
	ld	bc, 2048
	ldir
		di
	#endasm
	vz_setbase(0xb000);
	while(1){

		c = 0;
		for(i = 0; i < 4; i++) {
			ozcopyvector(&t,&tri[i]);
			ozrotatepointx(&t, rot.x);
			ozrotatepointy(&t, rot.y);
			ozrotatepointz(&t, rot.z);
			t.z += zf; 			/* zoom factor */
//			ozplotpointcam(&t,&mycam, &p[i]);
			ozplotpoint(&t, &p[i]);
		}
		rot.y = (rot.y+2)%360;
		rot.x = (rot.x+2)%360;
		rot.z = (rot.z+2)%360;

		#asm			
	ld	hl, $b000
	ld	de, $7000
	ld	bc, 1024
	ldir
	ld	bc, 1024
	ldir

	ld	hl, $b000	//fast CLS buffer
	ld	de, $b001
	ld	(hl), 0
	ld	b, 128
lp1:	ldi
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
	djnz	lp1
	



		#endasm

		vz_line2(p[1].x + MX, p[1].y + MY, p[2].x + MX, p[2].y + MY,3);
		vz_line2(p[2].x + MX, p[2].y + MY, p[3].x + MX, p[3].y + MY,3);
		vz_line2(p[3].x + MX, p[3].y + MY, p[1].x + MX, p[1].y + MY,3);
		vz_line2(p[1].x + MX, p[1].y + MY, p[0].x + MX, p[0].y + MY,3);
		vz_line2(p[2].x + MX, p[2].y + MY, p[0].x + MX, p[0].y + MY,3);
		vz_line2(p[3].x + MX, p[3].y + MY, p[0].x + MX, p[0].y + MY,3);

		fill(50,32);		//semi-fake side fill.
	}
}




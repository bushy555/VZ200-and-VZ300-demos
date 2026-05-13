/*
3d.c
Demo using standard Wizard 3d and 4d math functions
Copyright© 2002, Mark Hamilton
Flickering (non paged graphics) port to Z88DK by Stefano Bodrato - Oct 2003


TIE FIGHTER


*/


#include <lib3d.h>
#include <graphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <vz.h>

#define MX	96/2
#define MY	64/2

Vector_t wingl[6] =		// LEFT WING
    {   { -15 , -15,  15 },
	{ -15 , -15,  -15 },
	{ -15 ,  0,   -20 },
	{ -15 ,  15,  -15 },
	{ -15 ,  15,  15 }, 
	{ -15 ,  0,   20 } };

Vector_t centre[10]		// CENTRE CONSOLE
=     { { -5 ,  5,   5 },
	{  5 ,  5,   5 },
	{  5 , -5,   5 },
	{ -5 , -5,   5 },
	{ -5 ,  5,  -5 },
	{  5 ,  5,  -5 },
	{  5 , -5,  -5 },
	{ -5 , -5,  -5 },
	{ -15 , 0,    0 },
	{ 15 ,  0,    0 }};

Vector_t wingr[6] =		// RIGHT WING
    {   { 15 , -15,  15 },
	{ 15 , -15,  -15 },
	{ 15 ,  0,   -20 },
	{ 15 ,  15,  -15 },
	{ 15 ,  15,  15 }, 
	{ 15 ,  0,   20 } };



int vz_line2(int x1, int y1, int x2, int y2, int c)	// DRAWS LINE TO BUFFER AT $B000
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
   
asmentr:ld a,e
   	cp l
   	jr nc, line1
   	ex de,hl                  ; swap so that x1 < x2
line1:	ld a,e
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
	; PLOT (X,Y,C)		; l = x
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
ldnx:   ld a,e                    ; get dx
   	ld b,a                    ; count = dx
   	srl a                     ; /2 -> overflow
ldnx1:	push af
   	push bc
   	push hl
;=============================
	; PLOT (X,Y,C)		; l = x
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
pset2:  rrca
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
	; PLOT (X,Y,C)		; l = x
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
pset3:	rrca
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
	; PLOT (X,Y,C)		; l = x
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
pset4:	rrca
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
	static Vector_t lw;
	static Vector_t cr;
	static Vector_t rw;
	static Vector_t tl;
	static Vector_t tr;
	static Vector_t tc;

	static Point_t pl[6];
	static Point_t pr[6];
	static Point_t pc[10];
	static int i,c;
	static int zf = 0;

	vz_mode(1);

	#asm
		di
	#endasm

	vz_setbase(0xb000);				// Set base B000 for FILL();


	while(c != 13) {
		//if(ozkeyhit()) c = ozngetch();
		//if(getk()) c = fgetc_cons();
		c=getk();
		switch(c) {
			case '1':
				zf -= 10;
				if(zf < -100) zf = -100;
				break;
			case '2':
				zf += 10;
				if(zf > 300) zf = 300;
				break;
			case '3':
				exit (0);
		}



		for(i = 0; i < 6; i++) {		/* left and right wing */
			ozcopyvector(&tl,&wingl[i]);
			ozcopyvector(&tr,&wingr[i]);
			ozrotatepointx(&tl, lw.x);
			ozrotatepointy(&tl, lw.y);
			ozrotatepointz(&tl, lw.z);
			ozrotatepointx(&tr, rw.x);
			ozrotatepointy(&tr, rw.y);
			ozrotatepointz(&tr, rw.z);
			tl.z += zf; 			/* zoom factor left wing*/
			tr.z += zf; 			/* zoom factor right wing*/
			ozplotpoint(&tl, &pl[i]);
			ozplotpoint(&tr, &pr[i]);
		}

		for(i = 0; i < 10; i++) {		/* do centre cube */
			ozcopyvector(&tc,&centre[i]);
			ozrotatepointx(&tc, cr.x);
			ozrotatepointy(&tc, cr.y);
			ozrotatepointz(&tc, cr.z);
			tc.z += zf; 			/* zoom factor for centre*/
			ozplotpoint(&tc, &pc[i]);
		}

		lw.y = (lw.y+2)%360;
		lw.x = (lw.x+2)%360;
		lw.z = (lw.z+2)%360;
		rw.y = (rw.y+2)%360;
		rw.x = (rw.x+2)%360;
		rw.z = (rw.z+2)%360;
		cr.y =  (cr.y+2)%360;
		cr.x =  (cr.x+2)%360;
		cr.z =  (cr.z+2)%360;

		#asm			
	ld	hl, $b000	// fast buffer to screen copy.
	ld	de, $7000	// For future Vsync.
	ld	bc, 1024
	ldir
	ld	bc, 1024
	ldir

	ld	hl, $b000	//fast CLS buffer
	ld	de, $b001
	ld	(hl), 0
	ld	b, 140
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



		vz_line2(pl[0].x + MX, pl[0].y + MY, pl[1].x + MX, pl[1].y + MY,2); //left wing
		vz_line2(pl[1].x + MX, pl[1].y + MY, pl[2].x + MX, pl[2].y + MY,2);
		vz_line2(pl[2].x + MX, pl[2].y + MY, pl[3].x + MX, pl[3].y + MY,2);
		vz_line2(pl[3].x + MX, pl[3].y + MY, pl[4].x + MX, pl[4].y + MY,2);
		vz_line2(pl[4].x + MX, pl[4].y + MY, pl[5].x + MX, pl[5].y + MY,2);
		vz_line2(pl[5].x + MX, pl[5].y + MY, pl[0].x + MX, pl[0].y + MY,2);

		vz_line2(pr[0].x + MX, pr[0].y + MY, pr[1].x + MX, pr[1].y + MY,2); //right wing
		vz_line2(pr[1].x + MX, pr[1].y + MY, pr[2].x + MX, pr[2].y + MY,2);
		vz_line2(pr[2].x + MX, pr[2].y + MY, pr[3].x + MX, pr[3].y + MY,2);
		vz_line2(pr[3].x + MX, pr[3].y + MY, pr[4].x + MX, pr[4].y + MY,2);
		vz_line2(pr[4].x + MX, pr[4].y + MY, pr[5].x + MX, pr[5].y + MY,2);
		vz_line2(pr[5].x + MX, pr[5].y + MY, pr[0].x + MX, pr[0].y + MY,2);

		vz_line2(pc[0].x + MX, pc[0].y + MY, pc[1].x + MX, pc[1].y + MY,2); // centre cube
		vz_line2(pc[1].x + MX, pc[1].y + MY, pc[2].x + MX, pc[2].y + MY,2);
		vz_line2(pc[2].x + MX, pc[2].y + MY, pc[3].x + MX, pc[3].y + MY,2);
		vz_line2(pc[3].x + MX, pc[3].y + MY, pc[0].x + MX, pc[0].y + MY,2);
		vz_line2(pc[4].x + MX, pc[4].y + MY, pc[5].x + MX, pc[5].y + MY,2);
		vz_line2(pc[5].x + MX, pc[5].y + MY, pc[6].x + MX, pc[6].y + MY,2);
		vz_line2(pc[6].x + MX, pc[6].y + MY, pc[7].x + MX, pc[7].y + MY,2);
		vz_line2(pc[7].x + MX, pc[7].y + MY, pc[4].x + MX, pc[4].y + MY,2);
		vz_line2(pc[0].x + MX, pc[0].y + MY, pc[4].x + MX, pc[4].y + MY,2);
		vz_line2(pc[1].x + MX, pc[1].y + MY, pc[5].x + MX, pc[5].y + MY,2);
		vz_line2(pc[2].x + MX, pc[2].y + MY, pc[6].x + MX, pc[6].y + MY,2);
		vz_line2(pc[3].x + MX, pc[3].y + MY, pc[7].x + MX, pc[7].y + MY,2);

		vz_line2(pc[8].x + MX, pc[8].y + MY, pc[9].x + MX, pc[9].y + MY,2); // centre line

	}
}




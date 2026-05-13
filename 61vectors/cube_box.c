/*
3d.c
Demo using standard Wizard 3d and 4d math functions
Copyright© 2002, Mark Hamilton
Flickering (non paged graphics) port to Z88DK by Stefano Bodrato - Oct 2003


-Using VZ_LINE ASM
-box inside a box !

*/

// zcc +zx -vn showlib3d.c -o showlib3d -lndos -llib3d -create-app

//#include <oz.h>
#include <lib3d.h>
#include <graphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <vz.h>

#define MX	60
#define MX2	60
#define MY	64/2

Vector_t cube[9]
=     { { -20 ,  20,   20 },
	{  20 ,  20,   20 },
	{  20 , -20,   20 },
	{ -20 , -20,   20 },
	{ -20 ,  20,  -20 },
	{  20 ,  20,  -20 },
	{  20 , -20,  -20 },
	{ -20 , -20,  -20 }};


Vector_t cube2[9]
=     { { -10 ,  10,   10 },
	{  10 ,  10,   10 },
	{  10 , -10,   10 },
	{ -10 , -10,   10 },
	{ -10 ,  10,  -10 },
	{  10 ,  10,  -10 },
	{  10 , -10,  -10 },
	{ -10 , -10,  -10 }};



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
; 	c = colour
; 	l = x1
; 	h = y1
; 	e = x2
; 	d = y2

   	ld a,e
   	cp l
   	jr nc, line1
   	ex de,hl                  ; swap so that x1 < x2
line1: 	ld a ,e
   	sub l                     ; dx
   	ld e,a                    ; save dx
   	ld a,d
   	sub h
   	jp c, lup                 ; negative (up)
ldn:   	ld d,a                    ; save dy
   	cp e                      ; dy < dx ?
   	jr c, ldnx
ldny:  	ld b,a                    ; count = dy
   	srl a                     ; /2 -> overflow
ldny1: 	push af		; push return
   	push bc		; push colour
   	push hl		; push Y1/X1
;=============================
; 	VZPLOT()   ; 	l = x
		   ; 	h = y
		   ; 	c = colour
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
pset1: 	rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset1
	add hl, $B000
   	and (hl)
   	or c
   	ld (hl),a
;==================================   
   	pop hl
;   	pop de
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
ldnx:  	ld a,e                    ; get dx
   	ld b,a                    ; count = dx
   	srl a                     ; /2 -> overflow
ldnx1: 	push af
   	push bc
   	push hl
;=============================
; 	VZPLOT()   ; 	l = x
		   ; 	h = y
		   ; 	c = colour
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
pset2: 	rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset2
	add hl, $B000
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
lup:   	neg                       ; make dy positive
   	ld d,a                    ; save dy
   	cp e                      ; dy < dx ?
   	jr c, lupx
lupy:  	ld b,a                    ; count = dy
   	srl a                     ; /2 -> overflow
lupy1: 	push af
   	push bc
   	push hl
;=============================
; 	VZPLOT()   ; 	l = x
		   ; 	h = y
		   ; 	c = colour
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
pset3: 	rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset3
	add hl, $B000
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
lupx:  	ld a,e                    ; get dx
   	ld b,a                    ; count = dx
   	srl a                     ; /2 -> overflow
lupx1: 	push af
   	push bc
   	push hl
;=============================
; 	VZPLOT()   ; 	l = x
		   ; 	h = y
		   ; 	c = colour
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
pset4: 	rrca
   	rrca
   	rrc c
   	rrc c
   	djnz pset4
	add hl, $B000
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
	static Vector_t rot2;
	static Vector_t t2;
	static Cam_t cam;
	static Cam_t cam2;
	static Point_t p[10];
	static Point_t p2[10];
	static unsigned c = 0;
	static int i;
	static int zf = 50;
	static int zf2 = 150;

	vz_mode(1);

	#asm
		di
	#endasm

	while(1){

		c = 0;
		for(i = 0; i < 8; i++) {
			ozcopyvector(&t,&cube[i]);
			ozrotatepointx(&t, rot.x);
			ozrotatepointy(&t, rot.y);
			ozrotatepointz(&t, rot.z);
			ozcopyvector(&t2,&cube2[i]);
			ozrotatepointx(&t2, rot2.x);
			ozrotatepointy(&t2, rot2.y);
			ozrotatepointz(&t2, rot2.z);
			t.z += zf; 			/* zoom factor */
			t2.z += zf2; 			/* zoom factor */
//			ozplotpointcam(&t, &cam, &p[i]);
//			ozplotpointcam(&t2,&cam2, &p2[i]);
			ozplotpoint(&t,  &p[i]);
			ozplotpoint(&t2, &p2[i]);
		}
		rot.y = (rot.y+1)%360;
		rot.x = (rot.x+1)%360;
		rot.z = (rot.z+1)%360;
		rot2.y = (rot2.y+3)%360;
		rot2.x = (rot2.x+3)%360;
		rot2.z = (rot2.z+3)%360;

		#asm			
			ld	hl, $b000	// blit from buffer to screen.
			ld	de, $7000
			ld	bc, 2048
			ldir
	
			ld	hl, $b000	// COPY background.
			ld	de, $b001
			ld	(hl), 0
			ld	bc, 2048
			ldir
		#endasm


// small blue box
		vz_line2(p2[0].x + MX2, p2[0].y + MY, p2[1].x + MX2, p2[1].y + MY,2);
		vz_line2(p2[1].x + MX2, p2[1].y + MY, p2[2].x + MX2, p2[2].y + MY,2);
		vz_line2(p2[2].x + MX2, p2[2].y + MY, p2[3].x + MX2, p2[3].y + MY,2);
		vz_line2(p2[3].x + MX2, p2[3].y + MY, p2[0].x + MX2, p2[0].y + MY,2);
		vz_line2(p2[4].x + MX2, p2[4].y + MY, p2[5].x + MX2, p2[5].y + MY,2);
		vz_line2(p2[5].x + MX2, p2[5].y + MY, p2[6].x + MX2, p2[6].y + MY,2);
		vz_line2(p2[6].x + MX2, p2[6].y + MY, p2[7].x + MX2, p2[7].y + MY,2);
		vz_line2(p2[7].x + MX2, p2[7].y + MY, p2[4].x + MX2, p2[4].y + MY,2);
		vz_line2(p2[0].x + MX2, p2[0].y + MY, p2[4].x + MX2, p2[4].y + MY,2);
		vz_line2(p2[1].x + MX2, p2[1].y + MY, p2[5].x + MX2, p2[5].y + MY,2);
		vz_line2(p2[2].x + MX2, p2[2].y + MY, p2[6].x + MX2, p2[6].y + MY,2);
		vz_line2(p2[3].x + MX2, p2[3].y + MY, p2[7].x + MX2, p2[7].y + MY,2);


//big box
		/* top face */
		vz_line2(p[0].x + MX, p[0].y + MY, p[1].x + MX, p[1].y + MY,3);
		vz_line2(p[1].x + MX, p[1].y + MY, p[2].x + MX, p[2].y + MY,3);
		vz_line2(p[2].x + MX, p[2].y + MY, p[3].x + MX, p[3].y + MY,3);
		vz_line2(p[3].x + MX, p[3].y + MY, p[0].x + MX, p[0].y + MY,3);

		/* bottom face */
		vz_line2(p[4].x + MX, p[4].y + MY, p[5].x + MX, p[5].y + MY,3);
		vz_line2(p[5].x + MX, p[5].y + MY, p[6].x + MX, p[6].y + MY,3);
		vz_line2(p[6].x + MX, p[6].y + MY, p[7].x + MX, p[7].y + MY,3);
		vz_line2(p[7].x + MX, p[7].y + MY, p[4].x + MX, p[4].y + MY,3);

		/* side faces */
		vz_line2(p[0].x + MX, p[0].y + MY, p[4].x + MX, p[4].y + MY,3);
		vz_line2(p[1].x + MX, p[1].y + MY, p[5].x + MX, p[5].y + MY,3);
		vz_line2(p[2].x + MX, p[2].y + MY, p[6].x + MX, p[6].y + MY,3);
		vz_line2(p[3].x + MX, p[3].y + MY, p[7].x + MX, p[7].y + MY,3);




	}
}




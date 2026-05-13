/*
3d.c
Demo using standard Wizard 3d and 4d math functions
Copyright© 2002, Mark Hamilton
Flickering (non paged graphics) port to Z88DK by Stefano Bodrato - Oct 2003


Using VZ_LINE ASM
*/

// zcc +zx -vn showlib3d.c -o showlib3d -lndos -llib3d -create-app

//#include <oz.h>
#include <lib3d.h>
#include <graphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <vz.h>

#define MX	128/2
#define MY	64/2

Vector_t dec[20]
= {  {	13 ,	13 ,	13 },
     {	-13 ,	13 ,	13 },
     {	-13 ,	-13, 	13 },
     {	-13 ,	-13 ,	-13 },
     {	13 ,	-13 ,	13 },
     {	13 ,	-13 ,	-13 },
     {	13 ,	13 ,	-13 },
     {	-13, 	13 ,	-13 },
     {	0 ,	8 ,	21 },
     {	0 ,	-8 ,	21 },
     {	0 ,	-8 ,	-21 },
     {	0 ,	8 ,	-21 },
     {	8 ,	21 ,	0 },
     {	-8 ,	21 ,	0 },
     {	-8, 	-21 ,	0 },
     {	8 ,	-21 ,	0 },
     {	21 ,	0 ,	8 },
     {	21 ,	0 ,	-8 },
     {	-21 ,	0 ,	-8 },
     {	-21 ,	0 ,	8 }};






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
	static Vector_t t;
	static Point_t p[20];
	static unsigned c = 0;
	static int i,j,k;
	static int zf = 0;
	static int MY2;

	vz_mode(1);
	#asm
	di
	#endasm
	k=0;
   j=0;
	MY2=MY;
	while(1){
	
		for(i = 0; i < 20; i++) {
			ozcopyvector(&t,&dec[i]);
			ozrotatepointx(&t, rot.x);
			ozrotatepointy(&t, rot.y);
			ozrotatepointz(&t, rot.z);
//			t.z += zf; 			/* zoom factor */
			ozplotpoint(&t, &p[i]);
		}
		rot.y = (rot.y+1)%360;
		rot.x = (rot.x+2)%360;
		rot.z = (rot.z+2)%360;
        
        




	
		#asm			
	ld	hl, $b000	// buffer to screen copy.
	ld	de, $7000	
	ld	bc, 2048
	ldir

	ld	hl, $b000	//fast CLS buffer
	ld	de, $b001
	ld	(hl), 170
	ld	b, 96
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
		 {vz_line2(p[0].x + MX, p[0].y + MY2, p[8].x + MX, p[8].y + MY2,1);}
		 {vz_line2(p[0].x + MX, p[0].y + MY2, p[12].x + MX, p[12].y + MY2,1);}
		 {vz_line2(p[0].x + MX, p[0].y + MY2, p[16].x + MX, p[16].y + MY2,1);}
		 {vz_line2(p[1].x + MX, p[1].y + MY2, p[8].x + MX, p[8].y + MY2,1);}
		 {vz_line2(p[1].x + MX, p[1].y + MY2, p[13].x + MX, p[13].y + MY2,1);}
		 {vz_line2(p[1].x + MX, p[1].y + MY2, p[19].x + MX, p[19].y + MY2,1);}
		 {vz_line2(p[2].x + MX, p[2].y + MY2, p[9].x + MX, p[9].y + MY2,1);}
		 {vz_line2(p[2].x + MX, p[2].y + MY2, p[14].x + MX, p[14].y + MY2,1);}
		 {vz_line2(p[2].x + MX, p[2].y + MY2, p[19].x + MX, p[19].y + MY2,1);}
		 {vz_line2(p[3].x + MX, p[3].y + MY2, p[10].x + MX, p[10].y + MY2,1);}
		 {vz_line2(p[3].x + MX, p[3].y + MY2, p[14].x + MX, p[14].y + MY2,1);}
		 {vz_line2(p[3].x + MX, p[3].y + MY2, p[18].x + MX, p[18].y + MY2,1);}
		 {vz_line2(p[4].x + MX, p[4].y + MY2, p[9].x + MX, p[9].y + MY2,1);}
		 {vz_line2(p[4].x + MX, p[4].y + MY2, p[15].x + MX, p[15].y + MY2,1);}
		 {vz_line2(p[4].x + MX, p[4].y + MY2, p[16].x + MX, p[16].y + MY2,1);}
		 {vz_line2(p[5].x + MX, p[5].y + MY2, p[10].x + MX, p[10].y + MY2,1);}
		 {vz_line2(p[5].x + MX, p[5].y + MY2, p[15].x + MX, p[15].y + MY2,1);}
		 {vz_line2(p[5].x + MX, p[5].y + MY2, p[17].x + MX, p[17].y + MY2,1);}
		 {vz_line2(p[6].x + MX, p[6].y + MY2, p[11].x + MX, p[11].y + MY2,1);}
		 {vz_line2(p[6].x + MX, p[6].y + MY2, p[12].x + MX, p[12].y + MY2,1);}
		 {vz_line2(p[6].x + MX, p[6].y + MY2, p[17].x + MX, p[17].y + MY2,1);}
		 {vz_line2(p[7].x + MX, p[7].y + MY2, p[11].x + MX, p[11].y + MY2,1);}
		 {vz_line2(p[7].x + MX, p[7].y + MY2, p[13].x + MX, p[13].y + MY2,1);}
		 {vz_line2(p[7].x + MX, p[7].y + MY2, p[18].x + MX, p[18].y + MY2,1);}
		 {vz_line2(p[8].x + MX, p[8].y + MY2, p[9].x + MX, p[9].y + MY2,1);}
		 {vz_line2(p[10].x + MX, p[10].y + MY2, p[11].x + MX, p[11].y + MY2,1);}
		 {vz_line2(p[12].x + MX, p[12].y + MY2, p[13].x + MX, p[13].y + MY2,1);}
		 {vz_line2(p[14].x + MX, p[14].y + MY2, p[15].x + MX, p[15].y + MY2,1);}
		 {vz_line2(p[16].x + MX, p[16].y + MY2, p[17].x + MX, p[17].y + MY2,1);}
		 {vz_line2(p[18].x + MX, p[18].y + MY2, p[19].x + MX, p[19].y + MY2,1);}

	
//1-9 	1-13	1-17				
//2-9	2-14	2-20	
//3-10  3-15    3-20
//4-11	4-15	4-19		
//5-10	5-16	5-17				
//6-11	6-16	6-18			
//7-12	7-13	7-18			
//8-12	8-14	8-19		
//9-10											
//11-12									
//13-14							
//15-16					
//17-18			
//19-20	

	}
}




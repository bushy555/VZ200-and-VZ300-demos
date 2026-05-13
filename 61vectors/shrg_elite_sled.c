/*

  
Somewhat Elite in 256x192.	SLED.
	  
USE  1, 2, 3 to rotate.
USE	 Q, A, M, <comma> to move.
		


*/

// zcc +zx -vn showlib3d.c -o showlib3d -lndos -llib3d -create-app

//#include <oz.h>
#include <lib3d.h>
#include <graphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <vz.h>

#define MX	120
#define MX2	120
#define MY	64






Vector_t sled[18]
=     { { -10 ,   0, -10 },	// base
	{ -10 ,   0, 10  },
	{  10 ,   0, 10  },
	{  10 ,   0, -10 },
	{   0 ,  -15, -3 },	// top point
	{   0 ,  -35, -3 },	//aerial
	{ -11 ,  3,  -12 },	// rear feet.
	{ -9 ,   3,  -12 },
	{ 11 ,   3,  -12 },
	{  9 ,   3,  -12 },
	{ -12 ,  3,  28 },	// front feet
	{ -8 ,   3,  28 },
	{ 12 ,   3,  28 },
	{  8 ,   3,  28 },
	{ -3 ,  -6,  6 },	// Nose
	{  3 ,  -6,  6 },
	{  0 ,  -10, 4 },
	{  0 ,  -8,  12 }};



int vz_line2(int x1, int y1, int x2, int y2)
{
  #asm
	ld	hl, 2
	add	hl, sp
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
   
asmentry:
   ld a,e
   cp l
   jr nc, line1
   ex de,hl                  ; swap so that x1 < x2
line1:
   ld a,e
   sub l                     ; dx
   ld e,a                    ; save dx
   ld a,d
   sub h
   jp c, lup                 ; negative (up)
ldn:
   ld d,a                    ; save dy
   cp e                      ; dy < dx ?
   jr c, ldnx
ldny:
   ld b,a                    ; count = dy
   srl a                     ; /2 -> overflow
ldny1:
   push af		; push return
   push bc		; push colour
   push de
   push hl		; push Y1/X1


;==================================   
;10 POKE 30779,PEEK(30779) OR 2:OUT 222,2:MODE(1)
;20 OUT222,1:MODE(1):OUT222,0:MODE(1)
;30 OUT222,Y/64
;40 PA=28672+32*(Y AND 63)+INT(X/8)
;50 X1=2^(7-(X AND 7))
;60 POKE PA,PEEK(PA)OR X1		SET
;70 POKE PA,PEEK(PA)AND255-X1		RESET


   ; l = x
   ; h = y

	ld	a, h
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	out	(222), a

	ld	a, l		
	and	7		; a = X AND 7
	ld	c, a
	ld	b, 0
	ld	ix, lut 
	add	ix, bc
	ld	e, (ix)		; b = X1			
	srl	l		; X/8
	srl	l
	srl	l
	ld	b, 0
	ld	c, l		; c = X/8
	ld	a, h		
	and	63		; a = Y AND 63
	ld	h, 0		; 32*...
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl		; hl = 32*(Y AND 63)
	add	hl, bc		; Add int(X/8)	
	ld	bc, 28672	
	add	hl, bc		
	ld	a, (hl)
	or	e
	ld	(hl), a
	



;==================================   
   pop hl
   pop de
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
ldnx:
   ld a,e                    ; get dx
   ld b,a                    ; count = dx
   srl a                     ; /2 -> overflow
ldnx1:
   push af
   push bc
   push de
   push hl



;10 POKE 30779,PEEK(30779) OR 2:OUT 222,2:MODE(1)
;20 OUT222,1:MODE(1):OUT222,0:MODE(1)
;30 OUT222,Y/64
;40 PA=28672+32*(Y AND 63)+INT(X/8)
;50 X1=2^(7-(X AND 7))
;60 POKE PA,PEEK(PA)OR X1		SET
;70 POKE PA,PEEK(PA)AND255-X1		RESET


   ; l = x
   ; h = y

	ld	a, h
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	out	(222), a

	ld	a, l		
	and	7		; a = X AND 7
	ld	c, a
	ld	b, 0
	ld	ix, lut 
	add	ix, bc
	ld	e, (ix)		; b = X1			
	srl	l		; X/8
	srl	l
	srl	l
	ld	b, 0
	ld	c, l		; c = X/8
	ld	a, h		
	and	63		; a = Y AND 63
	ld	h, 0		; 32*...
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl		; hl = 32*(Y AND 63)
	add	hl, bc		; Add int(X/8)	
	ld	bc, 28672	
	add	hl, bc		
	ld	a, (hl)
	or	e
	ld	(hl), a
	




;==================================   
   pop hl
   pop de
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
lup:
   neg                       ; make dy positive
   ld d,a                    ; save dy
   cp e                      ; dy < dx ?
   jr c, lupx
lupy:
   ld b,a                    ; count = dy
   srl a                     ; /2 -> overflow
lupy1:
   push af
   push bc
   push de
   push hl

 ;=============================
;10 POKE 30779,PEEK(30779) OR 2:OUT 222,2:MODE(1)
;20 OUT222,1:MODE(1):OUT222,0:MODE(1)
;30 OUT222,Y/64
;40 PA=28672+32*(Y AND 63)+INT(X/8)
;50 X1=2^(7-(X AND 7))
;60 POKE PA,PEEK(PA)OR X1		SET
;70 POKE PA,PEEK(PA)AND255-X1		RESET


   ; l = x
   ; h = y

	ld	a, h
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	out	(222), a

	ld	a, l		
	and	7		; a = X AND 7
	ld	c, a
	ld	b, 0
	ld	ix, lut 
	add	ix, bc
	ld	e, (ix)		; b = X1			
	srl	l		; X/8
	srl	l
	srl	l
	ld	b, 0
	ld	c, l		; c = X/8
	ld	a, h		
	and	63		; a = Y AND 63
	ld	h, 0		; 32*...
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl		; hl = 32*(Y AND 63)
	add	hl, bc		; Add int(X/8)	
	ld	bc, 28672	
	add	hl, bc		
	ld	a, (hl)
	or	e
	ld	(hl), a
	





;==================================   


   pop hl
   pop de
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
lupx:
   ld a,e                    ; get dx
   ld b,a                    ; count = dx
   srl a                     ; /2 -> overflow
lupx1:
   push af
   push bc
   push de
   push hl



;=============================

;10 POKE 30779,PEEK(30779) OR 2:OUT 222,2:MODE(1)
;20 OUT222,1:MODE(1):OUT222,0:MODE(1)
;30 OUT222,Y/64
;40 PA=28672+32*(Y AND 63)+INT(X/8)
;50 X1=2^(7-(X AND 7))
;60 POKE PA,PEEK(PA)OR X1		SET
;70 POKE PA,PEEK(PA)AND255-X1		RESET


   ; l = x
   ; h = y

	ld	a, h
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a
	out	(222), a

	ld	a, l		
	and	7		; a = X AND 7
	ld	c, a
	ld	b, 0
	ld	ix, lut 
	add	ix, bc
	ld	e, (ix)		; b = X1			
	srl	l		; X/8
	srl	l
	srl	l
	ld	b, 0
	ld	c, l		; c = X/8
	ld	a, h		
	and	63		; a = Y AND 63
	ld	h, 0		; 32*...
	ld	l, a
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, hl		; hl = 32*(Y AND 63)
	add	hl, bc		; Add int(X/8)	
	ld	bc, 28672	
	add	hl, bc		
	ld	a, (hl)
	or	e
	ld	(hl), a
	



;==================================   




   pop hl
   pop de
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

lut:	defb	128,64,32,16,8,4,2,1



   #endasm
}




void main(void)
{
	static Vector_t rot;
	static Vector_t t;
	static Point_t  p[18];


	static unsigned c = 0;
	static int i;
	static int zf = 50;
	static int zf2 = 140;
	static int tmp, x1;
	static int I1, J1, tmp, x1;


	vz_setbase(0x7000);
	wpoke(30779, wpeek(30779) | 2);
	vz_setbase(0x7000);
	outp(222,2);
   	vz_mode(1);
	outp(222,1);
   	vz_mode(1);
	outp(222,0);
   	vz_mode(1);

	I1 = MX2;
	J1 = MY;
	

//	background();

	#asm
		di
	#endasm

	while(1){

		c = 0;

		for(i=0;i<18;i++) {
			ozcopyvector(&t,&sled[i]);	// Table
			ozrotatepointx(&t, rot.x);
			ozrotatepointy(&t, rot.y);
			ozrotatepointz(&t, rot.z);
			t.z += -zf2; 			// Zoom factor
			ozplotpoint(&t, &p[i]);
		}

		c=getk();
		switch(c) {
			case '1':
				rot.y = (rot.y+5)%360;			// add rotation
				break;
			case '2':
				rot.x = (rot.x+5)%360;				
				break;
			case '3':
				rot.z = (rot.z+5)%360;
				break;


		case 'Q':
			J1=J1-3;
			break;
		case 'A':
			J1=J1+3;
			break;
		case 'M':
			I1=I1-3;
			break;
		case ',':
			I1=I1+3;
			break;

		}



		
		#asm			
		ld	a, 0
		out (222), a
		ld	hl, $7000	// CLS buffer
		ld	de, $7001
		ld	(hl), 0
		ld	bc, 2048
		ldir

		ld	a, 1
		out (222), a
		ld	hl, $7000	// CLS buffer
		ld	de, $7001
		ld	(hl), 0
		ld	bc, 2048
		ldir

		ld	a, 2
		out (222), a
		ld	hl, $7000	// CLS buffer
		ld	de, $7001
		ld	(hl), 0
		ld	bc, 2048
		ldir

		#endasm



/*
		#asm			
		ld	a, 0
		out (222), a
		ld	hl, $b000	// blit from buffer to screen.
		ld	de, $7000
		ld	bc, 2048
		ldir

		ld	a, 1
		out (222), a
		ld	hl, $b000	// blit from buffer to screen.
		ld	de, $7000
		ld	bc, 2048
		ldir

		ld	a, 3
		out (222), a
		ld	hl, $b000	// blit from buffer to screen.
		ld	de, $7000
		ld	bc, 2048
		ldir

		ld	hl, $b000	// CLS buffer
		ld	de, $b001
		ld	(hl), 0
		ld	bc, 2048
		ldir
		#endasm
*/


//=================
//	SLED
//=================


	vz_line2(p[ 0].x+I1,p[ 0].y+J1,p[ 1].x+I1,p[ 1].y+J1); //base
	vz_line2(p[ 1].x+I1,p[ 1].y+J1,p[ 2].x+I1,p[ 2].y+J1);
	vz_line2(p[ 2].x+I1,p[ 2].y+J1,p[ 3].x+I1,p[ 3].y+J1);
	vz_line2(p[ 3].x+I1,p[ 3].y+J1,p[ 0].x+I1,p[ 0].y+J1);
	vz_line2(p[ 0].x+I1,p[ 0].y+J1,p[ 4].x+I1,p[ 4].y+J1); //top
	vz_line2(p[ 1].x+I1,p[ 1].y+J1,p[ 4].x+I1,p[ 4].y+J1);
	vz_line2(p[ 2].x+I1,p[ 2].y+J1,p[ 4].x+I1,p[ 4].y+J1);
	vz_line2(p[ 3].x+I1,p[ 3].y+J1,p[ 4].x+I1,p[ 4].y+J1);
	vz_line2(p[ 4].x+I1,p[ 4].y+J1,p[ 5].x+I1,p[ 5].y+J1); // aerial
	vz_line2(p[ 6].x+I1,p[ 6].y+J1,p[ 7].x+I1,p[ 7].y+J1); //back feet
	vz_line2(p[ 8].x+I1,p[ 8].y+J1,p[ 9].x+I1,p[ 9].y+J1);
	vz_line2(p[10].x+I1,p[10].y+J1,p[11].x+I1,p[11].y+J1); // front feet
	vz_line2(p[12].x+I1,p[12].y+J1,p[13].x+I1,p[13].y+J1); 
	vz_line2(p[ 6].x+I1,p[ 6].y+J1,p[10].x+I1,p[10].y+J1); // back to front (4) lines
	vz_line2(p[ 7].x+I1,p[ 7].y+J1,p[11].x+I1,p[11].y+J1); // back to front (4) lines
	vz_line2(p[ 8].x+I1,p[ 8].y+J1,p[12].x+I1,p[12].y+J1); // back to front (4) lines
	vz_line2(p[ 9].x+I1,p[ 9].y+J1,p[13].x+I1,p[13].y+J1); // back to front (4) lines
	vz_line2(p[14].x+I1,p[14].y+J1,p[15].x+I1,p[15].y+J1); // nose
	vz_line2(p[15].x+I1,p[15].y+J1,p[16].x+I1,p[16].y+J1); // nose
	vz_line2(p[16].x+I1,p[16].y+J1,p[14].x+I1,p[14].y+J1); // nose
	vz_line2(p[14].x+I1,p[14].y+J1,p[17].x+I1,p[17].y+J1); // nose
	vz_line2(p[15].x+I1,p[15].y+J1,p[17].x+I1,p[17].y+J1); // nose
	vz_line2(p[16].x+I1,p[16].y+J1,p[17].x+I1,p[17].y+J1); // nose


/*
	vz_line2(p[0].x+I1,p[0].y+J1,p[1].x+I1,p[1].y+J1); //centre
	vz_line2(p[1].x+I1,p[1].y+J1,p[2].x+I1,p[2].y+J1);
	vz_line2(p[2].x+I1,p[2].y+J1,p[3].x+I1,p[3].y+J1);
	vz_line2(p[3].x+I1,p[3].y+J1,p[0].x+I1,p[0].y+J1);

	vz_line2(p[4].x+I1,p[4].y+J1,p[5].x+I1,p[5].y+J1); //bottom
	vz_line2(p[5].x+I1,p[5].y+J1,p[7].x+I1,p[7].y+J1);
	vz_line2(p[7].x+I1,p[7].y+J1,p[6].x+I1,p[6].y+J1);
	vz_line2(p[6].x+I1,p[6].y+J1,p[4].x+I1,p[4].y+J1);

	vz_line2(p[0].x+I1,p[0].y+J1,p[4].x+I1,p[4].y+J1); //bottom verticals
	vz_line2(p[1].x+I1,p[1].y+J1,p[5].x+I1,p[5].y+J1);
	vz_line2(p[2].x+I1,p[2].y+J1,p[7].x+I1,p[7].y+J1);
	vz_line2(p[3].x+I1,p[3].y+J1,p[6].x+I1,p[6].y+J1);

	vz_line2(p[0].x+I1,p[0].y+J1,p[8].x+I1,p[8].y+J1); //rear verticals
	vz_line2(p[1].x+I1,p[1].y+J1,p[9].x+I1,p[9].y+J1);

	vz_line2(p[8].x+I1,p[8].y+J1,p[9].x+I1,p[9].y+J1);    // Top front angled bonnet
	vz_line2(p[10].x+I1,p[10].y+J1,p[11].x+I1,p[11].y+J1);
	vz_line2(p[8].x+I1,p[8].y+J1,p[10].x+I1,p[10].y+J1);
	vz_line2(p[9].x+I1,p[9].y+J1,p[11].x+I1,p[11].y+J1);
	vz_line2(p[10].x+I1,p[10].y+J1,p[3].x+I1,p[3].y+J1);
	vz_line2(p[11].x+I1,p[11].y+J1,p[2].x+I1,p[2].y+J1);

	vz_line2(p[12].x+I1,p[12].y+J1,p[13].x+I1,p[13].y+J1); // rear square gun
	vz_line2(p[13].x+I1,p[13].y+J1,p[15].x+I1,p[15].y+J1);
	vz_line2(p[15].x+I1,p[15].y+J1,p[14].x+I1,p[14].y+J1);
	vz_line2(p[14].x+I1,p[14].y+J1,p[12].x+I1,p[12].y+J1);

	vz_line2(p[16].x+I1,p[16].y+J1,p[17].x+I1,p[17].y+J1); // front square gun
	vz_line2(p[17].x+I1,p[17].y+J1,p[19].x+I1,p[19].y+J1); 
	vz_line2(p[19].x+I1,p[19].y+J1,p[18].x+I1,p[18].y+J1);
	vz_line2(p[18].x+I1,p[18].y+J1,p[16].x+I1,p[16].y+J1);

	vz_line2(p[12].x+I1,p[12].y+J1,p[18].x+I1,p[18].y+J1); // rear to front gun
	vz_line2(p[13].x+I1,p[13].y+J1,p[19].x+I1,p[19].y+J1);
	vz_line2(p[14].x+I1,p[14].y+J1,p[16].x+I1,p[16].y+J1);
	vz_line2(p[15].x+I1,p[15].y+J1,p[17].x+I1,p[17].y+J1);

*/



	}
}




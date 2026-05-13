;    Technical demo: sliding overlapping rectangles
;    (C)2021 Miguel A. Rodriguez-Jodar ( mcleod_ideafix )
;            ZX Projects.
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <https://www.gnu.org/licenses/>.
;
;    Assemble using PASMO: pasmo --tapbas sliding_rectangles.asm sliding_rectangles.tap
;======================================================
;
; Found posted on the Z80/ZX Facebook group. Grabbed and modified for VZ by Dave.
;
; 307 bytes.     03/Oct/2021.
; Impossible aim --> 256 bytes.
;
;
; Assemble for VZ by using PASMO. 
;        pasmo --alocal rec.asm a.obj
;        rbinary a.obj pas.vz
;        del /q a.obj
;===================================================



X                       equ 0                     ; offset to X and Y coordinate
Y                       equ 1                     ; of top left pixel of rectangle
WIDTH                   equ 2                     ; offset to width and height
HEIGHT                  equ 3                     ;
SPEEDPAT                equ 4                     ; offset to binary pattern indicating which frame the rectangle is animated
SPEEDMULT               equ 5                     ; offset to value indicating how many pixels the rectangle is moved
LSTRU                   equ 6                     ; length of all fields above.

; PIXEL_ADDRESS           equ 22B1h                 
;			Original ZX routine at $22B1.
; 			C=x, B=y, A=y. Returns HL=address, A=x mod 8


                        org 	$8000

Main                    proc



;GM0	OUT 32,0	64x64		Color			1024 bytes
;GM1	OUT 32,4	128x64		Monochrome		1024 bytes

			ld	a, 8
			ld 	($6800),a 		; mode (1)


	ld	a, $8		; GM0. Colour. 64x64.
	ld	(30779), a
	ld	($6800), a

	ld	a, 4
	ld	c, 32
	out	(c), a

;	ld	a, $4		; GM1. Monochrome 128x64.
;	ld	(30779), a
;	ld	($6800), a


                        xor 	a                     	; CLS 
                        ld 	hl,28672   
                        ld 	de,28673   
                        ld 	bc,2048    
                        ld 	(hl),a            
                        ldir                      
			di

                        ld 	ix,RectTable           ; RectTable contains a list of rectangles
InitialParseTable       ld 	a,(ix+HEIGHT)
                        inc 	a
                        jr 	z,EndInitialDrawing    ; A rectangle with height=255 marks the end of the list

						      ; DrawInitialRectangle
                        ld 	d,(ix+HEIGHT)         ;
                        ld 	c,(ix+X)              ; Retrieve rectangle parameters
                        ld 	b,(ix+Y)              ; from the current entry of RectTable
                        ld 	e,(ix+WIDTH)          ;
DrawOneLine             call 	DrawLine              ;
                        inc 	b                     ; simple loop to draw a rectangle by drawing all the horizontal
                        dec 	d                     ; lines that comprises it.
                        jr 	nz,DrawOneLine        ;

                        ld 	de,LSTRU
                        add 	ix,de                 ; next rectangle
                        jr 	InitialParseTable
EndInitialDrawing

LoopMoveAll         	;    ld a,(23560)              ; Read last pressed key
                    	;    cp 32                     ; if SPACE is presssed, then
                    	;    ret z                     ; return to BASIC

                        ld 	ix,RectTable           ; Now we parse RectTable to move the rectangles
ParseTable              ld 	a,(ix+HEIGHT)
                        inc 	a                     ;
                        jr 	z,LoopMoveAll          ; if we reach the end of the table, start it all over again
                        call 	MoveOneRectangle     ; move one rectangle
                        ld 	de,LSTRU
                        add 	ix,de                 ; next rectangle
                        jr 	ParseTable
                        endp




MoveOneRectangle        proc
                        ld 	a,(ix+SPEEDPAT)        ; load SPEEDPAT for current rect
                        rrc 	(ix+SPEEDPAT)         ; and rotate it for the next frame
                        bit 	0,a                   ; time to animate this rect?
                        ret 	z
                        ld 	b,(ix+SPEEDMULT)       ; load how many pixels we have to move this rectangle
Move1PixelDown          push 	bc
                        ld 	d,(ix+HEIGHT)
                        ld 	c,(ix+X)
                        ld 	b,(ix+Y)
                        ld 	e,(ix+WIDTH)
                        call 	DrawLine             ; Draws the top line of the rectangle (actually erasing it)
                        ld 	a,b
                        add 	a,d
                        call 	AdjustBottomScreen
                        ld 	b,a                    ; Move to the line below the last line of the rectangle and draws it
                        call 	DrawLine
                        ld 	a,(ix+Y)
                        inc 	a                     ; This rectangle has moved 1 pixel.
                        call 	AdjustBottomScreen
                        ld 	(ix+Y),a
                        pop 	bc
                        djnz 	Move1PixelDown       ; Go back to move it again, if needed
                        ret
                        endp


AdjustBottomScreen      proc
                        jr 	nc,NoAdjustOverflow    ;
                        sub 	64                   ; Computes A mod 192
                        ret                       ; even if A overflowed
NoAdjustOverflow        cp 	64                    ; after an addition (i.e.
                        ret 	c                     ; 180 + 100 = 280, which
                        sub 	64                   ; doesn't fit in 8 bits)
                        ret                       ; This is to roll back to the top of the screen
                        endp


DrawLine  		proc
        push bc
        push de
				; C = X-axis.  B = Y-Axis.

; =============================================================================
; VZ : Get HL address from (X,Y)
; ------------------------------

	push	de
	push	bc


;	get_hl1	
;	h = y offset (0-63),  	l = x offset (0-127)
;	outputs : HL = address,    	: a = pixel colour

        sla     c              	 ; calculate screen offset
        srl     b
        rr      c
        srl     b
        rr      c
        srl     b
        rr      c
	ld	hl, $7000
	add	hl, bc		; HL = screen address

	pop	bc			
				

; Divide c by 8 and return in d, remainder in a.
idiv   	xor 	a
       	ld 	b,8          	; bits to shift.
idiv0  	sla 	c               ; multiply d by 2.
       	rla                 	; shift carry into remainder.
       	cp 	8               ; test if e is smaller.
       	jr 	c,idiv1         ; e is greater, no division this time.
       	sub 	8               ; subtract it.
       	inc 	c               ; rotate into d.
idiv1  	djnz 	idiv0

	pop	de

;; =============================================================================

                        ld 	c,a                    ;
                        or 	a                      ; Pixel 0 of this byte?
                        ld 	a,255                 ; Assume we fill the entire 8-pixel row
                        jr 	z,DontShiftRight       ; So there's no need to shift the 8-pixel row
                        ld 	b,a                    ;
ShiftRight              srl 	a                     ; Not pixel 0, so we shift to the right until pixel B
                        djnz 	ShiftRight           ;
DontShiftRight          xor 	(hl)                  ; OVER 1 with screen
                        ld 	(hl),a                 ; and store

                        ld 	a,8                    ;
                        sub 	c                     ; Compute how many pixels we painted in the code before
                        ld 	c,a                    ; and update E (line width) so there are less pixels to paint
                        ld 	a,e                    ;
                        sub 	c                     ;

Paint8Pixels            cp 	9                      ; If there are less than 9 pixels still to paint...
                        ld 	e,a
                        inc 	hl
                        jr 	c,PaintRightSide       ; then go calculate how many of them and paint them
                        ld 	a,(hl)                 ; If there are more than 8 pixels, then a complete 8-pixel row can be painted
                        cpl                       ; just by OVERing 1 the current 8-pixel row
                        ld 	(hl),a                 ; and storing it again
                        ld 	a,e                    ;
                        sub 	8                     ; 8 more pixels painted
                        jr 	Paint8Pixels           ; go see if there are still more than 8 pixels

PaintRightSide          ld 	a,128                  ; We generate a value in A with just one high bit at the left (bit 7)
ShiftRightSide          dec 	e                     ; If this is was the only pixel to paint
                        jr 	z,FinishShift          ; then go paint it
                        sra 	a                     ; If not, first replicate the 1-bit at bit 7 as much times as pixels are left to paint
                        jr 	ShiftRightSide
FinishShift             xor 	(hl)                  ; combine it with the current screen contents
                        ld 	(hl),a                 ; and store it

                        pop de
                        pop bc
                        ret
                        endp


  	; Format: each db line is a rectangle.
        ; x-coordinate (0-246), y coordinate (0-191), width (must be > 8), height (1-191), animation pattern, animation mutiplier
        ; Rectangle must initially fit on screen
        ; Animation pattern: each frame, bit 0 of this value is checked. If 0, the rectangle is not moved down. If 1, it is moved down.
        ; Whether it has been moved or not, this value rotates one bit to the right
        ; Animation multiplier: if the animation pattern bit is 1, this value indicates how many pixels the rectangle has to be moved.
        ;
        ; Animation pattern can be crafted to get slower than 1 pixel/frame moving
        ; For fast moving rectangles, use a higher animation multiplier


RectTable   	db 004,000,060,006, 10101010b,1
                db 010,030,024,022, 10101010b,3
                db 016,020,028,010, 11111111b,1
                db 020,002,122,004, 11111111b,1
                db 030,028,050,020, 11011011b,2
                db 064,038,050,008, 00000001b,1
                db 076,040,030,018, 10001000b,1
                db 080,028,092,006, 00001001b,2
                db 104,030,020,026, 00100101b,1
                db 255,255,255,255,255         ; end of table

                end Main



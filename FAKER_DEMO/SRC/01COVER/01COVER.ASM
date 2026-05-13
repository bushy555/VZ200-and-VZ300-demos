; THE COVER of FAKER
; ==================
;	...done over about three nights whilst binge watching 
; 	'The 100' with the wifey.  She laughs at me for spending
;	so much time (hours, and sometimes weeks!), just to plot a 
;	pixel in the right spot on the screen.
;	Today is about the 12th April 2026.   And is now 24th April.
;			
;	Assemble with the Z80 assembler 'PASMO'. 
;
;	Parts 1 & 2: Lots of dodgie stuff done throughout all of the effects.	
;       9.8kb snapshot, requiring memory up to $C800
;	May or may not run correctly on a standalone VZ300/Laser310.
;

; PART 1   =========================================================
; VZ / LASER COVER "FAKER"
; VZ200/VZ300 Plasma (128x64) — Fast per-nibble +1 colour rotate
; Colours: 00=Green -> 01=Yellow -> 10=Blue -> 11=Red -> 00
; No IX, no PUSH/POP BC. Table is page-aligned for LD L,A indexing.
; ===============================================================
;
;
; PART 2   =====================================================
; VZ200 / VZ300 MODE(1) - SINUS SCROLLER + HORIZONTAL COLOUR BARS BACKGROUND
; ============================================================
; Done by Dave , useless friggin spastic crappy Copilot, and Claude.
; April 2026.   Some near 100 hours have been spent on part 2!   FFS.
; A-Z & 0-9 16x16 fonts included which arent used, but are for future projects.
;
;
; ==========================================
;

        org     $8000
vram    equ     $7000          ; video RAM start (2KB)
latch   equ     $6800          ; mode / vsync latch
BYTES   equ     2048
BUFFER_ORIGIN	equ $B800	; Buffer1 2k at C000. Buffer2 2k at C8000. off-screen video buffer (2KB)
buff1 	equ 	$B8		; find: djm1.   -change the byte offset label.
buff2 	equ 	$c0		; find: djm2.	-change the byte offset label.


; ------------------------------------------------------------
; Enter graphics mode
; ------------------------------------------------------------
start:  di
        ld      a,8
        ld      (latch),a      	; MODE(1)

	ld	hl, buffer	; CLS buffer
	ld	(hl), 0
	ld	de, buffer+1
	ld	bc, 4192	; do all 4k. 2048
	ldir
	ld	hl, $7000	; CLS screen
	ld	(hl), 0
	ld	de, $7001
	ld	bc, 2048
	ldir


	call	delay
	call	delay
	call	delay
	call	delay


	call	ina		; Good old SPLIT in effect. 
				; Modified from old C source code.

; ------------------------------------------------------------
; Build 256-byte lookup table for 2-bit-per-pixel +1 (mod 4)
; For each 2-bit pair (x1:x0):
;   y0 = ~x0
;   y1 = x1 XOR x0
; Byte-wide formula:
;   new = (~x & 0x55) | ((x & 0xAA) ^ ((x & 0x55) << 1))
; ------------------------------------------------------------
        ld      hl, rot2        ; HL points to start of table
        ld      c, 0            ; C = 0..255 (256 entries)
mk_tbl: ld      a, c            ; x
        ld      e, a            ; keep original x in E
        ld      a, e	        ; t = (x & 0x55) << 1
        and     %01010101
        add     a, a
        ld      d, a            ; D = t
        ld      a, e		; msb_part = (x & 0xAA) ^ t
        and     %10101010
        xor     d
        ld      d, a            ; D = msb_part
        ld      a,e		; lsb_part = (~x & 0x55)
        cpl
        and     %01010101
        or      d	        ; combine and store
        ld      (hl),a
        inc     hl
        inc     c
        jr      nz, mk_tbl      ; 256 entries when C wraps

; ------------------------------------------------------------
; Copy initial 2048x $1B image into buffer
; ------------------------------------------------------------
        ld      hl, image1
        ld      de, buffer
        ld      bc, BYTES
        ldir


;==========================
; STEP 1
;==========================
; Faker flashes.
; Background rotates.
;
; ------------------------------------------------------------
; Main loop: rotate colours in buffer, vsync, copy to VRAM
; ------------------------------------------------------------
	ld	bc, $4500
plasy:	push	bc		; --- Fast per-byte transform using page-aligned table ---
        ld      h, HIGH(rot2)   ; keep H fixed to table page
        ld      de, buffer
        ld      bc, BYTES
rotlp:  ld      a,(de)          ; read 4 pixels
        ld      l,a             ; HL = rot2 + A  (page-aligned!)
        ld      a,(hl)          ; rotated result
        ld      (de),a          ; write back to buffer
        inc     de
        dec     bc		        ; BC 16-bit down-counter (no PUSH/POP)
        ld      a,b
        or      c
        jr      nz, rotlp
        ld      hl, latch
sync2:  bit     7,(hl)
        jr      nz, sync2
;       ld      hl, latch
;sync3: bit     7,(hl)
;       jr      nz, sync3
        ld      hl, buffer		        ; --- Blit buffer to video RAM ---
        ld      de, vram
        ld      bc, BYTES
						;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
						; Copies exactly 2048 bytes
Copy2048_64LDI0:				    	; 2048 / 64 = 32 iterations
Copy64_loop0:
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
    	jp      pe, Copy64_loop0
    	pop	bc
    	djnz	plasya
    	jr	herea
plasya:	jp      plasy
herea:





;==========================
; STEP 2
;==========================
; Faker DOES not flash.
; Background rotates.
;

	ld	bc, $3000		; OUTER LOOP.   $40 to 0.
plasy2:	push	bc		        ; --- Fast per-byte transform using page-aligned table ---
        ld      h, HIGH(rot2)   ; keep H fixed to table page
        ld      de, buffer
        ld      bc, BYTES
rotlp2: ld      a,(de)          ; read 4 pixels
        ld      l,a             ; HL = rot2 + A  (page-aligned!)
        ld      a,(hl)          ; rotated result
        ld      (de),a          ; write back to buffer
        inc     de
        dec     bc		        ; BC 16-bit down-counter (no PUSH/POP)
        ld      a,b
        or      c
        jr      nz, rotlp2
        ld      hl, latch
sync22: bit     7,(hl)
        jr      nz, sync22
;       ld      hl, latch
;sync3: bit     7,(hl)
;       jr      nz, sync3


	ld	de, buffer+(17*32)
	ld	hl, image2-16
	ld	bc, 22*32
	ldir


        ld      hl, buffer		        ; --- Blit buffer to video RAM ---
        ld      de, vram
        ld      bc, BYTES

						;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
						; Copies exactly 2048 bytes
Copy2048_64LDI2:				    	; 2048 / 64 = 32 iterations
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
    	pop	bc
    	djnz	plasyab
 	jr	herec		; JUMP BACK TO plasy2, so that the image2 is pushed down the screen.
plasyab:jp      plasy2
herec:



;==========================
; STEP 3
;==========================
; Faker SCROLLS down
; Background rotates.
;

	ld	ix, 0
	ld	c, 70
plasy4:	push	bc		        ; --- Fast per-byte transform using page-aligned table ---
        ld      h, HIGH(rot2)   ; keep H fixed to table page
        ld      de, buffer
        ld      bc, BYTES
rotlp4: ld      a,(de)          ; read 4 pixels
        ld      l,a             ; HL = rot2 + A  (page-aligned!)
        ld      a,(hl)          ; rotated result
        ld      (de),a          ; write back to buffer
        inc     de
        dec     bc		        ; BC 16-bit down-counter (no PUSH/POP)
        ld      a,b
        or      c
        jr      nz, rotlp4
        ld      hl, latch
sync24: bit     7,(hl)
        jr      nz, sync24
;       ld      hl, latch
;sync24:bit     7,(hl)
;       jr      nz, sync24




	ld	de, buffer+(17*32)
	push	ix
	pop	hl
	add	hl, de
	ld	d, h
	ld	e, l

	ld	hl, image2-16-32
	ld	bc, 22*32
	push	de
	ldir
	ld	hl, buffer; $7001
	ld	bc, 64
	pop	de
	ldir
        ld      hl, buffer		        ; --- Blit buffer to video RAM ---
        ld      de, vram
        ld      bc, BYTES

						;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
						; Copies exactly 2048 bytes
Copy2048_64LDI4:				    	; 2048 / 64 = 32 iterations
Copy64_loop4:
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
    	jp      pe, Copy64_loop4
herec4:	ld	de, 32
	push	ix
	pop	hl
	add	hl, de
	push	hl
	pop	ix
	pop	bc
        dec     c		        ; BC 16-bit down-counter (no PUSH/POP)
        ld      a,c
        or      c
        jp      nz, plasy4


















; ============================================================
; VZ200 / VZ300 MODE(1) - SINUS SCROLLER + HORIZONTAL COLOUR BARS BACKGROUND
; ============================================================
; Done by Dave , useless friggin spastic crappy Copilot, and Claude.
; April 2026.
;
; Frame structure each loop:
;   1. DRAW_BARS  -> fills VRAM $7000 with 4 colour bars
;   2. Clear off-screen buffer $A000
;   3. Render sinus scroller characters into $A000
;   4. OR $A000 onto VRAM so text appears over bars
;   5. Advance frame counter, delay, repeat
;
; VRAM layout: 64 rows x 32 bytes = 2048 bytes at $7000
; Each byte holds 4 x 2-bit pixels (MODE 1)
;   00=black  01=green  10=red  11=blue
; ============================================================


  DI
        LD A,8
        LD ($6800),A          ; set MODE(1)
        XOR A
        LD (FRAME),A
        LD (FRAME+1),A
        LD HL,64
        LD (BASE_X),HL

; ============================================================
MAIN_LOOP:

	; Ultra fast 2x 2k buffer CLS.

    LD   (SavedSP),SP

    LD   SP,buffer+2048      ; one past VRAM
    LD   DE,$0      ; blue (10101010)
    LD   B,$0           ; 256 pushes × 4 = 1024
ClearLoop:
    PUSH DE
    PUSH DE
    PUSH DE
    PUSH DE
     DJNZ ClearLoop

    LD   SP,buffer+2048+2048      ; one past VRAM
    LD   DE,$aaaa     ; blue (10101010)
    LD   B,0           ; 256 pushes × 4 = 1024
ClearLoop2:
    PUSH DE
    PUSH DE
    PUSH DE
    PUSH DE
     DJNZ ClearLoop2


    LD   SP,(SavedSP)





        ; 1. Draw colour bars into VRAM
        CALL DRAW_BARS


        ; 3. Scroll BASE_X left; wrap when underflowed ($FFxx)
        LD HL,(BASE_X)
        DEC HL
        LD (BASE_X),HL
        LD A,H
        CP $FF
        JP NZ,OK_X
        LD HL,128
        LD (BASE_X),HL
OK_X:

        ; 4. Render each message character into $A000
        LD HL,MESSAGE
        LD (MSG_PTR),HL
        XOR A
        LD (CHAR_INDEX),A

CHAR_LOOP:
        LD HL,(MSG_PTR)
        LD A,(HL)
        OR A
        JP Z,END_CHARS

        ; ASCII -> font index: font base is '@' (ASCII 64)
        SUB 64
        JP C,SKIP_CHAR
        CP 27
        JP NC,SKIP_CHAR

        ; Font pointer = FONT16 + index*64 (each glyph = 16 rows * 4 bytes)
        LD L,A
        LD H,0
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD DE,FONT16
        ADD HL,DE
        LD (FONT_PTR),HL

        ; Sinus Y for this character
        LD A,(CHAR_INDEX)
        ADD A,A
        LD HL,(FRAME)
        ADD A,L
        AND 31
        LD L,A
        LD H,0
        LD DE,SCRL_SIN
        ADD HL,DE
        LD A,(HL)
        LD (BASE_Y),A

        ; X pixel position: BASE_X + char_index*16
        LD HL,(BASE_X)
        LD A,(CHAR_INDEX)
        ADD A,A
        ADD A,A
        ADD A,A
        ADD A,A
        LD E,A
        LD D,0
        ADD HL,DE
        LD (CUR_X),HL
        LD B,16               ; 16 rows per character glyph
ROW_LOOP:
 ;       PUSH BC
        ; Screen row = BASE_Y + (16-B)  i.e. BASE_Y+15 down to BASE_Y+0
        LD A,(BASE_Y)
        ADD A,B
        DEC A
        CP 64
        JP NC,SKIP_ROW        ; skip if off screen
        ; Off-screen buffer row address: $A000 + row*32
        LD L,A
        LD H,0
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL             ; HL = row*32
        LD A, buff1	; $C0	; $A0			;DJM1
        ADD A,H
        LD H,A                ; HL = $A000 + row*32
        ; Add byte column from X (4 pixels per byte, so /4)
        LD DE,(CUR_X)
        SRL D
        RR E
        SRL D
        RR E                  ; DE = CUR_X / 4
        ADD HL,DE
        ; Write 4 bytes of glyph row
        LD DE,(FONT_PTR)
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        LD A,(DE)
        LD (HL),A
        INC HL
        INC DE
        LD A,(DE)
        LD (HL),A

SKIP_ROW:
        ; Advance font pointer to next glyph row (4 bytes)
        LD HL,(FONT_PTR)
        LD DE,4
        ADD HL,DE
        LD (FONT_PTR),HL

;        POP BC
        DJNZ ROW_LOOP
SKIP_CHAR:
        LD HL,(MSG_PTR)
        INC HL
        LD (MSG_PTR),HL
        LD A,(CHAR_INDEX)
        INC A
        LD (CHAR_INDEX),A
        JP CHAR_LOOP

END_CHARS:
        ; 5. OR text buffer $A000 onto VRAM $7000
        ;    This composites text pixels on top of colour bars.
        ;    2048 bytes = 8 passes of 256 (B=0 gives 256 DJNZ iterations)
        LD 	HL,buffer2 ; $A800
        LD 	DE,buffer  ; $A000
        LD 	C,8
OR_OUTER:LD 	B,0
OR_INNER:
	ld 	a, (de)
	ld 	b, a
	LD 	A,(HL)
;       OR 	(DE)  ;   <--- spastic COPILOT CREATED THIS! Left here to bag it out.
	or 	b
        LD 	(DE),A
        INC 	HL
        INC 	DE
	DJNZ 	OR_INNER
        DEC 	C
        JP 	NZ,OR_OUTER
        LD 	HL,(FRAME)	        ; Advance 16-bit frame counter
        INC 	HL
        LD 	(FRAME),HL

	ld	hl, buffer	; $a000
	ld	de, $7000
	ld	bc, 2048
;	ldir

; FAST LDIR - Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
; Copies exactly 2048 bytes
Copy2048_64LDI:
    ; 2048 / 64 = 32 iterations
Copy64_loop:
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
    jp      pe, Copy64_loop


        JP MAIN_LOOP

; ============================================================
; DRAW_BARS
; Fills VRAM $7000-$77FF with 4 horizontal colour bands.   ($A000 new buffer)
; Band stack Y moves via BAR_SIN table (64 entries).
; Each band: 4 rows tall, contiguous, no gaps.
; Corrupts: AF, BC, DE, HL, IX
; ============================================================
DRAW_BARS:

        ; Bar base Y = BAR_SIN[FRAME & 63]
        LD A,(FRAME)
        AND 63
        LD L,A
        LD H,0
        LD DE,BAR_SIN
        ADD HL,DE
        LD A,(HL)             ; A = top row of bar stack (0-47)
        LD (BAR_BASE_Y),A
        LD IX,BAR_COLORS
        LD B,4                ; 4 colour bands

BAR_LOOP:
        ; Band start Y = BAR_BASE_Y + band_index*4
        ; band_index = 4-B  (0 for top band, 3 for bottom)
        LD A,4
        SUB B                 ; A = 0,1,2,3
        ADD A,A
        ADD A,A               ; A = 0,4,8,12 (row offset for each band)
        LD C,A
        LD A,(BAR_BASE_Y)
        ADD A,C               ; A = first row Y of this band
        AND 63
        LD E,(IX+0)           ; colour fill byte
        INC IX
        LD C,4                ; 4 rows per band
BAND_ROW_LOOP:
        CP 64                 ; skip if Y wrapped off-screen
        JP NC,BAND_SKIP_ROW

        ; Compute VRAM address: $7000 + Y*32
        LD D,A                ; save current row Y in D
        LD L,A
        LD H,$0
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL             ; HL = Y*32
        LD A,buff2	; $C8	; $A8; $70	; $A800  second buffer	; djm2
        ADD A,H
        LD H,A                ; HL = $7000 + Y*32

        ; Fill the 32 bytes of this VRAM row
FILL_ROW:
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD (HL),E
        INC HL
        LD A,D                ; restore row Y
BAND_SKIP_ROW:
        INC A
        AND 63
        DEC C
        JP NZ,BAND_ROW_LOOP
        DJNZ BAR_LOOP
        RET




delay:	

	LD	hl, $fffe		
loop1f1:	nop
	DEC	hl
	LD	A, l
	OR	h
	JR	NZ, loop1f1
	ret







; ==================================================================
; ==================================================================
; ==================================================================
;
;// -------------------------------------------- 
;// Horizontal SPLIT-IN screen effect            
;// -------------------------------------------- 
ina:
;
;	Originally written in C back in ~2001 for VZ Cave game.
;	SCREEN LOCATION IN MEMORY AT intro_screen
; 	SCREEN DUMPED TO VIDEO AT $7000
;
;	for(i=1;i<1024+32;i=i+32){ 		
;	   memcpy(0x7800-i+1,0xe000+1024,i);
;	   memcpy(0x7000    ,0xe000+1024-i+1,i);
;	   for(j=0;j<200;j++){}
;	}

	ld	ix, 0
	ld	a, 0
splitin1:cp	32			; for(i=1;i<1024+32;i=i+32){ 		
	jr	z, splitin2
	inc	a
	push	ix
	pop	hl
	push	bc
	ld	bc, 32
	add	hl, bc
	pop	bc
	push	hl
	pop	ix			; ix=ix+32
	LD 	hl, 0x6800
spltin1:BIT 	7, (hl)			; fancy wait retrace.
	jr	NZ, spltin1
	LD 	hl, 0x6800
spltin2:BIT 	7, (hl)			; fancy wait retrace.
	jr	Z, spltin2
	ld	de, $7000
	ld	hl, intro_screen+1024 	;	   memcpy(0x7000    ,0xe000+1024-i+1,i);
	push	ix
	pop	bc
	sbc	hl, bc
	push	ix
	pop	bc
	ldir
	ld	hl, $7800		;	   memcpy(0x7800-i+1,0xe000+1024,i);
	push	ix
	pop	bc
	sbc	hl, bc
	inc	l
	push	hl
	pop	de
	ld	hl, intro_screen + 1025
	push	ix
	pop	bc
	ldir
	jr	splitin1
splitin2:ret


; ------------------------------------------------------------
; Page-aligned lookup table storage (filled at runtime)
; IMPORTANT: rot2 must sit at low byte = 0 for LD L,A indexing.
; We place it explicitly at $8200 (page boundary).
; ------------------------------------------------------------
;        org     $8200

  org (($+256) & $FF00)   ; unconditional 256-byte alignment

rot2:
        defs    256             ; 256-byte table (uninitialized; built at runtime)

; ------------------------------------------------------------
; Initial image (2KB) placed after the table; safe gap to buffer
; ------------------------------------------------------------
;        org     $8300
  org (($+256) & $FF00)   ; unconditional 256-byte alignment

image1:
file:
intro_screen:
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$015,$055,$01B,$0AA,$0AA,$09B,$01B,$01B,$01B,$01B

image2:
defb $03F,$0DB,$01B,$01B,$01B,$01B,$015,$055,$055,$05B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$019,$055,$055,$050,$001,$01B,$025,$055,$06A,$0AA,$09B,$01B,$0FF
defb $0EF,$03F,$0FF,$0FF,$0D5,$055,$07F,$0FF,$0FF,$05B,$01B,$0AA,$0AA,$0AA,$0AB,$01B
defb $01B,$01B,$015,$054,$000,$000,$000,$001,$01B,$019,$055,$055,$0AB,$01B,$0FE,$0AA
defb $0BB,$03A,$0AA,$0BF,$0FF,$0FF,$0FF,$0FF,$0FF,$05A,$0AA,$000,$000,$000,$00B,$01B
defb $01B,$01B,$019,$040,$000,$000,$000,$007,$01B,$025,$055,$055,$09B,$01B,$01E,$0AA
defb $0DB,$01E,$0AA,$0DB,$01F,$0FF,$0FF,$0FF,$0FF,$05B,$0A0,$000,$000,$000,$002,$01B
defb $01B,$01B,$01B,$010,$000,$000,$055,$047,$01B,$025,$056,$055,$09B,$01B,$01E,$0AA
defb $0DB,$0FA,$0AF,$01B,$01F,$0FF,$0FD,$055,$057,$05B,$018,$000,$000,$000,$002,$01B
defb $01B,$01B,$01B,$010,$000,$055,$01B,$047,$01B,$095,$05A,$055,$09B,$01B,$03A,$0AA
defb $0DB,$0AA,$0BB,$01B,$01F,$0FF,$0F7,$01B,$059,$05B,$020,$002,$000,$000,$000,$09B
defb $01B,$01B,$01B,$040,$000,$05B,$01B,$047,$01A,$055,$05A,$055,$06B,$01B,$03A,$0AB
defb $01E,$0AB,$0DB,$01B,$07F,$0FF,$0F7,$019,$05B,$05B,$020,$002,$0A0,$000,$002,$01B
defb $01B,$01B,$01B,$040,$000,$05B,$05B,$047,$01A,$055,$06A,$055,$06B,$01B,$0EA,$0AB
defb $0FA,$0AF,$01B,$01B,$07F,$0FF,$0DB,$055,$01B,$01B,$080,$00B,$020,$000,$002,$01B
defb $01B,$01B,$019,$000,$001,$015,$01B,$01B,$019,$055,$06A,$055,$06B,$01B,$0EA,$0AB
defb $0AA,$0AF,$01B,$01B,$07F,$0FF,$0D5,$0FD,$01B,$01B,$080,$00B,$020,$000,$002,$01B
defb $01B,$01B,$019,$000,$001,$050,$01B,$01B,$019,$055,$09A,$055,$06B,$01B,$0EA,$0AA
defb $0AA,$0AB,$01B,$01B,$07F,$0FF,$0FF,$0FD,$01B,$01A,$000,$02B,$080,$000,$002,$01B
defb $01B,$01B,$014,$000,$001,$000,$01B,$01B,$025,$055,$0A5,$055,$06B,$01B,$0AA,$0AA
defb $0AA,$0AB,$01B,$01B,$07F,$0FF,$0FF,$0F7,$01B,$01A,$000,$02A,$000,$000,$00B,$01B
defb $01B,$01B,$014,$000,$000,$000,$01B,$01B,$095,$056,$055,$055,$06B,$01B,$0AA,$0AF
defb $0AA,$0AA,$0DB,$019,$0FF,$0FF,$0D5,$0F7,$01B,$018,$000,$000,$000,$000,$02B,$01B
defb $01B,$01B,$014,$000,$000,$000,$05B,$01B,$095,$055,$055,$055,$06B,$01E,$0AA,$0AF
defb $0EA,$0AA,$0DB,$019,$0FF,$0FF,$05B,$057,$019,$018,$000,$000,$000,$00A,$09B,$01B
defb $01B,$01B,$010,$000,$005,$054,$05B,$01A,$055,$055,$055,$055,$05B,$01E,$0AA,$0AF
defb $0EA,$0AA,$0DB,$019,$0FF,$0FD,$01B,$01B,$017,$020,$000,$000,$000,$02B,$01B,$01B
defb $01B,$01B,$010,$000,$007,$014,$05B,$019,$055,$05A,$0AA,$055,$05B,$01E,$0AA,$0AF
defb $03A,$0AA,$0BB,$019,$0FF,$0FD,$01B,$01B,$057,$020,$002,$0A0,$00A,$09B,$01B,$01B
defb $01B,$01B,$040,$000,$007,$019,$05B,$019,$055,$06B,$01A,$055,$05B,$03A,$0AA,$0BB
defb $03A,$0AA,$0BB,$019,$0FF,$0F7,$01B,$019,$0DB,$080,$002,$020,$002,$01B,$01B,$01B
defb $01B,$01B,$040,$000,$01B,$019,$05B,$025,$055,$06B,$01A,$055,$05A,$03A,$0AA,$0BB
defb $01E,$0AA,$0BB,$017,$0FF,$0D5,$05B,$017,$0DB,$080,$00B,$018,$000,$0AB,$01B,$01B
defb $01B,$019,$000,$000,$01B,$01B,$05B,$025,$055,$09B,$01A,$055,$056,$0AA,$0AA,$0BB
defb $01E,$0AA,$0AF,$017,$0FF,$0FF,$0F5,$05F,$05A,$000,$00B,$018,$000,$00B,$01B,$01B
defb $01B,$015,$000,$000,$01B,$01B,$01A,$095,$055,$09B,$019,$056,$0AA,$0AA,$0AA,$0BB
defb $01F,$0AA,$0AF,$017,$0FF,$0FF,$0FF,$0FF,$05A,$000,$00B,$018,$000,$002,$01B,$01B
defb $01B,$050,$000,$000,$01B,$01B,$029,$056,$0AA,$0AB,$0A5,$0AB,$02A,$0AA,$0AA,$0BB
defb $0FF,$0FA,$0AF,$07F,$0FF,$0FF,$0FF,$0FD,$028,$000,$002,$01A,$000,$002,$09B,$01B
defb $019,$055,$055,$000,$007,$01B,$0AA,$0AB,$01B,$01A,$0AA,$01B,$01B,$03F,$0FE,$0BB
defb $01B,$01F,$0FF,$055,$055,$0FF,$0FF,$0FD,$0AA,$0A8,$002,$01A,$002,$0AB,$01B,$01B
defb $01B,$01B,$01B,$055,$055,$01B,$01B,$01B,$01B,$01A,$01B,$01B,$01B,$01B,$01B,$0FF
defb $01B,$01B,$01B,$01B,$01B,$055,$055,$057,$01B,$01A,$0AA,$098,$0AB,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01A,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B
defb $01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B,$01B

image3:
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B
defb $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B



; ============================================================
; Variables
; ============================================================
FRAME:          DW 0
BASE_X:         DW 0
CUR_X:          DW 0
BASE_Y:         DB 0
BAR_BASE_Y:     DB 0
FONT_PTR:       DW 0
MSG_PTR:        DW 0
CHAR_INDEX:     DB 0
SavedSP:	DW 0

; ============================================================
; SCRL_SIN: 32-entry sine for scroller Y (rows 16-31)
; Keeps 16-row glyphs safely within the 64-row display
; ============================================================
SCRL_SIN:
        DB 24,25,26,27,28,29,30,31
        DB 31,30,29,28,27,26,25,24
        DB 23,22,21,20,19,18,17,16
        DB 16,17,18,19,20,21,22,23

; ============================================================
; BAR_SIN: 64-entry sine for bar Y (values 0-47)
; Bar stack = 16 rows tall so max base Y = 47 keeps all bands on screen
; ============================================================
BAR_SIN:
        DB 21,24,27,30,32,34,36,38
        DB 40,41,43,44,45,46,47,47
        DB 47,47,47,46,45,44,43,41
        DB 40,38,36,34,32,30,28,26
        DB 24,22,20,18,16,14,12,10
        DB  8, 7, 5, 4, 3, 2, 1, 1
        DB  0, 0, 0, 1, 1, 2, 3, 4
        DB  5, 7, 8,10,12,14,16,18

; ============================================================
; BAR_COLORS: MODE(1) fill bytes, one per band
;   Bit-pair per pixel: 00=black 01=green 10=red 11=blue
;   $55 = 01010101 = solid green			<-- copilot comments suck!
;   $AA = 10101010 = solid red
;   $FF = 11111111 = solid blue
;   $6A = 01101010 = green+red mix (cyan-ish)
; ============================================================
BAR_COLORS:
        DB $55                ; band 0  green <---copilot sucks balls. Left these comments in. 6 months in
        DB $AA                ; band 1  red        and F'ing copilot still can not remember, or learn, even
        DB $FF                ; band 2  blue       with my own written supplied rules, that 55=yellow,
        DB $55                ; band 3  mixed      aa=blue, ff=red.  It just sucks.

; CSS0: 00=green, 55=yellow, AA=blue, FF=red.
; CSS1: 00=buff,  55=cian,   AA=magenta, FF=orange.

; ============================================================
MESSAGE:
        DB "  VZ LASER  ",0
; db " VZ ABCDEF",0
; db " GHIJKLMNO",0
; db " PQRSTUVWX",0
; db " YZ A B C",0
; db " DAVE WAS ERE",0
; db " HELLO VZ LASER WORLD",0


; ============================================================
FONT16:
; ================= SPACE =================
DS 64,0

; ================= A =================
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%00000000,%00000110,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01010101,%01010110,%01000000
DB %00011010,%10101010,%10101010,%10000000
DB %00011010,%10101010,%10101010,%10000000
DB %00011010,%01010101,%01010110,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01010101,%01010110,%01000000
DB %00000110,%10101010,%10100100,%00000000
DB %00000110,%10101010,%10100100,%00000000

; ================= B =================
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011010,%01010101,%01010110,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000

; ================= C =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011001,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000

; ================= D =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010101,%01010100,%00000000
DB %00000110,%10101010,%10100100,%00000000
DB %00000110,%10101010,%10100100,%00000000
DB %00011001,%01010101,%01010110,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01010101,%01010110,%01000000
DB %00000110,%10101010,%10100100,%00000000
DB %00000110,%10101010,%10100100,%00000000
DB %00000101,%01010101,%01010100,%00000000

; ================= E =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011010,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= F =================
DB %00000001,%01010101,%01010101,%01000000
DB %00011010,%10101010,%10101010,%10000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011010,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= G =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00000101,%01100000
DB %00011010,%01000000,%00000101,%01100000
DB %00011010,%01000001,%01010101,%01100000
DB %00011010,%01000010,%10101010,%10000000
DB %00011010,%01000010,%10101010,%10000000
DB %00011010,%01000001,%01010101,%01100000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= H =================
DB %00000101,%01010000,%00000101,%01010000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101001,%01010101,%01101000
DB %00011010,%10101001,%01010101,%01101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101001,%01010101,%01101000
DB %00011010,%10101001,%01010101,%01101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00011010,%10101000,%00001010,%10101000
DB %00000000,%00000000,%00000000,%00000000

; ================= I =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= J =================
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000001,%01010101,%01010101,%01000000

; ================= K =================
DB %00000101,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%10100000
DB %00011010,%01000000,%00101010,%00000000
DB %00011010,%01000000,%10100010,%00000000
DB %00011010,%01000101,%10000000,%00000000
DB %00011010,%01000101,%10000000,%00000000
DB %00011010,%01000010,%10100000,%00000000
DB %00011010,%01000000,%00101010,%00000000
DB %00011010,%01000000,%00101010,%00000000
DB %00011010,%01000010,%10100000,%00000000
DB %00011010,%01000101,%10000000,%00000000
DB %00011010,%01000101,%10000000,%00000000
DB %00011010,%01000010,%10100000,%00000000
DB %00011010,%01000000,%00101010,%00000000
DB %00011010,%01000000,%00000000,%10100000
DB %00000000,%00000000,%00000000,%00000000

; ================= L =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%10100000,%00000000,%00000000

; ================= M =================
DB %00000101,%01010000,%00000000,%01010000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10100000,%00000101,%01000000
DB %00011010,%10010101,%01000110,%01010100
DB %00011010,%10101010,%00000001,%10101010
DB %00011010,%10101000,%00000000,%00101010
DB %00011010,%10100000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00001010
DB %00000000,%00000000,%00000000,%00000000

; ================= N =================
DB %00000101,%01010000,%00000000,%01010000
DB %00011010,%10100000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00101010
DB %00011010,%10100000,%00000000,%10011010
DB %00011010,%10100000,%00000001,%01101010
DB %00011010,%10100000,%00000101,%01001010
DB %00011010,%10100000,%00010101,%00001010
DB %00011010,%10100000,%01010100,%00001010
DB %00011010,%10100001,%01010000,%00001010
DB %00011010,%10010101,%01000000,%00001010
DB %00011010,%10101010,%00000000,%00001010
DB %00011010,%10101000,%00000000,%00001010
DB %00011010,%10100000,%00000000,%00001010
DB %00000000,%00000000,%00000000,%00000000

; ================= O =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= P =================
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01000000,%00000000
DB %00000110,%10101010,%10101000,%00000000
DB %00000110,%10101010,%10101000,%00000000
DB %00011010,%01010101,%01000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%10100000,%00000000,%00000000
DB %00000000,%00000000,%00000000,%00000000

; ================= Q =================
DB %00000000,%00000000,%00000001,%10100000
DB %00000001,%01010101,%01010110,%01000000
DB %00000110,%10101010,%10101011,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000001,%01101001,%01100000
DB %00011010,%01000000,%10010101,%01100000
DB %00011010,%01000000,%00010101,%01100000
DB %00011010,%01000000,%00000101,%01100000
DB %00011010,%01000000,%00000101,%01100000
DB %00011010,%01000000,%00000101,%01100000
DB %00011010,%01000000,%00000101,%01100000
DB %00011010,%01010101,%01010101,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00000000,%00000000,%00000000

; ================= R =================
DB %00000101,%01010000,%00000000,%00000000
DB %00011010,%01000000,%00011010,%01000000
DB %00011010,%01000000,%01101001,%00000000
DB %00011010,%01000001,%10100100,%00000000
DB %00011010,%01000110,%10010000,%00000000
DB %00011010,%01011010,%01000000,%00000000
DB %00011010,%01011010,%00000000,%00000000
DB %00011010,%01010101,%01000000,%00000000
DB %00000110,%10101010,%10010000,%00000000
DB %00000110,%10101010,%10010000,%00000000
DB %00011010,%01010101,%01100100,%00000000
DB %00011010,%01000000,%01101001,%00000000
DB %00011010,%01000000,%01101001,%00000000
DB %00011010,%01010101,%01100100,%00000000
DB %00000110,%10101010,%10010000,%00000000
DB %00000101,%01010101,%01000000,%00000000

; ================= S =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000101,%01010101,%01010101,%01000000

; ================= T =================
DB %00000000,%00000101,%01010000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000110,%10101010,%10101010,%10101000
DB %00000001,%01010101,%01010101,%01010100
DB %00000000,%00000000,%00000000,%00000000

; ================= U =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00011010,%01000000,%00011010,%00101010
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00000000,%00000000,%00000000

; ================= V =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%01101010,%10010000,%00000000
DB %00000000,%01101010,%10010000,%00000000
DB %00000000,%01101010,%10010000,%00000000
DB %00000001,%10100101,%10100100,%00000000
DB %00000001,%10100101,%10100100,%00000000
DB %00000001,%10100101,%10100100,%00000000
DB %00000110,%10010000,%01101001,%00000000
DB %00000110,%10010000,%01101001,%00000000
DB %00000110,%10010000,%01101001,%00000000
DB %00011010,%01000000,%00011010,%10010100
DB %00011010,%01000000,%00011010,%10100100
DB %00010101,%01000000,%00010101,%01010100

; ================= W =================
DB %00000101,%01010000,%00000000,%01010000
DB %00011010,%10100000,%00000000,%00101010
DB %00011010,%10100000,%00000000,%00101010
DB %00011010,%10100000,%00000000,%00101010
DB %00011010,%10100000,%00010100,%00101010
DB %00011010,%10100101,%01010100,%10101010
DB %00011010,%10101010,%10101010,%10101010
DB %00011010,%10101000,%00101010,%10001010
DB %00011010,%10101000,%00101010,%10001010
DB %00011010,%10101010,%10101010,%10101010
DB %00011010,%10100101,%01010100,%10101010
DB %00011010,%10100000,%00010100,%00101010
DB %00011010,%10100000,%00000000,%00101010
DB %00011010,%10100000,%00000000,%00101010
DB %00011010,%10100000,%00000000,%00101010
DB %00000000,%00000000,%00000000,%00000000

; ================= X =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010000,%00000000,%01010000
DB %00011010,%10100000,%00000000,%00101010
DB %00001010,%10101000,%00000000,%00101000
DB %00000010,%10101010,%00000000,%00100000
DB %00000000,%01101010,%10000000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000000,%00011010,%10100000,%00000000
DB %00000000,%01101010,%10000000,%00000000
DB %00000010,%10101010,%00000000,%00100000
DB %00001010,%10101000,%00000000,%00101000
DB %00011010,%10100000,%00000000,%00101010
DB %00000101,%01010000,%00000000,%01010000
DB %00000000,%00000000,%00000000,%00000000

; ================= Y =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00011010,%10010000,%00000000
DB %00000000,%01101010,%10100101,%00000000
DB %00000010,%10101010,%01101010,%01000000
DB %00001010,%10101000,%00011010,%10010000
DB %00011010,%10100000,%00000110,%10010000
DB %00000000,%00000000,%00000001,%01010000
DB %00000000,%00000000,%00000000,%00000000


; ================= Z =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000101,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000110,%10010000,%00000000,%00000000
DB %00000001,%10100100,%00000000,%00000000
DB %00000000,%01101001,%00000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00000110,%10010000,%00000000
DB %00000000,%00000001,%10100100,%00000000
DB %00000000,%00000000,%01101001,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000


DS 64,0         ; [
DS 64,0         ; \
DS 64,0         ; ]
DS 64,0         ; ^
DS 64,0         ; <-
DS 64,0         ; <SPACE>
DS 64,0         ; !
DS 64,0         ; "
DS 64,0         ; #
DS 64,0         ; $
DS 64,0         ; %
DS 64,0         ; &
DS 64,0         ; '
DS 64,0         ; (
DS 64,0         ; )
DS 64,0         ; *
DS 64,0         ; +
DS 64,0         ; ,
DS 64,0         ; -
DS 64,0         ; .
DS 64,0         ; /

; ================= 0 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= 1 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01000000,%00000000
DB %00000110,%10101010,%10100000,%00000000
DB %00000001,%01010101,%10100000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000000,%00011010,%01000000,%00000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000


; ================= 2 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000101,%00000000,%00000000,%00000000
DB %00000001,%01000000,%00000000,%00000000
DB %00000000,%01010000,%00000000,%00000000
DB %00000000,%00010100,%00000000,%00000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000000,%00000001,%01000000,%00000000
DB %00000000,%00000000,%01010000,%00000000
DB %00000000,%00000000,%00010100,%00000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= 3 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000101,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01000000,%00000000
DB %00000110,%10101010,%10000000,%00000000
DB %00000001,%01010101,%01000000,%00000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000


; ================= 4 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000000,%00010101,%01000000,%00000000
DB %00000000,%01010101,%01000000,%00000000
DB %00000001,%01000101,%01000000,%00000000
DB %00000101,%00000101,%01000000,%00000000
DB %00010100,%00000101,%01000000,%00000000
DB %01010000,%00000101,%01000000,%00000000
DB %00011001,%01010101,%01010101,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000000,%00000101,%01000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00000000,%00000000,%00000000

; ================= 5 =================

DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= 6 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01000000
DB %00011010,%01000000,%00000000,%00000000
DB %00011010,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000


; ================= 7 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01010100
DB %00000110,%10101010,%10101010,%10101000
DB %00000101,%00000000,%00000000,%00000000
DB %00000001,%01000000,%00000000,%00000000
DB %00000000,%01010000,%00000000,%00000000
DB %00000000,%00010100,%00000000,%00000000
DB %00000000,%00000101,%00000000,%00000000
DB %00000000,%00000001,%01000000,%00000000
DB %00000000,%00000001,%01000000,%00000000
DB %00000000,%00000001,%01000000,%00000000
DB %00000000,%00000001,%01000000,%00000000
DB %00000000,%00000001,%01000000,%00000000
DB %00000001,%01010101,%01000000,%00000000
DB %00000000,%00000000,%00000000,%00000000
DB %00000000,%00000000,%00000000,%00000000

; ================= 8 =================
DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000

; ================= 9 =================

DB %00000000,%00000000,%00000000,%00000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00011001,%01010101,%01010101,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01000000,%00011010,%01100000
DB %00011010,%01010101,%01010110,%01100000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00000000,%00000000,%00011010,%01000000
DB %00011001,%01010101,%01010101,%01000000
DB %00000110,%10101010,%10101010,%10000000
DB %00000001,%01010101,%01010101,%01000000
DB %00000000,%00000000,%00000000,%00000000


 org BUFFER_ORIGIN

buffer  equ $		; 	buffer:   ds 2048 ,0
buffer2 equ $+2048	; 	buffer2:   ds 2048 ,0

;GREEN			YELLOW			BLUE			RED             
;00	00000000	01	00000001	02	00000010	03	00000011	
;00	00000000	04	00000100	08	00001000	0C	00001100
;00	00000000	10	00010000	20	00100000	30	00110000
;00	00000000	40	01000000	80	10000000	C0	11000000


; ============================================================
; VZ200 MODE(1) ORB DEMO - 7 DOTS - FIXED ALL-ASM VERSION
; Converted from C orb demo to pure Z80 assembly
; Strict PASMO / VZ200 rules compliant
;
; BUGS FIXED:
;  1. MAIN_LOOP: A was never reloaded from (Angle) before INC/store;
;     DRAW_ORBS clobbers A so the angle was never incremented correctly.
;
;  2. DRAW_ORBS: B was used for both the dot-loop counter AND as the
;     X coordinate (LD B,A for cosine result), so DEC B at the bottom
;     decremented X, not the counter.  Loop count is now kept in
;     memory (DotCount) and X is kept in C throughout.
;
;  3. DRAW_ORBS: CosTable index was wrong.  After the SinTable lookup,
;     HL pointed somewhere inside SinTable; adding CosTable base to it
;     gave a garbage address.  The phase index is now saved in E and
;     HL is rebuilt cleanly for both lookups.
;
;  4. PLOT: ADC HL,$7000 is not a valid Z80 opcode (no ADC HL,nn form).
;     Replaced with LD DE,$7000 / ADD HL,DE.
;
;  5. PLOT: OR $03 always set the two lowest bits regardless of which
;     of the four 2-bit pixel slots the X coordinate selects.  Pixels
;     at X positions 0-2 were written to the wrong bit-pair and
;     appeared invisible or in the wrong position.  Now the correct
;     bit-pair is chosen from (X AND 3).
;
;  6. SinTable / CosTable were only 32 entries each for an 8-bit
;     (0-255) phase index, so lookups past entry 31 read rubbish.
;     Replaced with full 256-entry tables (radius 28 for X centred
;     at 64; radius 20 for Y centred at 32).
; ============================================================

        ORG     $8000

START:

	di

        LD      A,8
        LD      ($6800),A           ; enter MODE(1) 128x64

        CALL    CLEAR

        XOR     A
        LD      (Angle),A

; ------------------------------------------------------------
; Main loop: draw all dots, advance angle, repeat forever
; ------------------------------------------------------------

MAIN_LOOP:

        CALL    DRAW_ORBS

	ld	hl, $a000
	ld	de, $7000
	ld	bc, 2048
	ldir

	ld	hl, $A000
	ld	de, $A001
	ld	(hl), $AA
	ld	bc, 2048
	ldir


        ; FIX 1: reload Angle - A is clobbered inside DRAW_ORBS
        LD      A,(Angle)
        INC     A
        LD      (Angle),A
        LD      A,(Angle2)
        DEC     A
        LD      (Angle2),A
        JP      MAIN_LOOP

; ------------------------------------------------------------
; Clear VRAM $7000-$77FF with zero (all green/buff pixels)
; ------------------------------------------------------------

CLEAR:
        LD      HL,$7000
        LD      DE,$7001
        LD      BC,2047
        XOR     A
        LD      (HL),A
        LDIR
        RET

; ------------------------------------------------------------
; DRAW_ORBS
; Draw 7 orbiting dots, each with its own phase offset.
; The loop counter is kept in memory (DotCount) so that B is
; free to be used as a general-purpose register inside the loop.
; Registers used: A, BC, DE, HL, IX
; ------------------------------------------------------------

DRAW_ORBS:
        LD      IX,DotPhases
        LD      A,9
        LD      (DotCount),A

ORB_LOOP:
        ; Compute phase index = global Angle + this dot's phase offset
        LD      A,(Angle)
        ADD     A,(IX+0)            ; 8-bit add wraps naturally in [0..255]
        LD      E,A                 ; FIX 3: save index in E for both lookups

        ; --- X coordinate from SinTable ---
        LD      L,E
        LD      H,0                 ; HL = index (0..255)
        LD      DE,SinTable
        ADD     HL,DE               ; HL = &SinTable[index]
        LD      A,(HL)
        LD      C,A                 ; C = X (0..127)

        ; --- Y coordinate from CosTable ---
        ; FIX 3: rebuild HL from saved index, not from previous HL
        LD      A,(Angle)
        ADD     A,(IX+0)            ; re-derive same index
        LD      L,A
        LD      H,0
        LD      DE,CosTable
        ADD     HL,DE               ; HL = &CosTable[index]
        LD      A,(HL)
        LD      D,A                 ; D = Y (0..63)

        ; Plot dot at C=X, D=Y

        CALL    PLOT
	inc	c
        CALL    PLOT
	inc	c
        CALL    PLOT

	inc	d
	inc	c
        CALL    PLOT	;d
	inc	c
	inc	d
        CALL    PLOT	;e

	inc	d
        CALL    PLOT	; f
	inc	d
	dec	c
        CALL    PLOT	; g
	inc	d
	dec	c
        CALL    PLOT	; h
	dec	c
	CALL	PLOT	; i
	dec	c
	CALL	PLOT	; j
	dec	c
	dec	d
	CALL	PLOT	; k
	dec	c
	dec	d
	CALL	PLOT	; l
	dec	d
	CALL	PLOT	; m
	inc	c
	dec	d
	CALL	PLOT	; n




;   XXX        abc
;  X   X      n   d
; X     X    m     e
; X     X    l     f
;  X   X      k   g
;   XXX        jih
;
        ; FIX 2: loop counter in memory, not B
        INC     IX
        LD      A,(DotCount)
        DEC     A
        LD      (DotCount),A
        JP      NZ,ORB_LOOP


;==================================
; YELLOW
;==================================
        LD      IX,DotPhases
        LD      A,9
        LD      (DotCount),A

YORB_LOOP:
        ; Compute phase index = global Angle + this dot's phase offset
        LD      A,(Angle2)
        ADD     A,(IX+0)            ; 8-bit add wraps naturally in [0..255]
        LD      E,A                 ; FIX 3: save index in E for both lookups

        ; --- X coordinate from SinTable ---
        LD      L,E
        LD      H,0                 ; HL = index (0..255)
        LD      DE,SinTable
        ADD     HL,DE               ; HL = &SinTable[index]
        LD      A,(HL)
        LD      C,A                 ; C = X (0..127)

        ; --- Y coordinate from CosTable ---
        ; FIX 3: rebuild HL from saved index, not from previous HL
        LD      A,(Angle2)
        ADD     A,(IX+0)            ; re-derive same index
        LD      L,A
        LD      H,0
        LD      DE,CosTable
        ADD     HL,DE               ; HL = &CosTable[index]
        LD      A,(HL)
        LD      D,A                 ; D = Y (0..63)

        ; Plot dot at C=X, D=Y

        CALL    PLOTY
	inc	c
        CALL    PLOTY
	inc	c
        CALL    PLOTY

	inc	d
	inc	c
        CALL    PLOTY	;d
	inc	c
	inc	d
        CALL    PLOTY	;e

	inc	d
        CALL    PLOTY	; f
	inc	d
	dec	c
        CALL    PLOTY	; g
	inc	d
	dec	c
        CALL    PLOTY	; h
	dec	c
	CALL	PLOTY	; i
	dec	c
	CALL	PLOTY	; j
	dec	c
	dec	d
	CALL	PLOTY	; k
	dec	c
	dec	d
	CALL	PLOTY	; l
	dec	d
	CALL	PLOTY	; m
	inc	c
	dec	d
	CALL	PLOTY	; n




;   XXX        abc
;  X   X      n   d
; X     X    m     e
; X     X    l     f
;  X   X      k   g
;   XXX        jih
;
        ; FIX 2: loop counter in memory, not B
        INC     IX
        LD      A,(DotCount)
        DEC     A
        LD      (DotCount),A
        JP      NZ,YORB_LOOP




        RET

; ------------------------------------------------------------
; PLOT
; Plot one pixel in MODE(1).
; Entry:  C = X  (0..127)
;         D = Y  (0..63)
;
; MODE(1) layout: 32 bytes per row, 4 pixels per byte (2 bpp).
; Byte address  = $7000 + Y*32 + (X SHR 2)
; Pixel slot    = X AND 3  (0 = leftmost = bits 7:6, 3 = rightmost = bits 1:0)
; Colour = red/orange = 2-bit value 11b = $03 shifted to correct slot.
;
; Slot  bit-pair  OR mask
;   0   7:6       $C0
;   1   5:4       $30
;   2   3:2       $0C
;   3   1:0       $03
;
; Clobbers: A, B, DE, HL
; ------------------------------------------------------------

PLOT:
	push	bc
	push	de
        ; --- HL = Y * 32 ---
        LD      H,0
        LD      L,D                 ; HL = Y
        ADD     HL,HL               ; HL = Y*2
        ADD     HL,HL               ; HL = Y*4
        ADD     HL,HL               ; HL = Y*8
        ADD     HL,HL               ; HL = Y*16
        ADD     HL,HL               ; HL = Y*32

        ; --- Save pixel slot (X AND 3) before we shift X ---
        LD      A,C
        AND     $03
        LD      B,A                 ; B = pixel slot 0..3

        ; --- Add column byte offset (X SHR 2) ---
        LD      A,C
        SRL     A
        SRL     A                   ; A = X/4
        LD      E,A
        LD      D,0
        ADD     HL,DE               ; HL = Y*32 + X/4

        ; --- Add VRAM base ---
        ; FIX 4: no ADC HL,nn opcode exists; use ADD HL,DE
        LD      DE,$A000
        ADD     HL,DE               ; HL = final VRAM byte address

        ; --- FIX 5: OR the correct 2-bit pair for the pixel slot ---
        LD      A,B                 ; A = slot 0..3
        OR      A
        JP      Z,PLOT_SLOT0
        DEC     A
        JP      Z,PLOT_SLOT1
        DEC     A
        JP      Z,PLOT_SLOT2
        ; slot 3: bits 1:0
        LD      A,(HL)
        OR      $03
        LD      (HL),A
	pop	de
	pop 	bc
	ret
PLOT_SLOT2:
        LD      A,(HL)
        OR      $0C
        LD      (HL),A
	pop	de
	pop 	bc
	ret
PLOT_SLOT1:
        LD      A,(HL)
        OR      $30
        LD      (HL),A
	pop	de
	pop 	bc
	ret
PLOT_SLOT0:
        LD      A,(HL)
        OR      $C0
        LD      (HL),A

	pop	de
	pop 	bc
	ret




; ------------------------------------------------------------
; PLOT YELLOW
; Plot one pixel in MODE(1).
; Entry:  C = X  (0..127)
;         D = Y  (0..63)
;
; MODE(1) layout: 32 bytes per row, 4 pixels per byte (2 bpp).
; Byte address  = $7000 + Y*32 + (X SHR 2)
; Pixel slot    = X AND 3  (0 = leftmost = bits 7:6, 3 = rightmost = bits 1:0)
; Colour = red/orange = 2-bit value 11b = $03 shifted to correct slot.
;
; Slot  bit-pair  OR mask
;   0   7:6       $C0
;   1   5:4       $30
;   2   3:2       $0C
;   3   1:0       $03
;
; Clobbers: A, B, DE, HL
; ------------------------------------------------------------

PLOTY:
	push	bc
	push	de
        ; --- HL = Y * 32 ---
        LD      H,0
        LD      L,D                 ; HL = Y
        ADD     HL,HL               ; HL = Y*2
        ADD     HL,HL               ; HL = Y*4
        ADD     HL,HL               ; HL = Y*8
        ADD     HL,HL               ; HL = Y*16
        ADD     HL,HL               ; HL = Y*32

        ; --- Save pixel slot (X AND 3) before we shift X ---
        LD      A,C
        AND     $03
        LD      B,A                 ; B = pixel slot 0..3

        ; --- Add column byte offset (X SHR 2) ---
        LD      A,C
        SRL     A
        SRL     A                   ; A = X/4
        LD      E,A
        LD      D,0
        ADD     HL,DE               ; HL = Y*32 + X/4

        ; --- Add VRAM base ---
        ; FIX 4: no ADC HL,nn opcode exists; use ADD HL,DE
        LD      DE,$A080
        ADD     HL,DE               ; HL = final VRAM byte address

        ; --- FIX 5: OR the correct 2-bit pair for the pixel slot ---
        LD      A,B                 ; A = slot 0..3
        OR      A
        JP      Z,YPLOT_SLOT0
        DEC     A
        JP      Z,YPLOT_SLOT1
        DEC     A
        JP      Z,YPLOT_SLOT2
        ; slot 3: bits 1:0
        LD      A,(HL)

; 10101001 A9       	10101000 A8
; 10100110 a6		10100010 A2
; 10011010 9a		10001010 8A
; 01101010 6a		00101010 2A
;        OR      $a9
 and $a8
        LD      (HL),A
	pop	de
	pop 	bc
	ret
YPLOT_SLOT2:
        LD      A,(HL)
    ;    OR      $a6
 and $a2    
    LD      (HL),A
	pop	de
	pop 	bc
	ret
YPLOT_SLOT1:
        LD      A,(HL)
;        OR      $9a
 and $8a
        LD      (HL),A
	pop	de
	pop 	bc
	ret
YPLOT_SLOT0:
        LD      A,(HL)
;        OR      $6a
 and $2a
        LD      (HL),A

	pop	de
	pop 	bc
	ret
;
;GREEN			YELLOW			BLUE			RED             
;00	00000000	01	00000001	02	00000010	03	00000011	
;00	00000000	04	00000100	08	00001000	0C	00001100
;00	00000000	10	00010000	20	00100000	30	00110000
;00	00000000	40	01000000	80	10000000	C0	11000000


; ============================================================
; DATA  -  all DB/DW at end of file per coding rules
; ============================================================

Angle:      DB  0	; RED
Angle2:      DB  0	; YELLOW
DotCount:   DB  0

; Phase offsets for 7 dots evenly spaced around 256-step circle
; 256 / 7 = ~36 steps apart
DotPhases:
;        DB  0, 36, 73, 109, 146, 182, 219
 db 0,28,57,85,114,142,170,199,227

; ------------------------------------------------------------
; SinTable: 256 entries
; Value = 64 + round(sin(i * 2 * PI / 256) * 28)
; Centred at X=64 (midpoint of 128-pixel-wide screen), radius 28
; Range: 36..92, all within valid X bounds 0..127
; ------------------------------------------------------------
SinTable:
        DB  64, 65, 66, 67, 69, 70, 71, 72
        DB  73, 74, 75, 76, 77, 78, 79, 79
        DB  80, 81, 82, 82, 83, 83, 84, 84
        DB  85, 85, 85, 86, 86, 86, 86, 86
        DB  86, 86, 86, 86, 86, 86, 85, 85
        DB  85, 84, 84, 83, 83, 82, 82, 81
        DB  80, 79, 79, 78, 77, 76, 75, 74
        DB  73, 72, 71, 70, 69, 67, 66, 65
        DB  64, 63, 62, 61, 59, 58, 57, 56
        DB  55, 54, 53, 52, 51, 50, 49, 49
        DB  48, 47, 46, 46, 45, 45, 44, 44
        DB  43, 43, 43, 42, 42, 42, 42, 42
        DB  42, 42, 42, 42, 42, 42, 43, 43
        DB  43, 44, 44, 45, 45, 46, 46, 47
        DB  48, 49, 49, 50, 51, 52, 53, 54
        DB  55, 56, 57, 58, 59, 61, 62, 63
        DB  64, 65, 66, 67, 69, 70, 71, 72
        DB  73, 74, 75, 76, 77, 78, 79, 79
        DB  80, 81, 82, 82, 83, 83, 84, 84
        DB  85, 85, 85, 86, 86, 86, 86, 86
        DB  86, 86, 86, 86, 86, 86, 85, 85
        DB  85, 84, 84, 83, 83, 82, 82, 81
        DB  80, 79, 79, 78, 77, 76, 75, 74
        DB  73, 72, 71, 70, 69, 67, 66, 65
        DB  64, 63, 62, 61, 59, 58, 57, 56
        DB  55, 54, 53, 52, 51, 50, 49, 49
        DB  48, 47, 46, 46, 45, 45, 44, 44
        DB  43, 43, 43, 42, 42, 42, 42, 42
        DB  42, 42, 42, 42, 42, 42, 43, 43
        DB  43, 44, 44, 45, 45, 46, 46, 47
        DB  48, 49, 49, 50, 51, 52, 53, 54
        DB  55, 56, 57, 58, 59, 61, 62, 63

; ------------------------------------------------------------
; CosTable: 256 entries
; Value = 32 + round(cos(i * 2 * PI / 256) * 20)
; Centred at Y=32 (midpoint of 64-pixel-tall screen), radius 20
; Range: 12..52, all within valid Y bounds 0..63
; ------------------------------------------------------------
CosTable:
        DB  52, 52, 52, 52, 51, 51, 51, 50
        DB  50, 49, 49, 48, 47, 47, 46, 45
        DB  44, 44, 43, 42, 41, 40, 39, 38
        DB  37, 36, 35, 34, 33, 32, 31, 30
        DB  29, 28, 27, 26, 25, 24, 23, 22
        DB  21, 20, 20, 19, 18, 18, 17, 16
        DB  16, 15, 15, 14, 14, 13, 13, 13
        DB  12, 12, 12, 12, 12, 12, 12, 12
        DB  12, 12, 12, 12, 12, 12, 12, 13
        DB  13, 13, 14, 14, 15, 15, 16, 16
        DB  17, 18, 18, 19, 20, 20, 21, 22
        DB  23, 24, 25, 26, 27, 28, 29, 30
        DB  31, 32, 33, 34, 35, 36, 37, 38
        DB  39, 40, 41, 42, 43, 44, 44, 45
        DB  46, 47, 47, 48, 49, 49, 50, 50
        DB  51, 51, 51, 52, 52, 52, 52, 52
        DB  52, 52, 52, 52, 51, 51, 51, 50
        DB  50, 49, 49, 48, 47, 47, 46, 45
        DB  44, 44, 43, 42, 41, 40, 39, 38
        DB  37, 36, 35, 34, 33, 32, 31, 30
        DB  29, 28, 27, 26, 25, 24, 23, 22
        DB  21, 20, 20, 19, 18, 18, 17, 16
        DB  16, 15, 15, 14, 14, 13, 13, 13
        DB  12, 12, 12, 12, 12, 12, 12, 12
        DB  12, 12, 12, 12, 12, 12, 12, 13
        DB  13, 13, 14, 14, 15, 15, 16, 16
        DB  17, 18, 18, 19, 20, 20, 21, 22
        DB  23, 24, 25, 26, 27, 28, 29, 30
        DB  31, 32, 33, 34, 35, 36, 37, 38
        DB  39, 40, 41, 42, 43, 44, 44, 45
        DB  46, 47, 47, 48, 49, 49, 50, 50
        DB  51, 51, 51, 52, 52, 52, 52, 52

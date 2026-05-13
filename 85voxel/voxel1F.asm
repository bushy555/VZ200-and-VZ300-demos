
; ============================================================
; VZ200 MODE(1) Voxel Landscape Scroller (128x64, 4 colors)
; ORG $8000, VRAM $7000, Latch $6800
; Requirements satisfied:
;  - Only A is used for direct memory loads/stores (LD A,(mem) / LD (mem),A)
;  - No arithmetic directly to memory
;  - No JR/DJNZ; use JP
;  - No illegal opcodes, no invented registers
;  - All data tables are placed at the end
;  - MODE(1): LD A,8 / LD ($6800),A
; Colors (2bpp): 00=green, 01=yellow, 10=blue, 11=red
; ============================================================

            ORG     $8000

buffer	    equ	    $b000
VRAM        EQU     $7000
LATCH       EQU     $6800
BOTBASE     EQU     $b7E0           ; VRAM + 63*32 (start of bottom row)
COLUMNS     EQU     128

; ------------------------------------------------------------
; Entry
; ------------------------------------------------------------
Start:
            LD      SP,$dFFF
 DI


; Enter MODE(1)
            LD      A,8
            LD      ($6800),A

; Init phases, speeds, steps
            XOR     A
            LD      (PH1_BASE),A
            LD      (PH2_BASE),A
            LD      A,3
            LD      (PH1_DX),A        ; per-column phase step for wave 1
            LD      A,5
            LD      (PH2_DX),A        ; per-column phase step for wave 2
            LD      A,1
            LD      (PH1_SPEED),A     ; per-frame base phase advance
            LD      A,2
            LD      (PH2_SPEED),A

MainLoop:
; Clear VRAM to sky (green = 00 everywhere)
;           CALL    ClearVRAM


;;	ld	hl, $b000
;	ld	de, $b001
;	ld	(hl), 0
;	ld	bc, 2048
;	ldir

;
; Prepare per-frame base phases
            LD      A,(PH1_BASE)
            LD      (PH1_CUR),A
            LD      A,(PH2_BASE)
            LD      (PH2_CUR),A

; Column state
            XOR     A
            LD      (XBYTE),A         ; byte index = x>>2
            XOR     A
            LD      (XPOS4),A         ; bit position x&3 (0..3)
            LD      A,COLUMNS
            LD      (XCNT),A          ; remaining columns

ColumnLoop:
            LD      A,(XCNT)
            OR      A
            JP      Z,ColumnsDone

; ---------------- Compute horizon height h(x) ----------------
; h = 8 + (SIN64[ph1]>>1) + (SIN64[ph2]>>2)    -> range ~8..54
; v1 = SIN64[PH1_CUR] >> 1
            LD      A,(PH1_CUR)
            LD      E,A
            LD      D,0
            LD      HL,SIN64
            ADD     HL,DE
            LD      A,(HL)
            SRL     A
            LD      B,A            ; B = v1'

; v2 = SIN64[PH2_CUR] >> 2
            LD      A,(PH2_CUR)
            LD      E,A
            LD      D,0
            LD      HL,SIN64
            ADD     HL,DE
            LD      A,(HL)
            SRL     A
            SRL     A              ; A = v2'
; h = 8 + v1' + v2'
            ADD     A,8
            ADD     A,B
            LD      (HVAL),A       ; store horizon (0..63 safe, ~8..54)

; ---------------- Precompute per-column pixel masks ----------
; bitpos = XPOS4 (0..3)
            LD      A,(XPOS4)
            LD      (BITPOS),A
; mask (to clear the pixel pair) into register C
            LD      E,A
            LD      D,0
            LD      HL,MaskTable
            ADD     HL,DE
            LD      A,(HL)
            LD      C,A

; Preload colorbits for this bitpos: CB0..CB3
; shift_base = bitpos*4
            LD      A,(BITPOS)
            RLCA
            RLCA
            LD      (SHIFTB),A          ; 0,4,8,12

; base = ColorShiftTable + shift_base
            LD      E,A
            LD      D,0
            LD      HL,ColorShiftTable
            ADD     HL,DE
; CB0
            LD      A,(HL)
            LD      (CB0),A
            INC     HL
; CB1
            LD      A,(HL)
            LD      (CB1),A
            INC     HL
; CB2
            LD      A,(HL)
            LD      (CB2),A
            INC     HL
; CB3
            LD      A,(HL)
            LD      (CB3),A

; ---------------- Prepare start address of column ------------
; HL = BOTBASE + XBYTE
            LD      HL,BOTBASE
            LD      A,(XBYTE)
            LD      E,A
            LD      D,0
            ADD     HL,DE             ; HL points at bottom row byte for this column

; YCur = 63 ; RowsToDraw = 64 - h
            LD      A,63
            LD      (YCUR),A
            LD      A,64
            LD      B,A
            LD      A,(HVAL)
            LD      D,A
            LD      A,B
            SUB     D
            LD      B,A               ; B = rows to draw (1..64)

; ---------------- Draw vertical span (bottom up) -------------
; For each row:
;   colorIndex = ColorByDistance(YCur)
;   colorBits  = CB[colorIndex]
;   newByte    = ((HL)&C) | colorBits
;   HL -= 32 ; YCur--

DrawSpanLoop:
            LD      A,B
            OR      A
            JP      Z,SpanDone

; colorIndex by distance bands:
; default color = 0 (green), then:
;   if YCur >= 16 -> color=2 (blue)
;   if YCur >= 32 -> color=1 (yellow)
;   if YCur >= 48 -> color=3 (red)
            LD      A,(YCUR)
            XOR     A                 ; A=0 but we need E=0; use memory temp
            LD      A,(YCUR)
            LD      E,0               ; E = color (default 0)
            CP      16
            JP      C,ColorPickDone
            LD      E,2
            CP      32
            JP      C,ColorPickDone
            LD      E,1
            CP      48
            JP      C,ColorPickDone
            LD      E,3
ColorPickDone:

; colorBits = CB[E]
            LD      A,E
            OR      A
            JP      Z,UseCB0
            DEC     A
            JP      Z,UseCB1
            DEC     A
            JP      Z,UseCB2
; else
UseCB3:
            LD      A,(CB3)
            JP      GotCB
UseCB2:
            LD      A,(CB2)
            JP      GotCB
UseCB1:
            LD      A,(CB1)
            JP      GotCB
UseCB0:
            LD      A,(CB0)
GotCB:
            LD      E,A               ; E = colorbits for this bitpos

; Write pixel (RMW): (HL) = ((HL)&C) | E
            LD      A,(HL)
            AND     C
            OR      E
            LD      (HL),A

; Move to previous row: HL -= 32
            LD      A,L
            SUB     32
            LD      L,A
            JP      NC,NoBorrow
            DEC     H
NoBorrow:

; YCur--
            LD      A,(YCUR)
            DEC     A
            LD      (YCUR),A

; B--
            DEC     B
            JP      DrawSpanLoop
SpanDone:


	


; ---------------- Advance to next column ---------------------
; Increment bitpos; if == 4 then bitpos=0 and XBYTE++
            LD      A,(XPOS4)
            INC     A
            CP      4
            JP      C,NoByteInc
            XOR     A
            LD      (XPOS4),A
            LD      A,(XBYTE)
            INC     A
            LD      (XBYTE),A
            JP      ByteIncDone
NoByteInc:
            LD      (XPOS4),A
ByteIncDone:

; Advance column phases: PHx_CUR += PHx_DX (mod 64)
; PH1
            LD      A,(PH1_CUR)
            LD      B,A
            LD      A,(PH1_DX)
            ADD     A,B
            AND     63
            LD      (PH1_CUR),A
; PH2
            LD      A,(PH2_CUR)
            LD      B,A
            LD      A,(PH2_DX)
            ADD     A,B
            AND     63
            LD      (PH2_CUR),A

; XCNT--
            LD      A,(XCNT)
            DEC     A
            LD      (XCNT),A



            JP      ColumnLoop

ColumnsDone:
; Advance base phases per frame
; PH1_BASE += PH1_SPEED (mod 64)
            LD      A,(PH1_BASE)
            LD      B,A
            LD      A,(PH1_SPEED)
            ADD     A,B
            AND     63
            LD      (PH1_BASE),A

; PH2_BASE += PH2_SPEED (mod 64)
            LD      A,(PH2_BASE)
            LD      B,A
            LD      A,(PH2_SPEED)
            ADD     A,B
            AND     63
            LD      (PH2_BASE),A




	ld	hl, $b000
	ld	de, $7000
	ld	bc, 2048

;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
; Copies exactly 2048 bytes
Copy2048_64LDI1:
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



;	ld	hl, $b000
;	ld	de, $b001
;	ld	(hl), 0
;	ld	bc, 2048
;	ldir



	ld	hl, $b000
	ld	de, $b001
	ld	bc, 2048
	ld	(hl), 0

;Assumes: HL = source ($9000), DE = dest ($7000), BC = 2048
; Copies exactly 2048 bytes
Copy2048_64LDI2:
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



; Small delay to regulate speed
;            CALL    SmallDelay

            JP      MainLoop

; ============================================================
; Subroutines
; ============================================================

; ClearVRAM: fill $7000..$77FF with 0
; Uses A only for memory store
ClearVRAM:
            LD      HL,buffer
            LD      bc, 2048
	ld	de, buffer + 1
        XOR     A
	ld	(hl), a
	ldir
	RET


; SmallDelay: simple CPU wait
SmallDelay:
	ret
            LD      B,1
SD_L1:
            LD      C,50
SD_L2:
            DEC     C
            JP      NZ,SD_L2
            DEC     B
            JP      NZ,SD_L1
            RET

; ============================================================
; Variables
; ============================================================
width 		db 0
PH1_BASE:       DB 0
PH2_BASE:       DB 0
PH1_CUR:        DB 0
PH2_CUR:        DB 0
PH1_DX:         DB 0
PH2_DX:         DB 0
PH1_SPEED:      DB 0
PH2_SPEED:      DB 0

XBYTE:          DB 0      ; x>>2
XPOS4:          DB 0      ; x&3
XCNT:           DB 0      ; remaining columns

HVAL:           DB 0      ; computed horizon y
YCUR:           DB 0      ; current y during span

BITPOS:         DB 0
SHIFTB:         DB 0

; per-bitpos preloaded colorbits
CB0:            DB 0
CB1:            DB 0
CB2:            DB 0
CB3:            DB 0

; ============================================================
; Tables (DATA AT END)
; ============================================================

; 64-entry "soft sine" 0..63, one cycle
SIN64:
            DB 32,35,38,41,44,47,50,53
            DB 56,58,60,62,63,64,64,64
            DB 63,62,60,58,56,53,50,47
            DB 44,41,38,35,32,29,26,23
            DB 20,18,16,14,13,12,12,12
            DB 13,14,16,18,20,23,26,29
            DB 32,35,38,41,44,47,50,53
            DB 56,58,60,62,63,64,64,64

; Pixel clear masks for positions x&3 (2bpp)
; pos0: clear bits 7..6 -> 0011 1111 = 0x3F
; pos1: clear bits 5..4 -> 1100 1111 = 0xCF
; pos2: clear bits 3..2 -> 1111 0011 = 0xF3
; pos3: clear bits 1..0 -> 1111 1100 = 0xFC
MaskTable:
            DB $3F,$CF,$F3,$FC

; ColorShiftTable[pos*4 + color]
; color 0..3 into bit-pair for that pixel (pos 0..3)
ColorShiftTable:
; pos0 (bits 7..6)
            DB %00000000,%01000000,%10000000,%11000000
; pos1 (bits 5..4)
            DB %00000000,%00010000,%00100000,%00110000
; pos2 (bits 3..2)
            DB %00000000,%00000100,%00001000,%00001100
; pos3 (bits 1..0)
            DB %00000000,%00000001,%00000010,%00000011

; ============================================================
; End of file
; ============================================================

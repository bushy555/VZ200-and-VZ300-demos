
; ================================================================
; VZ200 MODE(1) Sine-Flag Checkerboard (128x64)
; Author: M365 Copilot for David Maunder
; Assembler: PASMO
; Compliance:
;   - All memory I/O only via A (LD A,(mem), LD (mem),A, LD (DE),A, LD (HL),A)
;   - No arithmetic with memory operands
;   - No JR (only JP)
;   - No invalid ops for PASMO (no ADD DE,DE; no SUB HL,HL; etc.)
;   - All DB/DEFS at end
;   - ORG $8000, SP $B000
;   - MODE(1): LD A,8 / LD ($6800),A
;   - VRAM: $7000-$77FF (128x64, 2bpp, 32 bytes/row)
; ================================================================

            ORG     $8000

Start:
            DI
            LD      SP,$B000

; Enter MODE(1)
            LD      A,8
            LD      ($6800),A

; Main loop
MainLoop:
            CALL    RenderFrame

            ; time++ (0..255)
            LD      A,(Time)
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a
	inc	a

	inc	a
	inc	a
	inc	a
	inc	a

            LD      (Time),A


	ld	hl, $9000
	ld	de, $7000
	ld	bc, 2048
	ldir


            JP      MainLoop

; ================================================================
; RenderFrame
; Draws a full frame of the sine-flag checkerboard
; Checker squares: 8x8 pixels (CellShift=3)
; Horizontal displacement per row: dx = (sin( Time + 3*y ) - 128) >> AmpShift
; Colors: bit 0 -> yellow (1), bit 1 -> red (3)
; ================================================================
RenderFrame:
            ; Prepare VRAM destination pointer = $7000
            LD      A,$00
            LD      (DstLo),A
            LD      A,$90
            LD      (DstHi),A

            ; y = 0..63
            XOR     A
            LD      (YIdx),A
            LD      A,64
            LD      (Y_Rem),A

RowLoop:
            LD      A,(Y_Rem)
            OR      A
            JP      Z,RF_Done

            ; yCell = y >> 3
            LD      A,(YIdx)
            SRL     A
            SRL     A
            SRL     A
            LD      (YCell),A

            ; sinIdx = (Time + 3*y) & 255  (3*y = y + 2y)
            LD      A,(YIdx)
            LD      H,A
            LD      A,H
            ADD     A,H            ; 2y
            LD      L,A
            LD      A,(YIdx)
            ADD     A,L            ; 3y
            LD      L,A
            LD      A,(Time)
            ADD     A,L
            LD      (SinIdx),A

            ; sVal = Sin256U[sinIdx]  (0..255)
            LD      A,(SinIdx)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin256U
            ADD     HL,DE
            LD      A,(HL)         ; 0..255

            ; signed: A = A - 128
            SUB     128

            ; dx = signed >> AmpShift (AmpShift=4 -> +/-8 pixels)
            LD      (TmpA),A
            LD      A,(AmpShift)
            LD      (ShiftCnt),A
            LD      A,(TmpA)
RF_SignShift:
            LD      L,A
            LD      A,(ShiftCnt)
            OR      A
            JP      Z,RF_ShiftDone
            LD      A,L
            SRA     A
            LD      (ShiftCnt),A          ; temporarily wrong; fix by reloading ShiftCnt then dec
            ; Correct decrement:
            LD      A,(ShiftCnt)
            SUB     1
            LD      (ShiftCnt),A
            LD      A,L
            SRA     A
            ; We applied SRA twice; fix: redo cleanly.

            ; --- Clean redo of arithmetic shift loop ---
RF_ReShiftInit:
            LD      A,(TmpA)
            LD      (DxTmp),A
            LD      A,(AmpShift)
            LD      (ShiftCnt),A
RF_ReShiftLoop:
            LD      A,(ShiftCnt)
            OR      A
            JP      Z,RF_ShiftDone2
            LD      A,(DxTmp)
            SRA     A
            LD      (DxTmp),A
            LD      A,(ShiftCnt)
            SUB     1
            LD      (ShiftCnt),A
            JP      RF_ReShiftLoop
RF_ShiftDone2:
            LD      A,(DxTmp)
RF_ShiftDone:
            LD      (DxSigned),A          ; signed dx in A (two's complement)

            ; XPix = 0 ; 32 bytes in row
            XOR     A
            LD      (XPix),A
            LD      A,32
            LD      (XBytes_Rem),A

ByteLoop:
            LD      A,(XBytes_Rem)
            OR      A
            JP      Z,NextRow

            ; Accumulate 4 pixels into VRAM byte
            XOR     A
            LD      (AccByte),A

            ; ---------------- Pixel 0 (pos=0) ----------------
            ; xTemp = XPix + 0
            LD      A,(XPix)
            LD      (XTemp),A
            ; sum = xTemp + dx  (signed wrap)
            LD      A,(DxSigned)
            LD      L,A
            LD      A,(XTemp)
            ADD     A,L
            AND     127                   ; wrap to 0..127
            ; cellX = sum >> 3
            SRL     A
            SRL     A
            SRL     A
            LD      L,A                   ; L = cellX
            ; bit = (cellX XOR yCell) & 1
            LD      A,(YCell)
            XOR     L
            AND     1
            ; color = (bit==0)?1:3
            OR      A
            JP      Z,P0_Col1
            LD      A,3
            JP      P0_HaveCol
P0_Col1:
            LD      A,1
P0_HaveCol:
            ; contribution = Pix0[color]
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Pix0
            ADD     HL,DE
            LD      A,(HL)
            LD      H,A
            LD      A,(AccByte)
            OR      H
            LD      (AccByte),A

            ; ---------------- Pixel 1 (pos=1) ----------------
            ; xTemp = XPix + 1
            LD      A,(XPix)
            ADD     A,1
            LD      (XTemp),A
            LD      A,(DxSigned)
            LD      L,A
            LD      A,(XTemp)
            ADD     A,L
            AND     127
            SRL     A
            SRL     A
            SRL     A
            LD      L,A
            LD      A,(YCell)
            XOR     L
            AND     1
            OR      A
            JP      Z,P1_Col1
            LD      A,3
            JP      P1_HaveCol
P1_Col1:
            LD      A,1
P1_HaveCol:
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Pix1
            ADD     HL,DE
            LD      A,(HL)
            LD      H,A
            LD      A,(AccByte)
            OR      H
            LD      (AccByte),A

            ; ---------------- Pixel 2 (pos=2) ----------------
            LD      A,(XPix)
            ADD     A,2
            LD      (XTemp),A
            LD      A,(DxSigned)
            LD      L,A
            LD      A,(XTemp)
            ADD     A,L
            AND     127
            SRL     A
            SRL     A
            SRL     A
            LD      L,A
            LD      A,(YCell)
            XOR     L
            AND     1
            OR      A
            JP      Z,P2_Col1
            LD      A,3
            JP      P2_HaveCol
P2_Col1:
            LD      A,1
P2_HaveCol:
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Pix2
            ADD     HL,DE
            LD      A,(HL)
            LD      H,A
            LD      A,(AccByte)
            OR      H
            LD      (AccByte),A

            ; ---------------- Pixel 3 (pos=3) ----------------
            LD      A,(XPix)
            ADD     A,3
            LD      (XTemp),A
            LD      A,(DxSigned)
            LD      L,A
            LD      A,(XTemp)
            ADD     A,L
            AND     127
            SRL     A
            SRL     A
            SRL     A
            LD      L,A
            LD      A,(YCell)
            XOR     L
            AND     1
            OR      A
            JP      Z,P3_Col1
            LD      A,3
            JP      P3_HaveCol
P3_Col1:
            LD      A,1
P3_HaveCol:
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Pix3
            ADD     HL,DE
            LD      A,(HL)
            LD      H,A
            LD      A,(AccByte)
            OR      H
            LD      (AccByte),A

            ; -------- Write byte to VRAM at (DstHi:DstLo) --------
            LD      A,(DstLo)
            LD      E,A
            LD      A,(DstHi)
            LD      D,A
            LD      A,(AccByte)
            LD      (DE),A

            ; Dest++
            LD      A,(DstLo)
            ADD     A,1
            LD      (DstLo),A
            LD      A,(DstHi)
            ADC     A,0
            LD      (DstHi),A

            ; XPix += 4
            LD      A,(XPix)
            ADD     A,4
            LD      (XPix),A

            ; next byte in row
            LD      A,(XBytes_Rem)
            SUB     1
            LD      (XBytes_Rem),A
            JP      ByteLoop

NextRow:
            ; advance VRAM dest to next row (+32)
            LD      A,(DstLo)
;            ADD     A,32
            LD      (DstLo),A
            LD      A,(DstHi)
            ADC     A,0
            LD      (DstHi),A

            ; y++
            LD      A,(YIdx)
            ADD     A,1
            LD      (YIdx),A

            ; rows remaining--
            LD      A,(Y_Rem)
            SUB     1
            LD      (Y_Rem),A

            JP      RowLoop

RF_Done:
            RET

; ================================================================
;                         DATA (at end)
; ================================================================

; --- Animation / parameters ---
Time:           DB 0
AmpShift:       DB 4          ; >>4 => amplitude ~ +/-8 pixels

; --- Row / col working ---
YIdx:           DB 0
Y_Rem:          DB 0
YCell:          DB 0
SinIdx:         DB 0
TmpA:           DB 0
ShiftCnt:       DB 0
DxTmp:          DB 0
DxSigned:       DB 0

XPix:           DB 0
XBytes_Rem:     DB 0
XTemp:          DB 0
AccByte:        DB 0

; --- VRAM destination pointer ---
DstLo:          DB 0
DstHi:          DB 0

; --- Contribution tables (2bpp) ---
; Pixel position inside byte (0..3) mapped to proper bit lanes:
Pix0:       DB 0,64,128,192   ; bits 7..6
Pix1:       DB 0,16,32,48     ; bits 5..4
Pix2:       DB 0,4,8,12       ; bits 3..2
Pix3:       DB 0,1,2,3        ; bits 1..0

; --- 256-entry sine table (unsigned 0..255) ---
; Sin256U[n] ˜ round(127*sin(2pn/256) + 128)
Sin256U:
            DB 128,131,134,137,140,143,146,149,152,156,159,162,165,168,171,174
            DB 177,180,183,186,188,191,194,197,199,202,204,207,209,212,214,216
            DB 219,221,223,225,227,229,231,233,234,236,238,239,241,242,244,245
            DB 246,247,248,249,250,251,251,252,253,253,254,254,254,254,255,255
            DB 255,255,255,254,254,254,253,253,252,251,251,250,249,248,247,246
            DB 245,244,242,241,239,238,236,234,233,231,229,227,225,223,221,219
            DB 216,214,212,209,207,204,202,199,197,194,191,188,186,183,180,177
            DB 174,171,168,165,162,159,156,152,149,146,143,140,137,134,131,128
            DB 124,121,118,115,112,109,106,103,100,96,93,90,87,84,81,78
            DB 75,72,69,66,64,61,58,55,53,50,48,45,43,40,38,36
            DB 33,31,29,27,25,23,21,19,18,16,14,13,11,10,8,7
            DB 6,5,4,3,2,1,1,0,0,0,0,0,0,0,0,0
            DB 0,0,0,0,0,1,1,2,3,4,5,6,7,8,10,11
            DB 13,14,16,18,19,21,23,25,27,29,31,33,36,38,40,43
            DB 45,48,50,53,55,58,61,64,66,69,72,75,78,81,84,87
            DB 90,93,96,100,103,106,109,112,115,118,121,124

            END

; ==============================================================
; VZ200/VZ300 MODE(1) "Byte-Aligned Blobs (Step 1)"
; Goal   : Guaranteed visible rectangles (byte-aligned), no masks
; Rules  : ORG $8000, SP $F000, JP-only (no JR),
;          A-only absolute ((nn) only with A),
;          legal Z80 only, all DB/DW at end, one instruction/line.
; Video  : MODE(1) 128x64, 2 bpp, VRAM $7000–$77FF (32 bytes/row)
; ==============================================================

            ORG     $8000

Start:
            LD      SP,$F000

; ---- Enter MODE(1) ----
            LD      A,8
            LD      ($6800),A

; ---- Clear VRAM: seed $7000, replicate 2047 bytes to $77FF ----
            LD      HL,$7000
            LD      DE,$7001
            XOR     A
            LD      (HL),A
            LD      BC,2047
            LDIR

; ---- RNG init (8-bit LCG s = s*17 + 43) ----
            LD      A,157
            LD      (rng),A

; ==============================================================
; Main loop — paint random byte-aligned rectangles forever
; ==============================================================

MainLoop:
; -------- Width in BYTES: 3..12 (i.e., 12..48 pixels wide) --------
            CALL    Rand8
            AND     15
            ADD     A,3
            CP      13
            JP      C,Wb_OK
            LD      A,12
Wb_OK:
            LD      (wBytes),A

; -------- Height in rows: 5..40 --------
            CALL    Rand8
            AND     63
            ADD     A,5
            CP      41
            JP      C,H_OK
            LD      A,40
H_OK:
            LD      (hRows),A
            LD      A,(hRows)
            SRL     A
            LD      (halfH),A          ; halfH = hRows/2

; -------- Colour 1..3 (avoid 0 on blank background) --------
            CALL    Rand8
            AND     3
            JP      NZ,Col_OK


            LD      A,0

Col_OK:
            LD      (col),A

; fillByte = Fill4[col]
            LD      A,(col)
            LD      E,A
            LD      D,0
            LD      HL,Fill4
            ADD     HL,DE
            LD      A,(HL)
            LD      (fillByte),A

; -------- Centre X in BYTES: 0..31 --------
            CALL    Rand8
            AND     31
            LD      (xByteCenter),A

; -------- Centre Y in rows: 0..63 --------
            CALL    Rand8
            AND     63
            LD      (yCenter),A

; ===== Compute horizontal byte range [bStart..bEnd] inside 0..31 =====
; halfWB = wBytes/2
            LD      A,(wBytes)
            SRL     A
            LD      (halfWB),A

; if halfWB < xByteCenter -> bStart = xByteCenter - halfWB, else 0
            LD      A,(halfWB)
            LD      B,A
            LD      A,(xByteCenter)
            LD      C,A
            LD      A,B
            CP      C
            JP      C,StartOK_H
            XOR     A
            LD      (bStart),A
            JP      Calc_bEnd
StartOK_H:
            LD      A,C                ; xByteCenter
            LD      B,A
            LD      A,(halfWB)
            CPL
            ADD     A,1                ; -halfWB
            ADD     A,B
            LD      (bStart),A

Calc_bEnd:
; bEnd = min(31, bStart + wBytes - 1)
            LD      A,(bStart)
            LD      B,A
            LD      A,(wBytes)
            ADD     A,B
            DEC     A
            CP      32
            JP      C,Store_bEnd
            LD      A,31
Store_bEnd:
            LD      (bEnd),A

; ===== Compute vertical row range [yStart..yEnd] inside 0..63 =====
; yStart
            LD      A,(halfH)
            LD      B,A
            LD      A,(yCenter)
            LD      C,A
            LD      A,B
            CP      C
            JP      C,StartOK_V
            XOR     A
            LD      (yStart),A
            JP      Calc_yEnd
StartOK_V:
            LD      A,C                ; yCenter
            LD      B,A
            LD      A,(halfH)
            CPL
            ADD     A,1                ; -halfH
            ADD     A,B
            LD      (yStart),A

Calc_yEnd:
; yEnd = min(63, yStart + hRows - 1)
            LD      A,(yStart)
            LD      B,A
            LD      A,(hRows)
            ADD     A,B
            DEC     A
            CP      64
            JP      C,Store_yEnd
            LD      A,63
Store_yEnd:
            LD      (yEnd),A

; ===== rowsCnt = yEnd - yStart + 1 =====
            LD      A,(yEnd)
            LD      C,A
            LD      A,(yStart)
            CPL
            ADD     A,1
            ADD     A,C
            LD      (rowsCnt),A

; ===== Per-rectangle vertical loop =====
; yCur = yStart
            LD      A,(yStart)
            LD      (yCur),A

RowLoop:
            LD      A,(rowsCnt)
            OR      A
            JP      Z,NextRect

; ----- DE = RowTab[yCur] -----
            LD      A,(yCur)
            LD      L,A
            XOR     A
            LD      H,A
            ADD     HL,HL              ; index*2
            LD      DE,RowTab
            ADD     HL,DE
            LD      A,(HL)
            LD      (rowLo),A
            INC     HL
            LD      A,(HL)
            LD      (rowHi),A
            LD      A,(rowHi)
            LD      D,A
            LD      A,(rowLo)
            LD      E,A

; ----- DE += bStart (within row) -----
            LD      A,(bStart)
            LD      C,A
            LD      A,E
            ADD     A,C
            LD      E,A
            JP      NC,NoCarryStart
            INC     D
NoCarryStart:

; ----- byteCount = (bEnd - bStart + 1) -----
            LD      A,(bEnd)
            LD      B,A
            LD      A,(bStart)
            CPL
            ADD     A,1
            ADD     A,B
            LD      (byteCnt),A

; ----- Fill loop: write fillByte into DE, byteCnt times -----
            LD      A,(fillByte)
            LD      (tempFill),A

FillLoop:
            LD      A,(byteCnt)
            OR      A
            JP      Z,RowDone

            LD      A,(tempFill)
            LD      (DE),A
            INC     DE

            LD      HL,byteCnt
            DEC     (HL)
            JP      FillLoop

RowDone:
; yCur++, rowsCnt--
            LD      HL,yCur
            INC     (HL)
            LD      HL,rowsCnt
            DEC     (HL)
            JP      RowLoop

NextRect:
            JP      MainLoop

; ==============================================================
; --------------------- Subroutines ----------------------------
; ==============================================================

; Rand8: 8-bit LCG s = s*17 + 43  ? A
rand8:
            LD      A,(rng)
            LD      B,A
            LD      A,B
            ADD     A,A                ; *2
            ADD     A,A                ; *4
            ADD     A,A                ; *8
            ADD     A,A                ; *16
            ADD     A,B                ; *17
            ADD     A,43
            LD      (rng),A
            RET


Rand8:	ld 	a, r
	rrca
	rrca
	neg
seed	equ 	$+1
	xor 	0
	rrca
	ld 	(seed), a
	ret



; ==============================================================
; DATA SECTION (all data after code)
; ==============================================================

; RNG
rng:        DEFB    0

; Parameters / state
wBytes:     DEFB    0
hRows:      DEFB    0
halfWB:     DEFB    0
halfH:      DEFB    0
col:        DEFB    0
fillByte:   DEFB    0

xByteCenter:DEFB    0
yCenter:    DEFB    0

bStart:     DEFB    0
bEnd:       DEFB    0
yStart:     DEFB    0
yEnd:       DEFB    0
rowsCnt:    DEFB    0
yCur:       DEFB    0
byteCnt:    DEFB    0
rowLo:      DEFB    0
rowHi:      DEFB    0
tempFill:   DEFB    0

; Tables
; 2bpp full-byte fill patterns: 0->$00, 1->$55, 2->$AA, 3->$FF
Fill4:      DEFB    $00,$55,$AA,$FF

; RowTab[y] = $7000 + 32*y (64 entries)
RowTab:
            DEFW $7000,$7020,$7040,$7060,$7080,$70A0,$70C0,$70E0
            DEFW $7100,$7120,$7140,$7160,$7180,$71A0,$71C0,$71E0
            DEFW $7200,$7220,$7240,$7260,$7280,$72A0,$72C0,$72E0
            DEFW $7300,$7320,$7340,$7360,$7380,$73A0,$73C0,$73E0
            DEFW $7400,$7420,$7440,$7460,$7480,$74A0,$74C0,$74E0
            DEFW $7500,$7520,$7540,$7560,$7580,$75A0,$75C0,$75E0
            DEFW $7600,$7620,$7640,$7660,$7680,$76A0,$76C0,$76E0
            DEFW $7700,$7720,$7740,$7760,$7780,$77A0,$77C0,$77E0

            END     Start
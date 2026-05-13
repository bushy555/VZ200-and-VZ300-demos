; ================================================================
; VZ200 / VZ300 - MODE(1) Feedback Effect (fixed seed loop)
; - Visual feedback: copy screen down+right by 1 row + 1 byte
; - Seed new yellow/red pixels each frame using 16-bit LFSR
; - Blue background ($AA) in MODE(1)
; Strict PASMO rules: ORG $8000, SP $F000, JP only, A-only (nn), all data at end
; ================================================================

        ORG     $8000

Start:

        ; Enter MODE(1)
        LD      A,8
        LD      ($6800),A

        ; Clear to blue once
;        CALL    ClearScreenBlue

        ; Optional: initial seed cross near center
        CALL    InitSeedCross

; --------------------------
; Main loop
; --------------------------
MainLoop:
        CALL    FeedbackShiftDownRight   ; recursive feedback (down+right)
        CALL    SeedSprinkles            ; inject fresh energy (random pixels)
;        CALL    SmallDelay               ; pacing
 


	push	hl
	LD 	hl,0x6800
sync2:	BIT 	7,(hl)			; fancy wait retrace.
	jr	NZ,sync2

	LD 	hl,0x6800
sync3:	BIT 	7,(hl)			; fancy wait retrace.
	jr	Z,sync3
	pop	hl


       JP      MainLoop

; ---------------------------------------------------------------
; FeedbackShiftDownRight
; Copies VRAM [$7000..$77FF] to [$7000+33 .. $77FF] using LDDR,
; then refills the top row and the first column with $AA (blue).
; ---------------------------------------------------------------
FeedbackShiftDownRight:
        ; Move 2015 bytes: [0..2014] -> [33..2047]
        LD      HL,$7000+2014
        LD      DE,$7000+2047
        LD      BC,2015
        LDDR

        ; Top row (32 bytes) = blue
        LD      A,$AA
        LD      HL,$7000
        LD      B,32
FSDR_TopRow:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FSDR_TopRow

        ; First column of rows 1..63 = blue
        LD      A,$AA
        LD      HL,$7000+32          ; $7020
        LD      C,63
        LD      DE,32
FSDR_LeftCol:
        LD      (HL),A
        ADD     HL,DE
        DEC     C
        JP      NZ,FSDR_LeftCol
        RET

; ---------------------------------------------------------------
; SeedSprinkles  — FIXED
; Seeds ~8 pixels per frame using RNG16.
; Uses RAM counter SeedCnt so B can carry Y safely through plotting.
; ---------------------------------------------------------------
SeedSprinkles:
        LD      A,8
        LD      (SeedCnt),A
SS_Loop:
        CALL    RNG16

        ; X in C (0..127), Y in B (0..63)
        LD      A,L
        AND     127
        LD      C,A
        LD      A,H
        AND     63
        LD      B,A

        ; Color from LSB of LFSR
        LD      A,L
        AND     1
        JP      Z,SeedYellow
        CALL    PlotPixelRed
        JP      SS_Next
SeedYellow:
        CALL    PlotPixelYellow
SS_Next:
        LD      A,(SeedCnt)
        DEC     A
        LD      (SeedCnt),A
        JP      NZ,SS_Loop
        RET

; ---------------------------------------------------------------
; InitSeedCross — small cross around (64,32)
; ---------------------------------------------------------------
InitSeedCross:
        LD      B,32
        LD      C,64
        CALL    PlotPixelRed

        LD      B,32
        LD      C,63
        CALL    PlotPixelYellow

        LD      B,32
        LD      C,65
        CALL    PlotPixelYellow

        LD      B,31
        LD      C,64
        CALL    PlotPixelYellow

        LD      B,33
        LD      C,64
        CALL    PlotPixelYellow
        RET

; ---------------------------------------------------------------
; PlotPixelYellow
; Inputs: B=Y (0..63), C=X (0..127)
; Writes color 01 to the 2-bit pixel at (X,Y)
; ---------------------------------------------------------------
PlotPixelYellow:
        ; HL = RowBase[Y]
        LD      H,0
        LD      L,B
        ADD     HL,HL
        LD      DE,RowBaseTable
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      H,D
        LD      L,E                  ; HL = row base

        ; HL += (X>>2)
        LD      A,C
        SRL     A
        SRL     A
        LD      D,0
        LD      E,A
        ADD     HL,DE

        ; subpixel = X & 3  (0..3)
        LD      A,C
        AND     3

        ; Save VRAM byte address into DE
        LD      D,H
        LD      E,L

        ; B = clear mask, C = set mask (Yellow)
        LD      HL,ClearMaskTable
        LD      B,0
        LD      C,A
        ADD     HL,BC
        LD      B,(HL)

        LD      HL,SetMaskYellowTable
        ADD     HL,BC
        LD      C,(HL)

        ; Write back
        LD      H,D
        LD      L,E
        LD      A,(HL)
        AND     B
        OR      C
        LD      (HL),A
        RET

; ---------------------------------------------------------------
; PlotPixelRed
; Inputs: B=Y (0..63), C=X (0..127)
; Writes color 11 to the 2-bit pixel at (X,Y)
; ---------------------------------------------------------------
PlotPixelRed:
        ; HL = RowBase[Y]
        LD      H,0
        LD      L,B
        ADD     HL,HL
        LD      DE,RowBaseTable
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      H,D
        LD      L,E                  ; HL = row base

        ; HL += (X>>2)
        LD      A,C
        SRL     A
        SRL     A
        LD      D,0
        LD      E,A
        ADD     HL,DE

        ; subpixel = X & 3
        LD      A,C
        AND     3

        ; Save VRAM byte address into DE
        LD      D,H
        LD      E,L

        ; B = clear mask, C = set mask (Red)
        LD      HL,ClearMaskTable
        LD      B,0
        LD      C,A
        ADD     HL,BC
        LD      B,(HL)

        LD      HL,SetMaskRedTable
        ADD     HL,BC
        LD      C,(HL)

        ; Write back
        LD      H,D
        LD      L,E
        LD      A,(HL)
        AND     B
        OR      C
        LD      (HL),A
        RET

; ---------------------------------------------------------------
; ClearScreenBlue  ($AA across all 64 rows)
; ---------------------------------------------------------------
ClearScreenBlue:
        LD      HL,BlueRow32
        LD      DE,$7000
        LD      BC,32
        LDIR
        LD      HL,$7000
        LD      DE,$7020
        LD      B,63
CSB_RowLoop:
        LD      BC,32
        LDIR
        DEC     B
        JP      NZ,CSB_RowLoop
        RET

; ---------------------------------------------------------------
; SmallDelay
; ---------------------------------------------------------------
SmallDelay:
	
        LD      D,7
SD_Outer:
        LD      E,50
SD_Inner:
        DEC     E
        JP      NZ,SD_Inner
        DEC     D
        JP      NZ,SD_Outer
        RET

; ---------------------------------------------------------------
; RNG16: 16-bit Galois LFSR (right shift), polynomial 0xB400
; State at RNGState (word). Returns HL = new state.
; ---------------------------------------------------------------
RNG16:
        LD      HL,(RNGState)
        LD      A,L
        AND     1
        JP      Z,RNG_NoTap
        SRL     H
        RR      L
        LD      A,H
        XOR     $B4
        LD      H,A
        JP      RNG_Store
RNG_NoTap:
        SRL     H
        RR      L
RNG_Store:
        LD      (RNGState),HL
        RET

; ================================================================
; ======================== DATA SECTION ==========================
; All data at END (required)
; ================================================================

; VRAM row base addresses: $7000 + 32*y
RowBaseTable:
        DW $7000,$7020,$7040,$7060,$7080,$70A0,$70C0,$70E0
        DW $7100,$7120,$7140,$7160,$7180,$71A0,$71C0,$71E0
        DW $7200,$7220,$7240,$7260,$7280,$72A0,$72C0,$72E0
        DW $7300,$7320,$7340,$7360,$7380,$73A0,$73C0,$73E0
        DW $7400,$7420,$7440,$7460,$7480,$74A0,$74C0,$74E0
        DW $7500,$7520,$7540,$7560,$7580,$75A0,$75C0,$75E0
        DW $7600,$7620,$7640,$7660,$7680,$76A0,$76C0,$76E0
        DW $7700,$7720,$7740,$7760,$7780,$77A0,$77C0,$77E0

; Clear masks for 2-bit pair (index 0..3)
ClearMaskTable:
        DB $3F,$CF,$F3,$FC

; Set masks for Yellow (01) per pair
SetMaskYellowTable:
        DB $40,$10,$04,$01

; Set masks for Red (11) per pair
SetMaskRedTable:
        DB $C0,$30,$0C,$03

; 32-byte template for Blue row ($AA)
BlueRow32:
        DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
        DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
        DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
        DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA

; Seed loop counter (RAM)
SeedCnt:
        DB 0

; RNG initial state (non-zero)
RNGState:
        DW $ACE1

; ================================================================
; End of file

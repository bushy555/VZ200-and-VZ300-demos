; ================================================================
; VZ200 / VZ300 - MODE(1) Rotating Feedback Star Effect
;
; Stars radiate from the screen centre (64,32) and travel in one
; of 64 evenly-spaced directions.  The active direction advances
; every 10 animated frames, rotating smoothly through 360 degrees.
; The feedback scroll (the "echo" trail) rotates with the stars.
;
; 64 directions map to 8 physical scroll directions (the 8-compass
; directions that are achievable with +/-1 byte and +/-1 row steps):
;   0 Right, 1 Down-Right, 2 Down, 3 Down-Left,
;   4 Left,  5 Up-Left,    6 Up,   7 Up-Right
;
; Each feedback routine shifts the VRAM contents by the correct
; signed offset using LDDR (positive offset) or LDIR (negative),
; then fills the vacated strip with blue ($AA).
;
; Strict PASMO rules: ORG $8000, SP $F000, JP only, A-only (nn),
; legal Z80 16-bit opcodes, all DB/DW at end, one instruction/line.
; ================================================================

        ORG     $8000

Start:

        ; Enter MODE(1)
        LD      A,8
        LD      ($6800),A

        ; Clear VRAM to blue
        CALL    ClearScreenBlue

        ; Seed a cross at screen centre to kick off the effect
        CALL    InitSeedCross

        ; Initialise rotation state
        XOR     A
        LD      (DirIndex),A
        LD      A,10
        LD      (FrameCount),A

; ================================================================
; Main loop
; ================================================================
MainLoop:
        ; Step 1: Feedback scroll in the current direction
        CALL    DoFeedback

        ; Step 2: Seed fresh pixels near the screen centre
        CALL    SeedSprinkles

        ; Step 3: Advance direction timer
        LD      A,(FrameCount)
        DEC     A
        LD      (FrameCount),A
        JP      NZ,ML_NoAdvance

        ; Timer reached zero: advance to next direction
        LD      A,10
        LD      (FrameCount),A
        LD      A,(DirIndex)
        INC     A
        AND     63              ; wrap 0..63
        LD      (DirIndex),A

ML_NoAdvance:
        JP      MainLoop

; ================================================================
; DoFeedback
; Reads DirIndex -> looks up DirIDTable -> dispatches to one of
; 8 feedback routines via a 16-bit jump table.
; ================================================================
DoFeedback:
        ; A = DirIDTable[DirIndex]  (0..7)
        LD      HL,DirIDTable
        LD      A,(DirIndex)
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)          ; A = direction ID 0..7

        ; Index into FeedbackJumpTable (2 bytes per entry)
        LD      E,A
        LD      D,0
        ADD     HL,DE           ; Note: HL still in DirIDTable area
        LD      HL,FeedbackJumpTable
        ADD     HL,DE
        ADD     HL,DE           ; HL = &FeedbackJumpTable[DirID*2]

        ; Load target address into DE then jump
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        JP      (HL)

; ================================================================
; FB_Right  (DirID=0)
; Shifts VRAM right by 1 byte (4 pixels).
; LDDR copies VRAM[0..2046] -> VRAM[1..2047].
; Clears vacated byte: VRAM[0] = $AA.
; ================================================================
FB_Right:
        LD      HL,$77FE
        LD      DE,$77FF
        LD      BC,2047
        LDDR
        LD      A,$AA
        LD      HL,$7000
        LD      (HL),A
        RET

; ================================================================
; FB_DownRight  (DirID=1)
; Shifts VRAM down 1 row + right 1 byte  (offset = +33).
; LDDR copies VRAM[0..2014] -> VRAM[33..2047].
; Clears vacated 33 bytes: VRAM[0..32] = $AA.
; ================================================================
FB_DownRight:
        LD      HL,$77DE
        LD      DE,$77FF
        LD      BC,2015
        LDDR
        LD      HL,$7000
        LD      B,33
        LD      A,$AA
FB_DR_Fill:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FB_DR_Fill
        RET

; ================================================================
; FB_Down  (DirID=2)
; Shifts VRAM down 1 row  (offset = +32).
; LDDR copies VRAM[0..2015] -> VRAM[32..2047].
; Clears vacated 32 bytes: VRAM[0..31] = $AA.
; ================================================================
FB_Down:
        LD      HL,$77DF
        LD      DE,$77FF
        LD      BC,2016
        LDDR
        LD      HL,$7000
        LD      B,32
        LD      A,$AA
FB_D_Fill:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FB_D_Fill
        RET

; ================================================================
; FB_DownLeft  (DirID=3)
; Shifts VRAM down 1 row + left 1 byte  (offset = +31).
; LDDR copies VRAM[0..2016] -> VRAM[31..2047].
; Clears vacated 31 bytes: VRAM[0..30] = $AA.
; ================================================================
FB_DownLeft:
        LD      HL,$77E0
        LD      DE,$77FF
        LD      BC,2017
        LDDR
        LD      HL,$7000
        LD      B,31
        LD      A,$AA
FB_DL_Fill:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FB_DL_Fill
        RET

; ================================================================
; FB_Left  (DirID=4)
; Shifts VRAM left by 1 byte  (offset = -1).
; LDIR copies VRAM[1..2047] -> VRAM[0..2046].
; Clears vacated byte: VRAM[2047] = $AA.
; ================================================================
FB_Left:
        LD      HL,$7001
        LD      DE,$7000
        LD      BC,2047
        LDIR
        LD      A,$AA
        LD      HL,$77FF
        LD      (HL),A
        RET

; ================================================================
; FB_UpLeft  (DirID=5)
; Shifts VRAM up 1 row + left 1 byte  (offset = -33).
; LDIR copies VRAM[33..2047] -> VRAM[0..2014].
; Clears vacated 33 bytes: VRAM[2015..2047] = $AA.
; ================================================================
FB_UpLeft:
        LD      HL,$7021
        LD      DE,$7000
        LD      BC,2015
        LDIR
        LD      HL,$77DF
        LD      B,33
        LD      A,$AA
FB_UL_Fill:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FB_UL_Fill
        RET

; ================================================================
; FB_Up  (DirID=6)
; Shifts VRAM up 1 row  (offset = -32).
; LDIR copies VRAM[32..2047] -> VRAM[0..2015].
; Clears vacated 32 bytes: VRAM[2016..2047] = $AA.
; ================================================================
FB_Up:
        LD      HL,$7020
        LD      DE,$7000
        LD      BC,2016
        LDIR
        LD      HL,$77E0
        LD      B,32
        LD      A,$AA
FB_U_Fill:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FB_U_Fill
        RET

; ================================================================
; FB_UpRight  (DirID=7)
; Shifts VRAM up 1 row + right 1 byte  (offset = -31).
; LDIR copies VRAM[31..2047] -> VRAM[0..2016].
; Clears vacated 31 bytes: VRAM[2017..2047] = $AA.
; ================================================================
FB_UpRight:
        LD      HL,$701F
        LD      DE,$7000
        LD      BC,2017
        LDIR
        LD      HL,$77E1
        LD      B,31
        LD      A,$AA
FB_UR_Fill:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FB_UR_Fill
        RET

; ================================================================
; SeedSprinkles
; Injects 8 fresh pixels per frame near the screen centre (64,32).
; Pixel X = 56 + (RNG.L AND 15) -> range 56..71 (centre ~63)
; Pixel Y = 28 + (RNG.H AND 7)  -> range 28..35 (centre ~31)
; Colour alternates yellow/red based on LFSR LSB.
; ================================================================
SeedSprinkles:
        LD      A,8
        LD      (SeedCnt),A

SS_Loop:
        CALL    RNG16

        ; X = 56 + (L AND 15)
        LD      A,L
        AND     15
        ADD     A,56
        LD      C,A             ; C = X

        ; Y = 28 + (H AND 7)
        LD      A,H
        AND     7
        ADD     A,28
        LD      B,A             ; B = Y

        ; Colour: use bit 0 of L
        LD      A,L
        AND     1
        JP      Z,SS_Yellow
        CALL    PlotPixelRed
        JP      SS_Next
SS_Yellow:
        CALL    PlotPixelYellow
SS_Next:
        LD      A,(SeedCnt)
        DEC     A
        LD      (SeedCnt),A
        JP      NZ,SS_Loop
        RET

; ================================================================
; InitSeedCross - small cross at (64,32) to prime the feedback
; ================================================================
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

; ================================================================
; PlotPixelYellow
; Inputs: B=Y (0..63), C=X (0..127)
; Writes colour 01 (yellow) to the 2-bit pixel at (X,Y).
; MC6847 pixel order within byte: MSB = leftmost pixel.
; pixel_field = (3 - (X AND 3)) * 2  (leftmost field at bits 7:6)
; ================================================================
PlotPixelYellow:
        ; HL = RowBaseTable[Y*2]
        LD      H,0
        LD      L,B
        ADD     HL,HL
        LD      DE,RowBaseTable
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      H,D
        LD      L,E             ; HL = VRAM row base

        ; HL += X >> 2
        LD      A,C
        SRL     A
        SRL     A
        LD      D,0
        LD      E,A
        ADD     HL,DE           ; HL = VRAM byte address

        ; subpixel index (0..3): invert so 0 = leftmost (MSB)
        LD      A,C
        AND     3
        XOR     3               ; 0->3(MSB), 1->2, 2->1, 3->0(LSB)

        LD      D,H
        LD      E,L             ; save VRAM address in DE

        ; clear mask
        LD      HL,ClearMaskTable
        LD      B,0
        LD      C,A
        ADD     HL,BC
        LD      B,(HL)          ; B = clear mask

        ; set mask (yellow)
        LD      HL,SetMaskYellowTable
        ADD     HL,BC
        LD      C,(HL)          ; C = set mask

        LD      H,D
        LD      L,E
        LD      A,(HL)
        AND     B
        OR      C
        LD      (HL),A
        RET

; ================================================================
; PlotPixelRed
; Inputs: B=Y (0..63), C=X (0..127)
; Writes colour 11 (red) to the 2-bit pixel at (X,Y).
; ================================================================
PlotPixelRed:
        LD      H,0
        LD      L,B
        ADD     HL,HL
        LD      DE,RowBaseTable
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      H,D
        LD      L,E

        LD      A,C
        SRL     A
        SRL     A
        LD      D,0
        LD      E,A
        ADD     HL,DE

        LD      A,C
        AND     3
        XOR     3

        LD      D,H
        LD      E,L

        LD      HL,ClearMaskTable
        LD      B,0
        LD      C,A
        ADD     HL,BC
        LD      B,(HL)

        LD      HL,SetMaskRedTable
        ADD     HL,BC
        LD      C,(HL)

        LD      H,D
        LD      L,E
        LD      A,(HL)
        AND     B
        OR      C
        LD      (HL),A
        RET

; ================================================================
; ClearScreenBlue  - fill all 2048 VRAM bytes with $AA
; ================================================================
ClearScreenBlue:
        LD      HL,$7000
        LD      DE,$7001
        LD      A,$AA
        LD      (HL),A
        LD      BC,2047
        LDIR
        RET

; ================================================================
; RNG16: 16-bit Galois LFSR, polynomial $B400
; Returns new state in HL; updates RNGState.
; ================================================================
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
; All DB / DW at end (PASMO rule).
; ================================================================

; VRAM row base addresses: $7000 + 32*y  (64 entries, 128 bytes)
RowBaseTable:
        DW $7000,$7020,$7040,$7060,$7080,$70A0,$70C0,$70E0
        DW $7100,$7120,$7140,$7160,$7180,$71A0,$71C0,$71E0
        DW $7200,$7220,$7240,$7260,$7280,$72A0,$72C0,$72E0
        DW $7300,$7320,$7340,$7360,$7380,$73A0,$73C0,$73E0
        DW $7400,$7420,$7440,$7460,$7480,$74A0,$74C0,$74E0
        DW $7500,$7520,$7540,$7560,$7580,$75A0,$75C0,$75E0
        DW $7600,$7620,$7640,$7660,$7680,$76A0,$76C0,$76E0
        DW $7700,$7720,$7740,$7760,$7780,$77A0,$77C0,$77E0

; Clear masks for 2-bit pixel field (index 0..3, where 3 = leftmost/MSB)
; Field 3 (bits 7:6): mask $3F   Field 2 (bits 5:4): mask $CF
; Field 1 (bits 3:2): mask $F3   Field 0 (bits 1:0): mask $FC
ClearMaskTable:
        DB $FC,$F3,$CF,$3F

; Set masks for Yellow (colour 01) per field index 0..3
SetMaskYellowTable:
        DB $01,$04,$10,$40

; Set masks for Red (colour 11) per field index 0..3
SetMaskRedTable:
        DB $03,$0C,$30,$C0

; 64-direction ID table.
; Maps angle index 0..63 (0=right, increases CCW) to direction ID 0..7.
; Computed from: dx=round(cos(i*360/64)*1.5), dy=round(sin(i*360/64))
; ID: 0=right 1=downright 2=down 3=downleft 4=left 5=upleft 6=up 7=upright
DirIDTable:
        DB 0,0,0,0,0,0,1,1
        DB 1,1,1,1,1,2,2,2
        DB 2,2,2,2,3,3,3,3
        DB 3,3,3,4,4,4,4,4
        DB 4,4,4,4,4,4,5,5
        DB 5,5,5,5,5,6,6,6
        DB 6,6,6,6,7,7,7,7
        DB 7,7,7,0,0,0,0,0

; Jump table: 8 words pointing to the 8 feedback routines
FeedbackJumpTable:
        DW FB_Right
        DW FB_DownRight
        DW FB_Down
        DW FB_DownLeft
        DW FB_Left
        DW FB_UpLeft
        DW FB_Up
        DW FB_UpRight

; ---- RAM variables ----

; Current direction angle index (0..63)
DirIndex:
        DB 0

; Frames remaining in current direction (counts 10 down to 1)
FrameCount:
        DB 10

; Seed loop counter
SeedCnt:
        DB 0

; LFSR state (must be non-zero)
RNGState:
        DW $ACE1

        END     Start

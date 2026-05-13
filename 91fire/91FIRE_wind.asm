; ============================================================
; DOOM FIRE effect for VZ200 / VZ300 -- WIND + FLICKER variant
; MODE(0): 32x16 colour blocks, VRAM $7000-$71FF
; ORG $8000, SP $F000
; PASMO assembler
; ============================================================
;
; CHANGES vs df1_flicker.asm: Gusting wind effect
;
;   The horizontal drift in PROPAGATE is no longer symmetric.
;   A wind state machine runs in MAIN_LOOP each frame:
;
;     WINDCNT  -- frame countdown; when it hits zero a new
;                 gust is chosen.
;     WINDDIR  -- current wind direction:
;                   0 = calm  (symmetric drift, as before)
;                   1 = right (flames lean right)
;                   2 = left  (flames lean left)
;
;   Each gust lasts (RND8 & 63) + 33 = 33..96 frames, so the
;   wind changes every second or two at typical VZ200 speed.
;   Direction is re-rolled as: 0,1->calm  2->right  3->left
;   (50% calm, 25% right, 25% left) so the fire spends about
;   half its time upright and half leaning one way or the other.
;
;   Drift probability tables per wind state:
;     CALM  : 0->left  1,3->centre  2->right   (25/50/25)
;     RIGHT : 0,1,2->right  3->centre           (75/25/0)
;     LEFT  : 0,1,2->left   3->centre           (0/25/75)
;
;   Flicker source row retained from df1_flicker.asm.
;
; Palette (authentic DOOM colours, no green):
;   BLACK  $80  background / off
;   RED    $BF  coolest visible flame
;   ORANGE $FF  mid flame
;   YELLOW $9F  hot
;   BUFF   $CF  white-hot (source)
;
; Cooling chain: BUFF -> YELLOW -> ORANGE -> RED -> BLACK
;
; ============================================================

        ORG     $8000

VRAM            EQU     $7000
WIDTH           EQU     32
HEIGHT          EQU     16

BLACK_BLOCK     EQU     $80
RED_BLOCK       EQU     $BF
ORANGE_BLOCK    EQU     $FF
YELLOW_BLOCK    EQU     $9F
BUFF_BLOCK      EQU     $CF

; ============================================================
; ENTRY
; ============================================================
START:
        DI
        LD      SP,$F000

        XOR     A
        LD      ($6800),A

        LD      HL,VRAM
        LD      A,BLACK_BLOCK
        LD      (HL),A
        LD      DE,VRAM+1
        LD      BC,512-1
        LDIR

        ; Initialise wind: calm, countdown = 48
        XOR     A
        LD      (WINDDIR),A
        LD      A,48
        LD      (WINDCNT),A

; ============================================================
; MAIN LOOP
; ============================================================
MAIN_LOOP:
        CALL    UPDATE_WIND
        CALL    FILL_SOURCE
        CALL    PROPAGATE
;        CALL    FRAME_DELAY
        JP      MAIN_LOOP

; ============================================================
; UPDATE_WIND
; Called once per frame. Decrements WINDCNT. When it reaches
; zero, rolls a new direction and a new duration.
;
; Duration  = (RND8 & 63) + 33   -> 33..96 frames
; Direction = RND8 & 3:
;               0,1 -> calm  (WINDDIR = 0)
;               2   -> right (WINDDIR = 1)
;               3   -> left  (WINDDIR = 2)
;
; Clobbers A only (WINDCNT/WINDDIR are memory).
; ============================================================
UPDATE_WIND:
        LD      A,(WINDCNT)
        DEC     A
        LD      (WINDCNT),A
        JP      NZ,UW_DONE      ; still counting, nothing to do

        ; Roll new duration: (RND8 & 63) + 33
        CALL    RND8
        AND     $3F             ; 0..63
        ADD     A,33            ; 33..96
        LD      (WINDCNT),A

        ; Roll new direction
        CALL    RND8
        AND     3
        CP      2
        JP      Z,UW_RIGHT
        CP      3
        JP      Z,UW_LEFT
        ; 0 or 1 -> calm
        XOR     A               ; WINDDIR = 0
        JP      UW_SETDIR
UW_RIGHT:
        LD      A,1             ; WINDDIR = 1
        JP      UW_SETDIR
UW_LEFT:
        LD      A,2             ; WINDDIR = 2
UW_SETDIR:
        LD      (WINDDIR),A
UW_DONE:
        RET

; ============================================================
; FILL_SOURCE
; Seeds the bottom row (row 15) with flickering fire.
;
;   AND 3 == 0  (25%) -> BLACK  (gap / flicker)
;   AND 3 == 1  (25%) -> BUFF   (white-hot)
;   AND 3 == 2  (25%) -> BUFF   (white-hot)
;   AND 3 == 3  (25%) -> YELLOW
; ============================================================
FILL_SOURCE:
        LD      HL,VRAM+15*WIDTH
        LD      A,WIDTH
        LD      (FSCNT),A

FS_LOOP:
        CALL    RND8
        AND     3
        CP      0
        JP      Z,FS_BLACK
        CP      3
        JP      Z,FS_YELLOW
        LD      A,BUFF_BLOCK
        JP      FS_STORE
FS_BLACK:
        LD      A,BLACK_BLOCK
        JP      FS_STORE
FS_YELLOW:
        LD      A,YELLOW_BLOCK
FS_STORE:
        LD      (HL),A
        INC     HL
        LD      A,(FSCNT)
        DEC     A
        LD      (FSCNT),A
        JP      NZ,FS_LOOP
        RET

; ============================================================
; PROPAGATE
; For each cell in rows 0-14, read from the row below,
; optionally cool one step, write with wind-biased col drift.
;
;   HL = destination (rows 0..14, starts VRAM)
;   DE = source      (rows 1..15, starts VRAM+WIDTH)
;   BC = cells remaining (15*32 = 480)
;   COL = current column 0..31 (memory)
;
; Drift is decided by WINDDIR:
;   0 (calm)  : 0->L  1,3->C  2->R
;   1 (right) : 0,1,2->R  3->C
;   2 (left)  : 0,1,2->L  3->C
; ============================================================
PROPAGATE:
        LD      HL,VRAM
        LD      DE,VRAM+WIDTH
        LD      BC,15*WIDTH
        XOR     A
        LD      (COL),A

PROP_LOOP:
        LD      A,(DE)
        LD      (TEMP),A

        CP      BLACK_BLOCK
        JP      Z,NO_COOL

        CALL    RND8
        BIT     3,A
        JP      Z,NO_COOL

        LD      A,(TEMP)
        CP      BUFF_BLOCK
        JP      Z,COOL_YELLOW
        CP      YELLOW_BLOCK
        JP      Z,COOL_ORANGE
        CP      ORANGE_BLOCK
        JP      Z,COOL_RED
        LD      A,BLACK_BLOCK
        JP      COOL_DONE
COOL_YELLOW:
        LD      A,YELLOW_BLOCK
        JP      COOL_DONE
COOL_ORANGE:
        LD      A,ORANGE_BLOCK
        JP      COOL_DONE
COOL_RED:
        LD      A,RED_BLOCK
COOL_DONE:
        LD      (TEMP),A

NO_COOL:
        ; Get random 2-bit value for drift decision
        CALL    RND8
        AND     3
        LD      (DRIFT),A       ; save safely -- B is BC loop counter

        ; Branch on WINDDIR
        LD      A,(WINDDIR)
        CP      1
        JP      Z,DRIFT_RIGHT_WIND
        CP      2
        JP      Z,DRIFT_LEFT_WIND

        ; --- CALM drift: 0->L  1,3->C  2->R ---
        LD      A,(DRIFT)
        CP      0
        JP      Z,TRY_LEFT
        CP      2
        JP      Z,TRY_RIGHT
        JP      CENTER

        ; --- RIGHT WIND drift: 0,1,2->R  3->C ---
DRIFT_RIGHT_WIND:
        LD      A,(DRIFT)
        CP      3
        JP      Z,CENTER
        JP      TRY_RIGHT

        ; --- LEFT WIND drift: 0,1,2->L  3->C ---
DRIFT_LEFT_WIND:
        LD      A,(DRIFT)
        CP      3
        JP      Z,CENTER
        JP      TRY_LEFT

CENTER:
        LD      A,(TEMP)
        LD      (HL),A
        JP      WRITE_DONE

TRY_LEFT:
        LD      A,(COL)
        OR      A
        JP      Z,CENTER
        DEC     HL
        LD      A,(TEMP)
        LD      (HL),A
        INC     HL
        JP      WRITE_DONE

TRY_RIGHT:
        LD      A,(COL)
        CP      WIDTH-1
        JP      Z,CENTER
        INC     HL
        LD      A,(TEMP)
        LD      (HL),A
        DEC     HL

WRITE_DONE:
        INC     HL
        INC     DE

        LD      A,(COL)
        INC     A
        CP      WIDTH
        JP      NZ,STORE_COL
        XOR     A
STORE_COL:
        LD      (COL),A

        DEC     BC
        LD      A,B
        OR      C
        JP      NZ,PROP_LOOP
        RET

; ============================================================
; FRAME_DELAY
; ============================================================
FRAME_DELAY:
        LD      BC,$0FFF
FD_LOOP:
        DEC     BC
        LD      A,B
        OR      C
        JP      NZ,FD_LOOP
        RET

; ============================================================
; RND8
; Returns pseudo-random byte in A.  Clobbers A ONLY.
; ============================================================
RND8:
        LD      A,(SEED)
        RRCA
        RRCA
        RRCA
        XOR     $1F
        LD      (RNDSCRATCH),A
        LD      A,(SEED)
        PUSH    HL
        LD      HL,RNDSCRATCH
        ADD     A,(HL)
        POP     HL
        LD      (SEED),A
        RET

; ============================================================
; DATA
; ============================================================
TEMP:           DB      0
RNDSCRATCH:     DB      0
COL:            DB      0
FSCNT:          DB      0
SEED:           DB      $A7
WINDDIR:        DB      0       ; 0=calm  1=right  2=left
WINDCNT:        DB      48      ; frames until next gust re-roll
DRIFT:          DB      0       ; saved 2-bit drift roll for PROPAGATE

        END

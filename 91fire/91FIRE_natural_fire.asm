; ============================================================
; DOOM FIRE effect for VZ200 / VZ300 -- COLOUR TEMPERATURE SHIFT
; MODE(0): 32x16 colour blocks, VRAM $7000-$71FF
; ORG $8000, SP $F000
; PASMO assembler
; ============================================================
;
; CHANGE vs df1_flicker.asm: Colour temperature shift
;
;   The source row temperature cycles slowly through 8 phases,
;   making the fire surge, cool, die out, then reignite -- a
;   full "breathing" cycle every ~512 frames.
;
;   Two new variables drive the cycle:
;     TCNT   -- frame countdown (64 frames per phase)
;     TPHASE -- current phase 0..7
;
;   FILL_SOURCE seeds the bottom row differently each phase.
;   PROPAGATE and the cooling chain are UNCHANGED -- old heat
;   already in the fire body dissipates naturally as the source
;   cools, so the colour change ripples up through the flames
;   gradually rather than cutting off hard.
;
;   Phase table (each phase = 64 frames):
;
;     Phase 0  PEAK    source: 25% black, 50% BUFF,   25% YELLOW
;     Phase 1  YELLOW  source: 25% black, 25% BUFF,   50% YELLOW
;     Phase 2  ORANGE  source: 25% black, 50% ORANGE, 25% YELLOW
;     Phase 3  RED     source: 50% black, 25% RED,    25% ORANGE
;     Phase 4  OUT     source: 100% black (fire dies completely)
;     Phase 5  CATCH   source: 50% black, 25% RED,    25% ORANGE
;     Phase 6  BUILD   source: 25% black, 50% ORANGE, 25% RED
;     Phase 7  SURGE   source: 25% black, 25% BUFF,   50% YELLOW
;     (wraps back to Phase 0)
;
;   The cooling chain carries existing heat upward naturally:
;     BUFF -> YELLOW -> ORANGE -> RED -> BLACK
;   So as the source cools across phases 1-4, the top of the
;   fire fades from yellow/buff down to red and then vanishes.
;   As the source reheats across phases 5-7, the base brightens
;   first and the heat climbs back up over subsequent frames.
;
; Palette (authentic DOOM colours, no green):
;   BLACK  $80  background / off
;   RED    $BF  coolest visible flame
;   ORANGE $FF  mid flame
;   YELLOW $9F  hot
;   BUFF   $CF  white-hot (source, peak temperature)
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

PHASE_LEN       EQU     64      ; frames per phase
NUM_PHASES      EQU     8       ; total phases in cycle

; ============================================================
; ENTRY
; ============================================================
START:
        DI

        ; Enter MODE(0)
        XOR     A
        LD      ($6800),A

        ; Clear all 512 VRAM bytes to BLACK_BLOCK
        LD      HL,VRAM
        LD      A,BLACK_BLOCK
        LD      (HL),A
        LD      DE,VRAM+1
        LD      BC,512-1
        LDIR

        ; Initialise temperature cycle: phase 0, full countdown
        XOR     A
        LD      (TPHASE),A
        LD      A,PHASE_LEN
        LD      (TCNT),A

; ============================================================
; MAIN LOOP
; ============================================================
MAIN_LOOP:
        CALL    UPDATE_TEMP
        CALL    FILL_SOURCE
        CALL    PROPAGATE
;        CALL    FRAME_DELAY
        JP      MAIN_LOOP

; ============================================================
; UPDATE_TEMP
; Called once per frame. Decrements TCNT. When it reaches
; zero it advances TPHASE and reloads TCNT with PHASE_LEN.
;
; Clobbers A only.
; ============================================================
UPDATE_TEMP:
        LD      A,(TCNT)
        DEC     A
        LD      (TCNT),A
        JP      NZ,UT_DONE

        ; Reload countdown
        LD      A,PHASE_LEN
        LD      (TCNT),A

        ; Advance phase, wrap at NUM_PHASES
        LD      A,(TPHASE)
        INC     A
        CP      NUM_PHASES
        JP      NZ,UT_SETPHASE
        XOR     A               ; wrap back to 0
UT_SETPHASE:
        LD      (TPHASE),A
UT_DONE:
        RET

; ============================================================
; FILL_SOURCE
; Seeds the bottom row (row 15) according to current TPHASE.
;
; Uses RND8 & 3 (4 equally likely values 0..3) to pick a
; colour for each cell.  The mapping changes per phase:
;
;   Phase 0  PEAK    0->BLK  1,2->BUFF    3->YELLOW
;   Phase 1  YELLOW  0->BLK  1->BUFF   2,3->YELLOW
;   Phase 2  ORANGE  0->BLK  1->YELLOW 2,3->ORANGE
;   Phase 3  RED     0,1->BLK  2->ORANGE  3->RED
;   Phase 4  OUT     all->BLACK
;   Phase 5  CATCH   0,1->BLK  2->RED     3->ORANGE
;   Phase 6  BUILD   0->BLK  1->RED    2,3->ORANGE
;   Phase 7  SURGE   0->BLK  1->ORANGE 2,3->YELLOW
;   (then phase 0 again)
; ============================================================
FILL_SOURCE:
        LD      HL,VRAM+15*WIDTH
        LD      A,WIDTH
        LD      (FSCNT),A

FS_LOOP:
        CALL    RND8
        AND     3
        LD      (FRAND),A       ; save random 0..3

        ; Dispatch on TPHASE
        LD      A,(TPHASE)
        CP      0
        JP      Z,FS_PHASE0
        CP      1
        JP      Z,FS_PHASE1
        CP      2
        JP      Z,FS_PHASE2
        CP      3
        JP      Z,FS_PHASE3
        CP      4
        JP      Z,FS_PHASE4
        CP      5
        JP      Z,FS_PHASE5
        CP      6
        JP      Z,FS_PHASE6
        ; fall through to phase 7

; Phase 7 SURGE: 0->BLK  1->ORANGE  2,3->YELLOW
FS_PHASE7:
        LD      A,(FRAND)
        CP      0
        JP      Z,FS_BLK
        CP      1
        JP      Z,FS_ORANGE
        LD      A,YELLOW_BLOCK
        JP      FS_STORE

; Phase 0 PEAK: 0->BLK  1,2->BUFF  3->YELLOW
FS_PHASE0:
        LD      A,(FRAND)
        CP      0
        JP      Z,FS_BLK
        CP      3
        JP      Z,FS_YELLOW
        LD      A,BUFF_BLOCK
        JP      FS_STORE

; Phase 1 YELLOW: 0->BLK  1->BUFF  2,3->YELLOW
FS_PHASE1:
        LD      A,(FRAND)
        CP      0
        JP      Z,FS_BLK
        CP      1
        JP      Z,FS_BUFF
        LD      A,YELLOW_BLOCK
        JP      FS_STORE

; Phase 2 ORANGE: 0->BLK  1->YELLOW  2,3->ORANGE
FS_PHASE2:
        LD      A,(FRAND)
        CP      0
        JP      Z,FS_BLK
        CP      1
        JP      Z,FS_YELLOW
        LD      A,ORANGE_BLOCK
        JP      FS_STORE

; Phase 3 RED: 0,1->BLK  2->ORANGE  3->RED
FS_PHASE3:
        LD      A,(FRAND)
        CP      2
        JP      Z,FS_ORANGE
        CP      3
        JP      Z,FS_RED
        LD      A,BLACK_BLOCK   ; 0 or 1 -> black (mostly dark)
        JP      FS_STORE

; Phase 4 OUT: all black
FS_PHASE4:
        LD      A,BLACK_BLOCK
        JP      FS_STORE

; Phase 5 CATCH: 0,1->BLK  2->RED  3->ORANGE
FS_PHASE5:
        LD      A,(FRAND)
        CP      2
        JP      Z,FS_RED
        CP      3
        JP      Z,FS_ORANGE
        LD      A,BLACK_BLOCK   ; 0 or 1 -> black
        JP      FS_STORE

; Phase 6 BUILD: 0->BLK  1->RED  2,3->ORANGE
FS_PHASE6:
        LD      A,(FRAND)
        CP      0
        JP      Z,FS_BLK
        CP      1
        JP      Z,FS_RED
        LD      A,ORANGE_BLOCK
        JP      FS_STORE

FS_BLK:
        LD      A,BLACK_BLOCK
        JP      FS_STORE
FS_BUFF:
        LD      A,BUFF_BLOCK
        JP      FS_STORE
FS_YELLOW:
        LD      A,YELLOW_BLOCK
        JP      FS_STORE
FS_ORANGE:
        LD      A,ORANGE_BLOCK
        JP      FS_STORE
FS_RED:
        LD      A,RED_BLOCK

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
; optionally cool one step, write with random +-1 col drift.
; Unchanged from df1_flicker.asm -- the temperature shift is
; entirely in FILL_SOURCE; old heat dissipates naturally.
;
;   HL = destination (rows 0..14, starts VRAM)
;   DE = source      (rows 1..15, starts VRAM+WIDTH)
;   BC = cells remaining (15*32 = 480)
;   COL = current column 0..31
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

        ; Cool one step: BUFF->YELLOW->ORANGE->RED->BLACK
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
        ; Symmetric random drift: 0->L  1,3->C  2->R
        CALL    RND8
        AND     3
        CP      0
        JP      Z,TRY_LEFT
        CP      2
        JP      Z,TRY_RIGHT

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
; RND8 -- returns pseudo-random byte in A, clobbers A only.
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
FRAND:          DB      0       ; saved RND8 result in FILL_SOURCE
TPHASE:         DB      0       ; current temperature phase 0..7
TCNT:           DB      PHASE_LEN ; frame countdown to next phase

        END

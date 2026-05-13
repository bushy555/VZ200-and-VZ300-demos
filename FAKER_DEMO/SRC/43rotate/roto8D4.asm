; ============================================================================
; VZ200/VZ300 – STRICT PASMO Roto-Zoomer (MODE(0), 32×16 lo-res blocks)
; Smooth zoom:
;   • Half-step scale table (Scale2TabSmooth) eliminates the “jump” at min zoom.
;   • Steps computed as  S = ((A * Scale2) >> 1) * 3  (fine 0.5 increments).
; Fix for your rules:
;   • Replaced illegal LD E,(nn) with LD A,(nn) / LD E,A (A-for-Absolute).
; Rules: ORG $8000; SP $F000; JP only; A-for-Absolute; legal 16-bit (nn) moves;
;        (HL)/(IX+d)/(IY+d) OK; all DB/DW at END; MODE(0) VRAM $7000–$71FF.
; ============================================================================

            ORG     $8000

IO_LATCH    EQU     $6800
VRAM_BASE   EQU     $7000
STACK_TOP   EQU     $F000

; Solid MODE(0) graphics characters (visible)
;YELLOW_FULL EQU     159;158; 159; 145 
;RED_FULL    EQU     191;190; 191; 177

YELLOW_FULL EQU     159+16;158; 159; 145 
RED_FULL    EQU     191+16+16;190; 191; 177

; ----------------------------------------------------------------------------
; Entry
; ----------------------------------------------------------------------------
START
            DI
            LD      SP,STACK_TOP

            ; Enter MODE(0)
            XOR     A
            LD      (IO_LATCH),A

            ; Clear to spaces (0x20)
            CALL    ClearScreenM0

            ; Init animation parameters
            XOR     A
            LD      (Angle),A
            LD      (ZoomPh),A

; ----------------------------------------------------------------------------
; Main loop
; ----------------------------------------------------------------------------
MainLoop
            ; angle = (angle + 1) & 63
            LD      A,(Angle)
            ADD     A,1
            AND     63
            LD      (Angle),A

            ; zoom phase = (zoom + 1) & 63
            LD      A,(ZoomPh)
            ADD     A,1
            AND     63
            LD      (ZoomPh),A

            ; ---- Build transform ----
            ; sin = Sin64S[ang]
            LD      A,(Angle)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin64S
            ADD     HL,DE
            LD      A,(HL)
            LD      (SinVal),A

            ; cos = Sin64S[(ang+16)&63]
            LD      A,(Angle)
            ADD     A,16
            AND     63
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Sin64S
            ADD     HL,DE
            LD      A,(HL)
            LD      (CosVal),A

            ; Scale2 = Scale2TabSmooth[zoom]  (values 2..12; used with >>1 for 0.5 steps)
            LD      A,(ZoomPh)
            LD      E,A
            XOR     A
            LD      D,A
            LD      HL,Scale2TabSmooth
            ADD     HL,DE
            LD      A,(HL)            ; A = Scale2 (2..12)
            LD      (Scale2Cur),A

            ; ---- SxV = ((sin * Scale2) >> 1) * 3  ----
            LD      A,(SinVal)
            LD      A,(Scale2Cur)     ; A-for-Absolute: fetch to A first
            LD      E,A               ; E = Scale2
            LD      A,(SinVal)        ; restore multiplicand into A
            CALL    MulA_by_scale     ; HL = sin * Scale2
            CALL    SarHL_1           ; HL = (..)/2  (0.5 step resolution)
            CALL    MulHL_By3         ; HL *= 3
            LD      (SxV),HL

            ; ---- SxU = ((cos * Scale2) >> 1) * 3  ----
            LD      A,(CosVal)
            LD      A,(Scale2Cur)     ; A-for-Absolute
            LD      E,A               ; E = Scale2
            LD      A,(CosVal)        ; restore multiplicand into A
            CALL    MulA_by_scale     ; HL = cos * Scale2
            CALL    SarHL_1
            CALL    MulHL_By3
            LD      (SxU),HL

            ; SyU = -SxV
            LD      HL,(SxV)
            CALL    NegHL
            LD      (SyU),HL

            ; SyV = SxU
            LD      HL,(SxU)
            LD      (SyV),HL

            ; Uoff = -(16*SxU + 8*SyU)
            LD      HL,(SxU)
            CALL    Shl16_4
            LD      (TMP1),HL
            LD      HL,(SyU)
            CALL    Shl16_3
            LD      (TMP2),HL
            LD      HL,(TMP1)
            LD      DE,(TMP2)
            ADD     HL,DE
            CALL    NegHL
            LD      (Uoff),HL

            ; Voff = -(16*SxV + 8*SyV)
            LD      HL,(SxV)
            CALL    Shl16_4
            LD      (TMP1),HL
            LD      HL,(SyV)
            CALL    Shl16_3
            LD      (TMP2),HL
            LD      HL,(TMP1)
            LD      DE,(TMP2)
            ADD     HL,DE
            CALL    NegHL
            LD      (Voff),HL

            ; Seed row accumulators
            LD      HL,(Uoff)
            LD      (Urow),HL
            LD      HL,(Voff)
            LD      (Vrow),HL

            ; ---- Render frame: 16 rows × 32 bytes ----
            XOR     A
            LD      (RowY),A
            LD      HL,VRAM_BASE
            LD      (Dest),HL

RowLoop
            LD      A,(RowY)
            CP      16
            JP      NC,FrameDone

            ; VRAM pointer for this row
            LD      HL,(Dest)

            ; U,V starters for this row
            LD      DE,(Urow)         ; U in DE (signed)
            LD      BC,(Vrow)         ; V in BC (signed)

            ; X across row: 32 cells (1 byte each)
            XOR     A
            LD      (ColX),A

ColLoop
            LD      A,(ColX)
            CP      32
            JP      NC,RowDone

            ; Checker: bit 2 of (U_hi XOR V_hi)
            LD      A,D
            XOR     B
            AND     4
            JP      Z,CellYellow

CellRed
            LD      A,RED_FULL
            JP      StoreCell

CellYellow
            LD      A,YELLOW_FULL

StoreCell
            LD      (HL),A
            INC     HL

            ; Step U,V across X: U += SxU ; V += SxV
            CALL    AddU_SxU
            CALL    AddV_SxV

            ; Next column
            LD      A,(ColX)
            ADD     A,1
            LD      (ColX),A
            JP      ColLoop

RowDone
            ; Save next-row start address (HL already +32 after 32 cells)
            LD      (Dest),HL

            ; Advance row accumulators: Urow += SyU ; Vrow += SyV
            LD      HL,(Urow)
            LD      DE,(SyU)
            ADD     HL,DE
            LD      (Urow),HL

            LD      HL,(Vrow)
            LD      DE,(SyV)
            ADD     HL,DE
            LD      (Vrow),HL

            ; y++
            LD      A,(RowY)
            ADD     A,1
            LD      (RowY),A
            JP      RowLoop

FrameDone
            ; Small delay
            LD      BC,$0600
DelayLoop
            DEC     BC
            LD      A,B
            OR      C
            JP      NZ,DelayLoop

            JP      MainLoop

; ----------------------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------------------

; Clear MODE(0) screen ($7000-$71FF) to spaces (0x20) using row replication
ClearScreenM0
            LD      HL,RowClr32_M0
            LD      DE,$7000
            LD      BC,32
            LDIR
            LD      HL,$7000
            LD      DE,$7020
            LD      A,15              ; copy 15 more rows (total 16)
            LD      (RowRep),A
CS0_Loop
            LD      A,(RowRep)
            OR      A
            JP      Z,CS0_Done
            LD      BC,32
            LDIR
            LD      A,(RowRep)
            SUB     1
            LD      (RowRep),A
            JP      CS0_Loop
CS0_Done
            RET

; HL <<= 4
Shl16_4
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            RET

; HL <<= 3
Shl16_3
            ADD     HL,HL
            ADD     HL,HL
            ADD     HL,HL
            RET

; HL := -HL
NegHL
            LD      A,L
            CPL
            LD      L,A
            LD      A,H
            CPL
            LD      H,A
            INC     HL
            RET

; HL := arithmetic shift right by 1 (÷2, sign-preserving)
SarHL_1
            SRA     H
            RR      L
            RET

; Multiply HL by 3 (HL := HL*3) — uses BC as temp
MulHL_By3
            LD      B,H
            LD      C,L
            ADD     HL,HL
            ADD     HL,BC
            RET

; Signed multiply: (A signed) * (E unsigned 1..255) -> HL signed 16-bit
; (Used here with E = Scale2 in range 2..12.)
MulA_by_scale
            ; Save sign flag in MulSign (0=+,1=-) and take |A| into C
            LD      C,A
            XOR     A
            LD      (MulSign),A       ; assume +
            LD      A,C
            BIT     7,A
            JP      Z,MS_Pos
            LD      A,1
            LD      (MulSign),A
            LD      A,C
            XOR     $FF
            ADD     A,1               ; A = |original A|
MS_Pos
            LD      C,A               ; C = |A|
            LD      B,E               ; B = multiplier (2..12)

            LD      H,0
            LD      L,0               ; HL = 0

MS_Loop
            LD      A,B
            OR      A
            JP      Z,MS_DoneAdd
            LD      D,0
            LD      E,C
            ADD     HL,DE
            LD      A,B
            SUB     1
            LD      B,A
            JP      MS_Loop

MS_DoneAdd
            LD      A,(MulSign)
            OR      A
            JP      Z,MS_Exit
            CALL    NegHL
MS_Exit
            RET

; U(DE) += SxU
AddU_SxU
            PUSH    HL
            LD      HL,(SxU)
            LD      A,L
            ADD     A,E
            LD      E,A
            LD      A,H
            ADC     A,D
            LD      D,A
            POP     HL
            RET

; V(BC) += SxV
AddV_SxV
            PUSH    HL
            LD      HL,(SxV)
            LD      A,L
            ADD     A,C
            LD      C,A
            LD      A,H
            ADC     A,B
            LD      B,A
            POP     HL
            RET

; ============================================================================
; ============================== DATA SECTION ================================
; ============================================================================

; Animation state
Angle       DB      0
ZoomPh      DB      0

; Trig/scale temps
SinVal      DB      0
CosVal      DB      0
MulSign     DB      0
Scale2Cur   DB      0

; Transform components (signed 16-bit)
SxU         DW      0
SxV         DW      0
SyU         DW      0
SyV         DW      0

; Offsets and per-row accumulators
Uoff        DW      0
Voff        DW      0
Urow        DW      0
Vrow        DW      0

; Row/column and pointer
RowY        DB      0
ColX        DB      0
Dest        DW      0
RowRep      DB      0

; Temps
TMP1        DW      0
TMP2        DW      0

; 32 bytes of spaces (0x20) for MODE(0) clear
RowClr32_M0
            DB $20,$20,$20,$20,$20,$20,$20,$20
            DB $20,$20,$20,$20,$20,$20,$20,$20
            DB $20,$20,$20,$20,$20,$20,$20,$20
            DB $20,$20,$20,$20,$20,$20,$20,$20

; Signed sine 64 steps: -32..31. cos(a)=Sin64S[(a+16)&63]
Sin64S
            DB   0,  3,  6,  9, 12, 15, 17, 20
            DB  22, 24, 26, 28, 29, 30, 31, 31
            DB  32, 31, 31, 30, 29, 28, 26, 24
            DB  22, 20, 17, 15, 12,  9,  6,  3
            DB   0, -3, -6, -9,-12,-15,-17,-20
            DB -22,-24,-26,-28,-29,-30,-31,-31
            DB -32,-31,-31,-30,-29,-28,-26,-24
            DB -22,-20,-17,-15,-12, -9, -6, -3

; Smooth 64-step Scale2 table (values ~2..12 for smooth min/max turnarounds)
Scale2TabSmooth
            DB 2,2,2,3,3,3,4,4
            DB 5,5,6,6,7,7,8,8
            DB 9,9,10,10,11,11,12,12
            DB 12,12,12,11,11,10,10,9
            DB 9,8,8,7,7,6,6,5
            DB 5,4,4,3,3,3,2,2
            DB 2,2,3,3,4,4,5,5
            DB 6,6,7,7,8,8,9,9

            END

        ORG $8000

; ============================================================
; CONSTANTS (EQU does not emit bytes)
; ============================================================
VRAM_BASE       EQU $7000
IO_LATCH        EQU $6800
STACK_TOP       EQU $F000

; ============================================================
; ENTRY / SETUP
; ============================================================
START
        DI
        LD SP,STACK_TOP

        ; Enter MODE(1)
        LD A,8
        LD (IO_LATCH),A

        ; Clear screen to $00 (all green/buff)
        CALL ClearScreenM1

        ; Init animation state (de-correlate p1/p2)
        XOR A
        LD (Frame),A
        LD (T1),A              ; T1 = 0
        LD A,64
        LD (T2),A              ; T2 = 64

; ============================================================
; MAIN LOOP
; ============================================================
MainLoop
        ; ---- Frame++ ----
        LD A,(Frame)
        ADD A,1
        LD (Frame),A

        ; ---- T1 += T1_Speed ----
        LD A,(T1_Speed)        ; A = speed1
        LD C,A                  ; C = speed1
        LD A,(T1)               ; A = T1
        ADD A,C
        LD (T1),A

        ; ---- T2 += T2_Speed ----
        LD A,(T2_Speed)        ; A = speed2
        LD C,A
        LD A,(T2)
        ADD A,C
        LD (T2),A

        ; ---- Row bases from T1/T2 ----
        LD A,(T1)
        LD (RowPhase1),A
        LD A,(T2)
        LD (RowPhase2),A

        ; y = 0..63
        XOR A
        LD (Yindex),A
        LD A,64
        LD (Y_Rem),A

RowLoop
        LD A,(Y_Rem)
        OR A
        JP Z,FrameDone

        ; ----- Resolve VRAM row destination into VRDest_L/H -----
        LD A,(Yindex)
        LD E,A
        XOR A
        LD D,A
        LD HL,RowTable_Mode1
        ADD HL,DE               ; HL += y
        ADD HL,DE               ; HL += y  (2 bytes/entry)
        LD A,(HL)
        LD (VRDest_L),A
        INC HL
        LD A,(HL)
        LD (VRDest_H),A

        ; ----- Prepare per-row phases -----
        LD A,(RowPhase1)
        LD D,A                  ; D = p1
        LD A,(RowPhase2)
        LD E,A                  ; E = p2

        ; ----- Build RowBuf[32] : 4 pixels per byte -----
        LD HL,RowBuf            ; HL = write ptr into RowBuf
        LD A,32
        LD (XBytes_Rem),A

ByteLoop
        LD A,(XBytes_Rem)
        OR A
        JP Z,RowReady

        ; B = accumulator for this output byte (4×2bpp)
        XOR A
        LD B,A

        ; --------------- Pixel 0 ---------------
        ; a2 = (p1>>6)&3
        LD A,D
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD (TmpA),A

        ; b2 = ((p2+17)>>6)&3
        LD A,E
        ADD A,17
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD C,A                  ; C = b2

        ; color0 = a2 ^ b2
        LD A,(TmpA)
        XOR C
        AND 3
        LD C,A                  ; C = color0

        ; acc = (acc<<2) | color0
        LD A,B
        ADD A,A
        ADD A,A
        OR C
        LD B,A

        ; advance phases by DX1/DX2
        LD A,(DX1)
        LD C,A
        LD A,D
        ADD A,C
        LD D,A

        LD A,(DX2)
        LD C,A
        LD A,E
        ADD A,C
        LD E,A

        ; --------------- Pixel 1 ---------------
        LD A,D
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD (TmpA),A

        LD A,E
        ADD A,17
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD C,A

        LD A,(TmpA)
        XOR C
        AND 3
        LD C,A

        LD A,B
        ADD A,A
        ADD A,A
        OR C
        LD B,A

        LD A,(DX1)
        LD C,A
        LD A,D
        ADD A,C
        LD D,A

        LD A,(DX2)
        LD C,A
        LD A,E
        ADD A,C
        LD E,A

        ; --------------- Pixel 2 ---------------
        LD A,D
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD (TmpA),A

        LD A,E
        ADD A,17
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD C,A

        LD A,(TmpA)
        XOR C
        AND 3
        LD C,A

        LD A,B
        ADD A,A
        ADD A,A
        OR C
        LD B,A

        LD A,(DX1)
        LD C,A
        LD A,D
        ADD A,C
        LD D,A

        LD A,(DX2)
        LD C,A
        LD A,E
        ADD A,C
        LD E,A

        ; --------------- Pixel 3 ---------------
        LD A,D
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD (TmpA),A

        LD A,E
        ADD A,17
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        SRL A
        AND 3
        LD C,A

        LD A,(TmpA)
        XOR C
        AND 3
        LD C,A

        LD A,B
        ADD A,A
        ADD A,A
        OR C
        LD B,A                  ; final packed byte

        ; write to RowBuf
        LD A,B
        LD (HL),A
        INC HL

        ; next byte
        LD A,(XBytes_Rem)
        SUB 1
        LD (XBytes_Rem),A
        JP ByteLoop

RowReady
        ; ----- Copy RowBuf -> VRAM row with LDIR -----
        LD HL,RowBuf
        LD A,(VRDest_L)
        LD E,A
        LD A,(VRDest_H)
        LD D,A
        LD BC,32
        LDIR

        ; ----- Next scanline phases: RowPhase += DY -----
        ; RowPhase1 += DY1
        LD A,(DY1)
        LD C,A
        LD A,(RowPhase1)
        ADD A,C
        LD (RowPhase1),A

        ; RowPhase2 += DY2
        LD A,(DY2)
        LD C,A
        LD A,(RowPhase2)
        ADD A,C
        LD (RowPhase2),A

        ; y++ and loop
        LD A,(Yindex)
        ADD A,1
        LD (Yindex),A

        LD A,(Y_Rem)
        SUB 1
        LD (Y_Rem),A
        JP RowLoop

FrameDone
        JP MainLoop


; ============================================================
; ClearScreenM1
; Seed row 0 with $00 then replicate to all 64 rows (63 copies).
; ============================================================
ClearScreenM1
        ; Seed first row
        LD HL,RowClr32_00
        LD DE,$7000
        LD BC,32
        LDIR

        ; Replicate rows (63 times)
        LD HL,$7000
        LD DE,$7020
        LD A,63
        LD (RowCopyRem),A
CSM1_Loop
        LD A,(RowCopyRem)
        OR A
        JP Z,CSM1_Done
        LD BC,32
        LDIR
        LD A,(RowCopyRem)
        SUB 1
        LD (RowCopyRem),A
        JP CSM1_Loop
CSM1_Done
        RET

; ============================================================
; ========================= DATA SECTION =====================
; ============================================================

; Animation state
Frame       DEFB 0
T1          DEFB 0
T2          DEFB 64

T1_Speed    DEFB 1      ; try 1..3
T2_Speed    DEFB 2

; Stripe field deltas (small, relatively prime ? rich moiré)
DX1         DEFB 5      ; X step for phase 1
DY1         DEFB 3      ; Y step for phase 1
DX2         DEFB 7      ; X step for phase 2
DY2         DEFB 4      ; Y step for phase 2

; Per-row phase bases
RowPhase1   DEFB 0
RowPhase2   DEFB 0

; Loop / helpers
Yindex      DEFB 0
Y_Rem       DEFB 0
XBytes_Rem  DEFB 0
RowCopyRem  DEFB 0

; VRAM dest (byte form; always via A)
VRDest_L    DEFB 0
VRDest_H    DEFB 0

; Row buffer and temps
RowBuf      DEFS 32
TmpA        DEFB 0

; 32 bytes of $00 (MODE1 all-green/buff pixels) for clear
RowClr32_00
        DEFB $00,$00,$00,$00,$00,$00,$00,$00
        DEFB $00,$00,$00,$00,$00,$00,$00,$00
        DEFB $00,$00,$00,$00,$00,$00,$00,$00
        DEFB $00,$00,$00,$00,$00,$00,$00,$00

; MODE(1) row base addresses (64 rows × 32 bytes)
RowTable_Mode1
        DW $7000,$7020,$7040,$7060,$7080,$70A0,$70C0,$70E0
        DW $7100,$7120,$7140,$7160,$7180,$71A0,$71C0,$71E0
        DW $7200,$7220,$7240,$7260,$7280,$72A0,$72C0,$72E0
        DW $7300,$7320,$7340,$7360,$7380,$73A0,$73C0,$73E0
        DW $7400,$7420,$7440,$7460,$7480,$74A0,$74C0,$74E0
        DW $7500,$7520,$7540,$7560,$7580,$75A0,$75C0,$75E0
        DW $7600,$7620,$7640,$7660,$7680,$76A0,$76C0,$76E0
        DW $7700,$7720,$7740,$7760,$7780,$77A0,$77C0,$77E0

        END

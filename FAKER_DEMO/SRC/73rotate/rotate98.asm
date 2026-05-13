
; c100_speed_origin_LUT_step3.asm
; VZ200/300 MODE(1) 128x64 rotating Sierpinski — origin (0,0), faster.
; - Direct VRAM render, JP-only control.
; - Truncate >>6 table quantisation with running DE pointers.
; - Negative-Y skip BEFORE y masking (top can go off-screen).
; - Branchless mask LUT per byte (PASMO-friendly hex).
; - Step 3: Register-only Xcos/Xsin fetch (no XcosTmp RAM).

        ORG     $8000

; --- Constants ---
VRAM            EQU     $7000
ROWS            EQU     64
COLS            EQU     128
BYTES_PER_ROW   EQU     32        ; 128 px / 4 px per byte

; --- Entry ---
Start:
        LD      A,8                ; enter MODE(1)
        LD      ($6800),A
        CALL    ClearScreen        ; one-time clear (fast LDI routine)
        DI
        XOR     A
        LD      (Angle),A

MainLoop:
; --- Fetch sin/cos for Angle (scale = 64) ---
        LD      A,(Angle)
        LD      B,A
        LD      L,B
        LD      H,0
        ADD     HL,HL              ; idx * 2
        LD      DE,SIN_TABLE
        ADD     HL,DE
        LD      A,(HL)             ; sin
        LD      (SinVal),A
        INC     HL
        LD      A,(HL)             ; cos
        LD      (CosVal),A

; --- Build per-frame tables (prefix-sum; truncation >>6) ---
        CALL    BuildTables_Prefix_Signed_TR

; --- Frame render directly to VRAM ---
        XOR     A
        LD      (Row),A            ; Row = 0

RowLoop:
        LD      A,(Row)
        CP      ROWS
        JP      Z,AfterRows

; --- Y constants once per row (signed tables) ---
        ; YS = TabYsin[Row] -> E (signed)
        LD      HL,TabYsin
        LD      C,A
        LD      B,0
        ADD     HL,BC
        LD      E,(HL)

        ; YC = TabYcos[Row] -> D (signed)
        LD      HL,TabYcos
        LD      A,(Row)            ; reload Row
        LD      C,A
        LD      B,0
        ADD     HL,BC
        LD      D,(HL)

; --- Row base pointer HL = VRAM + Row*32 ---
        LD      A,(Row)
        LD      L,A
        LD      H,0
        ADD     HL,HL              ; *2
        ADD     HL,HL              ; *4
        ADD     HL,HL              ; *8
        ADD     HL,HL              ; *16
        ADD     HL,HL              ; *32
        LD      BC,VRAM
        ADD     HL,BC              ; HL = RowBase in VRAM

; --- Alternate set: X pointers + byte counter ---
        EXX
        LD      HL,TabXcos         ; HL' walks Xcos across row
        LD      DE,TabXsin         ; DE' walks Xsin across row
        LD      B,BYTES_PER_ROW    ; B' = 32 bytes
        EXX

ByteLoop:
        ; B (primary) = flags nibble (start 0)
        XOR     A
        LD      B,A

; ================= Pixel 0 (bit 0) =================
        EXX
        LD      C,(HL)             ; C' = Xcos_0
        LD      A,(DE)             ; A  = Xsin_0
        INC     HL
        INC     DE
        EXX

        ADD     A,D                ; y' = Xsin + YC
        BIT     7,A
        JP      NZ,P0_Done         ; skip if negative (off-screen)
        AND     3Fh                ; y
        LD      C,A                ; save y in C

        EXX
        LD      A,C                ; A <- Xcos_0 (from C')
        EXX
        SUB     E                  ; x' = Xcos - YS
        AND     7Fh                ; x
        AND     C                  ; x & y
        JP      NZ,P0_Done
        SET     0,B
P0_Done:

; ================= Pixel 1 (bit 1) =================
        EXX
        LD      C,(HL)             ; C' = Xcos_1
        LD      A,(DE)             ; A  = Xsin_1
        INC     HL
        INC     DE
        EXX

        ADD     A,D
        BIT     7,A
        JP      NZ,P1_Done
        AND     3Fh
        LD      C,A
        EXX
        LD      A,C                ; A <- Xcos_1
        EXX
        SUB     E
        AND     7Fh
        AND     C
        JP      NZ,P1_Done
        SET     1,B
P1_Done:

; ================= Pixel 2 (bit 2) =================
        EXX
        LD      C,(HL)             ; C' = Xcos_2
        LD      A,(DE)             ; A  = Xsin_2
        INC     HL
        INC     DE
        EXX

        ADD     A,D
        BIT     7,A
        JP      NZ,P2_Done
        AND     3Fh
        LD      C,A
        EXX
        LD      A,C                ; A <- Xcos_2
        EXX
        SUB     E
        AND     7Fh
        AND     C
        JP      NZ,P2_Done
        SET     2,B
P2_Done:

; ================= Pixel 3 (bit 3) =================
        EXX
        LD      C,(HL)             ; C' = Xcos_3
        LD      A,(DE)             ; A  = Xsin_3
        INC     HL
        INC     DE
        EXX

        ADD     A,D
        BIT     7,A
        JP      NZ,P3_Done
        AND     3Fh
        LD      C,A
        EXX
        LD      A,C                ; A <- Xcos_3
        EXX
        SUB     E
        AND     7Fh
        AND     C
        JP      NZ,P3_Done
        SET     3,B
P3_Done:

        ; ---- LUT fetch with proper BC = MaskLUT + nibble (carry-handled) ----
        LD      A,B                ; A = nibble (flags)
        LD      C,A                ; C = nibble
        LD      A,LOW MaskLUT
        ADD     A,C                ; adds nibble, sets carry if overflow
        LD      C,A                ; new low byte
        LD      B,HIGH MaskLUT     ; base high byte
        JP      NC,LUT_NoCarry
        INC     B                  ; carry into high byte
LUT_NoCarry:
        LD      A,(BC)             ; A = MaskLUT[nibble]

        ; ---- Write mask and advance ----
        LD      (HL),A
        INC     HL

        ; ---- Decrement byte counter B' (alt) and loop JP-only ----
        EXX
        DEC     B
        JP      NZ,ByteLoopCont
        EXX
        JP      NextRow

ByteLoopCont:
        EXX
        JP      ByteLoop

; --- Next row ---
NextRow:
        LD      A,(Row)
        INC     A
        LD      (Row),A
        JP      RowLoop

AfterRows:
; --- Animate angle ---
        LD      A,(Angle)
        INC     A
        LD      (Angle),A
        JP      MainLoop

; ----------------------------------------------------------------------
; ClearScreen: (your lengthier/faster LDI-based blocks preserved)
ClearScreen:
        LD HL,VRAM
        LD DE,VRAM+1
        LD BC,2048
        LD (HL),0
Copy64_loop0:
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
        jp pe, Copy64_loop0
        ret

        ld      hl, $7800          ; BLIT FROM $7800 Buffer to screen
        ld      de, $7000
        ld      bc, 2048
Copy2048_64LDI:
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
        jp pe, Copy64_loop1
        ret

        ld      hl, $9000          ; MODE(1) CLS BUFFER at $9000
        ld      de, $7800
        ld      bc, 2048
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
        jp pe, Copy64_loop2
        ret

; ----------------------------------------------------------------------
; BuildTables_Prefix_Signed_TR:
; Fill TabXcos/TabXsin (128) and TabYsin/TabYcos (64), all signed bytes.
; Seeds: origin (0,0); Quantise: signed >>6 truncate; running DE pointers.

BuildTables_Prefix_Signed_TR:
; --- Sign-extend cos into Cos16Hi:Cos16Lo ---
        LD      A,(CosVal)
        LD      (Cos16Lo),A
        BIT     7,A
        JP      Z,cos_pos
        LD      A,0FFh
        JP      cos_sx_done
cos_pos:
        XOR     A
cos_sx_done:
        LD      (Cos16Hi),A

; --- Sign-extend sin into Sin16Hi:Sin16Lo ---
        LD      A,(SinVal)
        LD      (Sin16Lo),A
        BIT     7,A
        JP      Z,sin_pos
        LD      A,0FFh
        JP      sin_sx_done
sin_pos:
        XOR     A
sin_sx_done:
        LD      (Sin16Hi),A

; ======================== TabXcos[128] ========================
        XOR     A
        LD      H,A
        LD      L,A                ; HL = 0
        LD      DE,TabXcos         ; running pointer
        LD      A,128
        LD      (XCount),A
BT_Xcos_Run:
        LD      A,(XCount)
        OR      A
        JP      Z,BT_Xsin_Start
        PUSH    HL
        ; >>6 (truncate): 6×(SRA H; RR L)
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        LD      A,L
        LD      (DE),A
        INC     DE
        POP     HL
        LD      A,(Cos16Lo)
        LD      C,A
        LD      A,(Cos16Hi)
        LD      B,A
        ADD     HL,BC
        LD      A,(XCount)
        DEC     A
        LD      (XCount),A
        JP      BT_Xcos_Run

; ======================== TabXsin[128] ========================
BT_Xsin_Start:
        XOR     A
        LD      H,A
        LD      L,A                ; HL = 0
        LD      DE,TabXsin
        LD      A,128
        LD      (XCount),A
BT_Xsin_Run:
        LD      A,(XCount)
        OR      A
        JP      Z,BT_Ysin_Start
        PUSH    HL
        ; >>6 (truncate)
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        LD      A,L
        LD      (DE),A
        INC     DE
        POP     HL
        LD      A,(Sin16Lo)
        LD      C,A
        LD      A,(Sin16Hi)
        LD      B,A
        ADD     HL,BC
        LD      A,(XCount)
        DEC     A
        LD      (XCount),A
        JP      BT_Xsin_Run

; ======================== TabYsin[64] =========================
BT_Ysin_Start:
        XOR     A
        LD      H,A
        LD      L,A                ; HL = 0
        LD      DE,TabYsin
        LD      A,64
        LD      (YCount),A
BT_Ysin_Run:
        LD      A,(YCount)
        OR      A
        JP      Z,BT_Ycos_Start
        PUSH    HL
        ; >>6 (truncate)
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        LD      A,L
        LD      (DE),A
        INC     DE
        POP     HL
        LD      A,(Sin16Lo)
        LD      C,A
        LD      A,(Sin16Hi)
        LD      B,A
        ADD     HL,BC
        LD      A,(YCount)
        DEC     A
        LD      (YCount),A
        JP      BT_Ysin_Run

; ======================== TabYcos[64] =========================
BT_Ycos_Start:
        XOR     A
        LD      H,A
        LD      L,A                ; HL = 0
        LD      DE,TabYcos
        LD      A,64
        LD      (YCount),A
BT_Ycos_Run:
        LD      A,(YCount)
        OR      A
        JP      Z,BT_Done
        PUSH    HL
        ; >>6 (truncate)
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        SRA     H
        RR      L
        LD      A,L
        LD      (DE),A
        INC     DE
        POP     HL
        LD      A,(Cos16Lo)
        LD      C,A
        LD      A,(Cos16Hi)
        LD      B,A
        ADD     HL,BC
        LD      A,(YCount)
        DEC     A
        LD      (YCount),A
        JP      BT_Ycos_Run

BT_Done:
        RET

; --- State ---
Angle   DB      0
SinVal  DB      0
CosVal  DB      0
Row     DB      0

; --- Tables (signed) ---
TabXcos DEFS    128
TabXsin DEFS    128
TabYsin DEFS    64
TabYcos DEFS    64

; --- BuildTables helpers ---
XCount  DB      0
YCount  DB      0
Cos16Lo DB      0
Cos16Hi DB      0
Sin16Lo DB      0
Sin16Hi DB      0

; --- Mask LUT: index = flags nibble (bit0..bit3 => pixels 0..3) ---
; PASMO-friendly hex (leading zeros):
; mask = (f0?C0h:0) | (f1?30h:0) | (f2?0Ch:0) | (f3?03h:0)
MaskLUT:
        DB 000h, 0C0h, 030h, 0F0h, 00Ch, 0CCh, 03Ch, 0FCh
        DB 003h, 0C3h, 033h, 0F3h, 00Fh, 0CFh, 03Fh, 0FFh

; --- SIN_TABLE: (sin,cos) pairs, scale=64, signed; 256 entries ---
SIN_TABLE:
        DB 0,64
        DB 2,64
        DB 3,64
        DB 5,64
        DB 6,64
        DB 8,64
        DB 9,63
        DB 11,63
        DB 12,63
        DB 14,62
        DB 16,62
        DB 17,62
        DB 19,61
        DB 20,61
        DB 22,60
        DB 23,60
        DB 24,59
        DB 26,59
        DB 27,58
        DB 29,57
        DB 30,56
        DB 32,56
        DB 33,55
        DB 34,54
        DB 36,53
        DB 37,52
        DB 38,51
        DB 39,50
        DB 41,49
        DB 42,48
        DB 43,47
        DB 44,46
        DB 45,45
        DB 46,44
        DB 47,43
        DB 48,42
        DB 49,41
        DB 50,39
        DB 51,38
        DB 52,37
        DB 53,36
        DB 54,34
        DB 55,33
        DB 56,32
        DB 56,30
        DB 57,29
        DB 58,27
        DB 59,26
        DB 59,24
        DB 60,23
        DB 60,22
        DB 61,20
        DB 61,19
        DB 62,17
        DB 62,16
        DB 62,14
        DB 63,12
        DB 63,11
        DB 63,9
        DB 64,8
        DB 64,6
        DB 64,5
        DB 64,3
        DB 64,2
        DB 64,0
        DB 64,254
        DB 64,253
        DB 64,251
        DB 64,250
        DB 64,248
        DB 63,247
        DB 63,245
        DB 63,244
        DB 62,242
        DB 62,240
        DB 62,239
        DB 61,237
        DB 61,236
        DB 60,234
        DB 60,233
        DB 59,232
        DB 59,230
        DB 58,229
        DB 57,227
        DB 56,226
        DB 56,224
        DB 55,223
        DB 54,222
        DB 53,220
        DB 52,219
        DB 51,218
        DB 50,217
        DB 49,215
        DB 48,214
        DB 47,213
        DB 46,212
        DB 45,211
        DB 44,210
        DB 43,209
        DB 42,208
        DB 41,207
        DB 39,206
        DB 38,205
        DB 37,204
        DB 36,203
        DB 34,202
        DB 33,201
        DB 32,200
        DB 30,200
        DB 29,199
        DB 27,198
        DB 26,197
        DB 24,197
        DB 23,196
        DB 22,196
        DB 20,195
        DB 19,195
        DB 17,194
        DB 16,194
        DB 14,194
        DB 12,193
        DB 11,193
        DB 9,193
        DB 8,192
        DB 6,192
        DB 5,192
        DB 3,192
        DB 2,192
        DB 0,192
        DB 254,192
        DB 253,192
        DB 251,192
        DB 250,192
        DB 248,192
        DB 247,193
        DB 245,193
        DB 244,193
        DB 242,194
        DB 240,194
        DB 239,194
        DB 237,195
        DB 236,195
        DB 234,196
        DB 233,196
        DB 232,197
        DB 230,197
        DB 229,198
        DB 227,199
        DB 226,200
        DB 224,200
        DB 223,201
        DB 222,202
        DB 220,203
        DB 219,204
        DB 218,205
        DB 217,206
        DB 215,207
        DB 214,208
        DB 213,209
        DB 212,210
        DB 211,211
        DB 210,212
        DB 209,213
        DB 208,214
        DB 207,215
        DB 206,217
        DB 205,218
        DB 204,219
        DB 203,220
        DB 202,222
        DB 201,223
        DB 200,224
        DB 200,226
        DB 199,227
        DB 198,229
        DB 197,230
        DB 197,232
        DB 196,233
        DB 196,234
        DB 195,236
        DB 195,237
        DB 194,239
        DB 194,240
        DB 194,242
        DB 193,244
        DB 193,245
        DB 193,247
        DB 192,248
        DB 192,250
        DB 192,251
        DB 192,253
        DB 192,254
        DB 192,0
        DB 192,2
        DB 192,3
        DB 192,5
        DB 192,6
        DB 192,8
        DB 193,9
        DB 193,11
        DB 193,12
        DB 194,14
        DB 194,16
        DB 194,17
        DB 195,19
        DB 195,20
        DB 196,22
        DB 196,23
        DB 197,24
        DB 197,26
        DB 198,27
        DB 199,29
        DB 200,30
        DB 200,32
        DB 201,33
        DB 202,34
        DB 203,36
        DB 204,37
        DB 205,38
        DB 206,39
        DB 207,41
        DB 208,42
        DB 209,43
        DB 210,44
        DB 211,45
        DB 212,46
        DB 213,47
        DB 214,48
        DB 215,49
        DB 217,50
        DB 218,51
        DB 219,52
        DB 220,53
        DB 222,54
        DB 223,55
        DB 224,56
        DB 226,56
        DB 227,57
        DB 229,58
        DB 230,59
        DB 232,59
        DB 233,60
        DB 234,60
        DB 236,61
        DB 237,61
        DB 239,62
        DB 240,62
        DB 242,62
        DB 244,63
        DB 245,63
        DB 247,63
        DB 248,64
        DB 250,64
        DB 251,64
        DB 253,64
        DB 254,64

; --- End of program ---

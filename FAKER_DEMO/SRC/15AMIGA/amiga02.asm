; ==============================================================
; VZ200/VZ300 MODE(1) - AMIGA BOING BALL DEMO
;
; Red/white checkerboard ball bouncing over an Amiga-style
; perspective grid background.
;
; BACKGROUND (colour 2 = blue on green):
;   Back wall:  8 vertical lines at x=0,16..112, y=0..31
;   Horizon:    full horizontal line at y=32
;   Floor:      converging vertical lines from VP(64,32) to bottom
;               + perspective-spaced horizontal lines
;   All precomputed into 2KB BGBUF table.
;
; BALL:
;   Ellipse RX=30, RY=20 (compensates 2:3 pixel aspect).
;   Diagonal checker: (dx+dy+phase)>>2 bit0 selects red or bg.
;   Erases by copying BGBUF back to VRAM for the ball span.
;
; RULES: ORG $8000, JP-only, SP=$F000,
;   LD A,(nn)/LD (nn),A for byte vars, all DB/DEFS at END.
; ==============================================================

            ORG     $8000
            JP      Start

; --------------------- Constants ----------------------
VRAM        EQU     $7000
LATCH       EQU     $6800
RX          EQU     30          ; horiz radius (pixels)
RY          EQU     20          ; vert  radius (pixels) -- 30*2=60=20*3 units
WIDTAB_LEN  EQU     41          ; 2*RY + 1
X_MIN       EQU     RX
X_MAX       EQU     127-RX
Y_MIN       EQU     RY
Y_MAX       EQU     63-RY

; ===================== Start ==========================
Start:
            LD      A,8
            LD      (LATCH),A       ; MODE 1 graphics

	ld	hl, VRAM
	ld	(hl), 0
	ld	de, VRAM+1
	ld	bc, 2048
	ldir

	ld	hl, $9000
	ld	(hl), 0
	ld	de, $9000+1
	ld	bc, 2048
	ldir


            ; Copy precomputed background to VRAM
            LD      HL,BGBUF
            LD      DE,VRAM
            LD      BC,2048
            LDIR

            ; Initialise ball
            LD      A,64
            LD      (BX),A
            LD      A,38
            LD      (BY),A
            LD      A,2
            LD      (VX),A
            LD      A,2
            LD      (VY),A
            XOR     A
            LD      (PHASE),A

            ; Draw initial ball
            LD      A,1
            LD      (DRAWMODE),A
            CALL    DrawBall

	di

; ===================== MainLoop =======================
MainLoop:
            ; Erase ball (restore background)
            XOR     A
            LD      (DRAWMODE),A
            CALL    DrawBall

            ; Advance rotation phase
            LD      A,(PHASE)
            ADD     A,2
            LD      (PHASE),A

            ; Move ball
            LD      A,(BX)
            LD      B,A
            LD      A,(VX)
            ADD     A,B
            LD      (BX),A

            LD      A,(BY)
            LD      B,A
            LD      A,(VY)
            ADD     A,B
            LD      (BY),A

            ; Bounce X
            LD      A,(BX)
            CP      X_MIN
            JP      NC,BXhi
            LD      A,X_MIN
            LD      (BX),A
            LD      A,(VX)
            CPL
            INC     A
            LD      (VX),A
            JP      BXdone
BXhi:       CP      X_MAX+1
            JP      C,BXdone
            LD      A,X_MAX
            LD      (BX),A
            LD      A,(VX)
            CPL
            INC     A
            LD      (VX),A
BXdone:
            ; Bounce Y
            LD      A,(BY)
            CP      Y_MIN
            JP      NC,BYhi
            LD      A,Y_MIN
            LD      (BY),A
            LD      A,(VY)
            CPL
            INC     A
            LD      (VY),A
            JP      BYdone
BYhi:       CP      Y_MAX+1
            JP      C,BYdone
            LD      A,Y_MAX
            LD      (BY),A
            LD      A,(VY)
            CPL
            INC     A
            LD      (VY),A
BYdone:
            ; Draw ball at new position
            LD      A,1
            LD      (DRAWMODE),A
            CALL    DrawBall
	ld	hl, $9000
	ld	de, $7000
	ld	bc, 2048
	ldir

            JP      MainLoop

; ==============================================================
; GetRowBase: A=y -> HL = VRAM row base ($7000 + 32*y)
; ==============================================================
GetRowBase:
            LD      L,A
            LD      H,0
            ADD     HL,HL           ; HL = y*2
            LD      DE,YTAB
            ADD     HL,DE
            LD      E,(HL)
            INC     HL
            LD      D,(HL)
            EX      DE,HL
            RET

; ==============================================================
; GetBgRowBase: A=y -> HL = BGBUF row base (BGBUF + 32*y)
; ==============================================================
GetBgRowBase:
            LD      L,A
            LD      H,0
            ADD     HL,HL           ; HL = y*2
            LD      DE,BGTAB
            ADD     HL,DE
            LD      E,(HL)
            INC     HL
            LD      D,(HL)
            EX      DE,HL
            RET

; ==============================================================
; DrawBall
;   DRAWMODE=0: erase -- copy BGBUF span back to VRAM
;   DRAWMODE=1: draw  -- write checker pattern to VRAM
;
; For each of 41 rows through the ball:
;   Compute py, w (half-width), px_left, px_right, byte cols.
;   Erase: byte-by-byte copy from BGBUF to VRAM.
;   Draw:  compute checker parity, fill span with $FF/$00.
; ==============================================================
DrawBall:
            XOR     A
            LD      (WIDX),A

DB_Loop:
            LD      A,(WIDX)
            CP      WIDTAB_LEN
            JP      NZ,DB_Do
            RET

DB_Do:
            ; dy = WIDX - RY  (signed)
            SUB     RY
            LD      (DYTMP),A
            LD      B,A
            LD      A,(BY)
            ADD     A,B             ; py = BY + dy
            CP      64
            JP      NC,DB_Skip      ; out of screen
            LD      (PYTMP),A

            ; w = WIDTHTAB[WIDX]
            LD      A,(WIDX)
            LD      E,A
            LD      D,0
            LD      HL,WIDTHTAB
            ADD     HL,DE
            LD      A,(HL)
            LD      (WTMP),A

            ; px_left = max(BX-w, 0)
            LD      B,A
            LD      A,(BX)
            SUB     B
            JP      NC,DB_LOK
            XOR     A
DB_LOK:     LD      (PXLEFT),A

            ; px_right = min(BX+w, 127)
            LD      A,(BX)
            LD      B,A
            LD      A,(WTMP)
            ADD     A,B
            CP      128
            JP      C,DB_ROK
            LD      A,127
DB_ROK:     LD      (PXRIGHT),A

            ; byte columns
            LD      A,(PXLEFT)
            SRL     A
            SRL     A
            LD      (BCOLLEFT),A
            LD      A,(PXRIGHT)
            SRL     A
            SRL     A
            LD      (BCOLRIGHT),A

            LD      A,(DRAWMODE)
            OR      A
            JP      NZ,DB_DrawSpan

            ; ---- ERASE: copy BGBUF row span to VRAM ----
            ; Step 1: compute VRAM dest = VRAM_row_base + bcolleft -> save to VTMP
            LD      A,(PYTMP)
            CALL    GetRowBase      ; HL = $7000 + 32*py
            LD      A,(BCOLLEFT)
            ADD     A,L
            LD      (VTMP),A        ; VTMP lo
            LD      A,H
            ADC     A,0
            LD      (VTMP+1),A      ; VTMP hi

            ; Step 2: HL = BGBUF source = BGBUF_row_base + bcolleft
            LD      A,(PYTMP)
            CALL    GetBgRowBase    ; HL = BGBUF + 32*py
            LD      A,(BCOLLEFT)
            ADD     A,L
            LD      L,A
            LD      A,H
            ADC     A,0
            LD      H,A             ; HL = BGBUF source

            ; Step 3: DE = VRAM dest from VTMP
            LD      A,(VTMP)
            LD      E,A
            LD      A,(VTMP+1)
            LD      D,A

            ; Step 4: B = byte count = bcolright - bcolleft + 1
            LD      A,(BCOLRIGHT)
            LD      C,A
            LD      A,(BCOLLEFT)
            LD      B,A
            LD      A,C
            SUB     B               ; A = bcolright - bcolleft
            INC     A
            LD      B,A             ; B = byte count

DB_ELoop:   LD      A,(HL)
            LD      (DE),A
            INC     HL
            INC     DE
            DEC     B
            JP      NZ,DB_ELoop
            JP      DB_Skip

            ; ---- DRAW: checker pattern ----
DB_DrawSpan:
            ; Starting parity: bit2 of (phase + dy - w)
            LD      A,(PHASE)
            LD      B,A
            LD      A,(DYTMP)
            ADD     A,B
            LD      B,A
            LD      A,(WTMP)
            LD      C,A
            LD      A,B
            SUB     C               ; A = phase+dy-w
            AND     4
            JP      NZ,DB_SRed
            XOR     A
            LD      (CURCOL),A
            JP      DB_SSet
DB_SRed:    LD      A,$FF
            LD      (CURCOL),A
DB_SSet:
            ; VRAM pointer = row base + bcolleft
            LD      A,(PYTMP)
            CALL    GetRowBase      ; HL = VRAM row base
            LD      A,(BCOLLEFT)
            LD      E,A
            LD      D,0
            ADD     HL,DE
            LD      A,L
            LD      (VPTR),A
            LD      A,H
            LD      (VPTR+1),A

            ; Single byte span?
            LD      A,(BCOLLEFT)
            LD      B,A
            LD      A,(BCOLRIGHT)
            CP      B
            JP      NZ,DB_Multi
            CALL    DrawSingleByte
            JP      DB_Skip

DB_Multi:
            CALL    DrawLeftByte
            CALL    SwapCol

            ; Middle full bytes
            LD      A,(BCOLLEFT)
            INC     A
            LD      B,A             ; first middle col
            LD      A,(BCOLRIGHT)
            DEC     A               ; last middle col
            CP      B
            JP      C,DB_NoMid
            SUB     B
            INC     A
            LD      B,A             ; count
            LD      A,(VPTR)
            LD      L,A
            LD      A,(VPTR+1)
            LD      H,A
DB_MLoop:   LD      A,(CURCOL)
            LD      (HL),A
            INC     HL
            CALL    SwapCol
            DEC     B
            JP      NZ,DB_MLoop
            LD      A,L
            LD      (VPTR),A
            LD      A,H
            LD      (VPTR+1),A
DB_NoMid:
            CALL    DrawRightByte

DB_Skip:    LD      HL,WIDX
            INC     (HL)
            JP      DB_Loop

; ==============================================================
; Pixel span helpers
; ==============================================================
DrawSingleByte:
            LD      A,(PXLEFT)
            AND     3
            LD      E,A
            LD      D,0
            LD      HL,LMASK
            ADD     HL,DE
            LD      B,(HL)          ; left mask
            LD      A,(PXRIGHT)
            AND     3
            LD      E,A
            LD      D,0
            LD      HL,RMASK
            ADD     HL,DE
            LD      C,(HL)          ; right mask
            LD      A,B
            AND     C               ; combined pixel mask
            LD      B,A
            LD      A,(CURCOL)
            AND     B
            LD      C,A             ; set bits
            LD      A,B
            CPL
            LD      D,A             ; clear mask
            LD      A,(VPTR)
            LD      L,A
            LD      A,(VPTR+1)
            LD      H,A
            LD      A,(HL)
            AND     D
            OR      C
            LD      (HL),A
            RET

DrawLeftByte:
            LD      A,(PXLEFT)
            AND     3
            LD      E,A
            LD      D,0
            LD      HL,LMASK
            ADD     HL,DE
            LD      B,(HL)
            LD      A,(CURCOL)
            AND     B
            LD      C,A
            LD      A,B
            CPL
            LD      D,A
            LD      A,(VPTR)
            LD      L,A
            LD      A,(VPTR+1)
            LD      H,A
            LD      A,(HL)
            AND     D
            OR      C
            LD      (HL),A
            INC     HL
            LD      A,L
            LD      (VPTR),A
            LD      A,H
            LD      (VPTR+1),A
            RET

DrawRightByte:
            LD      A,(PXRIGHT)
            AND     3
            LD      E,A
            LD      D,0
            LD      HL,RMASK
            ADD     HL,DE
            LD      B,(HL)
            LD      A,(CURCOL)
            AND     B
            LD      C,A
            LD      A,B
            CPL
            LD      D,A
            LD      A,(VPTR)
            LD      L,A
            LD      A,(VPTR+1)
            LD      H,A
            LD      A,(HL)
            AND     D
            OR      C
            LD      (HL),A
            RET

SwapCol:
            LD      A,(CURCOL)
            OR      A
            JP      NZ,SC_On
            LD      A,$FF
            LD      (CURCOL),A
            RET
SC_On:      XOR     A
            LD      (CURCOL),A
            RET

; ==============================================================
; DATA SECTION - all byte variables, then tables
; ==============================================================
BX:         DB      64
BY:         DB      38
VX:         DB      2
VY:         DB      2
PHASE:      DB      0
DRAWMODE:   DB      0
CURCOL:     DB      0
WIDX:       DB      0
DYTMP:      DB      0
PYTMP:      DB      0
WTMP:       DB      0
PXLEFT:     DB      0
PXRIGHT:    DB      0
BCOLLEFT:   DB      0
BCOLRIGHT:  DB      0
VTMP:       DW      0           ; temp VRAM row base (byte access: VTMP, VTMP+1)
VPTR:       DW      0           ; current VRAM write pointer (byte access)

LMASK:      DB      $FF,$3F,$0F,$03
RMASK:      DB      $C0,$F0,$FC,$FF

; VRAM row base lookup: YTAB[y*2] = lo, YTAB[y*2+1] = hi
YTAB:
            DB $00,$90, $20,$90, $40,$90, $60,$90
            DB $80,$90, $A0,$90, $C0,$90, $E0,$90
            DB $00,$91, $20,$91, $40,$91, $60,$91
            DB $80,$91, $A0,$91, $C0,$91, $E0,$91
            DB $00,$92, $20,$92, $40,$92, $60,$92
            DB $80,$92, $A0,$92, $C0,$92, $E0,$92
            DB $00,$93, $20,$93, $40,$93, $60,$93
            DB $80,$93, $A0,$93, $C0,$93, $E0,$93
            DB $00,$94, $20,$94, $40,$94, $60,$94
            DB $80,$94, $A0,$94, $C0,$94, $E0,$94
            DB $00,$95, $20,$95, $40,$95, $60,$95
            DB $80,$95, $A0,$95, $C0,$95, $E0,$95
            DB $00,$96, $20,$96, $40,$96, $60,$96
            DB $80,$96, $A0,$96, $C0,$96, $E0,$96
            DB $00,$97, $20,$97, $40,$97, $60,$97
            DB $80,$97, $A0,$97, $C0,$97, $E0,$97

; BGBUF row base lookup: BGTAB[y*2] = lo/hi of (BGBUF + 32*y)
BGTAB:
            DW      BGBUF+0
            DW      BGBUF+32
            DW      BGBUF+64
            DW      BGBUF+96
            DW      BGBUF+128
            DW      BGBUF+160
            DW      BGBUF+192
            DW      BGBUF+224
            DW      BGBUF+256
            DW      BGBUF+288
            DW      BGBUF+320
            DW      BGBUF+352
            DW      BGBUF+384
            DW      BGBUF+416
            DW      BGBUF+448
            DW      BGBUF+480
            DW      BGBUF+512
            DW      BGBUF+544
            DW      BGBUF+576
            DW      BGBUF+608
            DW      BGBUF+640
            DW      BGBUF+672
            DW      BGBUF+704
            DW      BGBUF+736
            DW      BGBUF+768
            DW      BGBUF+800
            DW      BGBUF+832
            DW      BGBUF+864
            DW      BGBUF+896
            DW      BGBUF+928
            DW      BGBUF+960
            DW      BGBUF+992
            DW      BGBUF+1024
            DW      BGBUF+1056
            DW      BGBUF+1088
            DW      BGBUF+1120
            DW      BGBUF+1152
            DW      BGBUF+1184
            DW      BGBUF+1216
            DW      BGBUF+1248
            DW      BGBUF+1280
            DW      BGBUF+1312
            DW      BGBUF+1344
            DW      BGBUF+1376
            DW      BGBUF+1408
            DW      BGBUF+1440
            DW      BGBUF+1472
            DW      BGBUF+1504
            DW      BGBUF+1536
            DW      BGBUF+1568
            DW      BGBUF+1600
            DW      BGBUF+1632
            DW      BGBUF+1664
            DW      BGBUF+1696
            DW      BGBUF+1728
            DW      BGBUF+1760
            DW      BGBUF+1792
            DW      BGBUF+1824
            DW      BGBUF+1856
            DW      BGBUF+1888
            DW      BGBUF+1920
            DW      BGBUF+1952
            DW      BGBUF+1984
            DW      BGBUF+2016

; Ball ellipse half-widths: WIDTHTAB[i] = floor(RX*sqrt(1-((i-RY)/RY)^2))
; RX=30, RY=20: compensates 2:3 pixel aspect (30*2=60=20*3 physical units)
WIDTHTAB:
            DB  0, 9,13,15,17,19,21,22,24,25,25
            DB 26,27,28,28,29,29,29,29,29,30,29
            DB 29,29,29,29,28,28,27,26,25,25,24
            DB 22,21,19,17,15,13, 9, 0

; ==============================================================
; BGBUF - Precomputed background: 2048 bytes (64 rows x 32 bytes)
; Amiga Boing demo grid in colour 2 (blue) on green background:
;   Back wall: vertical lines at x=0,16,32..112 from y=0..31
;   Horizon:   full blue line at y=32
;   Floor:     perspective vertical lines converging to VP(64,32)
;              + perspective horizontal lines (closer near horizon)
; ==============================================================
BGBUF:
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 0
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 1
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 2
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 3
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 4
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 5
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 6
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 7
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 8
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y= 9
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=10
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=11
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=12
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=13
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=14
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=15
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=16
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=17
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=18
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=19
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=20
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=21
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=22
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=23
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=24
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=25
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=26
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=27
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=28
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=29
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=30
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00 ; y=31
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $80,$00,$00,$00,$80,$00,$00,$00
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=32
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=33
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=34
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=35
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=36
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=37
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=38
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=39
            DB $00,$00,$00,$00,$08,$20,$20,$80
            DB $80,$82,$02,$08,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=40
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=41
            DB $00,$00,$00,$20,$08,$02,$02,$00
            DB $80,$20,$20,$08,$02,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=42
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=43
            DB $00,$00,$20,$02,$00,$20,$08,$00
            DB $80,$08,$02,$00,$20,$02,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=44
            DB $00,$02,$00,$20,$00,$80,$08,$00
            DB $80,$08,$00,$80,$02,$00,$20,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=45
            DB $00,$20,$00,$80,$02,$00,$20,$00
            DB $80,$02,$00,$20,$00,$80,$02,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=46
            DB $02,$00,$08,$00,$08,$00,$20,$00
            DB $80,$02,$00,$08,$00,$08,$00,$20
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$00,$00 ; y=47
            DB $20,$00,$20,$00,$20,$00,$80,$00
            DB $80,$00,$80,$02,$00,$02,$00,$02
            DB $00,$00,$00,$00,$00,$00,$00,$00
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=48
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $00,$00,$00,$00,$00,$00,$00,$20 ; y=49
            DB $00,$08,$00,$08,$00,$02,$00,$00
            DB $80,$00,$20,$00,$08,$00,$08,$00
            DB $02,$00,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$02,$00 ; y=50
            DB $00,$80,$00,$20,$00,$02,$00,$00
            DB $80,$00,$20,$00,$02,$00,$00,$80
            DB $00,$20,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$00,$20,$00 ; y=51
            DB $02,$00,$00,$80,$00,$08,$00,$00
            DB $80,$00,$08,$00,$00,$80,$00,$20
            DB $00,$02,$00,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$02,$00,$00 ; y=52
            DB $20,$00,$02,$00,$00,$08,$00,$00
            DB $80,$00,$08,$00,$00,$20,$00,$02
            DB $00,$00,$20,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$00,$20,$00,$02 ; y=53
            DB $00,$00,$08,$00,$00,$20,$00,$00
            DB $80,$00,$02,$00,$00,$08,$00,$00
            DB $20,$00,$02,$00,$00,$00,$00,$00
            DB $00,$00,$00,$00,$02,$00,$00,$08 ; y=54
            DB $00,$00,$20,$00,$00,$20,$00,$00
            DB $80,$00,$02,$00,$00,$02,$00,$00
            DB $08,$00,$00,$20,$00,$00,$00,$00
            DB $00,$00,$00,$00,$20,$00,$00,$80 ; y=55
            DB $00,$00,$80,$00,$00,$80,$00,$00
            DB $80,$00,$00,$80,$00,$00,$80,$00
            DB $00,$80,$00,$02,$00,$00,$00,$00
            DB $00,$00,$00,$08,$00,$00,$02,$00 ; y=56
            DB $00,$02,$00,$00,$00,$80,$00,$00
            DB $80,$00,$00,$80,$00,$00,$20,$00
            DB $00,$20,$00,$00,$08,$00,$00,$00
            DB $00,$00,$00,$80,$00,$00,$20,$00 ; y=57
            DB $00,$08,$00,$00,$02,$00,$00,$00
            DB $80,$00,$00,$20,$00,$00,$08,$00
            DB $00,$02,$00,$00,$00,$80,$00,$00
            DB $00,$00,$08,$00,$00,$00,$80,$00 ; y=58
            DB $00,$20,$00,$00,$02,$00,$00,$00
            DB $80,$00,$00,$20,$00,$00,$02,$00
            DB $00,$00,$80,$00,$00,$08,$00,$00
            DB $00,$00,$80,$00,$00,$08,$00,$00 ; y=59
            DB $00,$80,$00,$00,$08,$00,$00,$00
            DB $80,$00,$00,$08,$00,$00,$00,$80
            DB $00,$00,$08,$00,$00,$00,$80,$00
            DB $00,$08,$00,$00,$00,$20,$00,$00 ; y=60
            DB $02,$00,$00,$00,$08,$00,$00,$00
            DB $80,$00,$00,$08,$00,$00,$00,$20
            DB $00,$00,$02,$00,$00,$00,$08,$00
            DB $00,$80,$00,$00,$02,$00,$00,$00 ; y=61
            DB $08,$00,$00,$00,$20,$00,$00,$00
            DB $80,$00,$00,$02,$00,$00,$00,$08
            DB $00,$00,$00,$20,$00,$00,$00,$80
            DB $08,$00,$00,$00,$08,$00,$00,$00 ; y=62
            DB $20,$00,$00,$00,$20,$00,$00,$00
            DB $80,$00,$00,$02,$00,$00,$00,$02
            DB $00,$00,$00,$08,$00,$00,$00,$08
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; y=63
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
            DB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA

; End of file

' *****************************************************************
' PROJECT: UX-MINIMA INDUSTRIAL DATA-COMPILER
' ARCHITECTURE: Data-Driven Pattern Matching
' *****************************************************************
DECLARE SUB Lexer ()
DECLARE SUB IndustrialParser ()
DECLARE FUNCTION MatchPattern% (startIdx%)

DIM SHARED Tokens$(5000), TokenCount, LStack(100), LPtr, LCount
DIM SHARED Pat$(80), AsmCode$(80), PatCount
DIM SHARED Src$: CLS

' --- 1. PATTERN DATA KÜTÜPHANESİ ---
RESTORE PatternData
READ PatCount
FOR i = 1 TO PatCount
    READ Pat$(i), AsmCode$(i)
NEXT i

PRINT "--- UX-MINIMA INDUSTRIAL COMPILER (Data-Driven) ---"
INPUT "Kaynak (.UXM): ", inF$: INPUT "ASM (.ASM): ", outF$

OPEN inF$ FOR INPUT AS #1: Src$ = INPUT$(LOF(1), 1): CLOSE #1
Lexer: IndustrialParser
PRINT "Derleme Tamamlandi: "; outF$: END

' --- STAGE 1: LEXER ---
SUB Lexer
    FOR i = 1 TO LEN(Src$)
        c$ = MID$(Src$, i, 1)
        IF INSTR("><+-0!?.,[]&|^$%@", c$) > 0 THEN
            TokenCount = TokenCount + 1: Tokens$(TokenCount) = c$
        END IF
    NEXT i
END SUB

' --- STAGE 2: INDUSTRIAL PARSER (Pattern Discovery) ---
SUB IndustrialParser
    OPEN outF$ FOR OUTPUT AS #2
    PRINT #2, "; UX-MINIMA DATA-DRIVEN INDUSTRIAL RUNTIME"
    PRINT #2, "PTR = $FB : MEM = $2000 : ORG $0801"
    PRINT #2, "    BYTE $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$31,$00,$00,$00"
    PRINT #2, "    LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1 : LDY #0"

    i = 1
    DO WHILE i <= TokenCount
        pIdx% = MatchPattern%(i)
        
        IF pIdx% > 0 THEN
            ' Pattern bulundu: ASM karşılığını bas ve pattern boyu kadar ilerle
            PRINT #2, "    " + AsmCode$(pIdx%) + " ; [Pattern Match]"
            i = i + LEN(Pat$(pIdx%))
        ELSE
            ' Standart komut (Pattern dışı)
            cmd$ = Tokens$(i)
            SELECT CASE cmd$
                CASE ">": PRINT #2, "    INY : BNE *+4 : INC PTR+1"
                CASE "<": PRINT #2, "    TYA : BNE *+4 : DEC PTR+1 : DEY"
                CASE "+": PRINT #2, "    LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y"
                CASE "-": PRINT #2, "    LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y"
                CASE "0": PRINT #2, "    LDA #0 : STA (PTR),Y"
                CASE ".": PRINT #2, "    LDA (PTR),Y : JSR $FFD2"
                CASE ",": PRINT #2, "    JSR $FFCF : STA (PTR),Y"
                CASE "[": 
                    LCount = LCount + 1: LPtr = LPtr + 1: LStack(LPtr) = LCount
                    PRINT #2, "L" + LTRIM$(STR$(LCount)) + ":"
                    PRINT #2, "    LDA (PTR),Y : BEQ E" + LTRIM$(STR$(LCount))
                CASE "]":
                    PRINT #2, "    JMP L" + LTRIM$(STR$(LStack(LPtr)))
                    PRINT #2, "E" + LTRIM$(STR$(LStack(LPtr))) + ":"
                    LPtr = LPtr - 1
                CASE "@": 
                    PRINT #2, "    LDA (PTR),Y : CMP #1 : BNE *+5 : JSR $E544"
                    PRINT #2, "    CMP #4 : BNE *+5 : JSR $E094"
            END SELECT
            i = i + 1
        END IF
    LOOP
    PRINT #2, "    RTS": CLOSE #2
END SUB

FUNCTION MatchPattern% (startIdx%)
    ' En uzun pattern'den başlayarak kontrol eder (Greedy Match)
    FOR p% = 1 TO PatCount
        pLen% = LEN(Pat$(p%))
        match% = 1
        FOR j% = 0 TO pLen% - 1
            IF (startIdx% + j% > TokenCount) OR (Tokens$(startIdx% + j%) <> MID$(Pat$(p%), j% + 1, 1)) THEN
                match% = 0: EXIT FOR
            END IF
        NEXT j%
        IF match% = 1 THEN MatchPattern% = p%: EXIT FUNCTION
    NEXT p%
    MatchPattern% = 0
END FUNCTION

' --- 3. PATTERN DATA BANKASI ---
PatternData:
DATA 135 : ' Toplam Pattern Sayısı
DATA "[-]", "LDA #0 : STA (PTR),Y"
DATA "[->+<]", "LDA (PTR),Y : CLC : INY : ADC (PTR),Y : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA ">>", "TYA : CLC : ADC #2 : TAY : BCC *+4 : INC PTR+1"
DATA "<<", "TYA : SEC : SBC #2 : TAY : BCS *+4 : DEC PTR+1"
DATA "++", "LDA (PTR),Y : CLC : ADC #2 : STA (PTR),Y"
DATA "--", "LDA (PTR),Y : SEC : SBC #2 : STA (PTR),Y"
DATA "0+@", "JSR $E544 ; [Meta: CLS via Pattern]"

' --- 1-8: Temel Aritmetik Katlama (Arithmetic Folding) ---
DATA "++", "LDA (PTR),Y : CLC : ADC #2 : STA (PTR),Y"
DATA "+++", "LDA (PTR),Y : CLC : ADC #3 : STA (PTR),Y"
DATA "++++", "LDA (PTR),Y : CLC : ADC #4 : STA (PTR),Y"
DATA "--", "LDA (PTR),Y : SEC : SBC #2 : STA (PTR),Y"
DATA "---", "LDA (PTR),Y : SEC : SBC #3 : STA (PTR),Y"
DATA "----", "LDA (PTR),Y : SEC : SBC #4 : STA (PTR),Y"
DATA ">>", "TYA : CLC : ADC #2 : TAY : BCC *+4 : INC PTR+1"
DATA "<<", "TYA : SEC : SBC #2 : TAY : BCS *+4 : DEC PTR+1"

' --- 9-16: Gelişmiş Navigasyon (Fast Seek) ---
DATA ">>>", "TYA : CLC : ADC #3 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<", "TYA : SEC : SBC #3 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>", "TYA : CLC : ADC #4 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<", "TYA : SEC : SBC #4 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>", "TYA : CLC : ADC #5 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<", "TYA : SEC : SBC #5 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>>", "TYA : CLC : ADC #6 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<<", "TYA : SEC : SBC #6 : TAY : BCS *+4 : DEC PTR+1"

' --- 17-24: İdiyomatik Mantık (BF Idioms) ---
DATA "[-]", "LDA #0 : STA (PTR),Y"
DATA "[+]", "LDA #0 : STA (PTR),Y"
DATA "[->+<]", "LDA (PTR),Y : CLC : INY : ADC (PTR),Y : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[->-<]", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[>+<-]", "INY : LDA (PTR),Y : CLC : DEY : ADC (PTR),Y : INY : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[<+>-]", "DEY : LDA (PTR),Y : CLC : INY : ADC (PTR),Y : DEY : STA (PTR),Y : INY : LDA #0 : STA (PTR),Y"
DATA "[->+>+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY"
DATA "[-]>", "LDA #0 : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"

' --- 25-32: Stack & Register Operasyonları ---
DATA "$%", "NOP ; redundant push/pull"
DATA "$>", "LDA (PTR),Y : PHA : INY : BNE *+4 : INC PTR+1"
DATA "<%", "TYA : BNE *+4 : DEC PTR+1 : DEY : PLA : STA (PTR),Y"
DATA "$+", "LDA (PTR),Y : PHA : CLC : ADC #1 : STA (PTR),Y"
DATA "$-", "LDA (PTR),Y : PHA : SEC : SBC #1 : STA (PTR),Y"
DATA "+$", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : PHA"
DATA "-$", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y : PHA"
DATA "0$", "LDA #0 : STA (PTR),Y : PHA"

' --- 33-40: Meta (ROM) Kombinasyonları ---
DATA "0+@", "JSR $E544 ; CLS"
DATA "0++++@", "JSR $E094 ; RND to Cell"
DATA "0++@", "JSR $E518 ; HOME"
DATA ".>", "LDA (PTR),Y : JSR $FFD2 : INY : BNE *+4 : INC PTR+1"
DATA ",>", "JSR $FFCF : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA ".<", "LDA (PTR),Y : JSR $FFD2 : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA ",<", "JSR $FFCF : STA (PTR),Y : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA "0.@", "LDA #0 : STA (PTR),Y : JSR $FFD2 : JSR $E544"

' --- 41-48: Bellek Blok İşlemleri (Bulk) ---
DATA "00", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : DEY"
DATA "0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "!!", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY"
DATA "??", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y : INY : INY"
DATA "!>", "LDA (PTR),Y : INY : STA (PTR),Y"
DATA "?<", "LDA (PTR),Y : DEY : STA (PTR),Y"
DATA "!?", "NOP ; Copy right then copy left (no change)"

' --- 49-56: Bitwise & Karşılaştırma Simülasyonu ---
DATA "0-", "LDA #255 : STA (PTR),Y"
DATA "+-", "NOP ; +1 then -1"
DATA "-+", "NOP ; -1 then +1"
DATA "<>", "NOP ; left then right"
DATA "><", "NOP ; right then left"
DATA "++-", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y"
DATA "--+", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y"
DATA "0+", "LDA #1 : STA (PTR),Y"

' --- 57-64: Gelişmiş Aritmetik & Sistem ---
DATA "&>", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "|>", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y"
DATA "&<", "LDA (PTR),Y : STA $02 : DEY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "|<", "LDA (PTR),Y : STA $02 : DEY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y"
DATA "++.", "LDA (PTR),Y : CLC : ADC #2 : JSR $FFD2 : STA (PTR),Y"
DATA "--.", "LDA (PTR),Y : SEC : SBC #2 : JSR $FFD2 : STA (PTR),Y"
DATA "0@", "LDA #0 : JSR $E544 ; ID 0 is also CLS"
DATA "^0", "LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1 : LDA #0 : STA (PTR),Y"

' --- 65-72: İleri Düzey Aritmetik (16-bit ve Kaydırma Simülasyonu) ---
DATA "+++++", "LDA (PTR),Y : CLC : ADC #5 : STA (PTR),Y"
DATA "-----", "LDA (PTR),Y : SEC : SBC #5 : STA (PTR),Y"
DATA ">>>>>", "TYA : CLC : ADC #5 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<", "TYA : SEC : SBC #5 : TAY : BCS *+4 : DEC PTR+1"
DATA "+&+", "LDA (PTR),Y : CLC : ADC #1 : STA $02 : INY : LDA (PTR),Y : ADC $02 : STA (PTR),Y : DEY"
DATA "[-]>+", "LDA #0 : STA (PTR),Y : INY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : DEY"
DATA "[-]<+", "LDA #0 : STA (PTR),Y : DEY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : INY"
DATA "0&", "LDA #0 : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y : DEY"

' --- 73-80: Screen RAM (VIC-II) Doğrudan Erişim Kalıpları ---
DATA "0.@", "LDA #0 : STA (PTR),Y : JSR $FFD2 ; Null terminate and print"
DATA "+++@", "LDA #3 : JSR $E544 ; Specific ROM Clear/Color Call"
DATA "!!>", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "??<", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA ". .", "LDA (PTR),Y : JSR $FFD2 : LDA #$20 : JSR $FFD2 ; Print char and space"
DATA "..", "LDA (PTR),Y : JSR $FFD2 : JSR $FFD2 ; Double print"
DATA "!!!", "LDA (PTR),Y : TAX : INY : STX (PTR),Y : INY : STX (PTR),Y : DEY : DEY"
DATA "???", "LDA (PTR),Y : TAX : DEY : STX (PTR),Y : DEY : STX (PTR),Y : INY : INY"

' --- 81-88: Mantıksal Karşılaştırma ve "If" Benzeri Yapılar ---
DATA "[-][", "LDA #0 : STA (PTR),Y : BEQ *+3 ; Force skip block"
DATA "0[", "LDA #0 : STA (PTR),Y : BEQ *+3 ; Optimized Skip"
DATA "0+", "LDA #1 : STA (PTR),Y"
DATA "0++", "LDA #2 : STA (PTR),Y"
DATA "0+++", "LDA #3 : STA (PTR),Y"
DATA "0++++", "LDA #4 : STA (PTR),Y"
DATA "[<]>", "LDY #0 ; Search back to start of page/boundary"
DATA "[>]<", "LDY #$FF ; Search forward to end of page"

' --- 89-96: Stack (Yığın) Tabanlı Veri Takası (Fast Swap) ---
DATA "$>$%", "LDA (PTR),Y : PHA : INY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : DEY : STA (PTR),Y"
DATA "$<$%", "LDA (PTR),Y : PHA : DEY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : INY : STA (PTR),Y"
DATA "$+$%", "LDA (PTR),Y : PHA : CLC : ADC #1 : TAX : PLA : STA (PTR),Y ; Inc and restore"
DATA "$$%%", "LDA (PTR),Y : PHA : PHA : PLA : PLA ; Redundant stack"
DATA "$0%", "LDA (PTR),Y : PHA : LDA #0 : STA (PTR),Y : PLA : STA (PTR),Y ; Clear with backup"
DATA "%$", "LDA (PTR),Y : PHA : PLA : STA (PTR),Y ; Redundant"
DATA "+%", "LDA (PTR),Y : CLC : ADC #1 : PHA : PLA : STA (PTR),Y"
DATA "-%", "LDA (PTR),Y : SEC : SBC #1 : PHA : PLA : STA (PTR),Y"

' --- 97-104: Alg (Biyoreaktör) Sensör İşleme Kalıpları ---
DATA "0+++++@", "JSR $E094 : AND #$0F : STA (PTR),Y ; Random nibble for sensor simulation"
DATA "@.", "LDA (PTR),Y : JSR $FFD2 ; Direct meta result print"
DATA "@>", "LDA (PTR),Y : JSR $E094 : INY : STA (PTR),Y ; Meta call then store in next cell"
DATA ",.", "JSR $FFCF : JSR $FFD2 : STA (PTR),Y ; Echo and store"
DATA "0|", "LDA #0 : SEC : SBC (PTR),Y : STA (PTR),Y ; Negate cell"
DATA "&&", "LDA (PTR),Y : ASL A : STA (PTR),Y ; Double (Shift Left)"
DATA "||", "LDA (PTR),Y : LSR A : STA (PTR),Y ; Half (Shift Right)"
DATA "++&", "LDA (PTR),Y : CLC : ADC #2 : STA $02 : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"

' --- 105-112: Bellek Temizliği ve Blok Taşıma (Page Ops) ---
DATA "0>0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0<0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "!!!!", "LDA (PTR),Y : STA $02 : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY : DEY"
DATA "++++++", "LDA (PTR),Y : CLC : ADC #6 : STA (PTR),Y"
DATA "------", "LDA (PTR),Y : SEC : SBC #6 : STA (PTR),Y"
DATA ">>>>>>", "TYA : CLC : ADC #6 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<<", "TYA : SEC : SBC #6 : TAY : BCS *+4 : DEC PTR+1"
DATA "0+@>", "JSR $E544 : INY ; Clear screen and move to next buffer"

' --- 113-120: Donanım Bayrakları ve Kesme (Interrupt) Hazırlığı ---
DATA "0!", "LDA #0 : INY : STA (PTR),Y : DEY"
DATA "0?", "LDA #0 : DEY : STA (PTR),Y : INY"
DATA "[@]", "LDA (PTR),Y : BEQ *+5 : JSR $FFD2 ; Conditional ROM call"
DATA "[[", "LDA (PTR),Y : BEQ *+7 : LDA (PTR),Y : BEQ *+4 ; Nested zero check"
DATA "]]", "JMP * ; Placeholder for nested loop exit"
DATA "+-+-", "NOP ; Stabilization sequence"
DATA ">><<", "NOP ; Stabilization sequence"
DATA ">>!", "INY : INY : LDA (PTR),Y : DEY : DEY : STA (PTR),Y ; Deep copy"

' --- 121-128: Final Sistem ve Kapanış Kalıpları ---
DATA "0+++++++@", "JSR $FFD8 ; KERNAL SAVE (Example)"
DATA "0++++++++@", "JSR $FFD5 ; KERNAL LOAD (Example)"
DATA "0^", "LDA #0 : STA (PTR),Y : LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1"
DATA "0$", "LDA #0 : PHA"
DATA "0%", "PLA : LDA #0"
DATA ".0", "LDA (PTR),Y : JSR $FFD2 : LDA #0 : STA (PTR),Y"
DATA ",0", "JSR $FFCF : LDA #0 : STA (PTR),Y ; Read and discard"
DATA "@@", "JSR $E544 : JSR $E518 ; Clear and Home"
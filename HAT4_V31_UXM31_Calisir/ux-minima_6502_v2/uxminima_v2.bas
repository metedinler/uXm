' *****************************************************************
' PROJECT      : UX-MINIMA INDUSTRIAL DATA-COMPILER
' ARCHITECTURE : Data-Driven Pattern Matching
' TARGET       : C64 / 6502 ASM Generator
' VERSION      : Fixed + Longest/Specific Pattern Priority
' *****************************************************************
'
' TEMEL MANTIK:
' 1. Kaynak dosyadan sadece komut karakterleri lexer ile alınır.
' 2. Parser önce pattern bankasına bakar.
' 3. En uzun pattern önce denenir.
' 4. Aynı uzunlukta ise daha spesifik pattern önce denenir.
' 5. Pattern bulunamazsa tekil komut ASM'ye çevrilir.
'
' *****************************************************************

OPTION EXPLICIT

CONST MAX_TOKENS = 50000
CONST MAX_PATTERNS = 512
CONST MAX_LOOP_STACK = 256

CONST COMMAND_CHARS = "><+-0!?.,[]&|^$%@"

' 0 = dengesiz bracket patternleri atla
' 1 = izin ver
CONST ALLOW_UNBALANCED_PATTERNS = 0

DECLARE SUB LoadPatterns()
DECLARE SUB AddPattern(ByRef rawPat As String, ByRef rawAsm As String)
DECLARE SUB SortPatternsByPriority()
DECLARE SUB Lexer()
DECLARE SUB IndustrialParser()
DECLARE SUB CompileError(ByRef msg As String)
DECLARE SUB EmitHeader(ByVal outFF As Integer)
DECLARE SUB EmitFooter(ByVal outFF As Integer)

DECLARE FUNCTION NormalizePattern(ByRef s As String) As String
DECLARE FUNCTION PatternIsBalanced(ByRef s As String) As Integer
DECLARE FUNCTION MatchPattern(ByVal startIdx As Integer) As Integer
DECLARE FUNCTION SpecificityScore(ByRef p As String) As Integer
DECLARE FUNCTION PatternCompare(ByVal a As Integer, ByVal b As Integer) As Integer

DIM SHARED Tokens(1 TO MAX_TOKENS) AS STRING
DIM SHARED TokenCount AS Integer

DIM SHARED LStack(1 TO MAX_LOOP_STACK) AS Integer
DIM SHARED LPtr AS Integer
DIM SHARED LCount AS Integer

DIM SHARED Pat(1 TO MAX_PATTERNS) AS STRING
DIM SHARED AsmCode(1 TO MAX_PATTERNS) AS STRING
DIM SHARED PatPriority(1 TO MAX_PATTERNS) AS Integer
DIM SHARED PatOrder(1 TO MAX_PATTERNS) AS Integer
DIM SHARED PatCount AS Integer
DIM SHARED WarningCount AS Integer

DIM SHARED Src AS STRING
DIM SHARED InFileName AS STRING
DIM SHARED OutFileName AS STRING
DIM SHARED HadError AS Integer

CLS
PRINT "--- UX-MINIMA INDUSTRIAL COMPILER ---"
PRINT "--- Data-Driven / Longest + Specific Pattern Priority ---"
PRINT

LoadPatterns

PRINT
PRINT "Aktif pattern sayisi : "; PatCount
PRINT "Uyari sayisi         : "; WarningCount
PRINT

INPUT "Kaynak (.UXM): ", InFileName
INPUT "ASM (.ASM): ", OutFileName

IF LEN(TRIM(InFileName)) = 0 THEN CompileError "Kaynak dosya adi bos."
IF LEN(TRIM(OutFileName)) = 0 THEN CompileError "ASM cikis dosya adi bos."

IF HadError = 0 THEN
    DIM inFF AS Integer
    inFF = FREEFILE

    OPEN InFileName FOR BINARY AS #inFF
    Src = SPACE(LOF(inFF))
    IF LOF(inFF) > 0 THEN GET #inFF, , Src
    CLOSE #inFF

    Lexer
    IndustrialParser
END IF

PRINT

IF HadError <> 0 THEN
    PRINT "Derleme hatali tamamlandi. Once HATA satirlarini duzelt."
ELSE
    PRINT "Derleme tamamlandi: "; OutFileName
END IF

END

' *****************************************************************
' PATTERN LOADER
' *****************************************************************

SUB LoadPatterns()
    DIM rawPat AS String
    DIM rawAsm AS String

    RESTORE PatternData

    DO
        READ rawPat, rawAsm

        IF rawPat = "__END__" THEN EXIT DO

        AddPattern rawPat, rawAsm

        IF HadError <> 0 THEN EXIT DO
    LOOP

    SortPatternsByPriority
END SUB

SUB AddPattern(ByRef rawPat As String, ByRef rawAsm As String)
    DIM p AS String
    DIM i AS Integer

    p = NormalizePattern(rawPat)

    IF LEN(p) = 0 THEN EXIT SUB

    IF ALLOW_UNBALANCED_PATTERNS = 0 THEN
        IF PatternIsBalanced(p) = 0 THEN
            WarningCount = WarningCount + 1
            PRINT "UYARI: Dengesiz bracket pattern atlandi: "; rawPat
            EXIT SUB
        END IF
    END IF

    FOR i = 1 TO PatCount
        IF Pat(i) = p THEN
            WarningCount = WarningCount + 1
            PRINT "UYARI: Duplicate pattern atlandi: "; rawPat; " -> "; p
            EXIT SUB
        END IF
    NEXT i

    IF PatCount >= MAX_PATTERNS THEN
        CompileError "Pattern dizisi doldu. MAX_PATTERNS degerini artir."
        EXIT SUB
    END IF

    PatCount = PatCount + 1
    Pat(PatCount) = p
    AsmCode(PatCount) = rawAsm
    PatPriority(PatCount) = SpecificityScore(p)
    PatOrder(PatCount) = PatCount
END SUB

FUNCTION NormalizePattern(ByRef s As String) As String
    DIM i AS Integer
    DIM ch AS String
    DIM r AS String

    r = ""

    FOR i = 1 TO LEN(s)
        ch = MID(s, i, 1)

        IF ch <> " " AND ch <> CHR(9) THEN
            r = r + ch
        END IF
    NEXT i

    NormalizePattern = r
END FUNCTION

FUNCTION PatternIsBalanced(ByRef s As String) As Integer
    DIM i AS Integer
    DIM ch AS String
    DIM bal AS Integer

    bal = 0

    FOR i = 1 TO LEN(s)
        ch = MID(s, i, 1)

        IF ch = "[" THEN
            bal = bal + 1
        ELSEIF ch = "]" THEN
            bal = bal - 1

            IF bal < 0 THEN
                PatternIsBalanced = 0
                EXIT FUNCTION
            END IF
        END IF
    NEXT i

    IF bal = 0 THEN
        PatternIsBalanced = 1
    ELSE
        PatternIsBalanced = 0
    END IF
END FUNCTION

' *****************************************************************
' SPECIFICITY SCORE
' *****************************************************************
'
' En uzun pattern zaten birinci ölçüttür.
' Aynı uzunlukta ise aşağıdaki puanlama kullanılır:
'
' - Bracket/loop idiomları daha spesifik kabul edilir.
' - Meta çağrılar, stack/register benzeri patternler daha spesifiktir.
' - Çok farklı sembol içeren patternler tek sembol tekrarından daha spesifiktir.
' - Sadece +++++ veya >>>>> gibi tekrar kalıpları daha genel kabul edilir.
'
' *****************************************************************

FUNCTION SpecificityScore(ByRef p As String) As Integer
    DIM i AS Integer
    DIM ch AS String
    DIM score AS Integer
    DIM uniqueChars AS Integer
    DIM seen AS String
    DIM allSame AS Integer

    score = 0
    seen = ""
    allSame = 1

    FOR i = 1 TO LEN(p)
        ch = MID(p, i, 1)

        IF INSTR(seen, ch) = 0 THEN
            seen = seen + ch
            uniqueChars = uniqueChars + 1
        END IF

        IF i > 1 THEN
            IF ch <> MID(p, 1, 1) THEN allSame = 0
        END IF

        SELECT CASE ch
            CASE "[", "]"
                score = score + 80
            CASE "@"
                score = score + 60
            CASE "$", "%"
                score = score + 50
            CASE "!", "?"
                score = score + 40
            CASE "&", "|", "^"
                score = score + 35
            CASE ".", ","
                score = score + 30
            CASE "0"
                score = score + 20
            CASE ">", "<"
                score = score + 10
            CASE "+", "-"
                score = score + 8
            CASE ELSE
                score = score + 1
        END SELECT
    NEXT i

    score = score + uniqueChars * 10

    IF allSame <> 0 THEN
        score = score - 30
    END IF

    SpecificityScore = score
END FUNCTION

' *****************************************************************
' PATTERN SORT
' *****************************************************************
'
' PatternCompare:
'   - 1 dönerse A, B'den önce gelmeli.
'   - 0 dönerse yerleri değişmemeli.
'
' Sıralama:
'   1. Daha uzun pattern önce.
'   2. Aynı uzunlukta daha yüksek specificity önce.
'   3. Hâlâ eşitse dosyada daha önce yazılan önce.
'
' *****************************************************************

FUNCTION PatternCompare(ByVal a As Integer, ByVal b As Integer) As Integer
    IF LEN(Pat(a)) > LEN(Pat(b)) THEN
        PatternCompare = 1
        EXIT FUNCTION
    END IF

    IF LEN(Pat(a)) < LEN(Pat(b)) THEN
        PatternCompare = 0
        EXIT FUNCTION
    END IF

    IF PatPriority(a) > PatPriority(b) THEN
        PatternCompare = 1
        EXIT FUNCTION
    END IF

    IF PatPriority(a) < PatPriority(b) THEN
        PatternCompare = 0
        EXIT FUNCTION
    END IF

    IF PatOrder(a) < PatOrder(b) THEN
        PatternCompare = 1
    ELSE
        PatternCompare = 0
    END IF
END FUNCTION

SUB SortPatternsByPriority()
    DIM i AS Integer
    DIM j AS Integer

    DIM tp AS String
    DIM ta AS String
    DIM tpri AS Integer
    DIM tord AS Integer

    IF PatCount <= 1 THEN EXIT SUB

    FOR i = 1 TO PatCount - 1
        FOR j = i + 1 TO PatCount
            IF PatternCompare(j, i) <> 0 THEN
                tp = Pat(i)
                ta = AsmCode(i)
                tpri = PatPriority(i)
                tord = PatOrder(i)

                Pat(i) = Pat(j)
                AsmCode(i) = AsmCode(j)
                PatPriority(i) = PatPriority(j)
                PatOrder(i) = PatOrder(j)

                Pat(j) = tp
                AsmCode(j) = ta
                PatPriority(j) = tpri
                PatOrder(j) = tord
            END IF
        NEXT j
    NEXT i
END SUB

SUB CompileError(ByRef msg As String)
    HadError = 1
    PRINT "HATA: "; msg
END SUB

' *****************************************************************
' STAGE 1: LEXER
' *****************************************************************

SUB Lexer()
    DIM i AS Integer
    DIM c AS String

    TokenCount = 0

    FOR i = 1 TO LEN(Src)
        c = MID(Src, i, 1)

        IF INSTR(COMMAND_CHARS, c) > 0 THEN
            IF TokenCount >= MAX_TOKENS THEN
                CompileError "Token dizisi doldu. MAX_TOKENS degerini artir."
                EXIT SUB
            END IF

            TokenCount = TokenCount + 1
            Tokens(TokenCount) = c
        END IF
    NEXT i
END SUB

' *****************************************************************
' STAGE 2: PARSER / CODE GENERATOR
' *****************************************************************

SUB EmitHeader(ByVal outFF As Integer)
    PRINT #outFF, "; UX-MINIMA DATA-DRIVEN INDUSTRIAL RUNTIME"
    PRINT #outFF, "; Generated by fixed longest/specific pattern compiler"
    PRINT #outFF, "PTR = $FB"
    PRINT #outFF, "MEM = $2000"
    PRINT #outFF, "ORG $0801"
    PRINT #outFF, "    BYTE $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$31,$00,$00,$00"
    PRINT #outFF, "    LDA #<MEM"
    PRINT #outFF, "    STA PTR"
    PRINT #outFF, "    LDA #>MEM"
    PRINT #outFF, "    STA PTR+1"
    PRINT #outFF, "    LDY #0"
END SUB

SUB EmitFooter(ByVal outFF As Integer)
    PRINT #outFF, "    RTS"
END SUB

SUB IndustrialParser()
    DIM outFF AS Integer
    DIM i AS Integer
    DIM pIdx AS Integer
    DIM cmd AS String
    DIM labelId AS Integer

    IF HadError <> 0 THEN EXIT SUB

    LPtr = 0
    LCount = 0

    outFF = FREEFILE
    OPEN OutFileName FOR OUTPUT AS #outFF

    EmitHeader outFF

    i = 1

    DO WHILE i <= TokenCount AND HadError = 0
        pIdx = MatchPattern(i)

        IF pIdx > 0 THEN
            PRINT #outFF, "    "; AsmCode(pIdx); " ; [Pattern Match: "; Pat(pIdx); "]"
            i = i + LEN(Pat(pIdx))
        ELSE
            cmd = Tokens(i)

            SELECT CASE cmd

                CASE ">"
                    PRINT #outFF, "    INY"
                    PRINT #outFF, "    BNE *+4"
                    PRINT #outFF, "    INC PTR+1"

                CASE "<"
                    PRINT #outFF, "    TYA"
                    PRINT #outFF, "    BNE *+4"
                    PRINT #outFF, "    DEC PTR+1"
                    PRINT #outFF, "    DEY"

                CASE "+"
                    PRINT #outFF, "    LDA (PTR),Y"
                    PRINT #outFF, "    CLC"
                    PRINT #outFF, "    ADC #1"
                    PRINT #outFF, "    STA (PTR),Y"

                CASE "-"
                    PRINT #outFF, "    LDA (PTR),Y"
                    PRINT #outFF, "    SEC"
                    PRINT #outFF, "    SBC #1"
                    PRINT #outFF, "    STA (PTR),Y"

                CASE "0"
                    PRINT #outFF, "    LDA #0"
                    PRINT #outFF, "    STA (PTR),Y"

                CASE "."
                    PRINT #outFF, "    LDA (PTR),Y"
                    PRINT #outFF, "    JSR $FFD2"

                CASE ","
                    PRINT #outFF, "    JSR $FFCF"
                    PRINT #outFF, "    STA (PTR),Y"

                CASE "["
                    IF LPtr >= MAX_LOOP_STACK THEN
                        CompileError "Loop stack doldu. Cok fazla ic ice '[' var."
                    ELSE
                        LCount = LCount + 1
                        LPtr = LPtr + 1
                        LStack(LPtr) = LCount

                        PRINT #outFF, "L"; LTRIM(STR(LCount)); ":"
                        PRINT #outFF, "    LDA (PTR),Y"
                        PRINT #outFF, "    BEQ E"; LTRIM(STR(LCount))
                    END IF

                CASE "]"
                    IF LPtr <= 0 THEN
                        CompileError "Fazla ']' bulundu. Eslesen '[' yok."
                    ELSE
                        labelId = LStack(LPtr)

                        PRINT #outFF, "    JMP L"; LTRIM(STR(labelId))
                        PRINT #outFF, "E"; LTRIM(STR(labelId)); ":"

                        LPtr = LPtr - 1
                    END IF

                CASE "@"
                    PRINT #outFF, "    LDA (PTR),Y"
                    PRINT #outFF, "    CMP #1"
                    PRINT #outFF, "    BNE *+5"
                    PRINT #outFF, "    JSR $E544"
                    PRINT #outFF, "    CMP #4"
                    PRINT #outFF, "    BNE *+5"
                    PRINT #outFF, "    JSR $E094"

                CASE ELSE
                    PRINT #outFF, "    ; ignored token: "; cmd

            END SELECT

            i = i + 1
        END IF
    LOOP

    IF LPtr <> 0 THEN
        CompileError "Eksik ']' bulundu. Acilan loop kapatilmamis."
        PRINT #outFF, "; HATA: Eksik ']' bulundu."
    END IF

    EmitFooter outFF

    CLOSE #outFF
END SUB

FUNCTION MatchPattern(ByVal startIdx As Integer) As Integer
    DIM p AS Integer
    DIM j AS Integer
    DIM pLen AS Integer
    DIM ok AS Integer

    FOR p = 1 TO PatCount
        pLen = LEN(Pat(p))

        IF startIdx + pLen - 1 <= TokenCount THEN
            ok = 1

            FOR j = 0 TO pLen - 1
                IF Tokens(startIdx + j) <> MID(Pat(p), j + 1, 1) THEN
                    ok = 0
                    EXIT FOR
                END IF
            NEXT j

            IF ok <> 0 THEN
                MatchPattern = p
                EXIT FUNCTION
            END IF
        END IF
    NEXT p

    MatchPattern = 0
END FUNCTION

' *****************************************************************
' PATTERN DATA BANKASI
' *****************************************************************
'
' Bu bölümde sıralama elle yapılmak zorunda değildir.
' Program açılışta otomatik olarak:
'   1. En uzun pattern
'   2. Daha spesifik pattern
'   3. İlk yazılan pattern
' sırasına göre düzenler.
'
' Duplicate olanlar otomatik atlanır.
' Dengesiz bracket içerenler ALLOW_UNBALANCED_PATTERNS = 0 ise atlanır.
'
' *****************************************************************

PatternData:

' --- Uzun meta / sistem patternleri ---
DATA "0++++++++@", "JSR $FFD5 ; KERNAL LOAD (Example)"
DATA "0+++++++@", "JSR $FFD8 ; KERNAL SAVE (Example)"
DATA "0+++++@", "JSR $E094 : AND #$0F : STA (PTR),Y ; Random nibble for sensor simulation"
DATA "0++++@", "JSR $E094 ; RND to Cell"
DATA "0+@>", "JSR $E544 : INY ; Clear screen and move to next buffer"
DATA "0++@", "JSR $E518 ; HOME"
DATA "0+@", "JSR $E544 ; CLS via Pattern"
DATA "+++@", "LDA #3 : JSR $E544 ; Specific ROM Clear/Color Call"
DATA "0.@", "LDA #0 : STA (PTR),Y : JSR $FFD2 : JSR $E544"
DATA "0@", "LDA #0 : JSR $E544 ; ID 0 is also CLS"
DATA "@@", "JSR $E544 : JSR $E518 ; Clear and Home"
DATA "@>", "LDA (PTR),Y : JSR $E094 : INY : STA (PTR),Y ; Meta call then store in next cell"
DATA "@.", "LDA (PTR),Y : JSR $FFD2 ; Direct meta result print"

' --- Uzun loop / BF idiomları ---
DATA "[->+>+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY"
DATA "[->+<]", "LDA (PTR),Y : CLC : INY : ADC (PTR),Y : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[->-<]", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[>+<-]", "INY : LDA (PTR),Y : CLC : DEY : ADC (PTR),Y : INY : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[<+>-]", "DEY : LDA (PTR),Y : CLC : INY : ADC (PTR),Y : DEY : STA (PTR),Y : INY : LDA #0 : STA (PTR),Y"
DATA "[-]>+", "LDA #0 : STA (PTR),Y : INY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : DEY"
DATA "[-]<+", "LDA #0 : STA (PTR),Y : DEY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : INY"
DATA "[-]>", "LDA #0 : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA "[<]>", "LDY #0 ; Search back to start of page/boundary"
DATA "[>]<", "LDY #$FF ; Search forward to end of page"
DATA "[@]", "LDA (PTR),Y : BEQ *+5 : JSR $FFD2 ; Conditional ROM call"
DATA "[-]", "LDA #0 : STA (PTR),Y"
DATA "[+]", "LDA #0 : STA (PTR),Y"

' --- Stack / register / swap patternleri ---
DATA "$>$%", "LDA (PTR),Y : PHA : INY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : DEY : STA (PTR),Y"
DATA "$<$%", "LDA (PTR),Y : PHA : DEY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : INY : STA (PTR),Y"
DATA "$+$%", "LDA (PTR),Y : PHA : CLC : ADC #1 : TAX : PLA : STA (PTR),Y ; Inc and restore"
DATA "$$%%", "LDA (PTR),Y : PHA : PHA : PLA : PLA ; Redundant stack"
DATA "$0%", "LDA (PTR),Y : PHA : LDA #0 : STA (PTR),Y : PLA : STA (PTR),Y ; Clear with backup"
DATA "$>", "LDA (PTR),Y : PHA : INY : BNE *+4 : INC PTR+1"
DATA "<%", "TYA : BNE *+4 : DEC PTR+1 : DEY : PLA : STA (PTR),Y"
DATA "$+", "LDA (PTR),Y : PHA : CLC : ADC #1 : STA (PTR),Y"
DATA "$-", "LDA (PTR),Y : PHA : SEC : SBC #1 : STA (PTR),Y"
DATA "+$", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : PHA"
DATA "-$", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y : PHA"
DATA "0$", "LDA #0 : STA (PTR),Y : PHA"
DATA "0%", "PLA : LDA #0"
DATA "%$", "LDA (PTR),Y : PHA : PLA : STA (PTR),Y ; Redundant"
DATA "+%", "LDA (PTR),Y : CLC : ADC #1 : PHA : PLA : STA (PTR),Y"
DATA "-%", "LDA (PTR),Y : SEC : SBC #1 : PHA : PLA : STA (PTR),Y"
DATA "$%", "NOP ; redundant push/pull"

' --- Bellek blok / kopyalama patternleri ---
DATA "0>0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0<0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "!!!!", "LDA (PTR),Y : STA $02 : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY : DEY"
DATA "!!!", "LDA (PTR),Y : TAX : INY : STX (PTR),Y : INY : STX (PTR),Y : DEY : DEY"
DATA "???", "LDA (PTR),Y : TAX : DEY : STX (PTR),Y : DEY : STX (PTR),Y : INY : INY"
DATA "!!>", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "??<", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "!!", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY"
DATA "??", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y : INY : INY"
DATA "!>", "LDA (PTR),Y : INY : STA (PTR),Y"
DATA "?<", "LDA (PTR),Y : DEY : STA (PTR),Y"
DATA "!?", "NOP ; Copy right then copy left (no change)"
DATA "0!", "LDA #0 : INY : STA (PTR),Y : DEY"
DATA "0?", "LDA #0 : DEY : STA (PTR),Y : INY"
DATA ">>!", "INY : INY : LDA (PTR),Y : DEY : DEY : STA (PTR),Y ; Deep copy"

' --- Aritmetik ve pointer folding ---
DATA "++++++", "LDA (PTR),Y : CLC : ADC #6 : STA (PTR),Y"
DATA "------", "LDA (PTR),Y : SEC : SBC #6 : STA (PTR),Y"
DATA ">>>>>>", "TYA : CLC : ADC #6 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<<", "TYA : SEC : SBC #6 : TAY : BCS *+4 : DEC PTR+1"

DATA "+++++", "LDA (PTR),Y : CLC : ADC #5 : STA (PTR),Y"
DATA "-----", "LDA (PTR),Y : SEC : SBC #5 : STA (PTR),Y"
DATA ">>>>>", "TYA : CLC : ADC #5 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<", "TYA : SEC : SBC #5 : TAY : BCS *+4 : DEC PTR+1"

DATA "++++", "LDA (PTR),Y : CLC : ADC #4 : STA (PTR),Y"
DATA "----", "LDA (PTR),Y : SEC : SBC #4 : STA (PTR),Y"
DATA ">>>>", "TYA : CLC : ADC #4 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<", "TYA : SEC : SBC #4 : TAY : BCS *+4 : DEC PTR+1"

DATA "+++", "LDA (PTR),Y : CLC : ADC #3 : STA (PTR),Y"
DATA "---", "LDA (PTR),Y : SEC : SBC #3 : STA (PTR),Y"
DATA ">>>", "TYA : CLC : ADC #3 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<", "TYA : SEC : SBC #3 : TAY : BCS *+4 : DEC PTR+1"

DATA "++", "LDA (PTR),Y : CLC : ADC #2 : STA (PTR),Y"
DATA "--", "LDA (PTR),Y : SEC : SBC #2 : STA (PTR),Y"
DATA ">>", "TYA : CLC : ADC #2 : TAY : BCC *+4 : INC PTR+1"
DATA "<<", "TYA : SEC : SBC #2 : TAY : BCS *+4 : DEC PTR+1"

' --- Sıfırlama / sabit değer patternleri ---
DATA "0++++", "LDA #4 : STA (PTR),Y"
DATA "0+++", "LDA #3 : STA (PTR),Y"
DATA "0++", "LDA #2 : STA (PTR),Y"
DATA "0+", "LDA #1 : STA (PTR),Y"
DATA "0-", "LDA #255 : STA (PTR),Y"
DATA "00", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : DEY"
DATA "0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y"

' --- Gelişmiş aritmetik / bitwise / sensör benzeri patternler ---
DATA "+&+", "LDA (PTR),Y : CLC : ADC #1 : STA $02 : INY : LDA (PTR),Y : ADC $02 : STA (PTR),Y : DEY"
DATA "++&", "LDA (PTR),Y : CLC : ADC #2 : STA $02 : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "&>", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "|>", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y"
DATA "&<", "LDA (PTR),Y : STA $02 : DEY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "|<", "LDA (PTR),Y : STA $02 : DEY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y"
DATA "0&", "LDA #0 : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y : DEY"
DATA "0|", "LDA #0 : SEC : SBC (PTR),Y : STA (PTR),Y ; Negate cell"
DATA "&&", "LDA (PTR),Y : ASL A : STA (PTR),Y ; Double / Shift Left"
DATA "||", "LDA (PTR),Y : LSR A : STA (PTR),Y ; Half / Shift Right"
DATA "^0", "LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1 : LDA #0 : STA (PTR),Y"
DATA "0^", "LDA #0 : STA (PTR),Y : LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1"

' --- Print / input / output patternleri ---
DATA "++.", "LDA (PTR),Y : CLC : ADC #2 : JSR $FFD2 : STA (PTR),Y"
DATA "--.", "LDA (PTR),Y : SEC : SBC #2 : JSR $FFD2 : STA (PTR),Y"
DATA ".0", "LDA (PTR),Y : JSR $FFD2 : LDA #0 : STA (PTR),Y"
DATA ",0", "JSR $FFCF : LDA #0 : STA (PTR),Y ; Read and discard"
DATA ",.", "JSR $FFCF : JSR $FFD2 : STA (PTR),Y ; Echo and store"
DATA ".>", "LDA (PTR),Y : JSR $FFD2 : INY : BNE *+4 : INC PTR+1"
DATA ",>", "JSR $FFCF : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA ".<", "LDA (PTR),Y : JSR $FFD2 : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA ",<", "JSR $FFCF : STA (PTR),Y : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA "..", "LDA (PTR),Y : JSR $FFD2 : JSR $FFD2 ; Double print"

' --- İptal / sadeleştirme patternleri ---
DATA "+-+-", "NOP ; Stabilization sequence"
DATA ">><<", "NOP ; Stabilization sequence"
DATA "++-", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y"
DATA "--+", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y"
DATA "+-", "NOP ; +1 then -1"
DATA "-+", "NOP ; -1 then +1"
DATA "<>", "NOP ; left then right"
DATA "><", "NOP ; right then left"

' --- Bilinçli olarak atlanacak / problemli pattern örnekleri ---
' Aşağıdakiler dengesiz bracket içerdiği için ALLOW_UNBALANCED_PATTERNS = 0 iken atlanır.
DATA "[-][", "LDA #0 : STA (PTR),Y : BEQ *+3 ; Force skip block"
DATA "0[", "LDA #0 : STA (PTR),Y : BEQ *+3 ; Optimized Skip"
DATA "[[", "LDA (PTR),Y : BEQ *+7 : LDA (PTR),Y : BEQ *+4 ; Nested zero check"
DATA "]]", "JMP * ; Placeholder for nested loop exit"

DATA "__END__", "__END__"
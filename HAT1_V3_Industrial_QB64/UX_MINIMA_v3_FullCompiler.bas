' =============================================================
' PROJECT      : UX-MINIMA INDUSTRIAL DATA-COMPILER v3.0
' ARCHITECTURE : Data-Driven Pattern Matching
' TARGET       : C64 / 6502 ASM Generator
' VERSION      : Merged + Deduplicated + ASM Optimized
' =============================================================
'
' TEMEL MANTIK:
' 1. Kaynak dosyadan sadece komut karakterleri lexer ile alınır.
' 2. Parser önce pattern bankasına bakar.
' 3. En uzun pattern önce denenir.
' 4. Aynı uzunlukta ise daha spesifik pattern önce denenir.
' 5. Pattern bulunamazsa tekil komut ASM'ye çevrilir.
'
' v3.0 DEĞİŞİKLİKLER:
' - 5 dosyadan patternler birleştirildi (142 benzersiz)
' - Tekrarlar kaldırıldı
' - ASM kodları optimize edildi:
'   * JSR $FFD2 A-clobber bugları düzeltildi (PHA/PLA)
'   * Gereksiz LDA #0'lar kaldırıldı (KERNAL rutinleri A'yi ignore eder)
'   * I/O kombinasyonları güvenli hale getirildi
' =============================================================

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
PRINT "--- UX-MINIMA INDUSTRIAL COMPILER v3.0 ---"
PRINT "--- Merged / Deduplicated / ASM Optimized ---"
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

' =============================================================
' PATTERN LOADER
' =============================================================

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

' =============================================================
' SPECIFICITY SCORE
' =============================================================
'
' En uzun pattern zaten birinci olcuttur.
' Ayni uzunlukta ise asagidaki puanlama kullanilir:
'
' - Bracket/loop idiomlari daha spesifik kabul edilir.
' - Meta cagrilar, stack/register benzeri patternler daha spesifiktir.
' - Cok farkli sembol iceren patternler tek sembol tekrarindan daha spesifiktir.
' - Sadece +++++ veya >>>>> gibi tekrar kaliplari daha genel kabul edilir.
'
' =============================================================

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
                score = score + 1000
            CASE "@"
                score = score + 500
            CASE "$", "%"
                score = score + 400
            CASE ".", ","
                score = score + 300
            CASE "!", "?"
                score = score + 250
            CASE "&", "|", "^"
                score = score + 200
            CASE "0"
                score = score + 150
            CASE ">", "<"
                score = score + 100
            CASE "+", "-"
                score = score + 50
            CASE ELSE
                score = score + 1
        END SELECT
    NEXT i

    score = score + uniqueChars * 30

    IF allSame <> 0 THEN
        score = score - 200
    END IF

    SpecificityScore = score
END FUNCTION

' =============================================================
' PATTERN SORT
' =============================================================
'
' PatternCompare:
'   - 1 donerse A, B'den once gelmeli.
'   - 0 donerse yerleri degismemeli.
'
' Siralama:
'   1. Daha uzun pattern once.
'   2. Ayni uzunlukta daha yuksek specificity once.
'   3. Hala esitse dosyada daha once yazilan once.
'
' =============================================================

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

' =============================================================
' STAGE 1: LEXER
' =============================================================

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

' =============================================================
' STAGE 2: PARSER / CODE GENERATOR
' =============================================================

SUB EmitHeader(ByVal outFF As Integer)
    PRINT #outFF, "; UX-MINIMA DATA-DRIVEN INDUSTRIAL RUNTIME v3.0"
    PRINT #outFF, "; Generated by merged/optimized pattern compiler"
    PRINT #outFF, "; Patterns: "; PatCount; " active"
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
            PRINT #outFF, "    "; AsmCode(pIdx); " ; [Pattern: "; Pat(pIdx); "]"
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

' =============================================================
' PATTERN DATA BANKASI - 142 BENZERSIZ PATTERN
' 5 kaynak dosyadan birlestirilmis, tekrarlar kaldirilmis,
' ASM kodlari optimize edilmis
' =============================================================
PatternData:

' 11 karakter: Ultra-spesifik multi-cell loop idiomlari
DATA "[->+>+<+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY"
DATA "[->+>+>+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY : DEY"

' 10 karakter: Uzun meta sistem + aritmetik
DATA "0++++++++@", "JSR $FFD5 ; KERNAL LOAD"
DATA ">>>>>>>>>>", "TYA : CLC : ADC #10 : TAY : BCC *+4 : INC PTR+1"
DATA "++++++++++", "LDA (PTR),Y : CLC : ADC #10 : STA (PTR),Y"
DATA "----------", "LDA (PTR),Y : SEC : SBC #10 : STA (PTR),Y"

' 9 karakter: Kompleks loop + blok + aritmetik
DATA "[->>>+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : INY : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY : DEY"
DATA "[->+>+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY"
DATA "[>+>+<<-]", "INY : LDA (PTR),Y : TAX : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY : LDA (PTR),Y : SEC : SBC (PTR),Y : STA (PTR),Y"
DATA "0>0>0>0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0+++++++@", "JSR $FFD8 ; KERNAL SAVE"
DATA ">>>>>>>>>", "TYA : CLC : ADC #9 : TAY : BCC *+4 : INC PTR+1"
DATA "+++++++++", "LDA (PTR),Y : CLC : ADC #9 : STA (PTR),Y"
DATA "---------", "LDA (PTR),Y : SEC : SBC #9 : STA (PTR),Y"

' 8 karakter: Gelişmis aritmetik + stabilizasyon
DATA "[<+>+>-]", "DEY : LDA (PTR),Y : TAX : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : LDA (PTR),Y : SEC : SBC (PTR),Y : STA (PTR),Y : DEY"
DATA "0++++++@", "JSR $E544 : JSR $E518 ; Full Clear+Home"
DATA "<<<<<<<<", "TYA : SEC : SBC #8 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>>>>", "TYA : CLC : ADC #8 : TAY : BCC *+4 : INC PTR+1"
DATA "++++++--", "LDA (PTR),Y : CLC : ADC #4 : STA (PTR),Y"
DATA "------++", "LDA (PTR),Y : SEC : SBC #4 : STA (PTR),Y"
DATA "++++++++", "LDA (PTR),Y : CLC : ADC #8 : STA (PTR),Y"
DATA "--------", "LDA (PTR),Y : SEC : SBC #8 : STA (PTR),Y"

' 7 karakter: Meta + blok + pointer
DATA "0+++++@", "JSR $E094 : AND #$0F : STA (PTR),Y ; Random nibble"
DATA "0>0>0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "<<<<<<<", "TYA : SEC : SBC #7 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>>>", "TYA : CLC : ADC #7 : TAY : BCC *+4 : INC PTR+1"

' 6 karakter: Loop idiomlari + meta
DATA "[-][+]", "LDA #0 : STA (PTR),Y"
DATA "[-<+>]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : DEY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY"
DATA "[->+<]", "LDA (PTR),Y : CLC : INY : ADC (PTR),Y : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[<+>-]", "DEY : LDA (PTR),Y : CLC : INY : ADC (PTR),Y : DEY : STA (PTR),Y : INY : LDA #0 : STA (PTR),Y"
DATA "[>+<-]", "INY : LDA (PTR),Y : CLC : DEY : ADC (PTR),Y : INY : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[-<->]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : DEY : TXA : STA (PTR),Y : INY"
DATA "[->-<]", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "$>$>$%", "LDA (PTR),Y : PHA : INY : LDA (PTR),Y : PHA : INY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : DEY : PLA : STA (PTR),Y : DEY : TXA : STA (PTR),Y"
DATA "0++++@", "JSR $E094 ; RND to Cell"
DATA "<<<<<<", "TYA : SEC : SBC #6 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>>", "TYA : CLC : ADC #6 : TAY : BCC *+4 : INC PTR+1"
DATA "++++++", "LDA (PTR),Y : CLC : ADC #6 : STA (PTR),Y"
DATA "------", "LDA (PTR),Y : SEC : SBC #6 : STA (PTR),Y"

' 5 karakter: Blok + stack + aritmetik
DATA "[<->]", "DEY : LDA (PTR),Y : TAX : INY : LDA (PTR),Y : STA (PTR),Y : DEY : TXA : STA (PTR),Y"
DATA "[-]<+", "LDA #0 : STA (PTR),Y : DEY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : INY"
DATA "[-]>+", "LDA #0 : STA (PTR),Y : INY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : DEY"
DATA "!!!!!", "LDA (PTR),Y : STA $02 : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY : DEY : DEY"
DATA "0!0!0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : DEY : INY : STA (PTR),Y"
DATA ". . .", "LDA (PTR),Y : JSR $FFD2 : LDA #$20 : JSR $FFD2 : LDA (PTR),Y : JSR $FFD2"
DATA "0+++@", "LDA #3 : JSR $E544"
DATA "0>!>0", "LDA #0 : STA (PTR),Y : INY : LDA (PTR),Y : INY : STA (PTR),Y : DEY : DEY"
DATA "0>0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "+&+&+", "LDA (PTR),Y : CLC : ADC #1 : STA $02 : INY : LDA (PTR),Y : ADC $02 : STA (PTR),Y : DEY"
DATA "++&++", "LDA (PTR),Y : CLC : ADC #4 : STA (PTR),Y"
DATA "--|--", "LDA (PTR),Y : SEC : SBC #4 : STA (PTR),Y"
DATA "0++++", "LDA #4 : STA (PTR),Y"
DATA "<<<<<", "TYA : SEC : SBC #5 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>", "TYA : CLC : ADC #5 : TAY : BCC *+4 : INC PTR+1"
DATA "+++++", "LDA (PTR),Y : CLC : ADC #5 : STA (PTR),Y"
DATA "-----", "LDA (PTR),Y : SEC : SBC #5 : STA (PTR),Y"

' 4 karakter: Temel folding + I/O + stack
DATA "[-]<", "LDA #0 : STA (PTR),Y : DEY : BCS *+4 : DEC PTR+1"
DATA "[-]>", "LDA #0 : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA "$<$%", "LDA (PTR),Y : PHA : DEY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : INY : STA (PTR),Y"
DATA "$>$%", "LDA (PTR),Y : PHA : INY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : DEY : STA (PTR),Y"
DATA "0$0%", "LDA #0 : STA (PTR),Y : PHA : INY : LDA #0 : STA (PTR),Y : PHA : DEY"
DATA "%<%<", "PLA : STA (PTR),Y : DEY : PLA : STA (PTR),Y : DEY"
DATA "$+$-", "LDA (PTR),Y : PHA : CLC : ADC #1 : STA (PTR),Y : SEC : SBC #2 : STA (PTR),Y : PLA"
DATA "!!!0", "LDA (PTR),Y : TAX : INY : STX (PTR),Y : INY : STX (PTR),Y : LDA #0 : STA (PTR),Y"
DATA ".0.0", "LDA (PTR),Y : PHA : JSR $FFD2 : PLA : LDA #0 : STA (PTR),Y : INY : LDA (PTR),Y : PHA : JSR $FFD2 : PLA : LDA #0 : STA (PTR),Y : DEY"
DATA "0+@>", "JSR $E544 : INY"
DATA "!!!>", "LDA (PTR),Y : TAX : INY : STX (PTR),Y : INY : STX (PTR),Y : INY : STX (PTR),Y"
DATA "???>", "LDA (PTR),Y : TAX : DEY : STX (PTR),Y : DEY : STX (PTR),Y : DEY : STX (PTR),Y"
DATA "0++@", "JSR $E518 ; HOME"
DATA "!!!!", "LDA (PTR),Y : STA $02 : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY : DEY"
DATA "+++@", "LDA #3 : JSR $E544"
DATA "0<<<", "LDA #0 : STA (PTR),Y : TYA : SEC : SBC #3 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>0", "TYA : CLC : ADC #3 : TAY : BCC *+4 : INC PTR+1 : LDA #0 : STA (PTR),Y"
DATA ">><<", "NOP"
DATA "0+++", "LDA #3 : STA (PTR),Y"
DATA "+-+-", "NOP"
DATA "++++", "LDA (PTR),Y : CLC : ADC #4 : STA (PTR),Y"
DATA "----", "LDA (PTR),Y : SEC : SBC #4 : STA (PTR),Y"

' 3 karakter: Kisa folding + I/O + bitwise
DATA "[<]", "DEY : LDA (PTR),Y : BEQ *+3"
DATA "[>]", "INY : LDA (PTR),Y : BEQ *+3"
DATA "[+]", "LDA #0 : STA (PTR),Y"
DATA "[-]", "LDA #0 : STA (PTR),Y"
DATA "@@.", "JSR $E544 : JSR $E518 : LDA (PTR),Y : JSR $FFD2"
DATA "@@@", "JSR $E544 : JSR $E518 : JSR $E544 ; Clear-Home-Clear"
DATA "$0%", "LDA (PTR),Y : PHA : LDA #0 : STA (PTR),Y : PLA : STA (PTR),Y"
DATA "0.@", "LDA #0 : STA (PTR),Y : JSR $FFD2 : JSR $E544"
DATA "0!@", "JSR $E544 : INY"
DATA "0..", "LDA #0 : STA (PTR),Y : JSR $FFD2 : LDA #0 : JSR $FFD2"
DATA "0+@", "JSR $E544 ; CLS"
DATA ",,,", "JSR $FFCF : STA (PTR),Y : INY : JSR $FFCF : STA (PTR),Y : INY : JSR $FFCF : STA (PTR),Y : DEY : DEY"
DATA "!!>", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "??<", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "0^^", "LDA #0 : STA (PTR),Y : LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1"
DATA "!!!", "LDA (PTR),Y : TAX : INY : STX (PTR),Y : INY : STX (PTR),Y : DEY : DEY"
DATA "0&0", "LDA #0 : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y : DEY"
DATA "0|0", "LDA #0 : SEC : SBC (PTR),Y : INY : STA (PTR),Y : DEY"
DATA "++.", "LDA (PTR),Y : CLC : ADC #2 : PHA : JSR $FFD2 : PLA : STA (PTR),Y"
DATA "--.", "LDA (PTR),Y : SEC : SBC #2 : PHA : JSR $FFD2 : PLA : STA (PTR),Y"
DATA "0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y"
DATA "&&&", "LDA (PTR),Y : ASL A : ASL A : STA (PTR),Y"
DATA "|||", "LDA (PTR),Y : LSR A : LSR A : STA (PTR),Y"
DATA "+&+", "LDA (PTR),Y : CLC : ADC #1 : STA $02 : INY : LDA (PTR),Y : ADC $02 : STA (PTR),Y : DEY"
DATA "++&", "LDA (PTR),Y : CLC : ADC #2 : STA $02 : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "0++", "LDA #2 : STA (PTR),Y"
DATA "<<<", "TYA : SEC : SBC #3 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>", "TYA : CLC : ADC #3 : TAY : BCC *+4 : INC PTR+1"

' 2 karakter: Minimal folding + stabilizasyon
DATA "@.", "LDA (PTR),Y : JSR $FFD2"
DATA "@@", "JSR $E544 : JSR $E518 ; Clear and Home"
DATA "0@", "JSR $E544 ; CLS"
DATA "@0", "JSR $E544 : STA (PTR),Y"
DATA ",.", "JSR $FFCF : PHA : JSR $FFD2 : PLA : STA (PTR),Y"
DATA ".,", "LDA (PTR),Y : PHA : JSR $FFD2 : PLA : JSR $FFCF : STA (PTR),Y"
DATA "@>", "LDA (PTR),Y : JSR $E094 : INY : STA (PTR),Y"
DATA "0$", "LDA #0 : STA (PTR),Y : PHA"
DATA "$>", "LDA (PTR),Y : PHA : INY : BNE *+4 : INC PTR+1"
DATA "<%", "TYA : BNE *+4 : DEC PTR+1 : DEY : PLA : STA (PTR),Y"
DATA "+$", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : PHA"
DATA "-$", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y : PHA"
DATA ".0", "LDA (PTR),Y : PHA : JSR $FFD2 : PLA : LDA #0 : STA (PTR),Y"
DATA ",<", "JSR $FFCF : STA (PTR),Y : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA ",>", "JSR $FFCF : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA ".<", "LDA (PTR),Y : JSR $FFD2 : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA ".>", "LDA (PTR),Y : JSR $FFD2 : INY : BNE *+4 : INC PTR+1"
DATA "..", "LDA (PTR),Y : PHA : JSR $FFD2 : PLA : PHA : JSR $FFD2 : PLA"
DATA "!>", "LDA (PTR),Y : INY : STA (PTR),Y"
DATA "0&", "LDA #0 : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y : DEY"
DATA "0^", "LDA #0 : STA (PTR),Y : LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1"
DATA "0|", "LDA #0 : SEC : SBC (PTR),Y : STA (PTR),Y"
DATA "?<", "LDA (PTR),Y : DEY : STA (PTR),Y"
DATA "^0", "LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1 : LDA #0 : STA (PTR),Y"
DATA "!!", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY"
DATA "0+", "LDA #1 : STA (PTR),Y"
DATA "0-", "LDA #255 : STA (PTR),Y"
DATA "&&", "LDA (PTR),Y : ASL A : STA (PTR),Y"
DATA "^^", "LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1"
DATA "||", "LDA (PTR),Y : LSR A : STA (PTR),Y"
DATA "00", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : DEY"
DATA "<<", "TYA : SEC : SBC #2 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>", "TYA : CLC : ADC #2 : TAY : BCC *+4 : INC PTR+1"
DATA "++", "LDA (PTR),Y : CLC : ADC #2 : STA (PTR),Y"
DATA "--", "LDA (PTR),Y : SEC : SBC #2 : STA (PTR),Y"

DATA "__END__", "__END__"

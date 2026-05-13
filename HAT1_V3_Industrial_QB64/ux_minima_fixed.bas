 ' *****************************************************************
' PROJECT: UX-MINIMA INDUSTRIAL DATA-COMPILER
' ARCHITECTURE: Data-Driven Pattern Matching
' FIXED VERSION: safer loader + longest-pattern greedy match
' *****************************************************************

OPTION EXPLICIT

CONST MAX_TOKENS = 50000
CONST MAX_PATTERNS = 512
CONST MAX_LOOP_STACK = 256
CONST COMMAND_CHARS = "><+-0!?.,[]&|^$%@"
CONST ALLOW_UNBALANCED_PATTERNS = 0

DECLARE SUB LoadPatterns()
DECLARE SUB AddPattern(ByRef rawPat As String, ByRef rawAsm As String)
DECLARE SUB SortPatternsByLengthDesc()
DECLARE SUB Lexer()
DECLARE SUB IndustrialParser()
DECLARE SUB CompileError(ByRef msg As String)
DECLARE FUNCTION NormalizePattern(ByRef s As String) As String
DECLARE FUNCTION PatternIsBalanced(ByRef s As String) As Integer
DECLARE FUNCTION MatchPattern(ByVal startIdx As Integer) As Integer

DIM SHARED Tokens(1 TO MAX_TOKENS) AS STRING
DIM SHARED TokenCount AS Integer

DIM SHARED LStack(1 TO MAX_LOOP_STACK) AS Integer
DIM SHARED LPtr AS Integer
DIM SHARED LCount AS Integer

DIM SHARED Pat(1 TO MAX_PATTERNS) AS STRING
DIM SHARED AsmCode(1 TO MAX_PATTERNS) AS STRING
DIM SHARED PatCount AS Integer
DIM SHARED WarningCount AS Integer

DIM SHARED Src AS STRING
DIM SHARED InFileName AS STRING
DIM SHARED OutFileName AS STRING
DIM SHARED HadError AS Integer

CLS
PRINT "--- UX-MINIMA INDUSTRIAL COMPILER (Data-Driven / Fixed) ---"

LoadPatterns
PRINT "Aktif pattern sayisi: "; PatCount; "  Uyari: "; WarningCount

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

IF HadError <> 0 THEN
    PRINT "Derleme hatali tamamlandi. Once HATA satirlarini duzelt."
ELSE
    PRINT "Derleme tamamlandi: "; OutFileName
END IF

END

' --- PATTERN LOADER ---
SUB LoadPatterns()
    DIM rawPat AS String
    DIM rawAsm AS String

    RESTORE PatternData
    DO
        READ rawPat, rawAsm
        IF rawPat = "__END__" THEN EXIT DO
        AddPattern rawPat, rawAsm
    LOOP

    SortPatternsByLengthDesc
END SUB

SUB AddPattern(ByRef rawPat As String, ByRef rawAsm As String)
    DIM p AS String
    DIM i AS Integer

    p = NormalizePattern(rawPat)
    IF LEN(p) = 0 THEN EXIT SUB

    IF ALLOW_UNBALANCED_PATTERNS = 0 THEN
        IF PatternIsBalanced(p) = 0 THEN
            WarningCount = WarningCount + 1
            PRINT "UYARI: Dengesiz bracket iceren pattern atlandi: "; rawPat
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
END SUB

FUNCTION NormalizePattern(ByRef s As String) As String
    DIM i AS Integer
    DIM ch AS String
    DIM r AS String

    r = ""
    FOR i = 1 TO LEN(s)
        ch = MID(s, i, 1)
        IF ch <> " " AND ch <> CHR(9) THEN r = r + ch
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

    IF bal = 0 THEN PatternIsBalanced = 1 ELSE PatternIsBalanced = 0
END FUNCTION

SUB SortPatternsByLengthDesc()
    DIM swapped AS Integer
    DIM i AS Integer
    DIM tp AS String
    DIM ta AS String

    IF PatCount <= 1 THEN EXIT SUB

    DO
        swapped = 0
        FOR i = 1 TO PatCount - 1
            IF LEN(Pat(i)) < LEN(Pat(i + 1)) THEN
                tp = Pat(i): ta = AsmCode(i)
                Pat(i) = Pat(i + 1): AsmCode(i) = AsmCode(i + 1)
                Pat(i + 1) = tp: AsmCode(i + 1) = ta
                swapped = 1
            END IF
        NEXT i
    LOOP WHILE swapped <> 0
END SUB

SUB CompileError(ByRef msg As String)
    HadError = 1
    PRINT "HATA: "; msg
END SUB

' --- STAGE 1: LEXER ---
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

' --- STAGE 2: INDUSTRIAL PARSER / CODE GENERATOR ---
SUB IndustrialParser()
    DIM outFF AS Integer
    DIM i AS Integer
    DIM pIdx AS Integer
    DIM cmd AS String
    DIM labelId AS Integer

    IF HadError <> 0 THEN EXIT SUB

    outFF = FREEFILE
    OPEN OutFileName FOR OUTPUT AS #outFF

    PRINT #outFF, "; UX-MINIMA DATA-DRIVEN INDUSTRIAL RUNTIME"
    PRINT #outFF, "; Generated by fixed pattern compiler"
    PRINT #outFF, "PTR = $FB : MEM = $2000 : ORG $0801"
    PRINT #outFF, "    BYTE $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$31,$00,$00,$00"
    PRINT #outFF, "    LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1 : LDY #0"

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
                    PRINT #outFF, "    INY : BNE *+4 : INC PTR+1"
                CASE "<"
                    PRINT #outFF, "    TYA : BNE *+4 : DEC PTR+1 : DEY"
                CASE "+"
                    PRINT #outFF, "    LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y"
                CASE "-"
                    PRINT #outFF, "    LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y"
                CASE "0"
                    PRINT #outFF, "    LDA #0 : STA (PTR),Y"
                CASE "."
                    PRINT #outFF, "    LDA (PTR),Y : JSR $FFD2"
                CASE ","
                    PRINT #outFF, "    JSR $FFCF : STA (PTR),Y"
                CASE "["
                    IF LPtr >= MAX_LOOP_STACK THEN
                        CompileError "Loop stack doldu. Cok fazla ic ice '[' var."
                    ELSE
                        LCount = LCount + 1
                        LPtr = LPtr + 1
                        LStack(LPtr) = LCount
                        PRINT #outFF, "L"; LTRIM(STR(LCount)); ":"
                        PRINT #outFF, "    LDA (PTR),Y : BEQ E"; LTRIM(STR(LCount))
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
                    PRINT #outFF, "    LDA (PTR),Y : CMP #1 : BNE *+5 : JSR $E544"
                    PRINT #outFF, "    CMP #4 : BNE *+5 : JSR $E094"
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

    PRINT #outFF, "    RTS"
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

' --- PATTERN DATA BANKASI ---
PatternData:
DATA "[-]", "LDA #0 : STA (PTR),Y"
DATA "[->+<]", "LDA (PTR),Y : CLC : INY : ADC (PTR),Y : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA ">>", "TYA : CLC : ADC #2 : TAY : BCC *+4 : INC PTR+1"
DATA "<<", "TYA : SEC : SBC #2 : TAY : BCS *+4 : DEC PTR+1"
DATA "++", "LDA (PTR),Y : CLC : ADC #2 : STA (PTR),Y"
DATA "--", "LDA (PTR),Y : SEC : SBC #2 : STA (PTR),Y"
DATA "0+@", "JSR $E544 ; [Meta: CLS via Pattern]"
DATA "++", "LDA (PTR),Y : CLC : ADC #2 : STA (PTR),Y"
DATA "+++", "LDA (PTR),Y : CLC : ADC #3 : STA (PTR),Y"
DATA "++++", "LDA (PTR),Y : CLC : ADC #4 : STA (PTR),Y"
DATA "--", "LDA (PTR),Y : SEC : SBC #2 : STA (PTR),Y"
DATA "---", "LDA (PTR),Y : SEC : SBC #3 : STA (PTR),Y"
DATA "----", "LDA (PTR),Y : SEC : SBC #4 : STA (PTR),Y"
DATA ">>", "TYA : CLC : ADC #2 : TAY : BCC *+4 : INC PTR+1"
DATA "<<", "TYA : SEC : SBC #2 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>", "TYA : CLC : ADC #3 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<", "TYA : SEC : SBC #3 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>", "TYA : CLC : ADC #4 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<", "TYA : SEC : SBC #4 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>", "TYA : CLC : ADC #5 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<", "TYA : SEC : SBC #5 : TAY : BCS *+4 : DEC PTR+1"
DATA ">>>>>>", "TYA : CLC : ADC #6 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<<", "TYA : SEC : SBC #6 : TAY : BCS *+4 : DEC PTR+1"
DATA "[-]", "LDA #0 : STA (PTR),Y"
DATA "[+]", "LDA #0 : STA (PTR),Y"
DATA "[->+<]", "LDA (PTR),Y : CLC : INY : ADC (PTR),Y : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[->-<]", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[>+<-]", "INY : LDA (PTR),Y : CLC : DEY : ADC (PTR),Y : INY : STA (PTR),Y : DEY : LDA #0 : STA (PTR),Y"
DATA "[<+>-]", "DEY : LDA (PTR),Y : CLC : INY : ADC (PTR),Y : DEY : STA (PTR),Y : INY : LDA #0 : STA (PTR),Y"
DATA "[->+>+<<]", "LDA (PTR),Y : TAX : LDA #0 : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : INY : TXA : CLC : ADC (PTR),Y : STA (PTR),Y : DEY : DEY"
DATA "[-]>", "LDA #0 : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA "$%", "NOP ; redundant push/pull"
DATA "$>", "LDA (PTR),Y : PHA : INY : BNE *+4 : INC PTR+1"
DATA "<%", "TYA : BNE *+4 : DEC PTR+1 : DEY : PLA : STA (PTR),Y"
DATA "$+", "LDA (PTR),Y : PHA : CLC : ADC #1 : STA (PTR),Y"
DATA "$-", "LDA (PTR),Y : PHA : SEC : SBC #1 : STA (PTR),Y"
DATA "+$", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : PHA"
DATA "-$", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y : PHA"
DATA "0$", "LDA #0 : STA (PTR),Y : PHA"
DATA "0+@", "JSR $E544 ; CLS"
DATA "0++++@", "JSR $E094 ; RND to Cell"
DATA "0++@", "JSR $E518 ; HOME"
DATA ".>", "LDA (PTR),Y : JSR $FFD2 : INY : BNE *+4 : INC PTR+1"
DATA ",>", "JSR $FFCF : STA (PTR),Y : INY : BNE *+4 : INC PTR+1"
DATA ".<", "LDA (PTR),Y : JSR $FFD2 : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA ",<", "JSR $FFCF : STA (PTR),Y : TYA : BNE *+4 : DEC PTR+1 : DEY"
DATA "0.@", "LDA #0 : STA (PTR),Y : JSR $FFD2 : JSR $E544"
DATA "00", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : DEY"
DATA "0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "!!", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY"
DATA "??", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y : INY : INY"
DATA "!>", "LDA (PTR),Y : INY : STA (PTR),Y"
DATA "?<", "LDA (PTR),Y : DEY : STA (PTR),Y"
DATA "!?", "NOP ; Copy right then copy left (no change)"
DATA "0-", "LDA #255 : STA (PTR),Y"
DATA "+-", "NOP ; +1 then -1"
DATA "-+", "NOP ; -1 then +1"
DATA "<>", "NOP ; left then right"
DATA "><", "NOP ; right then left"
DATA "++-", "LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y"
DATA "--+", "LDA (PTR),Y : SEC : SBC #1 : STA (PTR),Y"
DATA "0+", "LDA #1 : STA (PTR),Y"
DATA "&>", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "|>", "LDA (PTR),Y : STA $02 : INY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y"
DATA "&<", "LDA (PTR),Y : STA $02 : DEY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "|<", "LDA (PTR),Y : STA $02 : DEY : LDA (PTR),Y : SEC : SBC $02 : STA (PTR),Y"
DATA "++.", "LDA (PTR),Y : CLC : ADC #2 : JSR $FFD2 : STA (PTR),Y"
DATA "--.", "LDA (PTR),Y : SEC : SBC #2 : JSR $FFD2 : STA (PTR),Y"
DATA "0@", "LDA #0 : JSR $E544 ; ID 0 is also CLS"
DATA "^0", "LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1 : LDA #0 : STA (PTR),Y"
DATA "+++++", "LDA (PTR),Y : CLC : ADC #5 : STA (PTR),Y"
DATA "-----", "LDA (PTR),Y : SEC : SBC #5 : STA (PTR),Y"
DATA ">>>>>", "TYA : CLC : ADC #5 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<", "TYA : SEC : SBC #5 : TAY : BCS *+4 : DEC PTR+1"
DATA "+&+", "LDA (PTR),Y : CLC : ADC #1 : STA $02 : INY : LDA (PTR),Y : ADC $02 : STA (PTR),Y : DEY"
DATA "[-]>+", "LDA #0 : STA (PTR),Y : INY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : DEY"
DATA "[-]<+", "LDA #0 : STA (PTR),Y : DEY : LDA (PTR),Y : CLC : ADC #1 : STA (PTR),Y : INY"
DATA "0&", "LDA #0 : STA $02 : INY : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y : DEY"
DATA "0.@", "LDA #0 : STA (PTR),Y : JSR $FFD2 ; Null terminate and print"
DATA "+++@", "LDA #3 : JSR $E544 ; Specific ROM Clear/Color Call"
DATA "!!>", "LDA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "??<", "LDA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA ". .", "LDA (PTR),Y : JSR $FFD2 : LDA #$20 : JSR $FFD2 ; Print char and space"
DATA "..", "LDA (PTR),Y : JSR $FFD2 : JSR $FFD2 ; Double print"
DATA "!!!", "LDA (PTR),Y : TAX : INY : STX (PTR),Y : INY : STX (PTR),Y : DEY : DEY"
DATA "???", "LDA (PTR),Y : TAX : DEY : STX (PTR),Y : DEY : STX (PTR),Y : INY : INY"
DATA "[-][", "LDA #0 : STA (PTR),Y : BEQ *+3 ; Force skip block"
DATA "0[", "LDA #0 : STA (PTR),Y : BEQ *+3 ; Optimized Skip"
DATA "0+", "LDA #1 : STA (PTR),Y"
DATA "0++", "LDA #2 : STA (PTR),Y"
DATA "0+++", "LDA #3 : STA (PTR),Y"
DATA "0++++", "LDA #4 : STA (PTR),Y"
DATA "[<]>", "LDY #0 ; Search back to start of page/boundary"
DATA "[>]<", "LDY #$FF ; Search forward to end of page"
DATA "$>$%", "LDA (PTR),Y : PHA : INY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : DEY : STA (PTR),Y"
DATA "$<$%", "LDA (PTR),Y : PHA : DEY : LDA (PTR),Y : TAX : PLA : STA (PTR),Y : TXA : INY : STA (PTR),Y"
DATA "$+$%", "LDA (PTR),Y : PHA : CLC : ADC #1 : TAX : PLA : STA (PTR),Y ; Inc and restore"
DATA "$$%%", "LDA (PTR),Y : PHA : PHA : PLA : PLA ; Redundant stack"
DATA "$0%", "LDA (PTR),Y : PHA : LDA #0 : STA (PTR),Y : PLA : STA (PTR),Y ; Clear with backup"
DATA "%$", "LDA (PTR),Y : PHA : PLA : STA (PTR),Y ; Redundant"
DATA "+%", "LDA (PTR),Y : CLC : ADC #1 : PHA : PLA : STA (PTR),Y"
DATA "-%", "LDA (PTR),Y : SEC : SBC #1 : PHA : PLA : STA (PTR),Y"
DATA "0+++++@", "JSR $E094 : AND #$0F : STA (PTR),Y ; Random nibble for sensor simulation"
DATA "@.", "LDA (PTR),Y : JSR $FFD2 ; Direct meta result print"
DATA "@>", "LDA (PTR),Y : JSR $E094 : INY : STA (PTR),Y ; Meta call then store in next cell"
DATA ",.", "JSR $FFCF : JSR $FFD2 : STA (PTR),Y ; Echo and store"
DATA "0|", "LDA #0 : SEC : SBC (PTR),Y : STA (PTR),Y ; Negate cell"
DATA "&&", "LDA (PTR),Y : ASL A : STA (PTR),Y ; Double (Shift Left)"
DATA "||", "LDA (PTR),Y : LSR A : STA (PTR),Y ; Half (Shift Right)"
DATA "++&", "LDA (PTR),Y : CLC : ADC #2 : STA $02 : LDA (PTR),Y : CLC : ADC $02 : STA (PTR),Y"
DATA "0>0>0", "LDA #0 : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y"
DATA "0<0<0", "LDA #0 : STA (PTR),Y : DEY : STA (PTR),Y : DEY : STA (PTR),Y"
DATA "!!!!", "LDA (PTR),Y : STA $02 : INY : STA (PTR),Y : INY : STA (PTR),Y : INY : STA (PTR),Y : DEY : DEY : DEY"
DATA "++++++", "LDA (PTR),Y : CLC : ADC #6 : STA (PTR),Y"
DATA "------", "LDA (PTR),Y : SEC : SBC #6 : STA (PTR),Y"
DATA ">>>>>>", "TYA : CLC : ADC #6 : TAY : BCC *+4 : INC PTR+1"
DATA "<<<<<<", "TYA : SEC : SBC #6 : TAY : BCS *+4 : DEC PTR+1"
DATA "0+@>", "JSR $E544 : INY ; Clear screen and move to next buffer"
DATA "0!", "LDA #0 : INY : STA (PTR),Y : DEY"
DATA "0?", "LDA #0 : DEY : STA (PTR),Y : INY"
DATA "[@]", "LDA (PTR),Y : BEQ *+5 : JSR $FFD2 ; Conditional ROM call"
DATA "[[", "LDA (PTR),Y : BEQ *+7 : LDA (PTR),Y : BEQ *+4 ; Nested zero check"
DATA "]]", "JMP * ; Placeholder for nested loop exit"
DATA "+-+-", "NOP ; Stabilization sequence"
DATA ">><<", "NOP ; Stabilization sequence"
DATA ">>!", "INY : INY : LDA (PTR),Y : DEY : DEY : STA (PTR),Y ; Deep copy"
DATA "0+++++++@", "JSR $FFD8 ; KERNAL SAVE (Example)"
DATA "0++++++++@", "JSR $FFD5 ; KERNAL LOAD (Example)"
DATA "0^", "LDA #0 : STA (PTR),Y : LDA #<MEM : STA PTR : LDA #>MEM : STA PTR+1"
DATA "0$", "LDA #0 : PHA"
DATA "0%", "PLA : LDA #0"
DATA ".0", "LDA (PTR),Y : JSR $FFD2 : LDA #0 : STA (PTR),Y"
DATA ",0", "JSR $FFCF : LDA #0 : STA (PTR),Y ; Read and discard"
DATA "@@", "JSR $E544 : JSR $E518 ; Clear and Home"
DATA "__END__", "__END__"

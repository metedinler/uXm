Evet Mete abi, **QB64’de `DATA`, `READ`, `RESTORE` var**. Bu yüzden PDS 7.1’e dönmeye gerek yok. QB64 belgelerinde `DATA` alanlarının `READ` ile okunabildiği, `RESTORE label` ile belirli DATA bölümüne geri dönülebildiği yazıyor; ayrıca önemli uyarı olarak DATA alanlarını `SUB` / `FUNCTION` bloklarından sonra koymamak gerektiği belirtiliyor. O yüzden aşağıdaki kodda `DATA` tablolarını **ana program alanında, `END` satırından önce** verdim. ([QB64.com][1])

Aşağıdaki tasarım **UXM-64K V3 DATA/READ tabanlı compiler iskeleti** gibi düşünülmeli. V3 dememin sebebi dilin “komut tablosu + pattern tablosu + ASM emitter” olarak ayrılmasıdır. Inline uXBasic yok; bağımsız `.uxm` → `.asm` compiler.

```basic
' *****************************************************************
' PROJECT      : UXM-64K V3 COMPILER - QB64 DATA/READ VERSION
' HOST         : QB64 / QB64PE
' TARGET       : Windows x64 NASM ASM
' INPUT        : .uxm / .txt
' OUTPUT       : .asm
'
' V3 DESIGN:
'   - Command table is loaded from DATA / READ.
'   - Pattern optimizer table is loaded from DATA / READ.
'   - 64 KB UXM memory pool:
'       ux_mem = tape + stack + data
'   - Tape / Stack / Data sizes are user configurable.
'
' NOTE:
'   DATA blocks are deliberately placed before END and before SUB/FUNCTIONs.
'   QB64 documentation warns against placing DATA fields after SUB/FUNCTIONs.
' *****************************************************************

OPTION _EXPLICIT

CONST UXM_TOTAL_BYTES = 65536

CONST MAX_TOKENS = 400000
CONST MAX_COMMANDS = 64
CONST MAX_PATTERNS = 4096
CONST MAX_LOOP_STACK = 4096
CONST MAX_STRINGS = 1024
CONST MAX_REPEAT_COUNT = 1000000

CONST ACT_NOP = 0
CONST ACT_ADD_CUR = 1
CONST ACT_SUB_CUR = 2
CONST ACT_MOVE_PTR = 3
CONST ACT_CLEAR_CUR = 4
CONST ACT_SET_CUR = 5
CONST ACT_META_CONST = 6
CONST ACT_MOVE_ADD_RIGHT_CLEAR = 7
CONST ACT_MOVE_ADD_LEFT_CLEAR = 8

CONST OV_WRAP = 0
CONST OV_CHECK = 1

CONST CMP_EQ = 1
CONST CMP_GT = 2
CONST CMP_LT = 3

CONST BIN_AND = 1
CONST BIN_OR = 2
CONST BIN_XOR = 3

DECLARE SUB LoadCommandTable ()
DECLARE SUB LoadPatternTable ()
DECLARE SUB SortPatternsByPriority ()

DECLARE SUB AskOptions ()
DECLARE SUB ReadSourceFile ()
DECLARE SUB Lexer ()
DECLARE SUB AddToken (t AS STRING)
DECLARE SUB AddRepeatedToken (c AS STRING, countVal AS LONG)
DECLARE SUB SkipLine (pos AS LONG)
DECLARE SUB SkipSpaces (pos AS LONG)

DECLARE SUB AddStringDecl (sid AS LONG, startCell AS _UNSIGNED LONG, txt AS STRING)

DECLARE SUB GenerateASM ()
DECLARE SUB EmitHeader ()
DECLARE SUB EmitFooter ()
DECLARE SUB EmitLine (s AS STRING)
DECLARE SUB EmitStringInitializers ()
DECLARE SUB EmitPattern (pIdx AS LONG)
DECLARE SUB EmitSingleToken (t AS STRING)

DECLARE SUB EmitPointerCheck ()
DECLARE SUB EmitNeighborCheck (offCells AS LONG)
DECLARE SUB EmitMovePtr (delta AS LONG)
DECLARE SUB EmitSetCell (offCells AS LONG, value AS _UNSIGNED _INTEGER64)
DECLARE SUB EmitClearCell (offCells AS LONG)
DECLARE SUB EmitAddCell (offCells AS LONG, amount AS _UNSIGNED _INTEGER64)
DECLARE SUB EmitSubCell (offCells AS LONG, amount AS _UNSIGNED _INTEGER64)
DECLARE SUB EmitPutChar ()
DECLARE SUB EmitGetChar ()
DECLARE SUB EmitMetaFromCell ()
DECLARE SUB EmitMetaConst (metaId AS LONG)
DECLARE SUB EmitPushCell ()
DECLARE SUB EmitPopCell ()
DECLARE SUB EmitCompare (cmpMode AS LONG)
DECLARE SUB EmitBinaryBitwise (opMode AS LONG)
DECLARE SUB EmitNotCell ()
DECLARE SUB EmitShiftLeft ()
DECLARE SUB EmitShiftRight ()
DECLARE SUB EmitMoveAddClear (offCells AS LONG)
DECLARE SUB EmitLoopStart ()
DECLARE SUB EmitLoopEnd ()
DECLARE SUB EmitPrintStringById (sid AS LONG)

DECLARE SUB CompileError (msg AS STRING)

DECLARE FUNCTION DefaultASMName$ (srcName AS STRING)
DECLARE FUNCTION IsDigitChar% (c AS STRING)
DECLARE FUNCTION TryParseStringDecl% (pos AS LONG)
DECLARE FUNCTION TryParsePrintString% (pos AS LONG)
DECLARE FUNCTION ParseUnsignedNumber&& (pos AS LONG, ok AS LONG)
DECLARE FUNCTION ParseBracedString$ (pos AS LONG, ok AS LONG)
DECLARE FUNCTION FindStringIndexById% (sid AS LONG)

DECLARE FUNCTION IsTokenPrintString% (t AS STRING)
DECLARE FUNCTION PrintStringIdFromToken% (t AS STRING)

DECLARE FUNCTION RepeatChar$ (ch AS STRING, n AS LONG)
DECLARE FUNCTION NormalizePattern$ (s AS STRING)
DECLARE FUNCTION PatternIsBalanced% (s AS STRING)
DECLARE FUNCTION SpecificityScore% (p AS STRING)
DECLARE FUNCTION PatternCompare% (a AS LONG, b AS LONG)
DECLARE FUNCTION MatchPattern% (startIdx AS LONG)

DECLARE FUNCTION SizePrefix$ ()
DECLARE FUNCTION StoreReg$ ()
DECLARE FUNCTION MaxValueText$ ()
DECLARE FUNCTION ReduceValue&& (v AS _UNSIGNED _INTEGER64)
DECLARE FUNCTION IndexExpr$ (baseReg AS STRING, indexReg AS STRING, offCells AS LONG)
DECLARE FUNCTION CellOp$ (offCells AS LONG)
DECLARE FUNCTION StackOp$ ()
DECLARE FUNCTION DataByteOffset&& (cellNo AS _UNSIGNED LONG)
DECLARE FUNCTION DataCellOpConst$ (cellNo AS _UNSIGNED LONG)
DECLARE FUNCTION CommandChars$ ()

DIM SHARED Src AS STRING
DIM SHARED InFileName AS STRING
DIM SHARED OutASMName AS STRING

DIM SHARED Tokens(1 TO MAX_TOKENS) AS STRING
DIM SHARED TokenCount AS LONG

DIM SHARED CmdSymbol(1 TO MAX_COMMANDS) AS STRING
DIM SHARED CmdName(1 TO MAX_COMMANDS) AS STRING
DIM SHARED CmdRole(1 TO MAX_COMMANDS) AS STRING
DIM SHARED CommandCount AS LONG

DIM SHARED Pat(1 TO MAX_PATTERNS) AS STRING
DIM SHARED PatAction(1 TO MAX_PATTERNS) AS LONG
DIM SHARED PatArg(1 TO MAX_PATTERNS) AS LONG
DIM SHARED PatPriority(1 TO MAX_PATTERNS) AS LONG
DIM SHARED PatOrder(1 TO MAX_PATTERNS) AS LONG
DIM SHARED PatCount AS LONG

DIM SHARED LoopStack(1 TO MAX_LOOP_STACK) AS LONG
DIM SHARED LoopSP AS LONG
DIM SHARED LoopCount AS LONG

DIM SHARED StrId(1 TO MAX_STRINGS) AS LONG
DIM SHARED StrStartCell(1 TO MAX_STRINGS) AS _UNSIGNED LONG
DIM SHARED StrText(1 TO MAX_STRINGS) AS STRING
DIM SHARED StrCount AS LONG

DIM SHARED OutFF AS LONG
DIM SHARED HadError AS LONG
DIM SHARED WarningCount AS LONG

DIM SHARED CellBits AS LONG
DIM SHARED CellBytes AS LONG

DIM SHARED TapeBytes AS _UNSIGNED LONG
DIM SHARED StackBytes AS _UNSIGNED LONG
DIM SHARED DataBytes AS _UNSIGNED LONG

DIM SHARED TapeCells AS _UNSIGNED LONG
DIM SHARED StackCells AS _UNSIGNED LONG
DIM SHARED DataCells AS _UNSIGNED LONG

DIM SHARED StackOffsetBytes AS _UNSIGNED LONG
DIM SHARED DataOffsetBytes AS _UNSIGNED LONG

DIM SHARED BoundsCheck AS LONG
DIM SHARED OverflowMode AS LONG

CLS
PRINT "=============================================================="
PRINT " UXM-64K V3 COMPILER - QB64 DATA/READ VERSION"
PRINT " QB64 host -> Windows x64 NASM ASM"
PRINT "=============================================================="
PRINT

LoadCommandTable
LoadPatternTable
AskOptions

IF HadError = 0 THEN ReadSourceFile
IF HadError = 0 THEN Lexer
IF HadError = 0 THEN GenerateASM

PRINT

IF HadError <> 0 THEN
    PRINT "Derleme hatali bitti."
ELSE
    PRINT "ASM uretildi: "; OutASMName
    PRINT
    PRINT "NASM:"
    PRINT "  nasm -f win64 "; OutASMName; " -o build.obj"
    PRINT
    PRINT "FreeBASIC runtime ile link:"
    PRINT "  fbc uxm64_runtime.bas build.obj -x program.exe"
END IF

' *****************************************************************
' DATA TABLES
' DATA blocks must stay before END and before SUB/FUNCTION blocks.
' *****************************************************************

CommandData:
DATA 26
DATA ">", "MOVE_RIGHT", "Tape pointer one cell right"
DATA "<", "MOVE_LEFT", "Tape pointer one cell left"
DATA "+", "INC", "Increase current cell"
DATA "-", "DEC", "Decrease current cell"
DATA "0", "CLEAR", "Set current cell to zero"
DATA ".", "PUTC", "Print current cell as character"
DATA ",", "GETC", "Read one character into current cell"
DATA "[", "LOOP_BEGIN", "Loop or conditional block begin"
DATA "]", "LOOP_END", "Loop block end"
DATA "$", "PUSH", "Push current cell to UXM stack"
DATA "%", "POP", "Pop UXM stack into current cell"
DATA "?", "EQ", "Compare stack top equal current"
DATA "!", "GT", "Compare stack top greater than current"
DATA ";", "LT", "Compare stack top less than current"
DATA "&", "AND", "Bitwise AND stack top with current"
DATA "|", "OR", "Bitwise OR stack top with current"
DATA "^", "XOR", "Bitwise XOR stack top with current"
DATA "~", "NOT", "Bitwise NOT current cell"
DATA "@", "META", "Runtime or meta service call"
DATA "sN", "STRING_DEF", "String definition directive"
DATA "pN", "STRING_PRINT", "Print string directive"
DATA "kN", "REPEAT", "Repeat macro after a command"
DATA "#", "COMMENT", "Line comment"
DATA ":", "LABEL_RESERVED", "Reserved for future label or separator"
DATA "{", "SHL", "Shift left current cell"
DATA "}", "SHR", "Shift right current cell"

PatternData:
DATA "[->+<]", 7, 1
DATA "[>+<-]", 7, 1
DATA "[<+>-]", 8, -1
DATA "[-]", 4, 0
DATA "[+]", 4, 0
DATA "$%", 0, 0
DATA "+-", 0, 0
DATA "-+", 0, 0
DATA "<>", 0, 0
DATA "><", 0, 0
DATA "__END__", 0, 0

END

' *****************************************************************
' LOAD TABLES
' *****************************************************************

SUB LoadCommandTable
    DIM i AS LONG
    RESTORE CommandData
    READ CommandCount

    IF CommandCount > MAX_COMMANDS THEN
        CompileError "Command table MAX_COMMANDS limitini asti."
        EXIT SUB
    END IF

    FOR i = 1 TO CommandCount
        READ CmdSymbol(i), CmdName(i), CmdRole(i)
    NEXT i
END SUB

SUB LoadPatternTable
    DIM p AS STRING
    DIM actionId AS LONG
    DIM argVal AS LONG
    DIM n AS LONG

    PatCount = 0
    WarningCount = 0

    RESTORE PatternData

    DO
        READ p, actionId, argVal
        IF p = "__END__" THEN EXIT DO
        AddPattern p, actionId, argVal
    LOOP

    ' Programmatic pattern expansion.
    ' DATA table holds special idioms; generated pattern table holds folds.
    FOR n = 1 TO 128
        AddPattern "0" + RepeatChar$("+", n), ACT_SET_CUR, n
    NEXT n

    FOR n = 1 TO 32
        AddPattern "0" + RepeatChar$("+", n) + "@", ACT_META_CONST, n
    NEXT n

    FOR n = 2 TO 512
        AddPattern RepeatChar$("+", n), ACT_ADD_CUR, n
        AddPattern RepeatChar$("-", n), ACT_SUB_CUR, n
        AddPattern RepeatChar$(">", n), ACT_MOVE_PTR, n
        AddPattern RepeatChar$("<", n), ACT_MOVE_PTR, -n
    NEXT n

    SortPatternsByPriority

    PRINT "Komut sayisi  : "; CommandCount
    PRINT "Pattern sayisi: "; PatCount
END SUB

' *****************************************************************
' OPTIONS
' *****************************************************************

SUB AskOptions
    DIM s AS STRING
    DIM n AS LONG
    DIM totalBytes AS _UNSIGNED LONG

    PRINT
    PRINT "Kaynak dosya (.uxm veya .txt): ";
    LINE INPUT InFileName

    IF LEN(LTRIM$(RTRIM$(InFileName))) = 0 THEN
        CompileError "Kaynak dosya adi bos."
        EXIT SUB
    END IF

    PRINT "ASM cikis dosyasi [otomatik]: ";
    LINE INPUT s

    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        OutASMName = DefaultASMName$(InFileName)
    ELSE
        OutASMName = LTRIM$(RTRIM$(s))
    END IF

    PRINT
    PRINT "Hucre tipi:"
    PRINT "  8  = byte"
    PRINT "  16 = word"
    PRINT "  32 = dword"
    PRINT "Secim [8]: ";
    LINE INPUT s

    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        CellBits = 8
    ELSE
        CellBits = VAL(s)
    END IF

    SELECT CASE CellBits
        CASE 8
            CellBytes = 1
        CASE 16
            CellBytes = 2
        CASE 32
            CellBytes = 4
        CASE ELSE
            CompileError "Gecersiz hucre tipi. 8, 16 veya 32 secilmeli."
            EXIT SUB
    END SELECT

    PRINT
    PRINT "Toplam UXM bellek havuzu: 64 KB"
    PRINT "Tape + Stack + Data toplami tam 64 KB olmali."
    PRINT

    PRINT "Tape KB [32]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        n = 32
    ELSE
        n = VAL(s)
    END IF
    IF n < 1 THEN n = 32
    TapeBytes = n * 1024

    PRINT "Stack KB [8]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        n = 8
    ELSE
        n = VAL(s)
    END IF
    IF n < 1 THEN n = 8
    StackBytes = n * 1024

    PRINT "Data KB [otomatik kalan]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        IF TapeBytes + StackBytes >= UXM_TOTAL_BYTES THEN
            CompileError "Tape + Stack toplami 64 KB sinirini asti."
            EXIT SUB
        END IF
        DataBytes = UXM_TOTAL_BYTES - TapeBytes - StackBytes
    ELSE
        n = VAL(s)
        IF n < 1 THEN n = 24
        DataBytes = n * 1024
    END IF

    totalBytes = TapeBytes + StackBytes + DataBytes

    IF totalBytes <> UXM_TOTAL_BYTES THEN
        CompileError "Tape + Stack + Data toplami tam 64 KB olmali."
        PRINT "Su anki toplam KB: "; totalBytes \ 1024
        EXIT SUB
    END IF

    TapeCells = TapeBytes \ CellBytes
    StackCells = StackBytes \ CellBytes
    DataCells = DataBytes \ CellBytes

    StackOffsetBytes = TapeBytes
    DataOffsetBytes = TapeBytes + StackBytes

    PRINT
    PRINT "Overflow modu:"
    PRINT "  0 = wrap / dogal tasma"
    PRINT "  1 = check / tasma hatasi"
    PRINT "Secim [0]: ";
    LINE INPUT s

    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        OverflowMode = OV_WRAP
    ELSE
        OverflowMode = VAL(s)
    END IF

    IF OverflowMode <> OV_WRAP AND OverflowMode <> OV_CHECK THEN
        CompileError "Gecersiz overflow modu."
        EXIT SUB
    END IF

    PRINT "Pointer sinir kontrolu:"
    PRINT "  1 = acik"
    PRINT "  0 = kapali"
    PRINT "Secim [1]: ";
    LINE INPUT s

    IF LEN(LTRIM$(RTRIM$(s))) = 0 THEN
        BoundsCheck = 1
    ELSE
        BoundsCheck = VAL(s)
    END IF

    IF BoundsCheck <> 0 THEN BoundsCheck = 1

    PRINT
    PRINT "Ayarlar:"
    PRINT "  Cell bits       : "; CellBits
    PRINT "  Cell bytes      : "; CellBytes
    PRINT "  Total memory    : 64 KB"
    PRINT "  Tape bytes      : "; TapeBytes
    PRINT "  Tape cells      : "; TapeCells
    PRINT "  Stack bytes     : "; StackBytes
    PRINT "  Stack cells     : "; StackCells
    PRINT "  Data bytes      : "; DataBytes
    PRINT "  Data cells      : "; DataCells
    PRINT "  Stack offset    : "; StackOffsetBytes
    PRINT "  Data offset     : "; DataOffsetBytes

    IF OverflowMode = OV_WRAP THEN
        PRINT "  Overflow        : wrap"
    ELSE
        PRINT "  Overflow        : check"
    END IF

    IF BoundsCheck <> 0 THEN
        PRINT "  Bounds check    : on"
    ELSE
        PRINT "  Bounds check    : off"
    END IF

    PRINT
END SUB

FUNCTION DefaultASMName$ (srcName AS STRING)
    DIM i AS LONG
    DIM dotPos AS LONG

    dotPos = 0

    FOR i = LEN(srcName) TO 1 STEP -1
        IF MID$(srcName, i, 1) = "." THEN
            dotPos = i
            EXIT FOR
        END IF
    NEXT i

    IF dotPos > 0 THEN
        DefaultASMName$ = LEFT$(srcName, dotPos - 1) + ".asm"
    ELSE
        DefaultASMName$ = srcName + ".asm"
    END IF
END FUNCTION

' *****************************************************************
' SOURCE
' *****************************************************************

SUB ReadSourceFile
    DIM ff AS LONG
    DIM sz AS LONG

    IF _FILEEXISTS(InFileName) = 0 THEN
        CompileError "Kaynak dosya bulunamadi: " + InFileName
        EXIT SUB
    END IF

    ff = FREEFILE
    OPEN InFileName FOR BINARY AS #ff
    sz = LOF(ff)

    IF sz <= 0 THEN
        Src = ""
    ELSE
        Src = SPACE$(sz)
        GET #ff, , Src
    END IF

    CLOSE #ff

    ' UTF-8 BOM temizle: EF BB BF
    IF LEN(Src) >= 3 THEN
        IF (ASC(MID$(Src, 1, 1)) AND &HFF) = &HEF AND _
           (ASC(MID$(Src, 2, 1)) AND &HFF) = &HBB AND _
           (ASC(MID$(Src, 3, 1)) AND &HFF) = &HBF THEN
            Src = MID$(Src, 4)
        END IF
    END IF
END SUB

' *****************************************************************
' LEXER
' *****************************************************************

SUB Lexer
    DIM i AS LONG
    DIM j AS LONG
    DIM c AS STRING
    DIM nextC AS STRING
    DIM numText AS STRING
    DIM repeatCount AS LONG
    DIM chars AS STRING

    TokenCount = 0
    StrCount = 0
    chars = CommandChars$

    i = 1

    DO WHILE i <= LEN(Src) AND HadError = 0

        c = MID$(Src, i, 1)

        IF c = "#" THEN
            SkipLine i

        ELSEIF c = "s" OR c = "S" THEN
            IF TryParseStringDecl%(i) = 0 THEN
                i = i + 1
            END IF

        ELSEIF c = "p" OR c = "P" THEN
            IF TryParsePrintString%(i) = 0 THEN
                i = i + 1
            END IF

        ELSEIF INSTR(chars, c) > 0 THEN

            IF i + 2 <= LEN(Src) THEN
                nextC = MID$(Src, i + 1, 1)

                IF (nextC = "k" OR nextC = "K") AND IsDigitChar%(MID$(Src, i + 2, 1)) <> 0 THEN
                    j = i + 2
                    numText = ""

                    DO WHILE j <= LEN(Src)
                        IF IsDigitChar%(MID$(Src, j, 1)) = 0 THEN EXIT DO
                        numText = numText + MID$(Src, j, 1)
                        j = j + 1
                    LOOP

                    repeatCount = VAL(numText)

                    IF repeatCount > MAX_REPEAT_COUNT THEN
                        CompileError "Repeat macro cok buyuk: " + c + "k" + numText
                        EXIT SUB
                    END IF

                    AddRepeatedToken c, repeatCount
                    i = j
                ELSE
                    AddToken c
                    i = i + 1
                END IF

            ELSE
                AddToken c
                i = i + 1
            END IF

        ELSE
            i = i + 1
        END IF

    LOOP

    PRINT "Token sayisi : "; TokenCount
    PRINT "String sayisi: "; StrCount
END SUB

FUNCTION CommandChars$
    ' sN, pN, kN, and # are handled specially.
    CommandChars$ = "><+-0.,[]$%?!;&|^~@:{}"
END FUNCTION

SUB AddToken (t AS STRING)
    IF HadError <> 0 THEN EXIT SUB

    IF TokenCount >= MAX_TOKENS THEN
        CompileError "Token dizisi doldu. MAX_TOKENS artirilmali."
        EXIT SUB
    END IF

    TokenCount = TokenCount + 1
    Tokens(TokenCount) = t
END SUB

SUB AddRepeatedToken (c AS STRING, countVal AS LONG)
    DIM n AS LONG

    IF HadError <> 0 THEN EXIT SUB
    IF countVal <= 0 THEN EXIT SUB

    IF TokenCount + countVal > MAX_TOKENS THEN
        CompileError "Repeat macro token limitini asti: " + c + "k" + LTRIM$(STR$(countVal))
        EXIT SUB
    END IF

    FOR n = 1 TO countVal
        TokenCount = TokenCount + 1
        Tokens(TokenCount) = c
    NEXT n
END SUB

SUB SkipLine (pos AS LONG)
    DO WHILE pos <= LEN(Src)
        IF MID$(Src, pos, 1) = CHR$(10) THEN
            pos = pos + 1
            EXIT SUB
        END IF
        pos = pos + 1
    LOOP
END SUB

SUB SkipSpaces (pos AS LONG)
    DO WHILE pos <= LEN(Src)
        SELECT CASE MID$(Src, pos, 1)
            CASE " ", CHR$(9), CHR$(13), CHR$(10)
                pos = pos + 1
            CASE ELSE
                EXIT DO
        END SELECT
    LOOP
END SUB

FUNCTION TryParseStringDecl% (pos AS LONG)
    DIM p AS LONG
    DIM ok AS LONG
    DIM sid AS LONG
    DIM startCell AS _UNSIGNED LONG
    DIM txt AS STRING

    p = pos

    IF MID$(Src, p, 1) <> "s" AND MID$(Src, p, 1) <> "S" THEN
        TryParseStringDecl% = 0
        EXIT FUNCTION
    END IF

    p = p + 1

    IF p > LEN(Src) THEN
        TryParseStringDecl% = 0
        EXIT FUNCTION
    END IF

    IF IsDigitChar%(MID$(Src, p, 1)) = 0 THEN
        TryParseStringDecl% = 0
        EXIT FUNCTION
    END IF

    sid = ParseUnsignedNumber&&(p, ok)
    IF ok = 0 THEN
        CompileError "String numarasi okunamadi."
        TryParseStringDecl% = 1
        EXIT FUNCTION
    END IF

    SkipSpaces p

    IF p > LEN(Src) OR MID$(Src, p, 1) <> "=" THEN
        CompileError "String taniminda '=' bekleniyor."
        TryParseStringDecl% = 1
        EXIT FUNCTION
    END IF

    p = p + 1
    SkipSpaces p

    startCell = ParseUnsignedNumber&&(p, ok)
    IF ok = 0 THEN
        CompileError "String baslangic data hucre no okunamadi."
        TryParseStringDecl% = 1
        EXIT FUNCTION
    END IF

    SkipSpaces p

    IF p > LEN(Src) OR MID$(Src, p, 1) <> "," THEN
        CompileError "String taniminda ',' bekleniyor."
        TryParseStringDecl% = 1
        EXIT FUNCTION
    END IF

    p = p + 1
    SkipSpaces p

    txt = ParseBracedString$(p, ok)
    IF ok = 0 THEN
        CompileError "String metni { ... } arasinda okunamadi."
        TryParseStringDecl% = 1
        EXIT FUNCTION
    END IF

    AddStringDecl sid, startCell, txt

    pos = p
    TryParseStringDecl% = 1
END FUNCTION

FUNCTION TryParsePrintString% (pos AS LONG)
    DIM p AS LONG
    DIM ok AS LONG
    DIM sid AS LONG

    p = pos

    IF MID$(Src, p, 1) <> "p" AND MID$(Src, p, 1) <> "P" THEN
        TryParsePrintString% = 0
        EXIT FUNCTION
    END IF

    p = p + 1

    IF p > LEN(Src) THEN
        TryParsePrintString% = 0
        EXIT FUNCTION
    END IF

    IF IsDigitChar%(MID$(Src, p, 1)) = 0 THEN
        TryParsePrintString% = 0
        EXIT FUNCTION
    END IF

    sid = ParseUnsignedNumber&&(p, ok)
    IF ok = 0 THEN
        CompileError "p komutunda string numarasi okunamadi."
        TryParsePrintString% = 1
        EXIT FUNCTION
    END IF

    AddToken "P:" + LTRIM$(STR$(sid))

    pos = p
    TryParsePrintString% = 1
END FUNCTION

FUNCTION ParseUnsignedNumber&& (pos AS LONG, ok AS LONG)
    DIM s AS STRING

    s = ""
    ok = 0

    DO WHILE pos <= LEN(Src)
        IF IsDigitChar%(MID$(Src, pos, 1)) = 0 THEN EXIT DO
        s = s + MID$(Src, pos, 1)
        pos = pos + 1
    LOOP

    IF LEN(s) = 0 THEN
        ParseUnsignedNumber&& = 0
        EXIT FUNCTION
    END IF

    ok = 1
    ParseUnsignedNumber&& = VAL(s)
END FUNCTION

FUNCTION ParseBracedString$ (pos AS LONG, ok AS LONG)
    DIM r AS STRING
    DIM c AS STRING
    DIM n AS STRING

    r = ""
    ok = 0

    IF pos > LEN(Src) THEN EXIT FUNCTION
    IF MID$(Src, pos, 1) <> "{" THEN EXIT FUNCTION

    pos = pos + 1

    DO WHILE pos <= LEN(Src)
        c = MID$(Src, pos, 1)

        IF c = "\" THEN
            IF pos + 1 <= LEN(Src) THEN
                n = MID$(Src, pos + 1, 1)

                SELECT CASE n
                    CASE "n": r = r + CHR$(10)
                    CASE "r": r = r + CHR$(13)
                    CASE "t": r = r + CHR$(9)
                    CASE "{": r = r + "{"
                    CASE "}": r = r + "}"
                    CASE "\": r = r + "\"
                    CASE ELSE: r = r + n
                END SELECT

                pos = pos + 2
            ELSE
                r = r + c
                pos = pos + 1
            END IF

        ELSEIF c = "}" THEN
            pos = pos + 1
            ok = 1
            ParseBracedString$ = r
            EXIT FUNCTION

        ELSE
            r = r + c
            pos = pos + 1
        END IF
    LOOP

    ParseBracedString$ = r
END FUNCTION

SUB AddStringDecl (sid AS LONG, startCell AS _UNSIGNED LONG, txt AS STRING)
    DIM i AS LONG

    IF HadError <> 0 THEN EXIT SUB

    IF StrCount >= MAX_STRINGS THEN
        CompileError "String tablosu doldu."
        EXIT SUB
    END IF

    FOR i = 1 TO StrCount
        IF StrId(i) = sid THEN
            CompileError "Ayni string numarasi tekrar kullanildi: s" + LTRIM$(STR$(sid))
            EXIT SUB
        END IF
    NEXT i

    IF startCell + LEN(txt) + 1 >= DataCells THEN
        CompileError "String data alanini asiyor: s" + LTRIM$(STR$(sid))
        EXIT SUB
    END IF

    StrCount = StrCount + 1
    StrId(StrCount) = sid
    StrStartCell(StrCount) = startCell
    StrText(StrCount) = txt
END SUB

FUNCTION FindStringIndexById% (sid AS LONG)
    DIM i AS LONG

    FOR i = 1 TO StrCount
        IF StrId(i) = sid THEN
            FindStringIndexById% = i
            EXIT FUNCTION
        END IF
    NEXT i

    FindStringIndexById% = 0
END FUNCTION

FUNCTION IsDigitChar% (c AS STRING)
    IF LEN(c) = 0 THEN
        IsDigitChar% = 0
    ELSEIF c >= "0" AND c <= "9" THEN
        IsDigitChar% = 1
    ELSE
        IsDigitChar% = 0
    END IF
END FUNCTION

FUNCTION IsTokenPrintString% (t AS STRING)
    IF LEFT$(t, 2) = "P:" THEN
        IsTokenPrintString% = 1
    ELSE
        IsTokenPrintString% = 0
    END IF
END FUNCTION

FUNCTION PrintStringIdFromToken% (t AS STRING)
    PrintStringIdFromToken% = VAL(MID$(t, 3))
END FUNCTION

' *****************************************************************
' PATTERN HELPERS
' *****************************************************************

SUB AddPattern (p AS STRING, actionId AS LONG, argVal AS LONG)
    DIM i AS LONG
    DIM q AS STRING

    q = NormalizePattern$(p)

    IF LEN(q) = 0 THEN EXIT SUB

    IF PatternIsBalanced%(q) = 0 THEN
        WarningCount = WarningCount + 1
        EXIT SUB
    END IF

    FOR i = 1 TO PatCount
        IF Pat(i) = q THEN EXIT SUB
    NEXT i

    IF PatCount >= MAX_PATTERNS THEN
        CompileError "Pattern dizisi doldu."
        EXIT SUB
    END IF

    PatCount = PatCount + 1
    Pat(PatCount) = q
    PatAction(PatCount) = actionId
    PatArg(PatCount) = argVal
    PatPriority(PatCount) = SpecificityScore%(q)
    PatOrder(PatCount) = PatCount
END SUB

FUNCTION RepeatChar$ (ch AS STRING, n AS LONG)
    DIM i AS LONG
    DIM r AS STRING

    r = ""

    FOR i = 1 TO n
        r = r + ch
    NEXT i

    RepeatChar$ = r
END FUNCTION

FUNCTION NormalizePattern$ (s AS STRING)
    DIM i AS LONG
    DIM c AS STRING
    DIM r AS STRING

    r = ""

    FOR i = 1 TO LEN(s)
        c = MID$(s, i, 1)

        IF c <> " " AND c <> CHR$(9) THEN
            r = r + c
        END IF
    NEXT i

    NormalizePattern$ = r
END FUNCTION

FUNCTION PatternIsBalanced% (s AS STRING)
    DIM i AS LONG
    DIM bal AS LONG
    DIM c AS STRING

    bal = 0

    FOR i = 1 TO LEN(s)
        c = MID$(s, i, 1)

        IF c = "[" THEN
            bal = bal + 1
        ELSEIF c = "]" THEN
            bal = bal - 1
            IF bal < 0 THEN
                PatternIsBalanced% = 0
                EXIT FUNCTION
            END IF
        END IF
    NEXT i

    IF bal = 0 THEN
        PatternIsBalanced% = 1
    ELSE
        PatternIsBalanced% = 0
    END IF
END FUNCTION

FUNCTION SpecificityScore% (p AS STRING)
    DIM i AS LONG
    DIM c AS STRING
    DIM score AS LONG
    DIM seen AS STRING
    DIM uniqueChars AS LONG
    DIM allSame AS LONG

    score = 0
    seen = ""
    uniqueChars = 0
    allSame = 1

    FOR i = 1 TO LEN(p)
        c = MID$(p, i, 1)

        IF INSTR(seen, c) = 0 THEN
            seen = seen + c
            uniqueChars = uniqueChars + 1
        END IF

        IF i > 1 THEN
            IF c <> MID$(p, 1, 1) THEN allSame = 0
        END IF

        SELECT CASE c
            CASE "[", "]": score = score + 100
            CASE "@": score = score + 90
            CASE "$", "%": score = score + 80
            CASE "?", "!", ";", "&", "|", "^", "~", "{", "}": score = score + 70
            CASE ".", ",": score = score + 50
            CASE "0": score = score + 40
            CASE ">", "<": score = score + 20
            CASE "+", "-": score = score + 15
            CASE ELSE: score = score + 1
        END SELECT
    NEXT i

    score = score + uniqueChars * 25
    IF allSame <> 0 THEN score = score - 40

    SpecificityScore% = score
END FUNCTION

FUNCTION PatternCompare% (a AS LONG, b AS LONG)
    IF LEN(Pat(a)) > LEN(Pat(b)) THEN PatternCompare% = 1: EXIT FUNCTION
    IF LEN(Pat(a)) < LEN(Pat(b)) THEN PatternCompare% = 0: EXIT FUNCTION

    IF PatPriority(a) > PatPriority(b) THEN PatternCompare% = 1: EXIT FUNCTION
    IF PatPriority(a) < PatPriority(b) THEN PatternCompare% = 0: EXIT FUNCTION

    IF PatOrder(a) < PatOrder(b) THEN
        PatternCompare% = 1
    ELSE
        PatternCompare% = 0
    END IF
END FUNCTION

SUB SortPatternsByPriority
    DIM i AS LONG
    DIM j AS LONG

    DIM tp AS STRING
    DIM ta AS LONG
    DIM targ AS LONG
    DIM tpri AS LONG
    DIM tord AS LONG

    FOR i = 1 TO PatCount - 1
        FOR j = i + 1 TO PatCount
            IF PatternCompare%(j, i) <> 0 THEN
                tp = Pat(i)
                ta = PatAction(i)
                targ = PatArg(i)
                tpri = PatPriority(i)
                tord = PatOrder(i)

                Pat(i) = Pat(j)
                PatAction(i) = PatAction(j)
                PatArg(i) = PatArg(j)
                PatPriority(i) = PatPriority(j)
                PatOrder(i) = PatOrder(j)

                Pat(j) = tp
                PatAction(j) = ta
                PatArg(j) = targ
                PatPriority(j) = tpri
                PatOrder(j) = tord
            END IF
        NEXT j
    NEXT i
END SUB

FUNCTION MatchPattern% (startIdx AS LONG)
    DIM p AS LONG
    DIM j AS LONG
    DIM pLen AS LONG
    DIM ok AS LONG

    IF IsTokenPrintString%(Tokens(startIdx)) <> 0 THEN
        MatchPattern% = 0
        EXIT FUNCTION
    END IF

    FOR p = 1 TO PatCount
        pLen = LEN(Pat(p))

        IF startIdx + pLen - 1 <= TokenCount THEN
            ok = 1

            FOR j = 0 TO pLen - 1
                IF IsTokenPrintString%(Tokens(startIdx + j)) <> 0 THEN
                    ok = 0
                    EXIT FOR
                END IF

                IF Tokens(startIdx + j) <> MID$(Pat(p), j + 1, 1) THEN
                    ok = 0
                    EXIT FOR
                END IF
            NEXT j

            IF ok <> 0 THEN
                MatchPattern% = p
                EXIT FUNCTION
            END IF
        END IF
    NEXT p

    MatchPattern% = 0
END FUNCTION

' *****************************************************************
' ASM HELPERS
' *****************************************************************

FUNCTION SizePrefix$ ()
    SELECT CASE CellBits
        CASE 8: SizePrefix$ = "byte"
        CASE 16: SizePrefix$ = "word"
        CASE 32: SizePrefix$ = "dword"
        CASE ELSE: SizePrefix$ = "byte"
    END SELECT
END FUNCTION

FUNCTION StoreReg$ ()
    SELECT CASE CellBits
        CASE 8: StoreReg$ = "al"
        CASE 16: StoreReg$ = "ax"
        CASE 32: StoreReg$ = "eax"
        CASE ELSE: StoreReg$ = "al"
    END SELECT
END FUNCTION

FUNCTION MaxValueText$ ()
    SELECT CASE CellBits
        CASE 8: MaxValueText$ = "255"
        CASE 16: MaxValueText$ = "65535"
        CASE 32: MaxValueText$ = "4294967295"
        CASE ELSE: MaxValueText$ = "255"
    END SELECT
END FUNCTION

FUNCTION ReduceValue&& (v AS _UNSIGNED _INTEGER64)
    SELECT CASE CellBits
        CASE 8: ReduceValue&& = v MOD 256
        CASE 16: ReduceValue&& = v MOD 65536
        CASE 32: ReduceValue&& = v
        CASE ELSE: ReduceValue&& = v MOD 256
    END SELECT
END FUNCTION

FUNCTION IndexExpr$ (baseReg AS STRING, indexReg AS STRING, offCells AS LONG)
    DIM s AS STRING
    DIM disp AS LONG

    SELECT CASE CellBytes
        CASE 1: s = baseReg + " + " + indexReg
        CASE 2: s = baseReg + " + " + indexReg + "*2"
        CASE 4: s = baseReg + " + " + indexReg + "*4"
        CASE ELSE: s = baseReg + " + " + indexReg
    END SELECT

    disp = offCells * CellBytes

    IF disp > 0 THEN
        s = s + " + " + LTRIM$(STR$(disp))
    ELSEIF disp < 0 THEN
        s = s + " - " + LTRIM$(STR$(ABS(disp)))
    END IF

    IndexExpr$ = "[" + s + "]"
END FUNCTION

FUNCTION CellOp$ (offCells AS LONG)
    CellOp$ = SizePrefix$ + " " + IndexExpr$("r12", "rbx", offCells)
END FUNCTION

FUNCTION StackOp$ ()
    StackOp$ = SizePrefix$ + " " + IndexExpr$("r13", "r14", 0)
END FUNCTION

FUNCTION DataByteOffset&& (cellNo AS _UNSIGNED LONG)
    DataByteOffset&& = cellNo * CellBytes
END FUNCTION

FUNCTION DataCellOpConst$ (cellNo AS _UNSIGNED LONG)
    DataCellOpConst$ = SizePrefix$ + " [ux_mem + DATA_OFFSET + " + LTRIM$(STR$(DataByteOffset&&(cellNo))) + "]"
END FUNCTION

' *****************************************************************
' ASM GENERATOR
' *****************************************************************

SUB GenerateASM
    DIM i AS LONG
    DIM pIdx AS LONG

    OutFF = FREEFILE
    OPEN OutASMName FOR OUTPUT AS #OutFF

    EmitHeader
    EmitStringInitializers

    i = 1

    DO WHILE i <= TokenCount AND HadError = 0

        IF IsTokenPrintString%(Tokens(i)) <> 0 THEN
            EmitPrintStringById PrintStringIdFromToken%(Tokens(i))
            i = i + 1
        ELSE
            pIdx = MatchPattern%(i)

            IF pIdx > 0 THEN
                EmitLine "    ; pattern: " + Pat(pIdx)
                EmitPattern pIdx
                i = i + LEN(Pat(pIdx))
            ELSE
                EmitSingleToken Tokens(i)
                i = i + 1
            END IF
        END IF

    LOOP

    IF LoopSP <> 0 THEN
        CompileError "Eksik ']' var. Acilan loop kapatilmamis."
        EmitLine "    ; ERROR: unclosed loop"
    END IF

    EmitFooter

    CLOSE #OutFF
END SUB

SUB EmitHeader
    EmitLine "; *****************************************************************"
    EmitLine "; UXM-64K V3 generated Windows x64 NASM output"
    EmitLine "; Assemble:"
    EmitLine ";   nasm -f win64 this_file.asm -o build.obj"
    EmitLine "; Link:"
    EmitLine ";   fbc uxm64_runtime.bas build.obj -x program.exe"
    EmitLine "; *****************************************************************"
    EmitLine ""
    EmitLine "default rel"
    EmitLine ""
    EmitLine "global uxm_entry"
    EmitLine ""
    EmitLine "extern ux_putc"
    EmitLine "extern ux_getc"
    EmitLine "extern ux_print_cells"
    EmitLine "extern ux_meta_call"
    EmitLine "extern ux_ptr_oob"
    EmitLine "extern ux_stack_overflow"
    EmitLine "extern ux_stack_underflow"
    EmitLine "extern ux_overflow_error"
    EmitLine "extern ux_exit"
    EmitLine ""
    EmitLine "%define UXM_TOTAL_BYTES 65536"
    EmitLine "%define TAPE_BYTES      " + LTRIM$(STR$(TapeBytes))
    EmitLine "%define STACK_BYTES     " + LTRIM$(STR$(StackBytes))
    EmitLine "%define DATA_BYTES      " + LTRIM$(STR$(DataBytes))
    EmitLine "%define TAPE_CELLS      " + LTRIM$(STR$(TapeCells))
    EmitLine "%define STACK_CELLS     " + LTRIM$(STR$(StackCells))
    EmitLine "%define DATA_CELLS      " + LTRIM$(STR$(DataCells))
    EmitLine "%define STACK_OFFSET    " + LTRIM$(STR$(StackOffsetBytes))
    EmitLine "%define DATA_OFFSET     " + LTRIM$(STR$(DataOffsetBytes))
    EmitLine "%define CELL_BITS       " + LTRIM$(STR$(CellBits))
    EmitLine "%define CELL_BYTES      " + LTRIM$(STR$(CellBytes))
    EmitLine ""
    EmitLine "section .bss"
    EmitLine "align 16"
    EmitLine "ux_mem: resb UXM_TOTAL_BYTES"
    EmitLine ""
    EmitLine "section .text"
    EmitLine ""
    EmitLine "uxm_entry:"
    EmitLine "    push rbp"
    EmitLine "    mov rbp, rsp"
    EmitLine "    push rbx"
    EmitLine "    push r12"
    EmitLine "    push r13"
    EmitLine "    push r14"
    EmitLine "    push r15"
    EmitLine ""
    EmitLine "    ; Windows x64 shadow space + alignment"
    EmitLine "    sub rsp, 40"
    EmitLine ""
    EmitLine "    lea r12, [ux_mem]"
    EmitLine "    xor rbx, rbx"
    EmitLine "    lea r13, [ux_mem + STACK_OFFSET]"
    EmitLine "    xor r14, r14"
    EmitLine ""
END SUB

SUB EmitFooter
    EmitLine ""
    EmitLine "    xor ecx, ecx"
    EmitLine "    call ux_exit"
    EmitLine ""
    EmitLine "__ux_return:"
    EmitLine "    add rsp, 40"
    EmitLine "    pop r15"
    EmitLine "    pop r14"
    EmitLine "    pop r13"
    EmitLine "    pop r12"
    EmitLine "    pop rbx"
    EmitLine "    pop rbp"
    EmitLine "    ret"
    EmitLine ""
    EmitLine "__ux_ptr_oob:"
    EmitLine "    call ux_ptr_oob"
    EmitLine "    jmp __ux_return"
    EmitLine ""
    EmitLine "__ux_stack_overflow:"
    EmitLine "    call ux_stack_overflow"
    EmitLine "    jmp __ux_return"
    EmitLine ""
    EmitLine "__ux_stack_underflow:"
    EmitLine "    call ux_stack_underflow"
    EmitLine "    jmp __ux_return"
    EmitLine ""
    EmitLine "__ux_overflow:"
    EmitLine "    call ux_overflow_error"
    EmitLine "    jmp __ux_return"
END SUB

SUB EmitLine (s AS STRING)
    PRINT #OutFF, s
END SUB

SUB EmitStringInitializers
    DIM i AS LONG
    DIM j AS LONG
    DIM chVal AS LONG
    DIM startCell AS _UNSIGNED LONG
    DIM txt AS STRING

    IF StrCount = 0 THEN EXIT SUB

    EmitLine "    ; string initializers into data area"

    FOR i = 1 TO StrCount
        startCell = StrStartCell(i)
        txt = StrText(i)

        EmitLine "    ; s" + LTRIM$(STR$(StrId(i))) + " data cell " + LTRIM$(STR$(startCell))

        FOR j = 1 TO LEN(txt)
            chVal = ASC(MID$(txt, j, 1)) AND &HFF
            EmitLine "    mov " + DataCellOpConst$(startCell + j - 1) + ", " + LTRIM$(STR$(chVal))
        NEXT j

        EmitLine "    mov " + DataCellOpConst$(startCell + LEN(txt)) + ", 0"
    NEXT i

    EmitLine ""
END SUB

SUB EmitPattern (pIdx AS LONG)
    SELECT CASE PatAction(pIdx)
        CASE ACT_NOP: EmitLine "    nop"
        CASE ACT_ADD_CUR: EmitAddCell 0, PatArg(pIdx)
        CASE ACT_SUB_CUR: EmitSubCell 0, PatArg(pIdx)
        CASE ACT_MOVE_PTR: EmitMovePtr PatArg(pIdx)
        CASE ACT_CLEAR_CUR: EmitClearCell 0
        CASE ACT_SET_CUR: EmitSetCell 0, PatArg(pIdx)
        CASE ACT_META_CONST: EmitMetaConst PatArg(pIdx)
        CASE ACT_MOVE_ADD_RIGHT_CLEAR: EmitMoveAddClear 1
        CASE ACT_MOVE_ADD_LEFT_CLEAR: EmitMoveAddClear -1
        CASE ELSE: EmitLine "    ; unknown pattern action"
    END SELECT
END SUB

SUB EmitSingleToken (t AS STRING)
    SELECT CASE t
        CASE ">": EmitMovePtr 1
        CASE "<": EmitMovePtr -1
        CASE "+": EmitAddCell 0, 1
        CASE "-": EmitSubCell 0, 1
        CASE "0": EmitClearCell 0
        CASE ".": EmitPutChar
        CASE ",": EmitGetChar
        CASE "[": EmitLoopStart
        CASE "]": EmitLoopEnd
        CASE "$": EmitPushCell
        CASE "%": EmitPopCell
        CASE "?": EmitCompare CMP_EQ
        CASE "!": EmitCompare CMP_GT
        CASE ";": EmitCompare CMP_LT
        CASE "&": EmitBinaryBitwise BIN_AND
        CASE "|": EmitBinaryBitwise BIN_OR
        CASE "^": EmitBinaryBitwise BIN_XOR
        CASE "~": EmitNotCell
        CASE "{": EmitShiftLeft
        CASE "}": EmitShiftRight
        CASE "@": EmitMetaFromCell
        CASE ":": EmitLine "    ; ':' reserved for future label/separator"
        CASE ELSE: EmitLine "    ; ignored token: " + t
    END SELECT
END SUB

' *****************************************************************
' LOW LEVEL EMITTERS
' *****************************************************************

SUB EmitPointerCheck
    IF BoundsCheck = 0 THEN EXIT SUB
    EmitLine "    cmp rbx, TAPE_CELLS"
    EmitLine "    jae __ux_ptr_oob"
END SUB

SUB EmitNeighborCheck (offCells AS LONG)
    IF BoundsCheck = 0 THEN EXIT SUB

    IF offCells > 0 THEN
        EmitLine "    cmp rbx, " + LTRIM$(STR$(TapeCells - offCells))
        EmitLine "    jae __ux_ptr_oob"
    ELSEIF offCells < 0 THEN
        EmitLine "    cmp rbx, " + LTRIM$(STR$(ABS(offCells)))
        EmitLine "    jb __ux_ptr_oob"
    END IF
END SUB

SUB EmitMovePtr (delta AS LONG)
    IF delta = 0 THEN EXIT SUB

    IF delta = 1 THEN
        EmitLine "    inc rbx"
    ELSEIF delta = -1 THEN
        EmitLine "    dec rbx"
    ELSEIF delta > 0 THEN
        EmitLine "    add rbx, " + LTRIM$(STR$(delta))
    ELSE
        EmitLine "    sub rbx, " + LTRIM$(STR$(ABS(delta)))
    END IF

    EmitPointerCheck
END SUB

SUB EmitSetCell (offCells AS LONG, value AS _UNSIGNED _INTEGER64)
    DIM v AS _UNSIGNED _INTEGER64

    EmitNeighborCheck offCells

    IF OverflowMode = OV_CHECK THEN
        EmitLine "    mov rax, " + LTRIM$(STR$(value))
        EmitLine "    cmp rax, " + MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp$(offCells) + ", " + StoreReg$
    ELSE
        v = ReduceValue&&(value)
        EmitLine "    mov " + CellOp$(offCells) + ", " + LTRIM$(STR$(v))
    END IF
END SUB

SUB EmitClearCell (offCells AS LONG)
    EmitNeighborCheck offCells
    EmitLine "    mov " + CellOp$(offCells) + ", 0"
END SUB

SUB EmitAddCell (offCells AS LONG, amount AS _UNSIGNED _INTEGER64)
    DIM v AS _UNSIGNED _INTEGER64

    IF amount = 0 THEN EXIT SUB
    EmitNeighborCheck offCells

    IF OverflowMode = OV_WRAP THEN
        v = ReduceValue&&(amount)
        IF v = 0 THEN EXIT SUB

        IF v = 1 THEN
            EmitLine "    inc " + CellOp$(offCells)
        ELSE
            EmitLine "    add " + CellOp$(offCells) + ", " + LTRIM$(STR$(v))
        END IF
    ELSE
        SELECT CASE CellBits
            CASE 8: EmitLine "    movzx eax, " + CellOp$(offCells)
            CASE 16: EmitLine "    movzx eax, " + CellOp$(offCells)
            CASE 32: EmitLine "    mov eax, " + CellOp$(offCells)
        END SELECT

        EmitLine "    add rax, " + LTRIM$(STR$(amount))
        EmitLine "    cmp rax, " + MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp$(offCells) + ", " + StoreReg$
    END IF
END SUB

SUB EmitSubCell (offCells AS LONG, amount AS _UNSIGNED _INTEGER64)
    DIM v AS _UNSIGNED _INTEGER64

    IF amount = 0 THEN EXIT SUB
    EmitNeighborCheck offCells

    IF OverflowMode = OV_WRAP THEN
        v = ReduceValue&&(amount)
        IF v = 0 THEN EXIT SUB

        IF v = 1 THEN
            EmitLine "    dec " + CellOp$(offCells)
        ELSE
            EmitLine "    sub " + CellOp$(offCells) + ", " + LTRIM$(STR$(v))
        END IF
    ELSE
        SELECT CASE CellBits
            CASE 8: EmitLine "    movzx eax, " + CellOp$(offCells)
            CASE 16: EmitLine "    movzx eax, " + CellOp$(offCells)
            CASE 32: EmitLine "    mov eax, " + CellOp$(offCells)
        END SELECT

        EmitLine "    cmp rax, " + LTRIM$(STR$(amount))
        EmitLine "    jb __ux_overflow"
        EmitLine "    sub rax, " + LTRIM$(STR$(amount))
        EmitLine "    mov " + CellOp$(offCells) + ", " + StoreReg$
    END IF
END SUB

SUB EmitPutChar
    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx ecx, " + CellOp$(0)
        CASE 16: EmitLine "    movzx ecx, " + CellOp$(0)
        CASE 32: EmitLine "    mov ecx, " + CellOp$(0)
    END SELECT

    EmitLine "    call ux_putc"
END SUB

SUB EmitGetChar
    EmitLine "    call ux_getc"
    EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
END SUB

SUB EmitMetaFromCell
    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx ecx, " + CellOp$(0)
        CASE 16: EmitLine "    movzx ecx, " + CellOp$(0)
        CASE 32: EmitLine "    mov ecx, " + CellOp$(0)
    END SELECT

    EmitLine "    call ux_meta_call"
    EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
END SUB

SUB EmitMetaConst (metaId AS LONG)
    EmitLine "    mov ecx, " + LTRIM$(STR$(metaId))
    EmitLine "    call ux_meta_call"
    EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
END SUB

SUB EmitPushCell
    EmitLine "    cmp r14, STACK_CELLS"
    EmitLine "    jae __ux_stack_overflow"

    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx eax, " + CellOp$(0)
        CASE 16: EmitLine "    movzx eax, " + CellOp$(0)
        CASE 32: EmitLine "    mov eax, " + CellOp$(0)
    END SELECT

    EmitLine "    mov " + StackOp$ + ", " + StoreReg$
    EmitLine "    inc r14"
END SUB

SUB EmitPopCell
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"

    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx eax, " + StackOp$
        CASE 16: EmitLine "    movzx eax, " + StackOp$
        CASE 32: EmitLine "    mov eax, " + StackOp$
    END SELECT

    EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
END SUB

SUB EmitCompare (cmpMode AS LONG)
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"

    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx eax, " + StackOp$
        CASE 16: EmitLine "    movzx eax, " + StackOp$
        CASE 32: EmitLine "    mov eax, " + StackOp$
    END SELECT

    EmitLine "    mov r15, rax"

    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx eax, " + CellOp$(0)
        CASE 16: EmitLine "    movzx eax, " + CellOp$(0)
        CASE 32: EmitLine "    mov eax, " + CellOp$(0)
    END SELECT

    EmitLine "    cmp r15, rax"

    SELECT CASE cmpMode
        CASE CMP_EQ: EmitLine "    sete al"
        CASE CMP_GT: EmitLine "    seta al"
        CASE CMP_LT: EmitLine "    setb al"
        CASE ELSE: EmitLine "    sete al"
    END SELECT

    EmitLine "    movzx eax, al"
    EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
END SUB

SUB EmitBinaryBitwise (opMode AS LONG)
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"

    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx eax, " + StackOp$
        CASE 16: EmitLine "    movzx eax, " + StackOp$
        CASE 32: EmitLine "    mov eax, " + StackOp$
    END SELECT

    EmitLine "    mov r15, rax"

    SELECT CASE CellBits
        CASE 8: EmitLine "    movzx eax, " + CellOp$(0)
        CASE 16: EmitLine "    movzx eax, " + CellOp$(0)
        CASE 32: EmitLine "    mov eax, " + CellOp$(0)
    END SELECT

    SELECT CASE opMode
        CASE BIN_AND: EmitLine "    and rax, r15"
        CASE BIN_OR: EmitLine "    or rax, r15"
        CASE BIN_XOR: EmitLine "    xor rax, r15"
    END SELECT

    EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
END SUB

SUB EmitNotCell
    EmitLine "    not " + CellOp$(0)
END SUB

SUB EmitShiftLeft
    IF OverflowMode = OV_WRAP THEN
        EmitLine "    shl " + CellOp$(0) + ", 1"
    ELSE
        SELECT CASE CellBits
            CASE 8: EmitLine "    movzx eax, " + CellOp$(0)
            CASE 16: EmitLine "    movzx eax, " + CellOp$(0)
            CASE 32: EmitLine "    mov eax, " + CellOp$(0)
        END SELECT

        EmitLine "    shl rax, 1"
        EmitLine "    cmp rax, " + MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp$(0) + ", " + StoreReg$
    END IF
END SUB

SUB EmitShiftRight
    EmitLine "    shr " + CellOp$(0) + ", 1"
END SUB

SUB EmitMoveAddClear (offCells AS LONG)
    EmitNeighborCheck offCells

    IF OverflowMode = OV_WRAP THEN
        SELECT CASE CellBits
            CASE 8: EmitLine "    mov al, " + CellOp$(0)
            CASE 16: EmitLine "    mov ax, " + CellOp$(0)
            CASE 32: EmitLine "    mov eax, " + CellOp$(0)
        END SELECT

        EmitLine "    add " + CellOp$(offCells) + ", " + StoreReg$
        EmitLine "    mov " + CellOp$(0) + ", 0"
    ELSE
        SELECT CASE CellBits
            CASE 8: EmitLine "    movzx eax, " + CellOp$(0)
            CASE 16: EmitLine "    movzx eax, " + CellOp$(0)
            CASE 32: EmitLine "    mov eax, " + CellOp$(0)
        END SELECT

        EmitLine "    mov r15, rax"

        SELECT CASE CellBits
            CASE 8: EmitLine "    movzx eax, " + CellOp$(offCells)
            CASE 16: EmitLine "    movzx eax, " + CellOp$(offCells)
            CASE 32: EmitLine "    mov eax, " + CellOp$(offCells)
        END SELECT

        EmitLine "    add rax, r15"
        EmitLine "    cmp rax, " + MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp$(offCells) + ", " + StoreReg$
        EmitLine "    mov " + CellOp$(0) + ", 0"
    END IF
END SUB

SUB EmitLoopStart
    IF LoopSP >= MAX_LOOP_STACK THEN
        CompileError "Loop stack doldu."
        EXIT SUB
    END IF

    LoopCount = LoopCount + 1
    LoopSP = LoopSP + 1
    LoopStack(LoopSP) = LoopCount

    EmitLine "L" + LTRIM$(STR$(LoopCount)) + ":"
    EmitLine "    cmp " + CellOp$(0) + ", 0"
    EmitLine "    je E" + LTRIM$(STR$(LoopCount))
END SUB

SUB EmitLoopEnd
    DIM id AS LONG

    IF LoopSP <= 0 THEN
        CompileError "Fazla ']' bulundu. Eslesen '[' yok."
        EXIT SUB
    END IF

    id = LoopStack(LoopSP)
    LoopSP = LoopSP - 1

    EmitLine "    jmp L" + LTRIM$(STR$(id))
    EmitLine "E" + LTRIM$(STR$(id)) + ":"
END SUB

SUB EmitPrintStringById (sid AS LONG)
    DIM idx AS LONG
    DIM offsetBytes AS _UNSIGNED _INTEGER64

    idx = FindStringIndexById%(sid)

    IF idx = 0 THEN
        CompileError "Tanimlanmamis string basiliyor: p" + LTRIM$(STR$(sid))
        EXIT SUB
    END IF

    offsetBytes = DataOffsetBytes + DataByteOffset&&(StrStartCell(idx))

    EmitLine "    ; print string p" + LTRIM$(STR$(sid))
    EmitLine "    lea rcx, [ux_mem + " + LTRIM$(STR$(offsetBytes)) + "]"
    EmitLine "    mov edx, CELL_BITS"
    EmitLine "    call ux_print_cells"
END SUB

SUB CompileError (msg AS STRING)
    HadError = 1
    PRINT "HATA: "; msg
END SUB
```

Bu sürümde komut ailesi ve temel patternler artık **DATA/READ** üzerinden yükleniyor. `PatternData` kısmına yeni özel optimizasyon kalıpları eklemek kolay:

```basic
DATA "++--", 0, 0
DATA "0++++@", 6, 4
DATA "[->++<]", 7, 2
```

Ama `DATA` satırlarını yine ana program alanında, `SUB/FUNCTION`lardan önce tutmak gerekiyor.

[1]: https://qb64.com/wiki/DATA.html?utm_source=chatgpt.com "DATA [value1, value2, …]"

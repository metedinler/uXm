' *****************************************************************
' UX-MINIMA INDUSTRIAL DATA-COMPILER - v3 (İyileştirilmiş)
' *****************************************************************

OPTION EXPLICIT

CONST MAX_TOKENS = 50000
CONST MAX_PATTERNS = 512
CONST MAX_LOOP_STACK = 256

DIM SHARED Tokens(1 TO MAX_TOKENS) AS STRING
DIM SHARED TokenCount AS Integer

DIM SHARED LStack(1 TO MAX_LOOP_STACK) AS Integer
DIM SHARED LPtr AS Integer, LCount AS Integer

DIM SHARED Pat(1 TO MAX_PATTERNS) AS STRING
DIM SHARED AsmCode(1 TO MAX_PATTERNS) AS STRING
DIM SHARED PatCount AS Integer

DIM SHARED Src AS STRING, InFileName AS STRING, OutFileName AS STRING
DIM SHARED HadError AS Integer, WarningCount AS Integer

CLS
PRINT "--- UX-MINIMA INDUSTRIAL COMPILER v3 ---"
PRINT

LoadPatterns

PRINT "Aktif pattern sayısı :"; PatCount
PRINT "Uyarı sayısı        :"; WarningCount
PRINT

INPUT "Kaynak (.UXM): ", InFileName
INPUT "Çıktı  (.ASM): ", OutFileName

IF InFileName = "" OR OutFileName = "" THEN 
    PRINT "HATA: Dosya adı boş olamaz!": END
END IF

' Dosya oku
DIM f AS Integer = FREEFILE
OPEN InFileName FOR BINARY AS #f
Src = SPACE(LOF(f))
GET #f, , Src
CLOSE #f

Lexer
IndustrialParser

IF HadError = 0 THEN
    PRINT "Derleme başarıyla tamamlandı → "; OutFileName
ELSE
    PRINT "Derleme hatalarla tamamlandı."
END IF

END

' =============================================================
SUB LoadPatterns()
    DIM p AS STRING, a AS STRING
    RESTORE PatternData
    
    DO
        READ p, a
        IF p = "__END__" THEN EXIT DO
        AddPattern p, a
    LOOP
    
    SortPatterns
END SUB

SUB AddPattern(pRaw AS STRING, aRaw AS STRING)
    DIM p AS STRING = NormalizePattern(pRaw)
    IF LEN(p) = 0 THEN EXIT SUB

    ' Duplicate kontrolü
    DIM i AS Integer
    FOR i = 1 TO PatCount
        IF Pat(i) = p THEN 
            WarningCount = WarningCount + 1
            PRINT "UYARI: Duplicate atlandı -> "; pRaw
            EXIT SUB
        END IF
    NEXT i

    PatCount = PatCount + 1
    Pat(PatCount) = p
    AsmCode(PatCount) = aRaw
END SUB

FUNCTION NormalizePattern(s AS STRING) AS STRING
    DIM r AS STRING, i AS Integer
    FOR i = 1 TO LEN(s)
        DIM ch AS STRING = MID(s, i, 1)
        IF INSTR("><+-0!?.,[]&|^$%@", ch) > 0 THEN r = r + ch
    NEXT i
    NormalizePattern = r
END FUNCTION

SUB SortPatterns()
    DIM i AS Integer, j AS Integer, swapped AS Integer
    DIM tempP AS STRING, tempA AS STRING
    
    ' Bubble sort ile en uzun + en spesifik öne
    FOR i = 1 TO PatCount - 1
        swapped = 0
        FOR j = 1 TO PatCount - i
            IF ShouldComeBefore(j, j+1) THEN
                ' Swap
                tempP = Pat(j): tempA = AsmCode(j)
                Pat(j) = Pat(j+1): AsmCode(j) = AsmCode(j+1)
                Pat(j+1) = tempP: AsmCode(j+1) = tempA
                swapped = -1
            END IF
        NEXT j
        IF swapped = 0 THEN EXIT FOR
    NEXT i
END SUB

FUNCTION ShouldComeBefore(a AS Integer, b AS Integer) AS Integer
    IF LEN(Pat(a)) > LEN(Pat(b)) THEN RETURN -1          ' Daha uzun önce
    IF LEN(Pat(a)) < LEN(Pat(b)) THEN RETURN 0
    
    ' Aynı uzunlukta specificity'e bak
    IF SpecificityScore(Pat(a)) > SpecificityScore(Pat(b)) THEN RETURN -1
    RETURN 0
END FUNCTION

FUNCTION SpecificityScore(p AS STRING) AS Integer
    DIM score AS Integer = LEN(p) * 10   ' Uzunluk en önemli
    DIM i AS Integer, ch AS STRING
    
    FOR i = 1 TO LEN(p)
        ch = MID(p, i, 1)
        SELECT CASE ch
            CASE "[", "]": score = score + 100
            CASE "@": score = score + 70
            CASE "$", "%": score = score + 55
            CASE "!", "?": score = score + 45
            CASE "&", "|": score = score + 40
            CASE ".", ",": score = score + 25
        END SELECT
    NEXT i
    SpecificityScore = score
END FUNCTION

' Lexer ve Parser fonksiyonları (önceki versiyonundan neredeyse aynı, sadece ufak temizlik)
' ... (Lexer, IndustrialParser, MatchPattern, EmitHeader, EmitFooter aynı kalabilir)

' =============================================================
PatternData:
' (Buraya önceki mesajındaki tüm DATA satırlarını olduğu gibi koyabilirsin)
' Sadece en sona __END__ koy

DATA "[-]", "LDA #0 : STA (PTR),Y"
' ... tüm pattern'lar ...
DATA "__END__", ""
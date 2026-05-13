' *****************************************************************
' UX-MINIMA V2 RUNTIME
' HOST: FreeBASIC
' LINK: fbc uxm_v2_runtime.bas build.obj -x program.exe
' *****************************************************************

OPTION EXPLICIT

#INCLUDE "windows.bi"

Extern "C"
    Declare Sub uxm_entry Alias "uxm_entry"()
End Extern

Sub ux_putc Cdecl Alias "ux_putc" (ByVal ch As ULong)
    PRINT CHR(ch AND &HFF);
End Sub

Function ux_getc Cdecl Alias "ux_getc" () As ULong
    DIM s AS String

    DO
        s = INKEY$
    LOOP WHILE LEN(s) = 0

    ux_getc = ASC(s, 1) AND &HFF
End Function

Sub ux_print_cells Cdecl Alias "ux_print_cells" (ByVal p As Any Ptr, ByVal cellBits As ULong)
    DIM v AS ULong
    DIM pb AS UByte Ptr
    DIM pw AS UShort Ptr
    DIM pd AS UInteger Ptr

    SELECT CASE cellBits

        CASE 8
            pb = CAST(UByte Ptr, p)

            DO
                v = *pb
                IF v = 0 THEN EXIT DO
                PRINT CHR(v AND &HFF);
                pb = pb + 1
            LOOP

        CASE 16
            pw = CAST(UShort Ptr, p)

            DO
                v = *pw
                IF v = 0 THEN EXIT DO
                PRINT CHR(v AND &HFF);
                pw = pw + 1
            LOOP

        CASE 32
            pd = CAST(UInteger Ptr, p)

            DO
                v = *pd
                IF v = 0 THEN EXIT DO
                PRINT CHR(v AND &HFF);
                pd = pd + 1
            LOOP

        CASE ELSE
            PRINT "[UX-MINIMA ERROR] Gecersiz cellBits: "; cellBits

    END SELECT
End Sub

Function ux_meta_call Cdecl Alias "ux_meta_call" (ByVal id As ULong) As ULong
    SELECT CASE id

        CASE 0
            ux_meta_call = 0

        CASE 1
            CLS
            ux_meta_call = 0

        CASE 2
            LOCATE 1, 1
            ux_meta_call = 0

        CASE 3
            RANDOMIZE TIMER
            ux_meta_call = CULNG(INT(RND * 256)) AND &HFF

        CASE 4
            ux_meta_call = CULNG(TIMER * 1000) AND &HFFFFFFFF

        CASE 5
            PRINT
            ux_meta_call = 10

        CASE 6
            PRINT "[UX-MINIMA META]"
            ux_meta_call = 0

        CASE 7
            ux_meta_call = 7

        CASE 8
            ux_meta_call = 8

        CASE ELSE
            PRINT
            PRINT "[UX-MINIMA] Bilinmeyen meta komut: "; id
            ux_meta_call = id

    END SELECT
End Function

Sub ux_ptr_oob Cdecl Alias "ux_ptr_oob" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] Tape pointer sinir disina cikti."
    END 10
End Sub

Sub ux_stack_overflow Cdecl Alias "ux_stack_overflow" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] UX user stack doldu."
    END 11
End Sub

Sub ux_stack_underflow Cdecl Alias "ux_stack_underflow" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] UX user stack bosken pop yapildi."
    END 12
End Sub

Sub ux_overflow_error Cdecl Alias "ux_overflow_error" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] Hucre overflow/underflow hatasi."
    END 13
End Sub

Sub ux_exit Cdecl Alias "ux_exit" (ByVal code As ULong)
    END code
End Sub

' UTF-8 terminal denemesi.
' Windows Terminal destekliyorsa Turkce karakterler daha duzgun gorunur.
SetConsoleOutputCP(65001)
SetConsoleCP(65001)

PRINT "UX-MINIMA V2 runtime started."
uxm_entry
PRINT
PRINT "UX-MINIMA V2 runtime finished."
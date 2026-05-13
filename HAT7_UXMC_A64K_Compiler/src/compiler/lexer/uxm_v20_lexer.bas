#ifndef UXM_V20_LEXER_BAS
#define UXM_V20_LEXER_BAS

type UXMToken
    kind As Long
    text As String
    line As Long
    col As Long
End Type

Const UXM_TOK_EOF As Long = 0
Const UXM_TOK_COMMAND As Long = 1
Const UXM_TOK_NUMBER As Long = 2
Const UXM_TOK_META As Long = 3
Const UXM_TOK_STRING As Long = 4
Const UXM_TOK_IDENT As Long = 5
Const UXM_TOK_SYMBOL As Long = 6
Const UXM_TOK_PRAGMA As Long = 7
Const UXM_TOK_COMMENT As Long = 8

Function UXMLexerIsSpace(ByVal ch As String) As Long
    Return IIf(ch=" " Or ch=Chr(9) Or ch=Chr(13) Or ch=Chr(10), -1, 0)
End Function

Function UXMLexerIsDigit(ByVal ch As String) As Long
    Return IIf(ch>="0" And ch<="9", -1, 0)
End Function

Function UXMLexerIsIdent(ByVal ch As String) As Long
    Return IIf((ch>="a" And ch<="z") Or (ch>="A" And ch<="Z") Or (ch>="0" And ch<="9") Or ch="_", -1, 0)
End Function

Sub UXMLex(ByVal source As String, ByRef tokens() As UXMToken, ByRef tokenCount As Long)
    Dim p As Long = 1, ln As Long = 1, co As Long = 1
    Dim maxTok As Long = Len(source) + 8
    ReDim tokens(0 To maxTok) As UXMToken
    tokenCount = 0
    While p <= Len(source)
        Dim ch As String = Mid(source,p,1)
        If ch=Chr(10) Then ln += 1: co = 1: p += 1: Continue While
        If ch=" " Or ch=Chr(9) Or ch=Chr(13) Then p += 1: co += 1: Continue While
        Dim startP As Long = p, startC As Long = co
        If ch="'" Then
            While p<=Len(source) And Mid(source,p,1)<>Chr(10): p += 1: co += 1: Wend
            Continue While
        End If
        If ch="#" Then
            While p<=Len(source) And Mid(source,p,1)<>Chr(10): p += 1: co += 1: Wend
            tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_PRAGMA: tokens(tokenCount).text=Mid(source,startP,p-startP): tokens(tokenCount).line=ln: tokens(tokenCount).col=startC
            Continue While
        End If
        If ch="@" Then
            p += 1: co += 1
            If p<=Len(source) And (Mid(source,p,1)="#" Or Mid(source,p,1)="@" Or Mid(source,p,1)="*") Then p += 1: co += 1
            While p<=Len(source) And UXMLexerIsDigit(Mid(source,p,1)): p += 1: co += 1: Wend
            tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_META: tokens(tokenCount).text=Mid(source,startP,p-startP): tokens(tokenCount).line=ln: tokens(tokenCount).col=startC
            Continue While
        End If
        If ch="\"" Then
            p += 1: co += 1
            While p<=Len(source) And Mid(source,p,1)<>"\"": p += 1: co += 1: Wend
            If p<=Len(source) Then p += 1: co += 1
            tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_STRING: tokens(tokenCount).text=Mid(source,startP,p-startP): tokens(tokenCount).line=ln: tokens(tokenCount).col=startC
            Continue While
        End If
        If UXMLexerIsDigit(ch) Then
            While p<=Len(source) And UXMLexerIsDigit(Mid(source,p,1)): p += 1: co += 1: Wend
            tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_NUMBER: tokens(tokenCount).text=Mid(source,startP,p-startP): tokens(tokenCount).line=ln: tokens(tokenCount).col=startC
            Continue While
        End If
        If UXMLexerIsIdent(ch) Then
            While p<=Len(source) And UXMLexerIsIdent(Mid(source,p,1)): p += 1: co += 1: Wend
            tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_IDENT: tokens(tokenCount).text=Mid(source,startP,p-startP): tokens(tokenCount).line=ln: tokens(tokenCount).col=startC
            Continue While
        End If
        tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_SYMBOL: tokens(tokenCount).text=ch: tokens(tokenCount).line=ln: tokens(tokenCount).col=startC
        p += 1: co += 1
    Wend
    tokenCount += 1: tokens(tokenCount).kind=UXM_TOK_EOF: tokens(tokenCount).text="": tokens(tokenCount).line=ln: tokens(tokenCount).col=co
End Sub

#endif

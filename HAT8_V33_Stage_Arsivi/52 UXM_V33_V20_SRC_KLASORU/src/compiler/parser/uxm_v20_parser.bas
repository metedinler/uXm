#ifndef UXM_V20_PARSER_BAS
#define UXM_V20_PARSER_BAS
#Include Once "../lexer/uxm_v20_lexer.bas"
#Include Once "../ast/uxm_v20_ast.bas"

Function UXMParseMetaId(ByVal s As String) As Long
    Dim t As String = s
    t = Replace(t,"@","")
    t = Replace(t,"#","")
    t = Replace(t,"*","")
    Return ValInt(t)
End Function

Function UXMIsBrainCommand(ByVal ch As String) As Long
    Return IIf(ch=">" Or ch="<" Or ch="+" Or ch="-" Or ch="." Or ch="," Or ch="[" Or ch="]", -1, 0)
End Function

Sub UXMParseTokens(ByRef tokens() As UXMToken, ByVal tokenCount As Long, ByRef nodes() As UXMAstNode, ByRef nodeCount As Long, ByRef errorText As String)
    ReDim nodes(0 To 1024) As UXMAstNode
    nodeCount = 0
    errorText = ""
    Dim i As Long
    For i=1 To tokenCount
        Select Case tokens(i).kind
        Case UXM_TOK_META
            UXMAstAdd nodes(), nodeCount, UXM_AST_META, 0, UXMParseMetaId(tokens(i).text), tokens(i).text, tokens(i).line, tokens(i).col
        Case UXM_TOK_SYMBOL
            Dim ch As String = tokens(i).text
            Select Case ch
            Case ">": UXMAstAdd nodes(), nodeCount, UXM_AST_RIGHT, 1, 0, ch, tokens(i).line, tokens(i).col
            Case "<": UXMAstAdd nodes(), nodeCount, UXM_AST_LEFT, 1, 0, ch, tokens(i).line, tokens(i).col
            Case "+": UXMAstAdd nodes(), nodeCount, UXM_AST_INC, 1, 0, ch, tokens(i).line, tokens(i).col
            Case "-": UXMAstAdd nodes(), nodeCount, UXM_AST_DEC, 1, 0, ch, tokens(i).line, tokens(i).col
            Case ".": UXMAstAdd nodes(), nodeCount, UXM_AST_PUTC, 1, 0, ch, tokens(i).line, tokens(i).col
            Case ",": UXMAstAdd nodes(), nodeCount, UXM_AST_GETC, 1, 0, ch, tokens(i).line, tokens(i).col
            Case "[": UXMAstAdd nodes(), nodeCount, UXM_AST_LOOP_BEGIN, 0, 0, ch, tokens(i).line, tokens(i).col
            Case "]": UXMAstAdd nodes(), nodeCount, UXM_AST_LOOP_END, 0, 0, ch, tokens(i).line, tokens(i).col
            End Select
        Case UXM_TOK_STRING
            UXMAstAdd nodes(), nodeCount, UXM_AST_STRING_PRINT, 0, 0, tokens(i).text, tokens(i).line, tokens(i).col
        End Select
    Next i
End Sub

Sub UXMParseSource(ByVal source As String, ByRef nodes() As UXMAstNode, ByRef nodeCount As Long, ByRef errorText As String)
    Dim toks() As UXMToken, tc As Long
    UXMLex source, toks(), tc
    UXMParseTokens toks(), tc, nodes(), nodeCount, errorText
End Sub

#endif

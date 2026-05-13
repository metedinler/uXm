#ifndef UXM_V20_AST_BAS
#define UXM_V20_AST_BAS

type UXMAstNode
    op As Long
    amount As Long
    serviceId As Long
    text As String
    line As Long
    col As Long
End Type

Const UXM_AST_NOP As Long = 0
Const UXM_AST_RIGHT As Long = 1
Const UXM_AST_LEFT As Long = 2
Const UXM_AST_INC As Long = 3
Const UXM_AST_DEC As Long = 4
Const UXM_AST_PUTC As Long = 5
Const UXM_AST_GETC As Long = 6
Const UXM_AST_LOOP_BEGIN As Long = 7
Const UXM_AST_LOOP_END As Long = 8
Const UXM_AST_META As Long = 9
Const UXM_AST_STRING_PRINT As Long = 10

Sub UXMAstAdd(ByRef nodes() As UXMAstNode, ByRef count As Long, ByVal op As Long, ByVal amount As Long, ByVal serviceId As Long, ByVal txt As String, ByVal line As Long, ByVal col As Long)
    count += 1
    If count > UBound(nodes) Then ReDim Preserve nodes(0 To UBound(nodes)+1024) As UXMAstNode
    nodes(count).op = op
    nodes(count).amount = amount
    nodes(count).serviceId = serviceId
    nodes(count).text = txt
    nodes(count).line = line
    nodes(count).col = col
End Sub

Function UXMAstOpName(ByVal op As Long) As String
    Select Case op
    Case UXM_AST_RIGHT: Return "RIGHT"
    Case UXM_AST_LEFT: Return "LEFT"
    Case UXM_AST_INC: Return "INC"
    Case UXM_AST_DEC: Return "DEC"
    Case UXM_AST_PUTC: Return "PUTC"
    Case UXM_AST_GETC: Return "GETC"
    Case UXM_AST_LOOP_BEGIN: Return "LOOP_BEGIN"
    Case UXM_AST_LOOP_END: Return "LOOP_END"
    Case UXM_AST_META: Return "META"
    Case UXM_AST_STRING_PRINT: Return "STRING_PRINT"
    Case Else: Return "NOP"
    End Select
End Function

#endif

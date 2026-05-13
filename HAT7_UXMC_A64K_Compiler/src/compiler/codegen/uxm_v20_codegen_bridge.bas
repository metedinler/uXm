#ifndef UXM_V20_CODEGEN_BRIDGE_BAS
#define UXM_V20_CODEGEN_BRIDGE_BAS
#Include Once "../ast/uxm_v20_ast.bas"

Function UXMCodegenTrace(ByRef nodes() As UXMAstNode, ByVal nodeCount As Long) As String
    Dim out As String = ""
    Dim i As Long
    For i=1 To nodeCount
        out &= Str(i) & ":" & UXMAstOpName(nodes(i).op)
        If nodes(i).op=UXM_AST_META Then out &= " @" & Str(nodes(i).serviceId)
        out &= Chr(10)
    Next i
    Return out
End Function

#endif

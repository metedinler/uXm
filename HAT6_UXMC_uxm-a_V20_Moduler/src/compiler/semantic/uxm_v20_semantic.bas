#ifndef UXM_V20_SEMANTIC_BAS
#define UXM_V20_SEMANTIC_BAS
#Include Once "../ast/uxm_v20_ast.bas"
#Include Once "../../shared/uxm_v20_service_registry.bi"

Function UXMSemanticValidate(ByRef nodes() As UXMAstNode, ByVal nodeCount As Long, ByRef errorText As String) As Long
    Dim depth As Long = 0
    Dim i As Long
    For i=1 To nodeCount
        If nodes(i).op=UXM_AST_LOOP_BEGIN Then depth += 1
        If nodes(i).op=UXM_AST_LOOP_END Then
            depth -= 1
            If depth<0 Then errorText="fazla kapanan dongu satir=" & Str(nodes(i).line): Return 0
        End If
        If nodes(i).op=UXM_AST_META Then
            If UXMServiceIsDispatchable(nodes(i).serviceId)=0 Then errorText="gecersiz servis @" & Str(nodes(i).serviceId): Return 0
        End If
    Next i
    If depth<>0 Then errorText="acik kalan dongu": Return 0
    errorText=""
    Return -1
End Function

#endif

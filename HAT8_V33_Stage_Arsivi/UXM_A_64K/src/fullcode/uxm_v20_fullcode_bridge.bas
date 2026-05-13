#ifndef UXM_V20_FULLCODE_BRIDGE_BAS
#define UXM_V20_FULLCODE_BRIDGE_BAS
#Include Once "../compiler/parser/uxm_v20_parser.bas"
#Include Once "../compiler/semantic/uxm_v20_semantic.bas"
#Include Once "../compiler/codegen/uxm_v20_codegen_bridge.bas"

Function UXMFullCodeAnalyse(ByVal source As String) As String
    Dim nodes() As UXMAstNode, nc As Long, err As String
    UXMParseSource source, nodes(), nc, err
    If Len(err)>0 Then Return "parse_error=" & err
    If UXMSemanticValidate(nodes(), nc, err)=0 Then Return "semantic_error=" & err
    Return UXMCodegenTrace(nodes(), nc)
End Function

#endif

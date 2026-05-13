#Lang "fb"
' UXM V20 interpreter lane: AST walker using the same service registry and runtime dispatch.
#Include Once "../compiler/parser/uxm_v20_parser.bas"
#Include Once "../compiler/semantic/uxm_v20_semantic.bas"
#Include Once "../runtime/uxm31_runtime_fb_full.bas"

Const UXM_INTERP_MEM_BYTES As ULongInt = 16UL * 1024UL * 1024UL
Dim Shared ux_mem(0 To UXM_INTERP_MEM_BYTES-1) As UByte
Dim Shared ux_status As UByte
Dim Shared ux_flags As UShort
Dim Shared ux_ptr As ULongInt
Dim Shared ux_sp As ULongInt
Dim Shared ux_cell_bits As ULong = 8
Dim Shared ux_cell_bytes As ULong = 1
Dim Shared ux_tape_cells As ULong = 1048576
Dim Shared ux_stack_cells As ULong = 262144
Dim Shared ux_data_cells As ULong = 4194304
Dim Shared ux_queue_cells As ULong = 262144
Dim Shared ux_stack_offset As ULong = 1048576
Dim Shared ux_data_offset As ULong = 1048576 + 262144

Sub ux_putc(ByVal ch As ULongInt) Export
    Print Chr(ch And &HFF);
End Sub

Function ux_getc() As ULongInt Export
    Dim s As String
    s = Input(1)
    If Len(s)=0 Then Return 0
    Return Asc(s)
End Function

Sub ux_runtime_error(ByVal code As ULongInt) Export
    ux_status = code And &HFF
End Sub

Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt) Export
    Dim i As ULongInt=startCell
    Dim v As ULongInt
    Do
        v = ReadData(i)
        If v=0 Then Exit Do
        Print Chr(v And &HFF);
        i += 1
    Loop
End Sub

Sub uxm_entry() Export
End Sub

Sub UXMInterpretAst(ByRef nodes() As UXMAstNode, ByVal nodeCount As Long)
    Dim pc As Long = 1
    Dim loopStack(0 To 8192) As Long
    Dim loopTop As Long = 0
    While pc<=nodeCount
        Select Case nodes(pc).op
        Case UXM_AST_RIGHT
            ux_ptr += nodes(pc).amount
        Case UXM_AST_LEFT
            If ux_ptr>=CULngInt(nodes(pc).amount) Then ux_ptr -= nodes(pc).amount Else ux_status = STATUS_PTR_BOUNDS
        Case UXM_AST_INC
            WriteTape ux_ptr, ReadTape(ux_ptr)+nodes(pc).amount
        Case UXM_AST_DEC
            WriteTape ux_ptr, ReadTape(ux_ptr)-nodes(pc).amount
        Case UXM_AST_PUTC
            ux_putc ReadTape(ux_ptr)
        Case UXM_AST_GETC
            WriteTape ux_ptr, ux_getc()
        Case UXM_AST_META
            ux_meta_call_ex nodes(pc).serviceId, @ux_mem(0)
        Case UXM_AST_LOOP_BEGIN
            If ReadTape(ux_ptr)=0 Then
                Dim d As Long=1
                Do While d>0 And pc<nodeCount
                    pc += 1
                    If nodes(pc).op=UXM_AST_LOOP_BEGIN Then d += 1
                    If nodes(pc).op=UXM_AST_LOOP_END Then d -= 1
                Loop
            Else
                loopTop += 1: loopStack(loopTop)=pc
            End If
        Case UXM_AST_LOOP_END
            If ReadTape(ux_ptr)<>0 And loopTop>0 Then
                pc = loopStack(loopTop)
            ElseIf loopTop>0 Then
                loopTop -= 1
            End If
        Case UXM_AST_STRING_PRINT
            Dim t As String = nodes(pc).text
            If Len(t)>=2 Then t=Mid(t,2,Len(t)-2)
            Print t;
        End Select
        pc += 1
    Wend
End Sub

Function UXMInterpretSource(ByVal source As String, ByRef errorText As String) As Long
    Dim nodes() As UXMAstNode, nc As Long
    UXMParseSource source, nodes(), nc, errorText
    If Len(errorText)>0 Then Return 0
    If UXMSemanticValidate(nodes(), nc, errorText)=0 Then Return 0
    UXMInterpretAst nodes(), nc
    Return -1
End Function

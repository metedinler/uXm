#ifndef UXM_V20_ADDRESSING_MODES_BAS
#define UXM_V20_ADDRESSING_MODES_BAS

type UXMAddress
    kind As Long
    a As Long
    b As Long
    raw As String
End Type

Const UXM_ADDR_T As Long = 0
Const UXM_ADDR_T_REL As Long = 1
Const UXM_ADDR_T_ABS As Long = 2
Const UXM_ADDR_D_ABS As Long = 3
Const UXM_ADDR_S_ABS As Long = 4
Const UXM_ADDR_SP As Long = 5
Const UXM_ADDR_P As Long = 6
Const UXM_ADDR_E As Long = 7
Const UXM_ADDR_F As Long = 8
Const UXM_ADDR_D_AT_T As Long = 9
Const UXM_ADDR_D_AT_T_REL As Long = 10
Const UXM_ADDR_D_AT_BASE_PLUS_P As Long = 11
Const UXM_ADDR_T_BASE_PLUS_P As Long = 12

Function UXMTrimLower(ByVal s As String) As String
    Return LCase(Trim(s))
End Function

Function UXMParseSignedInt(ByVal s As String, ByRef ok As Long) As Long
    Dim t As String = Trim(s)
    ok = 0
    If Len(t)=0 Then Return 0
    Dim i As Long
    For i=1 To Len(t)
        Dim c As String = Mid(t,i,1)
        If i=1 And (c="+" Or c="-") Then Continue For
        If c<"0" Or c>"9" Then Return 0
    Next i
    ok = -1
    Return ValInt(t)
End Function

Function UXMParseAddressMode(ByVal text As String, ByRef addr As UXMAddress) As Long
    Dim s As String = UXMTrimLower(text)
    Dim ok As Long
    addr.raw = text: addr.kind = UXM_ADDR_T: addr.a = 0: addr.b = 0
    If s="t" Or s="(t)" Then addr.kind=UXM_ADDR_T: Return -1
    If s="sp" Or s="(sp)" Then addr.kind=UXM_ADDR_SP: Return -1
    If s="p" Or s="(p)" Then addr.kind=UXM_ADDR_P: Return -1
    If s="e" Or s="(e)" Then addr.kind=UXM_ADDR_E: Return -1
    If s="f" Or s="(f)" Then addr.kind=UXM_ADDR_F: Return -1
    If Left(s,2)="t+" Or Left(s,2)="t-" Then
        addr.kind=UXM_ADDR_T_REL: addr.a=UXMParseSignedInt(Mid(s,2), ok): Return ok
    End If
    If Left(s,2)="d:" Then
        addr.kind=UXM_ADDR_D_ABS: addr.a=UXMParseSignedInt(Mid(s,3), ok): Return ok
    End If
    If Left(s,2)="s:" Then
        addr.kind=UXM_ADDR_S_ABS: addr.a=UXMParseSignedInt(Mid(s,3), ok): Return ok
    End If
    If Left(s,2)="t:" Then
        addr.kind=UXM_ADDR_T_ABS: addr.a=UXMParseSignedInt(Mid(s,3), ok): Return ok
    End If
    If s="d@t" Or s="(d@t)" Then addr.kind=UXM_ADDR_D_AT_T: Return -1
    If Left(s,4)="d@t+" Or Left(s,4)="d@t-" Then
        addr.kind=UXM_ADDR_D_AT_T_REL: addr.a=UXMParseSignedInt(Mid(s,4), ok): Return ok
    End If
    If InStr(s,"d:base+p")>0 Then addr.kind=UXM_ADDR_D_AT_BASE_PLUS_P: Return -1
    If InStr(s,"t:base+p")>0 Then addr.kind=UXM_ADDR_T_BASE_PLUS_P: Return -1
    Return 0
End Function

Function UXMAddressKindName(ByVal k As Long) As String
    Select Case k
    Case UXM_ADDR_T: Return "T"
    Case UXM_ADDR_T_REL: Return "T_REL"
    Case UXM_ADDR_T_ABS: Return "T_ABS"
    Case UXM_ADDR_D_ABS: Return "D_ABS"
    Case UXM_ADDR_S_ABS: Return "S_ABS"
    Case UXM_ADDR_SP: Return "SP"
    Case UXM_ADDR_P: Return "P"
    Case UXM_ADDR_E: Return "E"
    Case UXM_ADDR_F: Return "F"
    Case UXM_ADDR_D_AT_T: Return "D_AT_T"
    Case UXM_ADDR_D_AT_T_REL: Return "D_AT_T_REL"
    Case UXM_ADDR_D_AT_BASE_PLUS_P: Return "D_BASE_PLUS_P"
    Case UXM_ADDR_T_BASE_PLUS_P: Return "T_BASE_PLUS_P"
    Case Else: Return "INVALID"
    End Select
End Function

#endif

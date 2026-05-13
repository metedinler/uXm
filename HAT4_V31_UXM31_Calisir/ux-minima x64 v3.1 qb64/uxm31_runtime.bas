'Bu runtime şunları karşılıyor:

'- ux_putc / ux_getc
'- data string yazdırma
'- status/error sistemi
'- flags sistemi: Z, C, O, S, SGN, END, ERR, PCHG
'- @0..@12 temel servisler
'- @20..@29 aritmetik/karşılaştırma
'- @33..@36 signed/unsigned açık div/mod
'- @40..@59 trigonometrik, hiperbolik ve bilimsel servisler
'- @60..@68 decimal/hex/bin I/O
'- @80..@89 pointer/layout servisleri
'- @120..@122 signed/unsigned mode
'- @130..@135 karşılaştırma servisleri
'- @140..@149 flag servisleri
'- @150..@156 endian ve word/dword parçalama servisleri
'- @180..@185 data servislerinin başlangıcı



' ## Dosya 2 — Düzeltilmiş Tam Sürüm

' # `uxm31_runtime.bas`

' ```basic id="3rbbkv"
OPTION EXPLICIT
#LANG "fb"
Extern "C"
    Declare Sub uxm_entry()
    Declare Sub ux_putc(ByVal ch As ULongInt)
    Declare Function ux_getc() As ULongInt
    Declare Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt)
    Declare Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr)
    Declare Sub ux_runtime_error(ByVal code As ULongInt)
    Extern ux_mem As UByte
    Extern ux_status As UByte
    Extern ux_flags As UShort
    Extern ux_ptr As ULongInt
    Extern ux_sp As ULongInt
    Extern ux_cell_bits As ULong
    Extern ux_cell_bytes As ULong
    Extern ux_tape_cells As ULong
    Extern ux_stack_cells As ULong
    Extern ux_data_cells As ULong
    Extern ux_stack_offset As ULong
    Extern ux_data_offset As ULong
End Extern
Const FLAG_Z As UShort=&H0001
Const FLAG_C As UShort=&H0002
Const FLAG_O As UShort=&H0004
Const FLAG_S As UShort=&H0008
Const FLAG_SGN As UShort=&H0010
Const FLAG_END As UShort=&H0020
Const FLAG_WILD As UShort=&H0040
Const FLAG_BND As UShort=&H0080
Const FLAG_TRC As UShort=&H0100
Const FLAG_FIFO As UShort=&H0200
Const FLAG_ERR As UShort=&H0400
Const FLAG_DIRTY As UShort=&H0800
Const FLAG_PCHG As UShort=&H1000
Const STATUS_OK As UByte=0
Const STATUS_INVALID_META As UByte=5
Const STATUS_PTR_BOUNDS As UByte=10
Const STATUS_STACK_OVERFLOW As UByte=11
Const STATUS_STACK_UNDERFLOW As UByte=12
Const STATUS_OVERFLOW As UByte=13
Const STATUS_UNDERFLOW As UByte=14
Const STATUS_DIV_ZERO As UByte=15
Const STATUS_DATA_BOUNDS As UByte=16
Const STATUS_PROTECTED_META As UByte=24
Const STATUS_EOF As UByte=26
Const PI_D As Double=3.1415926535897932384626433832795
Declare Function CellMask() As ULongInt
Declare Function CellSignBit() As ULongInt
Declare Function CellMaxSigned() As LongInt
Declare Function CellMinSigned() As LongInt
Declare Function ReadCell(ByVal memPtr As UByte Ptr, ByVal cellIndex As ULongInt) As ULongInt
Declare Sub WriteCell(ByVal memPtr As UByte Ptr, ByVal cellIndex As ULongInt, ByVal value As ULongInt)
Declare Function ReadTapeRel(ByVal memPtr As UByte Ptr, ByVal rel As LongInt) As ULongInt
Declare Sub WriteTapeRel(ByVal memPtr As UByte Ptr, ByVal rel As LongInt, ByVal value As ULongInt)
Declare Function ToSignedValue(ByVal value As ULongInt) As LongInt
Declare Function FromSignedValue(ByVal value As LongInt) As ULongInt
Declare Sub SetStatus(ByVal code As UByte)
Declare Sub ClearArithFlags()
Declare Sub SetZeroSignFlags(ByVal value As ULongInt)
Declare Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetMulFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetLogicFlags(ByVal resultMasked As ULongInt)
Declare Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
Declare Function IsSignedMode() As Long
Declare Function IsBigEndian() As Long
Declare Function Arg1(ByVal memPtr As UByte Ptr) As ULongInt
Declare Function Arg2(ByVal memPtr As UByte Ptr) As ULongInt
Declare Sub SetResult(ByVal memPtr As UByte Ptr, ByVal value As ULongInt)
Declare Function ResultValue(ByVal memPtr As UByte Ptr) As ULongInt
Declare Sub PrintStatusMessage(ByVal code As ULongInt)
Declare Function ScaleFactor() As LongInt
Declare Function SinScaled(ByVal degree As Double) As LongInt
Declare Function CosScaled(ByVal degree As Double) As LongInt
Declare Function TanScaled(ByVal degree As Double) As LongInt
Declare Function SinhLocal(ByVal x As Double) As Double
Declare Function CoshLocal(ByVal x As Double) As Double
Declare Function TanhLocal(ByVal x As Double) As Double
Declare Function AsinLocal(ByVal x As Double) As Double
Declare Function AcosLocal(ByVal x As Double) As Double
Declare Function AsinhLocal(ByVal x As Double) As Double
Declare Function AcoshLocal(ByVal x As Double) As Double
Declare Function AtanhLocal(ByVal x As Double) As Double
Declare Function RandomByte() As ULongInt
Declare Sub PrintDecimalValue(ByVal value As ULongInt)
Declare Function ReadDecimalValue() As ULongInt
Declare Function ClampToCell(ByVal v As LongInt) As ULongInt
Extern "C"
Sub ux_putc(ByVal ch As ULongInt) Export
    Print Chr$(ch And &HFF);
End Sub
Function ux_getc() As ULongInt Export
    Dim s As String
    s=Inkey$
    Do While Len(s)=0
        Sleep 10
        s=Inkey$
    Loop
    ux_status=0
    ux_getc=Asc(Left$(s,1)) And &HFF
End Function
Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt) Export
    Dim memPtr As UByte Ptr
    Dim i As ULongInt
    Dim v As ULongInt
    Dim oldBits As ULong
    memPtr=@ux_mem
    oldBits=ux_cell_bits
    If cellBits=8 Or cellBits=16 Or cellBits=32 Then ux_cell_bits=cellBits
    i=startCell
    Do
        If i>=ux_data_cells Then
            SetStatus STATUS_DATA_BOUNDS
            Exit Do
        End If
        v=ReadCell(memPtr+ux_data_offset,i)
        If v=0 Then Exit Do
        Print Chr$(v And &HFF);
        i=i+1
    Loop
    ux_cell_bits=oldBits
End Sub
Sub ux_runtime_error(ByVal code As ULongInt) Export
    ux_status=code And &HFF
    ux_flags=ux_flags Or FLAG_ERR
    Print
    Print "[UXM runtime error ";Str$(code);"] ";
    PrintStatusMessage code
End Sub
Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr) Export
    Dim a As ULongInt
    Dim b As ULongInt
    Dim r As ULongInt
    Dim full As ULongInt
    Dim sf As LongInt
    Dim sb As LongInt
    Dim sr As LongInt
    Dim x As Double
    If metaId>=128 Then
        SetStatus STATUS_INVALID_META
        Exit Sub
    End If
    Select Case metaId
        Case 0
            SetStatus STATUS_OK
        Case 1
            Cls
            SetStatus STATUS_OK
        Case 2
            Locate 1,1
            SetStatus STATUS_OK
        Case 3
            SetResult memPtr,RandomByte()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 4
            SetResult memPtr,CLngInt(Timer*1000) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 5
            Print
            SetStatus STATUS_OK
        Case 6
            Print "[UXM META]";
            SetStatus STATUS_OK
        Case 7
            SetResult memPtr,7
            SetLogicFlags 7
            SetStatus STATUS_OK
        Case 8
            SetResult memPtr,8
            SetLogicFlags 8
            SetStatus STATUS_OK
        Case 9
            SetResult memPtr,ux_status
            SetLogicFlags ux_status
        Case 10
            ux_status=0
            ux_flags=ux_flags And Not FLAG_ERR
        Case 11
            ux_status=Arg1(memPtr) And &HFF
            If ux_status=0 Then
                ux_flags=ux_flags And Not FLAG_ERR
            Else
                ux_flags=ux_flags Or FLAG_ERR
            End If
        Case 12
            PrintStatusMessage ux_status
        Case 20
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            full=a+b
            r=full And CellMask()
            SetResult memPtr,r
            SetAddFlags a,b,full,r
            SetStatus STATUS_OK
        Case 21
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            r=(a-b) And CellMask()
            SetResult memPtr,r
            SetSubFlags a,b,r
            SetStatus STATUS_OK
        Case 22
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            full=a*b
            r=full And CellMask()
            SetResult memPtr,r
            SetMulFlags a,b,full,r
            If full>CellMask() Then SetStatus STATUS_OVERFLOW Else SetStatus STATUS_OK
        Case 23
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If b=0 Then
                SetResult memPtr,0
                ux_flags=ux_flags Or FLAG_O Or FLAG_C Or FLAG_Z Or FLAG_ERR
                SetStatus STATUS_DIV_ZERO
            Else
                If IsSignedMode() Then
                    sf=ToSignedValue(a)
                    sb=ToSignedValue(b)
                    sr=sf\sb
                    r=FromSignedValue(sr)
                Else
                    r=(a\b) And CellMask()
                End If
                SetResult memPtr,r
                SetZeroSignFlags r
                ux_flags=ux_flags And Not FLAG_C
                ux_flags=ux_flags And Not FLAG_O
                SetStatus STATUS_OK
            End If
        Case 24
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If b=0 Then
                SetResult memPtr,0
                ux_flags=ux_flags Or FLAG_O Or FLAG_C Or FLAG_Z Or FLAG_ERR
                SetStatus STATUS_DIV_ZERO
            Else
                If IsSignedMode() Then
                    sf=ToSignedValue(a)
                    sb=ToSignedValue(b)
                    sr=sf Mod sb
                    r=FromSignedValue(sr)
                Else
                    r=(a Mod b) And CellMask()
                End If
                SetResult memPtr,r
                SetZeroSignFlags r
                ux_flags=ux_flags And Not FLAG_C
                ux_flags=ux_flags And Not FLAG_O
                SetStatus STATUS_OK
            End If
        Case 25
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If a<b Then r=a Else r=b
            SetResult memPtr,r
            SetLogicFlags r
            SetStatus STATUS_OK
        Case 26
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If a>b Then r=a Else r=b
            SetResult memPtr,r
            SetLogicFlags r
            SetStatus STATUS_OK
        Case 27
            a=Arg2(memPtr)
            If IsSignedMode() Then
                sf=ToSignedValue(a)
                If sf<0 Then sf=-sf
                r=FromSignedValue(sf)
            Else
                r=a
            End If
            SetResult memPtr,r
            SetLogicFlags r
            SetStatus STATUS_OK
        Case 28
            a=Arg2(memPtr)
            sf=ToSignedValue(a)
            r=FromSignedValue(-sf)
            SetResult memPtr,r
            SetLogicFlags r
            SetStatus STATUS_OK
        Case 29
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            SetCompareFlags a,b
            If a=b Then
                r=0
            Elseif a>b Then
                r=1
            Else
                r=CellMask()
            End If
            SetResult memPtr,r
            SetStatus STATUS_OK
        Case 33
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If b=0 Then
                SetResult memPtr,0
                SetStatus STATUS_DIV_ZERO
            Else
                SetResult memPtr,(a\b) And CellMask()
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 34
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If b=0 Then
                SetResult memPtr,0
                SetStatus STATUS_DIV_ZERO
            Else
                SetResult memPtr,FromSignedValue(ToSignedValue(a)\ToSignedValue(b))
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 35
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If b=0 Then
                SetResult memPtr,0
                SetStatus STATUS_DIV_ZERO
            Else
                SetResult memPtr,(a Mod b) And CellMask()
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 36
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If b=0 Then
                SetResult memPtr,0
                SetStatus STATUS_DIV_ZERO
            Else
                SetResult memPtr,FromSignedValue(ToSignedValue(a) Mod ToSignedValue(b))
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 40
            a=Arg2(memPtr)
            SetResult memPtr,ClampToCell(SinScaled(CDbl(a)))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 41
            a=Arg2(memPtr)
            SetResult memPtr,ClampToCell(CosScaled(CDbl(a)))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 42
            a=Arg2(memPtr)
            If (a Mod 180)=90 Then
                SetResult memPtr,0
                ux_flags=ux_flags Or FLAG_O
                SetStatus STATUS_OVERFLOW
            Else
                SetResult memPtr,ClampToCell(TanScaled(CDbl(a)))
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 43
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            SetResult memPtr,CLngInt(Sqr(CDbl(a)*CDbl(a)+CDbl(b)*CDbl(b))) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 44
            a=Arg2(memPtr)
            x=CDbl(ToSignedValue(a))/CDbl(ScaleFactor())
            SetResult memPtr,CLngInt(AsinLocal(x)*180.0/PI_D) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 45
            a=Arg2(memPtr)
            x=CDbl(ToSignedValue(a))/CDbl(ScaleFactor())
            SetResult memPtr,CLngInt(AcosLocal(x)*180.0/PI_D) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 46
            a=Arg2(memPtr)
            SetResult memPtr,CLngInt(Sqr(CDbl(a))) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 47
            a=Arg2(memPtr)
            SetResult memPtr,ClampToCell(CLngInt(SinhLocal(CDbl(a)*PI_D/180.0)*ScaleFactor()))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 48
            a=Arg2(memPtr)
            SetResult memPtr,ClampToCell(CLngInt(CoshLocal(CDbl(a)*PI_D/180.0)*ScaleFactor()))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 49
            a=Arg2(memPtr)
            SetResult memPtr,ClampToCell(CLngInt(TanhLocal(CDbl(a)*PI_D/180.0)*ScaleFactor()))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 52
            a=Arg2(memPtr)
            x=CDbl(ToSignedValue(a))/CDbl(ScaleFactor())
            SetResult memPtr,ClampToCell(CLngInt(AsinhLocal(x)*ScaleFactor()))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 53
            a=Arg2(memPtr)
            x=CDbl(a)/CDbl(ScaleFactor())
            If x<1.0 Then
                SetResult memPtr,0
                SetStatus STATUS_UNDERFLOW
            Else
                SetResult memPtr,ClampToCell(CLngInt(AcoshLocal(x)*ScaleFactor()))
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 54
            a=Arg2(memPtr)
            x=CDbl(ToSignedValue(a))/CDbl(ScaleFactor())
            If Abs(x)>=1.0 Then
                SetResult memPtr,0
                SetStatus STATUS_OVERFLOW
            Else
                SetResult memPtr,ClampToCell(CLngInt(AtanhLocal(x)*ScaleFactor()))
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 55
            a=Arg2(memPtr)
            If a=0 Then
                SetResult memPtr,0
                SetStatus STATUS_UNDERFLOW
            Else
                SetResult memPtr,ClampToCell(CLngInt(Log(CDbl(a))*ScaleFactor()))
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 56
            a=Arg2(memPtr)
            SetResult memPtr,ClampToCell(CLngInt(Exp(CDbl(ToSignedValue(a))/CDbl(ScaleFactor()))*ScaleFactor()))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 57
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            SetResult memPtr,ClampToCell(CLngInt(CDbl(a)^CDbl(b)))
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 58
            a=Arg2(memPtr)
            SetResult memPtr,CLngInt(CDbl(a)*PI_D/180.0*ScaleFactor()) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 59
            a=Arg2(memPtr)
            SetResult memPtr,CLngInt(CDbl(a)/CDbl(ScaleFactor())*180.0/PI_D) And CellMask()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 60
            PrintDecimalValue Arg2(memPtr)
            SetStatus STATUS_OK
        Case 61
            PrintDecimalValue ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 62
            If ux_sp=0 Then
                SetStatus STATUS_STACK_UNDERFLOW
            Else
                ux_sp=ux_sp-1
                PrintDecimalValue ReadCell(memPtr+ux_stack_offset,ux_sp)
                SetStatus STATUS_OK
            End If
        Case 63
            SetResult memPtr,ReadDecimalValue()
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 64
            Print " ";
            SetStatus STATUS_OK
        Case 67
            Print Hex$(Arg2(memPtr));
            SetStatus STATUS_OK
        Case 68
            Print Bin$(Arg2(memPtr));
            SetStatus STATUS_OK
        Case 80
            a=Arg2(memPtr)
            If a>=ux_tape_cells Then
                SetStatus STATUS_PTR_BOUNDS
            Else
                ux_ptr=a
                ux_flags=ux_flags Or FLAG_PCHG
                SetStatus STATUS_OK
            End If
        Case 81
            a=Arg2(memPtr)
            If ux_ptr+a>=ux_tape_cells Then
                SetStatus STATUS_PTR_BOUNDS
            Else
                ux_ptr=ux_ptr+a
                ux_flags=ux_flags Or FLAG_PCHG
                SetStatus STATUS_OK
            End If
        Case 82
            SetResult memPtr,ux_ptr
            SetLogicFlags ux_ptr
            SetStatus STATUS_OK
        Case 83
            If ux_ptr<ux_tape_cells Then SetResult memPtr,1 Else SetResult memPtr,0
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 84
            SetResult memPtr,ux_tape_cells
            SetStatus STATUS_OK
        Case 85
            SetResult memPtr,ux_data_cells
            SetStatus STATUS_OK
        Case 86
            SetResult memPtr,ux_stack_cells
            SetStatus STATUS_OK
        Case 87
            SetResult memPtr,ux_cell_bits
            SetStatus STATUS_OK
        Case 88
            SetResult memPtr,ux_cell_bytes
            SetStatus STATUS_OK
        Case 89
            Print "[UXM layout tape=";ux_tape_cells;" stack=";ux_stack_cells;" data=";ux_data_cells;" cellbits=";ux_cell_bits;"]"
            SetStatus STATUS_OK
        Case 120
            ux_flags=ux_flags And Not FLAG_SGN
            SetStatus STATUS_OK
        Case 121
            ux_flags=ux_flags Or FLAG_SGN
            SetStatus STATUS_OK
        Case 122
            If IsSignedMode() Then SetResult memPtr,1 Else SetResult memPtr,0
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 130
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If a=b Then r=1 Else r=0
            SetResult memPtr,r
            SetCompareFlags a,b
            SetStatus STATUS_OK
        Case 131
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If a>b Then r=1 Else r=0
            SetResult memPtr,r
            SetCompareFlags a,b
            SetStatus STATUS_OK
        Case 132
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If a<b Then r=1 Else r=0
            SetResult memPtr,r
            SetCompareFlags a,b
            SetStatus STATUS_OK
        Case 133
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If ToSignedValue(a)=ToSignedValue(b) Then r=1 Else r=0
            SetResult memPtr,r
            SetCompareFlags a,b
            SetStatus STATUS_OK
        Case 134
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If ToSignedValue(a)>ToSignedValue(b) Then r=1 Else r=0
            SetResult memPtr,r
            SetCompareFlags a,b
            SetStatus STATUS_OK
        Case 135
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If ToSignedValue(a)<ToSignedValue(b) Then r=1 Else r=0
            SetResult memPtr,r
            SetCompareFlags a,b
            SetStatus STATUS_OK
        Case 140
            If (ux_flags And FLAG_C)<>0 Then SetResult memPtr,1 Else SetResult memPtr,0
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 141
            ux_flags=ux_flags Or FLAG_C
            SetStatus STATUS_OK
        Case 142
            ux_flags=ux_flags And Not FLAG_C
            SetStatus STATUS_OK
        Case 143
            If (ux_flags And FLAG_O)<>0 Then SetResult memPtr,1 Else SetResult memPtr,0
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 144
            ux_flags=ux_flags Or FLAG_O
            SetStatus STATUS_OK
        Case 145
            ux_flags=ux_flags And Not FLAG_O
            SetStatus STATUS_OK
        Case 146
            If (ux_flags And FLAG_Z)<>0 Then SetResult memPtr,1 Else SetResult memPtr,0
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 147
            If (ux_flags And FLAG_S)<>0 Then SetResult memPtr,1 Else SetResult memPtr,0
            SetLogicFlags ResultValue(memPtr)
            SetStatus STATUS_OK
        Case 148
            ux_flags=ux_flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
            SetStatus STATUS_OK
        Case 149
            SetResult memPtr,ux_flags
            SetStatus STATUS_OK
        Case 150
            ux_flags=ux_flags And Not FLAG_END
            SetStatus STATUS_OK
        Case 151
            ux_flags=ux_flags Or FLAG_END
            SetStatus STATUS_OK
        Case 152
            If IsBigEndian() Then SetResult memPtr,1 Else SetResult memPtr,0
            SetStatus STATUS_OK
        Case 153
            a=Arg2(memPtr)
            If IsBigEndian() Then
                WriteTapeRel memPtr,1,(a Shr 8) And &HFF
                WriteTapeRel memPtr,2,a And &HFF
            Else
                WriteTapeRel memPtr,1,a And &HFF
                WriteTapeRel memPtr,2,(a Shr 8) And &HFF
            End If
            SetStatus STATUS_OK
        Case 154
            If IsBigEndian() Then
                r=((ReadTapeRel(memPtr,1) And &HFF) Shl 8) Or (ReadTapeRel(memPtr,2) And &HFF)
            Else
                r=(ReadTapeRel(memPtr,1) And &HFF) Or ((ReadTapeRel(memPtr,2) And &HFF) Shl 8)
            End If
            SetResult memPtr,r
            SetLogicFlags r
            SetStatus STATUS_OK
        Case 155
            a=Arg2(memPtr)
            If IsBigEndian() Then
                WriteTapeRel memPtr,1,(a Shr 24) And &HFF
                WriteTapeRel memPtr,2,(a Shr 16) And &HFF
                WriteTapeRel memPtr,3,(a Shr 8) And &HFF
                WriteTapeRel memPtr,4,a And &HFF
            Else
                WriteTapeRel memPtr,1,a And &HFF
                WriteTapeRel memPtr,2,(a Shr 8) And &HFF
                WriteTapeRel memPtr,3,(a Shr 16) And &HFF
                WriteTapeRel memPtr,4,(a Shr 24) And &HFF
            End If
            SetStatus STATUS_OK
        Case 156
            If IsBigEndian() Then
                r=((ReadTapeRel(memPtr,1) And &HFF) Shl 24) Or ((ReadTapeRel(memPtr,2) And &HFF) Shl 16) Or ((ReadTapeRel(memPtr,3) And &HFF) Shl 8) Or (ReadTapeRel(memPtr,4) And &HFF)
            Else
                r=(ReadTapeRel(memPtr,1) And &HFF) Or ((ReadTapeRel(memPtr,2) And &HFF) Shl 8) Or ((ReadTapeRel(memPtr,3) And &HFF) Shl 16) Or ((ReadTapeRel(memPtr,4) And &HFF) Shl 24)
            End If
            SetResult memPtr,r
            SetLogicFlags r
            SetStatus STATUS_OK
        Case 180
            a=Arg2(memPtr)
            If a>=ux_data_cells Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                SetResult memPtr,ReadCell(memPtr+ux_data_offset,a)
                SetLogicFlags ResultValue(memPtr)
                SetStatus STATUS_OK
            End If
        Case 181
            a=Arg1(memPtr)
            b=Arg2(memPtr)
            If a>=ux_data_cells Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                WriteCell memPtr+ux_data_offset,a,b
                SetStatus STATUS_OK
            End If
        Case 185
            a=Arg2(memPtr)
            If a>=ux_data_cells Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                b=ReadCell(memPtr+ux_data_offset,a)
                If b>=48 And b<=57 Then
                    SetResult memPtr,b-48
                    SetLogicFlags ResultValue(memPtr)
                    SetStatus STATUS_OK
                Else
                    SetResult memPtr,0
                    SetStatus STATUS_UNDERFLOW
                End If
            End If
        Case Else
            SetStatus STATUS_INVALID_META
    End Select
End Sub
End Extern
Function CellMask() As ULongInt
    Select Case ux_cell_bits
        Case 8
            CellMask=&HFFull
        Case 16
            CellMask=&HFFFFull
        Case 32
            CellMask=&HFFFFFFFFull
        Case Else
            CellMask=&HFFull
    End Select
End Function
Function CellSignBit() As ULongInt
    Select Case ux_cell_bits
        Case 8
            CellSignBit=&H80ull
        Case 16
            CellSignBit=&H8000ull
        Case 32
            CellSignBit=&H80000000ull
        Case Else
            CellSignBit=&H80ull
    End Select
End Function
Function CellMaxSigned() As LongInt
    Select Case ux_cell_bits
        Case 8
            CellMaxSigned=127
        Case 16
            CellMaxSigned=32767
        Case 32
            CellMaxSigned=2147483647
        Case Else
            CellMaxSigned=127
    End Select
End Function
Function CellMinSigned() As LongInt
    Select Case ux_cell_bits
        Case 8
            CellMinSigned=-128
        Case 16
            CellMinSigned=-32768
        Case 32
            CellMinSigned=-2147483648
        Case Else
            CellMinSigned=-128
    End Select
End Function
Function ReadCell(ByVal memPtr As UByte Ptr, ByVal cellIndex As ULongInt) As ULongInt
    Select Case ux_cell_bits
        Case 8
            ReadCell=memPtr[cellIndex]
        Case 16
            ReadCell=CULngInt(*Cast(UShort Ptr,memPtr+cellIndex*2))
        Case 32
            ReadCell=CULngInt(*Cast(ULong Ptr,memPtr+cellIndex*4))
        Case Else
            ReadCell=memPtr[cellIndex]
    End Select
End Function
Sub WriteCell(ByVal memPtr As UByte Ptr, ByVal cellIndex As ULongInt, ByVal value As ULongInt)
    value=value And CellMask()
    Select Case ux_cell_bits
        Case 8
            memPtr[cellIndex]=value And &HFF
        Case 16
            *Cast(UShort Ptr,memPtr+cellIndex*2)=value And &HFFFF
        Case 32
            *Cast(ULong Ptr,memPtr+cellIndex*4)=value And &HFFFFFFFF
        Case Else
            memPtr[cellIndex]=value And &HFF
    End Select
End Sub
Function ReadTapeRel(ByVal memPtr As UByte Ptr, ByVal rel As LongInt) As ULongInt
    Dim idx As LongInt
    idx=CLngInt(ux_ptr)+rel
    If idx<0 Or idx>=ux_tape_cells Then
        SetStatus STATUS_PTR_BOUNDS
        ReadTapeRel=0
        Exit Function
    End If
    ReadTapeRel=ReadCell(memPtr,idx)
End Function
Sub WriteTapeRel(ByVal memPtr As UByte Ptr, ByVal rel As LongInt, ByVal value As ULongInt)
    Dim idx As LongInt
    idx=CLngInt(ux_ptr)+rel
    If idx<0 Or idx>=ux_tape_cells Then
        SetStatus STATUS_PTR_BOUNDS
        Exit Sub
    End If
    WriteCell memPtr,idx,value
End Sub
Function ToSignedValue(ByVal value As ULongInt) As LongInt
    value=value And CellMask()
    If (value And CellSignBit())<>0 Then
        ToSignedValue=CLngInt(value)-CLngInt(CellMask()+1)
    Else
        ToSignedValue=CLngInt(value)
    End If
End Function
Function FromSignedValue(ByVal value As LongInt) As ULongInt
    FromSignedValue=CULngInt(value) And CellMask()
End Function
Sub SetStatus(ByVal code As UByte)
    ux_status=code
    If code=0 Then
        ux_flags=ux_flags And Not FLAG_ERR
    Else
        ux_flags=ux_flags Or FLAG_ERR
    End If
End Sub
Sub ClearArithFlags()
    ux_flags=ux_flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
End Sub
Sub SetZeroSignFlags(ByVal value As ULongInt)
    ux_flags=ux_flags And Not (FLAG_Z Or FLAG_S)
    value=value And CellMask()
    If value=0 Then ux_flags=ux_flags Or FLAG_Z
    If (value And CellSignBit())<>0 Then ux_flags=ux_flags Or FLAG_S
End Sub
Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
    Dim sa As LongInt
    Dim sb As LongInt
    Dim sr As LongInt
    ClearArithFlags
    SetZeroSignFlags resultMasked
    If resultFull>CellMask() Then ux_flags=ux_flags Or FLAG_C
    sa=ToSignedValue(a)
    sb=ToSignedValue(b)
    sr=ToSignedValue(resultMasked)
    If ((sa>=0 And sb>=0 And sr<0) Or (sa<0 And sb<0 And sr>=0)) Then ux_flags=ux_flags Or FLAG_O
End Sub
Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultMasked As ULongInt)
    Dim sa As LongInt
    Dim sb As LongInt
    Dim sr As LongInt
    ClearArithFlags
    SetZeroSignFlags resultMasked
    If a>=b Then ux_flags=ux_flags Or FLAG_C
    sa=ToSignedValue(a)
    sb=ToSignedValue(b)
    sr=ToSignedValue(resultMasked)
    If ((sa>=0 And sb<0 And sr<0) Or (sa<0 And sb>=0 And sr>=0)) Then ux_flags=ux_flags Or FLAG_O
End Sub
Sub SetMulFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
    ClearArithFlags
    SetZeroSignFlags resultMasked
    If resultFull>CellMask() Then ux_flags=ux_flags Or FLAG_C Or FLAG_O
End Sub
Sub SetLogicFlags(ByVal resultMasked As ULongInt)
    ClearArithFlags
    SetZeroSignFlags resultMasked
End Sub
Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
    Dim r As ULongInt
    r=(a-b) And CellMask()
    ClearArithFlags
    If a=b Then ux_flags=ux_flags Or FLAG_Z
    If a>=b Then ux_flags=ux_flags Or FLAG_C
    If (r And CellSignBit())<>0 Then ux_flags=ux_flags Or FLAG_S
End Sub
Function IsSignedMode() As Long
    If (ux_flags And FLAG_SGN)<>0 Then IsSignedMode=-1 Else IsSignedMode=0
End Function
Function IsBigEndian() As Long
    If (ux_flags And FLAG_END)<>0 Then IsBigEndian=-1 Else IsBigEndian=0
End Function
Function Arg1(ByVal memPtr As UByte Ptr) As ULongInt
    Dim idx As LongInt
    idx=CLngInt(ux_ptr)-2
    If idx<0 Or idx>=ux_tape_cells Then
        SetStatus STATUS_PTR_BOUNDS
        Arg1=0
    Else
        Arg1=ReadCell(memPtr,idx)
    End If
End Function
Function Arg2(ByVal memPtr As UByte Ptr) As ULongInt
    Dim idx As LongInt
    idx=CLngInt(ux_ptr)-1
    If idx<0 Or idx>=ux_tape_cells Then
        SetStatus STATUS_PTR_BOUNDS
        Arg2=0
    Else
        Arg2=ReadCell(memPtr,idx)
    End If
End Function
Sub SetResult(ByVal memPtr As UByte Ptr, ByVal value As ULongInt)
    Dim idx As ULongInt
    idx=ux_ptr+1
    If idx>=ux_tape_cells Then
        SetStatus STATUS_PTR_BOUNDS
    Else
        WriteCell memPtr,idx,value
    End If
End Sub
Function ResultValue(ByVal memPtr As UByte Ptr) As ULongInt
    Dim idx As ULongInt
    idx=ux_ptr+1
    If idx>=ux_tape_cells Then
        SetStatus STATUS_PTR_BOUNDS
        ResultValue=0
    Else
        ResultValue=ReadCell(memPtr,idx)
    End If
End Function
Sub PrintStatusMessage(ByVal code As ULongInt)
    Select Case code
        Case 0
            Print "OK"
        Case 5
            Print "Invalid meta id"
        Case 10
            Print "Pointer out of bounds"
        Case 11
            Print "Stack overflow"
        Case 12
            Print "Stack underflow"
        Case 13
            Print "Arithmetic overflow"
        Case 14
            Print "Arithmetic underflow"
        Case 15
            Print "Division by zero"
        Case 16
            Print "Data bounds error"
        Case 24
            Print "Protected meta id"
        Case 26
            Print "EOF"
        Case Else
            Print "Unknown status"
    End Select
End Sub
Function ScaleFactor() As LongInt
    Select Case ux_cell_bits
        Case 8
            ScaleFactor=100
        Case 16
            ScaleFactor=1000
        Case 32
            ScaleFactor=10000
        Case Else
            ScaleFactor=100
    End Select
End Function
Function SinScaled(ByVal degree As Double) As LongInt
    SinScaled=CLngInt(Sin(degree*PI_D/180.0)*ScaleFactor())
End Function
Function CosScaled(ByVal degree As Double) As LongInt
    CosScaled=CLngInt(Cos(degree*PI_D/180.0)*ScaleFactor())
End Function
Function TanScaled(ByVal degree As Double) As LongInt
    TanScaled=CLngInt(Tan(degree*PI_D/180.0)*ScaleFactor())
End Function
Function SinhLocal(ByVal x As Double) As Double
    SinhLocal=(Exp(x)-Exp(-x))/2.0
End Function
Function CoshLocal(ByVal x As Double) As Double
    CoshLocal=(Exp(x)+Exp(-x))/2.0
End Function
Function TanhLocal(ByVal x As Double) As Double
    TanhLocal=SinhLocal(x)/CoshLocal(x)
End Function
Function AsinLocal(ByVal x As Double) As Double
    If x>1.0 Then x=1.0
    If x<-1.0 Then x=-1.0
    AsinLocal=Atn(x/Sqr(1.0-x*x))
End Function
Function AcosLocal(ByVal x As Double) As Double
    AcosLocal=PI_D/2.0-AsinLocal(x)
End Function
Function AsinhLocal(ByVal x As Double) As Double
    AsinhLocal=Log(x+Sqr(x*x+1.0))
End Function
Function AcoshLocal(ByVal x As Double) As Double
    AcoshLocal=Log(x+Sqr(x*x-1.0))
End Function
Function AtanhLocal(ByVal x As Double) As Double
    AtanhLocal=0.5*Log((1.0+x)/(1.0-x))
End Function
Function RandomByte() As ULongInt
    RandomByte=Int(Rnd*256) And &HFF
End Function
Sub PrintDecimalValue(ByVal value As ULongInt)
    If IsSignedMode() Then
        Print LTrim$(Str$(ToSignedValue(value)));
    Else
        Print LTrim$(Str$(value And CellMask()));
    End If
End Sub
Function ReadDecimalValue() As ULongInt
    Dim s As String
    Line Input s
    If IsSignedMode() Then
        ReadDecimalValue=FromSignedValue(CLngInt(Val(s)))
    Else
        ReadDecimalValue=CULngInt(Val(s)) And CellMask()
    End If
End Function
Function ClampToCell(ByVal v As LongInt) As ULongInt
    If IsSignedMode() Then
        If v>CellMaxSigned() Then
            ux_flags=ux_flags Or FLAG_O
            SetStatus STATUS_OVERFLOW
            v=CellMaxSigned()
        Elseif v<CellMinSigned() Then
            ux_flags=ux_flags Or FLAG_O
            SetStatus STATUS_UNDERFLOW
            v=CellMinSigned()
        End If
        ClampToCell=FromSignedValue(v)
    Else
        If v<0 Then
            ux_flags=ux_flags Or FLAG_O
            SetStatus STATUS_UNDERFLOW
            v=0
        Elseif CULngInt(v)>CellMask() Then
            ux_flags=ux_flags Or FLAG_O Or FLAG_C
            SetStatus STATUS_OVERFLOW
            v=CellMask()
        End If
        ClampToCell=CULngInt(v) And CellMask()
    End If
End Function
Randomize Timer
ux_cell_bits=8
ux_cell_bytes=1
ux_tape_cells=32768
ux_stack_cells=8192
ux_data_cells=24576
ux_stack_offset=32768
ux_data_offset=40960
ux_flags=FLAG_BND
ux_status=0
ux_ptr=0
ux_sp=0
uxm_entry
Print
Print "[UXM program finished]"
If ux_status<>0 Then
    Print "Final status: ";ux_status;" ";
    PrintStatusMessage ux_status
End If



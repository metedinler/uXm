' UXM V3.3 Stage-10 Matrix Advanced + Tensor Basic Services
' Meta range: @512..@559
'
' Matrix advanced uses the existing UX-MAT descriptor from runtime_matrix_services.bas.
' Frame convention follows MetaMatrix:
'   T-4 = dst/out descriptor base
'   T-3 = A/base descriptor
'   T-2 = B/aux descriptor
'   T-1 = p1 / row / option
'   T   = p2 / col / value
'   T+1 = scalar result/status
'
' Tensor basic descriptor layout in data[]:
'   base+0  magic = 8401
'   base+1  ndims = 2 in Stage-10
'   base+2  dim0
'   base+3  dim1
'   base+4  total elements
'   base+5  data offset = 16
'   base+6  status
'   base+16 values row-major

Const TENSOR_MAGIC As LongInt = 8401
Const TENSOR_DATA_OFFSET As LongInt = 16

Declare Function MatAdvRoundLong(ByVal x As Double) As LongInt
Declare Function MatAdvDetN(ByVal baseAddr As LongInt) As LongInt
Declare Function MatAdvRank(ByVal baseAddr As LongInt) As LongInt
Declare Function MatAdvNormInf(ByVal baseAddr As LongInt) As LongInt
Declare Function MatAdvFrobenius2(ByVal baseAddr As LongInt) As LongInt
Declare Sub MatAdvInverse2(ByVal dst As LongInt, ByVal a As LongInt)
Declare Sub MatAdvLU2(ByVal lBase As LongInt, ByVal uBase As LongInt, ByVal aBase As LongInt)
Declare Function TensorIsValid(ByVal baseAddr As LongInt) As Long
Declare Function TensorIndex2(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByRef ok As Long) As LongInt
Declare Sub TensorInit2D(ByVal baseAddr As LongInt, ByVal dim0 As LongInt, ByVal dim1 As LongInt)
Declare Sub TensorSet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
Declare Function TensorGet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
Declare Sub TensorFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
Declare Function TensorSum(ByVal baseAddr As LongInt) As LongInt
Declare Sub TensorShape(ByVal baseAddr As LongInt)

Function MatAdvRoundLong(ByVal x As Double) As LongInt
    If x>=0 Then
        Return CLngInt(x+0.5)
    Else
        Return CLngInt(x-0.5)
    End If
End Function

Function MatAdvDetN(ByVal baseAddr As LongInt) As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim piv As LongInt
    Dim best As Double
    Dim tmp As Double
    Dim factor As Double
    Dim det As Double
    Dim sign As Double
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=MatRows(baseAddr)
    If n<>MatCols(baseAddr) Or n<1 Or n>8 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    Dim a(0 To 7,0 To 7) As Double
    For i=0 To n-1
        For j=0 To n-1
            a(i,j)=CDbl(MatGet(baseAddr,i,j))
        Next j
    Next i
    det=1.0
    sign=1.0
    For k=0 To n-1
        piv=k
        best=Abs(a(k,k))
        For i=k+1 To n-1
            If Abs(a(i,k))>best Then
                best=Abs(a(i,k))
                piv=i
            End If
        Next i
        If best<0.000000001 Then
            SetStatus STATUS_OK
            Return 0
        End If
        If piv<>k Then
            For j=0 To n-1
                tmp=a(k,j)
                a(k,j)=a(piv,j)
                a(piv,j)=tmp
            Next j
            sign=-sign
        End If
        det=det*a(k,k)
        For i=k+1 To n-1
            factor=a(i,k)/a(k,k)
            For j=k+1 To n-1
                a(i,j)=a(i,j)-factor*a(k,j)
            Next j
        Next i
    Next k
    SetStatus STATUS_OK
    Return MatAdvRoundLong(det*sign)
End Function

Function MatAdvRank(ByVal baseAddr As LongInt) As LongInt
    Dim m As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim rowIdx As LongInt
    Dim colIdx As LongInt
    Dim piv As LongInt
    Dim best As Double
    Dim pv As Double
    Dim f As Double
    Dim tmp As Double
    Dim rank As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    m=MatRows(baseAddr)
    n=MatCols(baseAddr)
    If m<1 Or n<1 Or m>8 Or n>8 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    Dim a(0 To 7,0 To 7) As Double
    For i=0 To m-1
        For j=0 To n-1
            a(i,j)=CDbl(MatGet(baseAddr,i,j))
        Next j
    Next i
    rowIdx=0
    rank=0
    For colIdx=0 To n-1
        piv=rowIdx
        best=0.0
        For i=rowIdx To m-1
            If Abs(a(i,colIdx))>best Then
                best=Abs(a(i,colIdx))
                piv=i
            End If
        Next i
        If best>0.000000001 Then
            For j=colIdx To n-1
                tmp=a(rowIdx,j)
                a(rowIdx,j)=a(piv,j)
                a(piv,j)=tmp
            Next j
            pv=a(rowIdx,colIdx)
            For j=colIdx To n-1
                a(rowIdx,j)=a(rowIdx,j)/pv
            Next j
            For i=0 To m-1
                If i<>rowIdx Then
                    f=a(i,colIdx)
                    For j=colIdx To n-1
                        a(i,j)=a(i,j)-f*a(rowIdx,j)
                    Next j
                End If
            Next i
            rowIdx=rowIdx+1
            rank=rank+1
            If rowIdx=m Then Exit For
        End If
    Next colIdx
    SetStatus STATUS_OK
    Return rank
End Function

Function MatAdvNormInf(ByVal baseAddr As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim s As LongInt
    Dim best As LongInt
    Dim v As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    best=0
    For r=0 To MatRows(baseAddr)-1
        s=0
        For c=0 To MatCols(baseAddr)-1
            v=MatGet(baseAddr,r,c)
            If v<0 Then v=-v
            s=s+v
        Next c
        If s>best Then best=s
    Next r
    SetStatus STATUS_OK
    Return best
End Function

Function MatAdvFrobenius2(ByVal baseAddr As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    Dim s As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To MatRows(baseAddr)-1
        For c=0 To MatCols(baseAddr)-1
            v=MatGet(baseAddr,r,c)
            s=s+v*v
        Next c
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Sub MatAdvInverse2(ByVal dst As LongInt, ByVal a As LongInt)
    Dim a00 As LongInt
    Dim a01 As LongInt
    Dim a10 As LongInt
    Dim a11 As LongInt
    Dim det As LongInt
    If MatIsValid(a)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatRows(a)<>2 Or MatCols(a)<>2 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    a00=MatGet(a,0,0)
    a01=MatGet(a,0,1)
    a10=MatGet(a,1,0)
    a11=MatGet(a,1,1)
    det=a00*a11-a01*a10
    If det=0 Then
        SetStatus STATUS_DIV_ZERO
        Exit Sub
    End If
    MatInit dst,2,2,MatType(a),MatScale(a)
    If ux_status<>STATUS_OK Then Exit Sub
    ' Exact integer inverse for unimodular/simple matrices. Fractional inverse is reserved for fixed-point matrix type.
    MatSet dst,0,0,a11\det
    MatSet dst,0,1,(-a01)\det
    MatSet dst,1,0,(-a10)\det
    MatSet dst,1,1,a00\det
    SetStatus STATUS_OK
End Sub

Sub MatAdvLU2(ByVal lBase As LongInt, ByVal uBase As LongInt, ByVal aBase As LongInt)
    Dim a00 As LongInt
    Dim a01 As LongInt
    Dim a10 As LongInt
    Dim a11 As LongInt
    Dim l10 As LongInt
    Dim u11 As LongInt
    If MatIsValid(aBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatRows(aBase)<>2 Or MatCols(aBase)<>2 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    a00=MatGet(aBase,0,0)
    a01=MatGet(aBase,0,1)
    a10=MatGet(aBase,1,0)
    a11=MatGet(aBase,1,1)
    If a00=0 Then
        SetStatus STATUS_DIV_ZERO
        Exit Sub
    End If
    l10=a10\a00
    u11=a11-l10*a01
    MatInit lBase,2,2,MatType(aBase),MatScale(aBase)
    MatInit uBase,2,2,MatType(aBase),MatScale(aBase)
    If ux_status<>STATUS_OK Then Exit Sub
    MatSet lBase,0,0,1
    MatSet lBase,0,1,0
    MatSet lBase,1,0,l10
    MatSet lBase,1,1,1
    MatSet uBase,0,0,a00
    MatSet uBase,0,1,a01
    MatSet uBase,1,0,0
    MatSet uBase,1,1,u11
    SetStatus STATUS_OK
End Sub

Function TensorIsValid(ByVal baseAddr As LongInt) As Long
    If baseAddr<0 Or baseAddr+TENSOR_DATA_OFFSET>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr)<>TENSOR_MAGIC Then Return 0
    If ReadData(baseAddr+1)<>2 Then Return 0
    If ReadData(baseAddr+2)<=0 Or ReadData(baseAddr+3)<=0 Then Return 0
    Return -1
End Function

Function TensorIndex2(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByRef ok As Long) As LongInt
    Dim dim0 As LongInt
    Dim dim1 As LongInt
    Dim idx As LongInt
    ok=0
    If TensorIsValid(baseAddr)=0 Then Return 0
    dim0=CLngInt(ReadData(baseAddr+2))
    dim1=CLngInt(ReadData(baseAddr+3))
    If r<0 Or c<0 Or r>=dim0 Or c>=dim1 Then Return 0
    idx=baseAddr+TENSOR_DATA_OFFSET+r*dim1+c
    If idx<0 Or idx>=CLngInt(ux_data_cells) Then Return 0
    ok=-1
    Return idx
End Function

Sub TensorInit2D(ByVal baseAddr As LongInt, ByVal dim0 As LongInt, ByVal dim1 As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    If baseAddr<0 Or dim0<=0 Or dim1<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=dim0*dim1
    If baseAddr+TENSOR_DATA_OFFSET+total>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr+0,TENSOR_MAGIC
    WriteData baseAddr+1,2
    WriteData baseAddr+2,dim0
    WriteData baseAddr+3,dim1
    WriteData baseAddr+4,total
    WriteData baseAddr+5,TENSOR_DATA_OFFSET
    WriteData baseAddr+6,0
    For i=0 To total-1
        WriteData baseAddr+TENSOR_DATA_OFFSET+i,0
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorSet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
    Dim idx As LongInt
    Dim ok As Long
    idx=TensorIndex2(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData idx,ClampToCell(value)
    SetStatus STATUS_OK
End Sub

Function TensorGet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
    Dim idx As LongInt
    Dim ok As Long
    idx=TensorIndex2(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    Return CLngInt(ReadData(idx))
End Function

Sub TensorFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    If TensorIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=CLngInt(ReadData(baseAddr+4))
    For i=0 To total-1
        WriteData baseAddr+TENSOR_DATA_OFFSET+i,ClampToCell(value)
    Next i
    SetStatus STATUS_OK
End Sub

Function TensorSum(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim total As LongInt
    Dim s As LongInt
    If TensorIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    total=CLngInt(ReadData(baseAddr+4))
    s=0
    For i=0 To total-1
        s=s+CLngInt(ReadData(baseAddr+TENSOR_DATA_OFFSET+i))
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Sub TensorShape(ByVal baseAddr As LongInt)
    If TensorIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteTape CLngInt(ux_ptr)+1,ReadData(baseAddr+2)
    WriteTape CLngInt(ux_ptr)+2,ReadData(baseAddr+3)
    WriteTape CLngInt(ux_ptr)+3,ReadData(baseAddr+4)
    SetStatus STATUS_OK
End Sub

Sub MetaMatrixAdvancedTensor(ByVal metaId As ULongInt)
    Dim dst As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim p1 As LongInt
    Dim p2 As LongInt
    Dim r As LongInt
    dst=CLngInt(ReadTape(CLngInt(ux_ptr)-4))
    a=CLngInt(ReadTape(CLngInt(ux_ptr)-3))
    b=CLngInt(ReadTape(CLngInt(ux_ptr)-2))
    p1=CLngInt(ReadTape(CLngInt(ux_ptr)-1))
    p2=CLngInt(ReadTape(CLngInt(ux_ptr)))

    Select Case metaId
    Case 512
        r=MatAdvDetN(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 513
        MatAdvInverse2 dst,a
        SetResult ux_status
    Case 514
        r=MatAdvRank(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 516
        r=MatAdvNormInf(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 517
        r=MatAdvFrobenius2(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 518
        MatAdvLU2 dst,b,a
        SetResult ux_status
    Case 519
        Print "[UXM MATADV] @512 detN, @513 inv2, @514 rank, @516 normInf, @517 frob2, @518 lu2; @540.. tensor2d"
        SetStatus STATUS_OK
        SetResult STATUS_OK
    Case 540
        TensorInit2D dst,a,b
        SetResult ux_status
    Case 541
        TensorSet2D dst,a,b,p1
        SetResult ux_status
    Case 542
        r=TensorGet2D(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 543
        TensorFill dst,a
        SetResult ux_status
    Case 544
        r=TensorSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 545
        TensorShape dst
        SetResult ux_status
    Case 559
        Print "[UXM TENSOR] @540 init2d, @541 set2d, @542 get2d, @543 fill, @544 sum, @545 shape"
        SetStatus STATUS_OK
        SetResult STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub

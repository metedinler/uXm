









Mete abi, matrisler için çok sağlam bir yapı şöyle olmalı: **UX-MAT V1**.

Bu sistemde matrisler `Data` alanında blok olarak tutulur. Kullanıcı matris işlemlerini macro gibi çağırır; ağır işlemler isterse `@!N` host hızlandırıcıya gider. Böylece kullanıcı açısından komutlar hep macro olur, ama içeride hızlı FreeBASIC runtime servisleri çalışabilir.

---

# UX-MAT V1: Matris Macro Sistemi

## 1. Ana fikir

Matris şu şekilde düşünülür:

```text
Matris = Data alanında bir blok
Header = matris bilgileri
Body   = elemanlar
```

Örnek 2x3 matris:

```text
A =
[ 1  2  3
  4  5  6 ]
```

Bellekte satır satır tutulur:

```text
1, 2, 3, 4, 5, 6
```

Buna **row-major dense matrix** diyelim.

---

# 2. Matris blok formatı

Her matris `Data` alanında şu başlıkla başlar:

```text
D:BASE+0   = 77      # magic: 'M'
D:BASE+1   = 1       # version
D:BASE+2   = type    # 0 integer, 1 fixed-point, 2 UX-FP16, 3 UX-FP32
D:BASE+3   = flags
D:BASE+4   = rows
D:BASE+5   = cols
D:BASE+6   = scale   # fixed-point ölçek
D:BASE+7   = elemCells
D:BASE+8   = stride
D:BASE+9   = dataOffset
D:BASE+10  = status
D:BASE+11  = storage # 0 dense row-major
D:BASE+12  = reserved
D:BASE+13  = reserved
D:BASE+14  = reserved
D:BASE+15  = reserved
D:BASE+16  = ilk eleman
```

Varsayılan:

```text
dataOffset = 16
stride     = cols
elemCells  = 1
storage    = 0
```

Yani matris eleman adresi:

```text
elementAddress = BASE + 16 + row * cols + col
```

Örnek:

```text
A[1,2]
```

için:

```text
BASE + 16 + 1 * 3 + 2 = BASE + 21
```

---

# 3. Eleman tipleri

## Integer matris

```text
type = 0
elemCells = 1
scale = 0
```

Her eleman tek hücredir.

Örnek:

```text
1, 2, 3, 4
```

## Fixed-point matris

```text
type = 1
elemCells = 1
scale = 2
```

Bu durumda:

```text
123 = 1.23
250 = 2.50
```

Matris işlemleri yine integer gibi yapılır ama çarpma/bölmede scale dikkate alınır.

## UX-FP16 matris

```text
type = 2
elemCells = 24
```

Her eleman bir UX-FP16 bloktur.

## UX-FP32 matris

```text
type = 3
elemCells = 40
```

Her eleman bir UX-FP32 bloktur.

İlk sürümde **integer ve fixed-point** yeterli. UX-FP16/FP32 desteği ikinci aşama olsun.

---

# 4. Macro ve host meta alanı

Matris kütüphanesi için şu aralığı ayıralım:

```text
m160..m189  UX-MAT temel matris macro alanı
@!160..@!189 host hızlandırıcı servisleri

m190..m199  ileri matris işlemleri
@!190..@!199 ileri host servisleri
```

Bu aralık mantıklı çünkü:

```text
m200..m239  UX-FP floating point
m240..m254  polinom / expression / integral
```

alanını daha önce ayırmıştık.

---

# 5. Standart matris frame düzeni

Matris işlemleri 3 argümandan fazlasını ister. O yüzden geniş frame kullanalım.

## Genel matris işlem frame’i

```text
T-4 = destination matrix base
T-3 = A matrix base
T-2 = B matrix base
T-1 = param1
T   = param2
T+1 = result/status
```

## Eleman okuma/yazma frame’i

```text
T-4 = matrix base
T-3 = row
T-2 = col
T-1 = value
T+1 = result/status
```

Örnek eleman yazma:

```text
T-4 = 100   # matris base
T-3 = 1     # row
T-2 = 2     # col
T-1 = 99    # value
@162        # MAT_SET
```

Örnek eleman okuma:

```text
T-4 = 100
T-3 = 1
T-2 = 2
@163        # MAT_GET
```

Sonuç:

```text
T+1 = 99
```

---

# 6. Temel macro listesi

```text
m160  MAT_INIT
m161  MAT_CLEAR
m162  MAT_SET
m163  MAT_GET
m164  MAT_FILL
m165  MAT_COPY
m166  MAT_PRINT

m167  MAT_ADD
m168  MAT_SUB
m169  MAT_SCALAR_MUL
m170  MAT_MUL

m171  MAT_TRANSPOSE
m172  MAT_IDENTITY
m173  MAT_TRACE
m174  MAT_ROW_SWAP
m175  MAT_ROW_SCALE
m176  MAT_ROW_ADD

m177  MAT_DETERMINANT_2X2
m178  MAT_DETERMINANT_3X3
m179  MAT_INVERSE_2X2

m180  MAT_DOT
m181  MAT_VECTOR_NORM2
m182  MAT_COMPARE
m183  MAT_IS_SQUARE
m184  MAT_SHAPE
m185  MAT_PRINT_RAW

m190  MAT_GAUSS_ELIMINATION
m191  MAT_SOLVE_LINEAR
m192  MAT_INVERSE_NXN
m193  MAT_EIGEN_POWER
```

İlk çalışan sürümde şunlar yeterli:

```text
MAT_INIT
MAT_SET
MAT_GET
MAT_PRINT
MAT_ADD
MAT_SUB
MAT_SCALAR_MUL
MAT_MUL
MAT_TRANSPOSE
MAT_IDENTITY
MAT_TRACE
MAT_DETERMINANT_2X2
```

---

# 7. Macro header: `ux_mat_v1.uxm`

Kullanıcı açısından bütün işlemler macro’dur. Macro içinde host servis çağrısı vardır.

```text
# UX-MAT V1 matrix macro library
# Matrix block:
#   D:BASE+0  = 77 magic 'M'
#   D:BASE+1  = version
#   D:BASE+2  = type
#   D:BASE+3  = flags
#   D:BASE+4  = rows
#   D:BASE+5  = cols
#   D:BASE+6  = scale
#   D:BASE+7  = elemCells
#   D:BASE+8  = stride
#   D:BASE+9  = dataOffset
#   D:BASE+10 = status
#   D:BASE+11 = storage
#   D:BASE+16 = data

m160={@!160}
m161={@!161}
m162={@!162}
m163={@!163}
m164={@!164}
m165={@!165}
m166={@!166}

m167={@!167}
m168={@!168}
m169={@!169}
m170={@!170}

m171={@!171}
m172={@!172}
m173={@!173}
m174={@!174}
m175={@!175}
m176={@!176}

m177={@!177}
m178={@!178}
m179={@!179}

m180={@!180}
m181={@!181}
m182={@!182}
m183={@!183}
m184={@!184}
m185={@!185}

m190={@!190}
m191={@!191}
m192={@!192}
m193={@!193}
```

---

# 8. MAT_INIT

## Frame

```text
T-4 = matrix base
T-3 = rows
T-2 = cols
T-1 = type
T   = scale
```

Örnek:

```text
# A = D:100, 2x2 integer matrix
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
0(T-4)+k100
0(T-3)+k2
0(T-2)+k2
0(T-1)
0(T)
@160
```

Bu şunu oluşturur:

```text
D:100 = 77
D:101 = 1
D:102 = 0
D:103 = 0
D:104 = 2
D:105 = 2
D:106 = 0
D:107 = 1
D:108 = 2
D:109 = 16
D:110 = 0
D:111 = 0
```

---

# 9. MAT_SET

## Frame

```text
T-4 = matrix base
T-3 = row
T-2 = col
T-1 = value
```

Örnek:

```text
# A[0,0] = 5
0(T-4)+k100
0(T-3)
0(T-2)
0(T-1)+k5
@162
```

---

# 10. MAT_GET

## Frame

```text
T-4 = matrix base
T-3 = row
T-2 = col
T+1 = value
```

Örnek:

```text
# A[0,0] oku ve yazdır
0(T-4)+k100
0(T-3)
0(T-2)
@163
@61
```

---

# 11. MAT_ADD

## Frame

```text
T-4 = destination base
T-3 = A base
T-2 = B base
```

Örnek:

```text
# C = A + B
0(T-4)+k300
0(T-3)+k100
0(T-2)+k200
@167
```

Kural:

```text
A.rows == B.rows
A.cols == B.cols
```

Sonuç matrisi `C` aynı boyutta oluşturulur.

---

# 12. MAT_SUB

```text
C = A - B
```

Frame:

```text
T-4 = C base
T-3 = A base
T-2 = B base
@168
```

---

# 13. MAT_SCALAR_MUL

```text
B = A * scalar
```

Frame:

```text
T-4 = destination base
T-3 = A base
T-2 = scalar
```

Örnek:

```text
# B = A * 3
0(T-4)+k200
0(T-3)+k100
0(T-2)+k3
@169
```

---

# 14. MAT_MUL

```text
C = A × B
```

Frame:

```text
T-4 = C base
T-3 = A base
T-2 = B base
@170
```

Kural:

```text
A.cols == B.rows
```

Sonuç:

```text
C.rows = A.rows
C.cols = B.cols
```

Algoritma:

```text
for i = 0 to A.rows-1
    for j = 0 to B.cols-1
        sum = 0
        for k = 0 to A.cols-1
            sum += A[i,k] * B[k,j]
        C[i,j] = sum
```

UX-MINIMA’da bu saf macro olarak yazılabilir ama çok uzun olur. İlk sürümde `@!170` host hızlandırıcı daha mantıklı.

---

# 15. MAT_TRANSPOSE

```text
B = transpose(A)
```

Frame:

```text
T-4 = B base
T-3 = A base
@171
```

Örnek:

```text
A =
[1 2 3
 4 5 6]

B =
[1 4
 2 5
 3 6]
```

---

# 16. MAT_IDENTITY

Birim matris oluşturur.

Frame:

```text
T-4 = matrix base
T-3 = size
T-2 = type
T-1 = scale
```

Örnek:

```text
# I = 3x3 identity matrix
0(T-4)+k100
0(T-3)+k3
0(T-2)
0(T-1)
@172
```

Sonuç:

```text
[1 0 0
 0 1 0
 0 0 1]
```

---

# 17. MAT_TRACE

Kare matrisin diagonal toplamı.

Frame:

```text
T-3 = A base
T+1 = trace result
@173
```

Örnek:

```text
A =
[1 2
 3 4]

trace = 1 + 4 = 5
```

---

# 18. MAT_DETERMINANT_2X2

2x2 determinant:

```text
|a b|
|c d|

det = ad - bc
```

Frame:

```text
T-3 = A base
T+1 = determinant
@177
```

Örnek:

```text
A =
[1 2
 3 4]

det = 1*4 - 2*3 = -2
```

Unsigned byte modda negatif sonuç sorun çıkarır. O yüzden determinant için şunlar önerilir:

```text
#cell word
#compare signed
```

veya fixed-point/signed runtime.

---

# 19. MAT_INVERSE_2X2

2x2 matrisin tersi:

```text
A =
[a b
 c d]

A^-1 = 1/det * [ d -b
                -c  a ]
```

Bu işlem kesirli sonuç verebilir. O yüzden integer matris için doğrudan ters almak çoğu zaman doğru olmaz. Burada iki seçenek var:

```text
1. fixed-point matrix type = 1 kullan
2. UX-FP matrix type = 2/3 kullan
```

İlk sürümde `MAT_INVERSE_2X2` sadece fixed-point için anlamlı olsun.

---

# 20. Matris için ARGE parse komutları

Compiler’a mutlaka şu komutları ekleyelim:

```text
#matrix BASE rows cols = values...
#matrix-fixed BASE rows cols scale = values...
#identity BASE size
```

Örnek:

```text
#matrix 100 2 2 = 1,2,3,4
```

Compiler bunu şuna çevirir:

```text
D:100 = 77
D:101 = 1
D:102 = 0
D:103 = 0
D:104 = 2
D:105 = 2
D:106 = 0
D:107 = 1
D:108 = 2
D:109 = 16
D:110 = 0
D:111 = 0
D:116 = 1
D:117 = 2
D:118 = 3
D:119 = 4
```

Örnek fixed:

```text
#matrix-fixed 200 2 2 2 = 1.25,2.50,3.00,4.75
```

Compiler scale=2 ile şuna çevirir:

```text
1.25 → 125
2.50 → 250
3.00 → 300
4.75 → 475
```

---

# 21. Runtime servis taslağı

Runtime tarafında yeni yönlendirme:

```freebasic
ElseIf metaId>=160 And metaId<=193 Then
    MetaMatrix metaId
```

Ana servis:

```freebasic
Sub MetaMatrix(ByVal metaId As ULongInt)
    Dim dst As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim p1 As LongInt
    Dim p2 As LongInt

    dst = CLngInt(ReadTape(CLngInt(ux_ptr)-4))
    a   = CLngInt(ReadTape(CLngInt(ux_ptr)-3))
    b   = CLngInt(ReadTape(CLngInt(ux_ptr)-2))
    p1  = CLngInt(ReadTape(CLngInt(ux_ptr)-1))
    p2  = CLngInt(ReadTape(CLngInt(ux_ptr)))

    Select Case metaId
    Case 160
        MatInit dst,a,b,p1,p2
        SetResult ux_status
    Case 162
        MatSet dst,a,b,p1
        SetResult ux_status
    Case 163
        SetResult MatGet(dst,a,b)
    Case 166
        MatPrint a
        SetResult ux_status
    Case 167
        MatAdd dst,a,b
        SetResult ux_status
    Case 168
        MatSub dst,a,b
        SetResult ux_status
    Case 169
        MatScalarMul dst,a,b
        SetResult ux_status
    Case 170
        MatMul dst,a,b
        SetResult ux_status
    Case 171
        MatTranspose dst,a
        SetResult ux_status
    Case 172
        MatIdentity dst,a,b,p1
        SetResult ux_status
    Case 173
        SetResult MatTrace(a)
    Case 177
        SetResult MatDet2(a)
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
```

---

# 22. Temel runtime yardımcıları

```freebasic
Function MatRows(ByVal base As LongInt) As LongInt
    Return CLngInt(ReadData(base+4))
End Function

Function MatCols(ByVal base As LongInt) As LongInt
    Return CLngInt(ReadData(base+5))
End Function

Function MatScale(ByVal base As LongInt) As LongInt
    Return CLngInt(ReadData(base+6))
End Function

Function MatElemCells(ByVal base As LongInt) As LongInt
    Return CLngInt(ReadData(base+7))
End Function

Function MatStride(ByVal base As LongInt) As LongInt
    Return CLngInt(ReadData(base+8))
End Function

Function MatDataOffset(ByVal base As LongInt) As LongInt
    Return CLngInt(ReadData(base+9))
End Function

Function MatIndex(ByVal base As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
    Return base + MatDataOffset(base) + r * MatStride(base) + c * MatElemCells(base)
End Function

Function MatValid(ByVal base As LongInt) As Long
    If ReadData(base)<>77 Then Return 0
    If ReadData(base+1)<>1 Then Return 0
    Return -1
End Function
```

---

# 23. Runtime temel işlemler

```freebasic
Sub MatInit(ByVal base As LongInt, ByVal rows As LongInt, ByVal cols As LongInt, ByVal typ As LongInt, ByVal scale As LongInt)
    If base<0 Or rows<=0 Or cols<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    WriteData base+0,77
    WriteData base+1,1
    WriteData base+2,typ
    WriteData base+3,0
    WriteData base+4,rows
    WriteData base+5,cols
    WriteData base+6,scale

    If typ=0 Or typ=1 Then
        WriteData base+7,1
    ElseIf typ=2 Then
        WriteData base+7,24
    ElseIf typ=3 Then
        WriteData base+7,40
    Else
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    WriteData base+8,cols
    WriteData base+9,16
    WriteData base+10,0
    WriteData base+11,0

    SetStatus STATUS_OK
End Sub

Sub MatSet(ByVal base As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
    Dim idx As LongInt

    If MatValid(base)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    If r<0 Or c<0 Or r>=MatRows(base) Or c>=MatCols(base) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    idx=MatIndex(base,r,c)
    WriteData idx,value
    SetStatus STATUS_OK
End Sub

Function MatGet(ByVal base As LongInt, ByVal r As LongInt, ByVal c As LongInt) As ULongInt
    Dim idx As LongInt

    If MatValid(base)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If

    If r<0 Or c<0 Or r>=MatRows(base) Or c>=MatCols(base) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If

    idx=MatIndex(base,r,c)
    SetStatus STATUS_OK
    Return ReadData(idx)
End Function
```

---

# 24. Matris toplama

```freebasic
Sub MatAdd(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim rows As LongInt
    Dim cols As LongInt
    Dim v As LongInt

    If MatValid(a)=0 Or MatValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    rows=MatRows(a)
    cols=MatCols(a)

    If rows<>MatRows(b) Or cols<>MatCols(b) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    MatInit dst,rows,cols,ReadData(a+2),ReadData(a+6)

    For r=0 To rows-1
        For c=0 To cols-1
            v=CLngInt(MatGet(a,r,c))+CLngInt(MatGet(b,r,c))
            MatSet dst,r,c,v
        Next c
    Next r

    SetStatus STATUS_OK
End Sub
```

---

# 25. Matris çarpımı

```freebasic
Sub MatMul(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim sum As LongInt
    Dim rowsA As LongInt
    Dim colsA As LongInt
    Dim rowsB As LongInt
    Dim colsB As LongInt

    If MatValid(a)=0 Or MatValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    rowsA=MatRows(a)
    colsA=MatCols(a)
    rowsB=MatRows(b)
    colsB=MatCols(b)

    If colsA<>rowsB Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    MatInit dst,rowsA,colsB,ReadData(a+2),ReadData(a+6)

    For i=0 To rowsA-1
        For j=0 To colsB-1
            sum=0
            For k=0 To colsA-1
                sum=sum+CLngInt(MatGet(a,i,k))*CLngInt(MatGet(b,k,j))
            Next k
            MatSet dst,i,j,sum
        Next j
    Next i

    SetStatus STATUS_OK
End Sub
```

---

# 26. Matris yazdırma

```freebasic
Sub MatPrint(ByVal base As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim rows As LongInt
    Dim cols As LongInt

    If MatValid(base)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If

    rows=MatRows(base)
    cols=MatCols(base)

    For r=0 To rows-1
        Print "[";
        For c=0 To cols-1
            Print LTrim(Str(MatGet(base,r,c)));
            If c<cols-1 Then Print " ";
        Next c
        Print "]"
    Next r

    SetStatus STATUS_OK
End Sub
```

---

# 27. Test örneği: 2x2 matris toplama

```text
# TEST: Matrix add
# EXPECT_OUTPUT:
# [6 8]
# [10 12]

# A = D:100
# B = D:200
# C = D:300

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# A init 2x2
0(T-4)+k100
0(T-3)+k2
0(T-2)+k2
0(T-1)
0(T)
@160

# B init 2x2
0(T-4)+k200
0(T-3)+k2
0(T-2)+k2
0(T-1)
0(T)
@160

# A values
0(T-4)+k100
0(T-3)
0(T-2)
0(T-1)+k1
@162

0(T-4)+k100
0(T-3)
0(T-2)+k1
0(T-1)+k2
@162

0(T-4)+k100
0(T-3)+k1
0(T-2)
0(T-1)+k3
@162

0(T-4)+k100
0(T-3)+k1
0(T-2)+k1
0(T-1)+k4
@162

# B values
0(T-4)+k200
0(T-3)
0(T-2)
0(T-1)+k5
@162

0(T-4)+k200
0(T-3)
0(T-2)+k1
0(T-1)+k6
@162

0(T-4)+k200
0(T-3)+k1
0(T-2)
0(T-1)+k7
@162

0(T-4)+k200
0(T-3)+k1
0(T-2)+k1
0(T-1)+k8
@162

# C = A + B
0(T-4)+k300
0(T-3)+k100
0(T-2)+k200
@167

# print C
0(T-3)+k300
@166
```

Beklenen çıktı:

```text
[6 8]
[10 12]
```

---

# 28. Test örneği: 2x2 matris çarpımı

```text
# TEST: Matrix multiply
# A=[1 2; 3 4]
# B=[5 6; 7 8]
# C=A*B
# EXPECT_OUTPUT:
# [19 22]
# [43 50]

# A ve B önceki testteki gibi oluşturulur.
# Sonra:

0(T-4)+k300
0(T-3)+k100
0(T-2)+k200
@170

0(T-3)+k300
@166
```

---

# 29. Compiler ARGE `#matrix` komutu

Bence kullanıcı sürekli `@162 MAT_SET` yazmak zorunda kalmamalı. Bu yüzden compiler’a şu komut kesin eklenmeli:

```text
#matrix 100 2 2 = 1,2,3,4
#matrix 200 2 2 = 5,6,7,8
```

Sonra kullanıcı sadece şunu yazar:

```text
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
0(T-4)+k300
0(T-3)+k100
0(T-2)+k200
@170
0(T-3)+k300
@166
```

Bu çok daha güzel olur.

---

# 30. VS Code IDE gösterimi

IDE’de özel panel şöyle olmalı:

```text
UX-MINIMA Matrix Blocks
├─ Matrix D:100
│  ├─ shape: 2 x 2
│  ├─ type: integer
│  └─ values:
│     [1 2]
│     [3 4]
├─ Matrix D:200
│  ├─ shape: 2 x 2
│  └─ values:
│     [5 6]
│     [7 8]
└─ Matrix D:300
   ├─ shape: 2 x 2
   └─ values:
      [19 22]
      [43 50]
```

Copilot dokümanına da şu kural eklenmeli:

```text
UX-MAT matrisleri Data alanında D:BASE blokları olarak tutulur.
#matrix BASE rows cols = values... sözdizimi kullanılır.
Matris işlemleri m160..m193 macro aralığındadır.
Host hızlandırıcı çağrıları @!160..@!193 aralığındadır.
```

---

# Son karar

Mete abi, matris sistemi için en sağlam tasarım şudur:

```text
Adı:
    UX-MAT V1

Bellek:
    Data block matrix

İlk format:
    dense row-major

İlk tip:
    integer ve fixed-point

İleri tip:
    UX-FP16 / UX-FP32 matrix

Macro alanı:
    m160..m193

Host meta:
    @!160..@!193

Compiler ARGE:
    #matrix
    #matrix-fixed
    #identity

IDE:
    Matrix Blocks paneli

İlk zorunlu işlemler:
    init, set, get, print,
    add, sub, scalar_mul,
    mul, transpose,
    identity, trace,
    determinant_2x2
```

Bu sistem hem küçük testler için yeterli olur hem de ileride yapay zeka, genetik algoritma, lineer cebir, regresyon, PCA, küçük neural network ve bilimsel hesaplar için temel oluşturur.


Evet Mete abi, **var**. Tasarım iyi bir başlangıç ama hâlâ “tam matris sistemi” olmak için eksikleri var. En büyük eksik şu: önceki tasarım **matris veri formatını ve temel işlemleri tanımlıyor**, ama **bellek güvenliği, veri tipi, fixed-point doğruluğu, büyük matris yönetimi, hata kodları, parser/IDE entegrasyonu ve sayısal kararlılık** tarafı eksik kalıyor.

Bence eksikleri şöyle düzeltmeliyiz.

## 1. En büyük eksik: bellek çakışma kontrolü

Şu an `#matrix 100 2 2 = ...` dediğimizde matris D:100’den başlıyor. Ama D:100’deki matrisin kaç hücre kapladığını compiler kontrol etmiyor.

Örneğin:

```text
#matrix 100 10 10 = ...
#matrix 150 5 5 = ...
```

10x10 matris yaklaşık şöyle yer kaplar:

```text
header 16 hücre
100 eleman
toplam 116 hücre
D:100..D:215 arası
```

Ama ikinci matris D:150’den başlarsa çakışır. Bu yüzden compiler’da mutlaka **data block allocation map** olmalı.

Gerekli kural:

```text
Matris blokları çakışamaz.
String, FP blok, poly blok, expr blok ve matrix blok aynı data alanına binemez.
```

Bu çok önemli.

---

## 2. Header eksik: toplam eleman sayısı ve blok boyutu yok

Mevcut header:

```text
D:BASE+4 = rows
D:BASE+5 = cols
D:BASE+7 = elemCells
D:BASE+8 = stride
D:BASE+9 = dataOffset
```

Ama şunlar da olmalı:

```text
D:BASE+12 = totalElements
D:BASE+13 = totalCells
D:BASE+14 = capacityRows
D:BASE+15 = capacityCols
```

Böylece runtime şunu bilir:

```text
bu matris kaç eleman tutuyor
bu blok kaç data hücresi kaplıyor
ileride resize yapılabilir mi
```

Düzeltilmiş header:

```text
D:BASE+0   = 77      # magic 'M'
D:BASE+1   = 1       # version
D:BASE+2   = type
D:BASE+3   = flags
D:BASE+4   = rows
D:BASE+5   = cols
D:BASE+6   = scale
D:BASE+7   = elemCells
D:BASE+8   = stride
D:BASE+9   = dataOffset
D:BASE+10  = status
D:BASE+11  = storage
D:BASE+12  = totalElements
D:BASE+13  = totalCells
D:BASE+14  = capacityRows
D:BASE+15  = capacityCols
D:BASE+16  = data başlangıcı
```

---

## 3. Signed / unsigned ve negatif değer sorunu

Matrislerde negatif sayılar mutlaka olacak.

Örneğin determinant:

```text
[1 2]
[3 4]

det = 1*4 - 2*3 = -2
```

Byte unsigned modda `-2` doğrudan bozulur.

Bu yüzden matris sistemi kendi içinde şunu taşımalı:

```text
matrix flags içinde signed bilgisi
```

Öneri:

```text
MAT_FLAG_SIGNED = 1
MAT_FLAG_FIXED  = 2
MAT_FLAG_VIEW   = 4
MAT_FLAG_DIRTY  = 8
```

Yani `#matrix-signed` veya `#matrix-fixed` gibi komutlar olmalı.

Örnek:

```text
#matrix-signed 100 2 2 = 1,2,3,4
```

---

## 4. Fixed-point çarpımda scale düzeltmesi eksik

Eğer fixed-point matris yaparsak:

```text
scale = 2
125 = 1.25
250 = 2.50
```

Toplama kolaydır:

```text
125 + 250 = 375 → 3.75
```

Ama çarpma farklıdır:

```text
1.25 * 2.50 = 3.125
```

Hücre değerleriyle:

```text
125 * 250 = 31250
```

Bunu tekrar scale=2’ye indirmek gerekir:

```text
31250 / 100 = 312
```

Yani:

```text
3.12
```

Bu yüzden `MAT_MUL` fixed-point için şöyle olmalı:

```text
sum += (A[i,k] * B[k,j]) / 10^scale
```

Önceki tasarımda bu eksikti.

---

## 5. UX-FP16 / UX-FP32 matris desteği eksik kalır

Header’da `type=2 UX-FP16`, `type=3 UX-FP32` dedik ama işlem algoritmaları integer gibi yazıldı. Bu yeterli değil.

Çünkü UX-FP16 elemanı tek hücre değil, 24 hücrelik bloktur.

Yani şu formül:

```text
MatIndex = base + dataOffset + row * stride + col
```

integer için doğru ama FP için yetersiz. FP için:

```text
MatIndex = base + dataOffset + (row * cols + col) * elemCells
```

ve eleman üzerinde işlem yapılırken `@210 FP_ADD`, `@212 FP_MUL` gibi FP servisleri çağrılmalı.

Bu yüzden V1’de açıkça demeliyiz:

```text
UX-MAT V1: integer + fixed-point
UX-MAT V2: UX-FP16 / UX-FP32 matrix
```

Yoksa tasarım kağıt üzerinde fazla iddialı olur.

---

## 6. View / transpose tasarımı eksik

Transpose işlemini iki şekilde yapabiliriz:

### A) Gerçek kopya

```text
B = transpose(A)
```

Yeni matris oluşturur.

### B) View

Aynı veriyi başka açıdan gösterir. Bellek kopyalamaz.

Örneğin:

```text
A rows=2 cols=3
A^T rows=3 cols=2
```

Ama data aynı kalır, sadece `flags=VIEW`, `stride`, `storage` değişir.

İlk tasarımda `stride` var ama view mantığı tam tanımlı değil. Eğer view koyacaksak header’a şunlar da gerekir:

```text
D:BASE+16 = parentBase
D:BASE+17 = rowStride
D:BASE+18 = colStride
D:BASE+19 = baseOffset
```

Ama bu, V1’i karmaşıklaştırır. Bence V1’de transpose **kopya üretsin**, view sonra gelsin.

---

## 7. Büyük matrislerde overflow ve hız sorunu

Byte/word/dword hücrelerde matris çarpımı hızla taşar.

Örnek:

```text
A[i,k] = 200
B[k,j] = 200
200 * 200 = 40000
```

Byte modda imkânsız, word modda sınırda, birkaç toplamda taşar.

Bu yüzden matris işlemleri için önerilen default:

```text
#cell dword
#compare signed
```

veya fixed-point için:

```text
#cell dword
#matrix-fixed ...
```

Kılavuzda bunu net yazmak gerekir:

```text
Matris işlemleri için byte mod sadece eğitim/test içindir.
Gerçek hesap için word veya dword önerilir.
```

---

## 8. Hata kodları eksik

Matris sistemi kendi hata kodlarını üretmeli.

Öneri:

```text
40 MAT_OK
41 MAT_INVALID_MAGIC
42 MAT_DIM_MISMATCH
43 MAT_OUT_OF_RANGE
44 MAT_NOT_SQUARE
45 MAT_SINGULAR
46 MAT_TYPE_MISMATCH
47 MAT_OVERFLOW
48 MAT_UNSUPPORTED_TYPE
49 MAT_ALLOCATION_OVERLAP
```

Bunlar `D:BASE+10` matris status alanına da yazılmalı, genel `ux_status` içine de aktarılmalı.

---

## 9. `#matrix` parser çok önemli ama eksik

Kullanıcı sürekli şu şekilde matris girmemeli:

```text
0(D:116)+k1
0(D:117)+k2
0(D:118)+k3
```

Bu pratik değil.

Compiler ARGE komutları şart:

```text
#matrix 100 2 2 = 1,2,3,4
#matrix-signed 100 2 2 = 1,-2,3,-4
#matrix-fixed 200 2 2 scale=2 = 1.25,2.50,3.00,4.75
#identity 300 3
#zeros 400 5 5
#ones 500 3 3
```

Bu olmadan UX-MAT kullanışsız olur.

---

## 10. Matrix print yetersiz

`MatPrint` şu an sadece integer basıyor.

Ama şunları desteklemeli:

```text
integer print
signed print
fixed-point print
raw print
shape print
pretty print
```

Örneğin fixed-point:

```text
[1.25 2.50]
[3.00 4.75]
```

Bu ayrı servis olabilir:

```text
@166 MAT_PRINT
@185 MAT_PRINT_RAW
@186 MAT_PRINT_SHAPE
```

---

## 11. Determinant ve inverse çok erken eklenmiş

2x2 determinant güzel. Ama 3x3 determinant, inverse, Gaussian elimination, eigenvalue gibi işler V1’e hemen konursa sistem dağılır.

Daha doğru aşamalar:

```text
UX-MAT V1:
    init, set, get, print
    add, sub, scalar_mul
    mul, transpose
    identity, trace
    det2

UX-MAT V1.1:
    fixed-point print
    matrix parser
    test runner

UX-MAT V2:
    determinant NxN
    Gaussian elimination
    solve linear system

UX-MAT V3:
    inverse
    eigen power method
    neural network matrix ops
```

---

## 12. Test planı eksik

Matris sistemi için şu testler şart:

```text
1. 1x1 matrix init/get/set
2. 2x2 add
3. 2x2 sub
4. scalar multiply
5. 2x2 multiply
6. 2x3 × 3x2 multiply
7. dimension mismatch hata testi
8. out-of-range row/col testi
9. identity 3x3 testi
10. transpose 2x3 testi
11. trace 3x3 testi
12. determinant 2x2 signed testi
13. fixed-point add testi
14. fixed-point multiply scale testi
15. memory overlap testi
```

---

# Düzeltilmiş net V1 tasarımı

Bence final V1 şöyle olmalı:

```text
UX-MAT V1 hedefi:
    Dense row-major matrix
    integer + signed + fixed-point
    data block storage
    compiler #matrix parser
    runtime host meta servisleri
    VS Code matrix viewer
```

V1 macro aralığı:

```text
m160 MAT_INIT
m161 MAT_CLEAR
m162 MAT_SET
m163 MAT_GET
m164 MAT_FILL
m165 MAT_COPY
m166 MAT_PRINT
m167 MAT_ADD
m168 MAT_SUB
m169 MAT_SCALAR_MUL
m170 MAT_MUL
m171 MAT_TRANSPOSE
m172 MAT_IDENTITY
m173 MAT_TRACE
m174 MAT_SHAPE
m175 MAT_DET2
m176 MAT_PRINT_RAW
```

V1’de şunları şimdilik dışarıda bırakalım:

```text
inverse
eigen
NxN determinant
sparse matrix
view matrix
UX-FP matrix
```

Onlar V2/V3 olsun.

---

# Kısa cevap

Evet, tasarımın eksikleri var. En önemlileri:

```text
1. Bellek çakışma kontrolü yok.
2. Signed/negative sayı sistemi net değil.
3. Fixed-point çarpımda scale düzeltmesi eksik.
4. UX-FP matris tipi erken ve eksik tanımlanmış.
5. View/transpose mantığı net değil.
6. Hata kodları eksik.
7. #matrix parser şart.
8. Test planı eksik.
9. Matrix print sadece integer düzeyinde kalmış.
10. V1 kapsamı fazla geniş tutulmuş.
```

Benim önerim: **UX-MAT V1’i daraltalım ama sağlam yapalım.**

Önce sadece:

```text
integer / signed / fixed-point
init / set / get / print
add / sub / scalar / multiply
transpose / identity / trace / det2
#matrix parser
VS Code matrix viewer
```

Bunları taş gibi yapalım. Sonra determinant NxN, inverse, UX-FP matris ve neural network için genişletiriz.


Mete abi, compiler’ın derlenmesine çok sevindim. Biraz sorun çıkıp 1 saatte çözülmesi normal; bu tarz compiler/toolchain işlerinde asıl kritik şey artık “derlenen bir gövde” olması. Bundan sonra tasarımı daha taş gibi kurabiliriz.

Matris tarafında bence doğru karar şu: **bunu yalnızca matris değil, genişletilebilir çok boyutlu dizi temeli olarak tasarlayalım.** Ama V1’i dar ve sağlam tutalım. Yani V1’de kullanıcı 1D vektör ve 2D matris kullanabilsin; header yapısı ileride 3D/ND diziye genişleyebilsin.

# UX-MAT V1 ana hedefi

UX-MAT V1 şu ilkelere göre kurulmalı:

```text
1. Normal ve safe mode’da çalışmalı.
2. Wild mode gerektirmemeli.
3. Compiler’a en az değişiklikle eklenmeli.
4. Macro olarak kullanılmalı.
5. Macro numaraları önceki UXM/FP/math sistemleriyle çakışmamalı.
6. Data alanında blok yapısı kullanmalı.
7. Integer, signed integer ve fixed-point desteklemeli.
8. Uzun yoldan da yapılabilmeli; yani kullanıcı isterse MAT_SET / MAT_GET / MAT_ADD ile her şeyi kurabilmeli.
9. Host hızlandırıcı varsa @!N ile çalışmalı.
10. Native ASM derlemeye uygun olmalı.
```

Bence matris macro aralığı kesin şöyle olsun:

```text
m160..m189  UX-MAT V1 temel matris/dizi macro alanı
@!160..@!189 host/runtime hızlandırıcı alanı

m190..m199  UX-MAT V2 ileri lineer cebir için rezerve
@!190..@!199 host/runtime ileri servis alanı
```

Böylece önceki sistemlerle çakışmaz:

```text
m128..m159  genel kullanıcı macro alanı / küçük yardımcılar
m160..m199  matrix / array
m200..m239  UX-FP decimal floating point
m240..m254  polynomial / expression / derivative / integral
```

# En doğru temel: UX-ARRAY header

Matris aslında çok boyutlu dizidir. Bu yüzden header’ı sadece “matrix” diye değil, **array/matrix block** diye düşünelim.

V1’de `rank=1` vektör, `rank=2` matris desteklenir. V2’de `rank=3`, `rank=N` gelir.

## Blok formatı

```text
D:BASE+0   = 77      # magic 'M' / Matrix-Array block
D:BASE+1   = 1       # version
D:BASE+2   = rank    # 1 vector, 2 matrix
D:BASE+3   = type    # 0 uint, 1 signed, 2 fixed
D:BASE+4   = flags
D:BASE+5   = rows    # rank=2 için rows, rank=1 için length
D:BASE+6   = cols    # rank=2 için cols, rank=1 için 1
D:BASE+7   = scale   # fixed-point decimal scale
D:BASE+8   = elemCells
D:BASE+9   = dataOffset
D:BASE+10  = totalElements
D:BASE+11  = totalCells
D:BASE+12  = rowStride
D:BASE+13  = colStride
D:BASE+14  = status
D:BASE+15  = reserved
D:BASE+16  = data başlangıcı
```

Varsayılan dense row-major matris için:

```text
elemCells     = 1
dataOffset    = 16
totalElements = rows * cols
totalCells    = 16 + rows * cols
rowStride     = cols
colStride     = 1
```

Eleman adresi:

```text
index = BASE + dataOffset + row * rowStride + col * colStride
```

Bu çok sağlam olur. Çünkü ileride transpose view, submatrix view, image buffer, neural network weight matrix gibi şeyleri `stride` mantığıyla genişletebiliriz. V1’de view yapmayız ama header hazır olur.

# Type sistemi

V1’de üç tip yeterli:

```text
type = 0  unsigned integer
type = 1  signed integer
type = 2  fixed-point integer
```

UX-FP16/UX-FP32 matris V1’e girmesin. Header’da ileride yer açılabilir ama V1’de “desteklenmiyor” dönsün. Çünkü FP matris girerse her eleman 24/40 hücre olacak, işlem algoritması tamamen farklılaşacak.

Fixed-point için:

```text
scale = 2  ise 125 = 1.25
scale = 3  ise 1250 = 1.250
scale = 6  ise 1234567 = 1.234567
```

Toplama/çıkarma aynı scale içinde yapılır. Çarpımda düzeltme gerekir:

```text
fixed_mul_result = (a * b) / 10^scale
```

Bu kural kesin olmalı.

# Status / hata kodları

Matris işlemleri kendi hata kodlarını üretmeli. Bunlar hem `D:BASE+14` içine, hem de genel `ux_status` içine yazılabilir.

```text
40 MAT_OK
41 MAT_INVALID_MAGIC
42 MAT_DIM_MISMATCH
43 MAT_OUT_OF_RANGE
44 MAT_NOT_SQUARE
45 MAT_SINGULAR
46 MAT_TYPE_MISMATCH
47 MAT_OVERFLOW
48 MAT_UNSUPPORTED_TYPE
49 MAT_ALLOCATION_OVERLAP
50 MAT_BAD_RANK
51 MAT_BAD_SCALE
52 MAT_NOT_IMPLEMENTED
```

Bu sayede IDE de doğrudan gösterir:

```text
Matrix D:300 status = 42 MAT_DIM_MISMATCH
```

# Macro API

Kullanıcı yalnızca macro çağırır. Macro içinde `@!N` host hızlandırıcıya gider.

```text
m160={@!160}  MAT_INIT
m161={@!161}  MAT_CLEAR
m162={@!162}  MAT_SET
m163={@!163}  MAT_GET
m164={@!164}  MAT_FILL
m165={@!165}  MAT_COPY
m166={@!166}  MAT_PRINT
m167={@!167}  MAT_ADD
m168={@!168}  MAT_SUB
m169={@!169}  MAT_SCALAR_MUL
m170={@!170}  MAT_MUL
m171={@!171}  MAT_TRANSPOSE_COPY
m172={@!172}  MAT_IDENTITY
m173={@!173}  MAT_TRACE
m174={@!174}  MAT_SHAPE
m175={@!175}  MAT_DET2
m176={@!176}  MAT_PRINT_RAW
m177={@!177}  MAT_ROW_SWAP
m178={@!178}  MAT_ROW_SCALE
m179={@!179}  MAT_ROW_ADD
m180={@!180}  VEC_DOT
m181={@!181}  VEC_NORM2_INT
m182={@!182}  MAT_COMPARE_SHAPE
m183={@!183}  MAT_IS_SQUARE
m184={@!184}  MAT_TO_SCREEN_CHARS
m185={@!185}  MAT_FROM_SCREEN_CHARS
```

V2 için rezerve:

```text
m190={@!190}  MAT_GAUSS_ELIM
m191={@!191}  MAT_SOLVE_LINEAR
m192={@!192}  MAT_INVERSE_NXN
m193={@!193}  MAT_DET_NXN
m194={@!194}  MAT_EIGEN_POWER
```

V1’de `m190..m194` tanımlı olabilir ama `MAT_NOT_IMPLEMENTED` döndürür. Böylece geleceğe yer açılır.

# Frame düzeni

Matris işlemleri için 5 hücrelik geniş frame kullanalım:

```text
T-4 = destination / matrix base
T-3 = A base / row / rows
T-2 = B base / col / cols
T-1 = param1 / value / type
T   = param2 / scale
T+1 = result / status
```

Bu, önceki `T-2/T-1/T/T+1` frame’den daha geniş ama matris için şart. Kullanıcı pointer’ı güvenli bir frame alanına alır, örneğin `T:30`.

```text
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
```

# Temel kullanım örneği

2x2 matris oluşturma:

```text
# A = D:100, 2x2 signed integer matrix
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

0(T-4)+k100
0(T-3)+k2
0(T-2)+k2
0(T-1)+k1
0(T)
@160
```

Burada:

```text
T-4 = base = 100
T-3 = rows = 2
T-2 = cols = 2
T-1 = type = 1 signed
T   = scale = 0
@160 = MAT_INIT
```

Eleman yazma:

```text
# A[0,0] = 1
0(T-4)+k100
0(T-3)
0(T-2)
0(T-1)+k1
@162

# A[0,1] = 2
0(T-4)+k100
0(T-3)
0(T-2)+k1
0(T-1)+k2
@162

# A[1,0] = 3
0(T-4)+k100
0(T-3)+k1
0(T-2)
0(T-1)+k3
@162

# A[1,1] = 4
0(T-4)+k100
0(T-3)+k1
0(T-2)+k1
0(T-1)+k4
@162
```

Matris yazdırma:

```text
0(T-3)+k100
@166
```

Beklenen:

```text
[1 2]
[3 4]
```

# Uzun yoldan matris işlemi yapılabilmeli

Bu çok önemli dediğin nokta. Kullanıcı sadece `MAT_MUL` gibi hazır servisle sınırlı kalmamalı. Uzun yoldan kendisi algoritma kurabilmeli. Bunun için şu servisler yeterli:

```text
MAT_INIT
MAT_SET
MAT_GET
MAT_FILL
MAT_COPY
MAT_SHAPE
```

Bunlar varsa kullanıcı uzun yoldan:

```text
for i
  for j
    sum=0
    for k
      sum += A[i,k] * B[k,j]
```

mantığını UXM komutları ve branch ile kurabilir.

Yani `MAT_MUL` hızlandırıcıdır, ama şart değildir. Asıl temel `MAT_GET` ve `MAT_SET`tir.

Bu yüzden V1’de en kritik üç servis:

```text
@!160 MAT_INIT
@!162 MAT_SET
@!163 MAT_GET
```

Bunlar taş gibi olmalı.

# Compiler değişikliği minimum nasıl tutulur?

Compiler’a mecburi tek şey şudur:

```text
@!N host meta çağrısı
(D@...) dinamik data adresleme
```

Matris için compiler’a şart olmayan ama çok işe yarayan ARGE komutları:

```text
#matrix
#matrix-signed
#matrix-fixed
#identity
#zeros
#ones
```

Bunlar olmasa bile kullanıcı uzun yoldan `MAT_INIT/MAT_SET` ile matris kurabilir.

Yani katmanlar şöyle:

```text
Seviye 0:
    Elle data hücrelerine yazma

Seviye 1:
    MAT_INIT / MAT_SET / MAT_GET macro servisleri

Seviye 2:
    MAT_ADD / MAT_MUL / TRANSPOSE gibi hazır macro servisler

Seviye 3:
    #matrix gibi compiler kolaylaştırıcıları

Seviye 4:
    VS Code Matrix Viewer
```

Bu sayede compiler değişikliği az olur ama kullanım gittikçe kolaylaşır.

# Compiler ARGE komutları

Bunları eklemek iyi olur ama şart değil:

```text
#matrix BASE ROWS COLS = values...
#matrix-signed BASE ROWS COLS = values...
#matrix-fixed BASE ROWS COLS SCALE = values...
#identity BASE SIZE
#zeros BASE ROWS COLS
#ones BASE ROWS COLS
```

Örnek:

```text
#matrix-signed 100 2 2 = 1,2,3,4
#matrix-signed 200 2 2 = 5,6,7,8
```

Compiler bunu data initializer’a çevirir.

Bunun en büyük avantajı: kullanıcı yüzlerce `MAT_SET` yazmaz.

Ama bu ARGE komutları yoksa da sistem çalışır. Çünkü `MAT_SET` var.

# Matris demek ekran demek

Çok doğru söyledin. Matris sadece lineer cebir değil, aynı zamanda ekran/görüntü mantığıdır.

Bu yüzden V1’e iki basit servis ekleyelim:

```text
m184 MAT_TO_SCREEN_CHARS
m185 MAT_FROM_SCREEN_CHARS
```

## MAT_TO_SCREEN_CHARS

Bir matrisi karakter ekranı gibi basar.

Örneğin 5x5 matris:

```text
0 0 1 0 0
0 1 1 1 0
1 0 1 0 1
0 0 1 0 0
0 0 1 0 0
```

Ekranda:

```text
  #  
 ### 
# # #
  #  
  #  
```

Böyle bir şey üretir.

Bu, ileride:

```text
oyun haritası
piksel sanatı
hücre otomasyonları
Conway Game of Life
basit görüntü işleme
neural network weight visualization
```

için kapı açar.

# Çok boyutlu dizi yolu

V1’de rank=1 ve rank=2 destekleyelim. Ama header `rank` taşıdığı için ileride şunlar gelir:

```text
rank=1  vector
rank=2  matrix / screen
rank=3  tensor / image RGB / time-series cube
rank=N  future
```

V1 runtime `rank>2` görürse:

```text
MAT_BAD_RANK
```

döndürür. Böylece tasarım açık kalır ama sistem şimdilik dar kalır.

# ASM derlemeye uygunluk

Bu tasarım ASM derlemeye uygun. Çünkü matris işlemleri iki şekilde derlenebilir:

## Yol 1: Runtime call

Native compiler şunu üretir:

```asm
mov ecx, 170
lea rdx, [ux_mem]
call ux_meta_call_ex
```

Bu kolay ve güvenlidir.

## Yol 2: Inline ASM optimizer

İleride compiler `@170 MAT_MUL` gördüğünde küçük sabit boyutlu matrisler için doğrudan ASM loop üretebilir.

Örneğin 2x2 matris çarpımı:

```text
#matrix A 2 2
#matrix B 2 2
@170
```

sabit boyut belli olduğu için compiler ileride özel NASM üretebilir:

```asm
; C00 = A00*B00 + A01*B10
; C01 = A00*B01 + A01*B11
; ...
```

Ama bu V2/V3 optimizasyon. V1’de runtime call yeterli.

# Kesin daraltılmış V1 kapsamı

Bence UX-MAT V1’de sadece şu olsun:

```text
MAT_INIT
MAT_CLEAR
MAT_SET
MAT_GET
MAT_FILL
MAT_COPY
MAT_PRINT
MAT_PRINT_RAW
MAT_SHAPE

MAT_ADD
MAT_SUB
MAT_SCALAR_MUL
MAT_MUL
MAT_TRANSPOSE_COPY
MAT_IDENTITY
MAT_TRACE
MAT_DET2

VEC_DOT
MAT_TO_SCREEN_CHARS
```

V1’de olmayanlar:

```text
inverse
NxN determinant
Gaussian elimination
eigenvalue
sparse matrix
view matrix
UX-FP matrix
rank>2 gerçek işlem
```

Ama header ve macro alanı bunlara hazır kalır.

# Son tasarım cümlesi

UX-MAT V1’in özü şu olmalı:

```text
UX-MAT V1, UX-MINIMA içinde Data alanını kullanarak çalışan,
rank=1 vector ve rank=2 dense matrix bloklarını destekleyen,
integer/signed/fixed-point veri tipleriyle temel bilimsel hesap,
ekran matrisi, oyun haritası, neural network ağırlıkları ve lineer cebir
işlemlerine temel oluşturan, macro tabanlı ve host hızlandırıcıya açık
bir matris/dizi sistemidir.
```

Bu tasarım Python olmaya çalışmaz. Ama Python’daki “liste/matris/numpy mantığının en küçük, compiler’a uygun, ASM’e indirgenebilir çekirdeğini” kurar.

Bence sıradaki somut adım şu olmalı: `ux_mat_v1.uxm` macro header + `runtime_matrix_services.bas` gerçek kod + `tests_matrix/*.uxm` testlerini yazmak.


Tamam Mete abi, **UX-MAT V1 matris/dizi çekirdeğini** paket olarak yazdım:

[UX-MAT V1 paketini indir](sandbox:/mnt/data/ux_mat_v1_package.zip)

İçinde şunlar var:

```text
ux_mat_v1_package/
├─ lib/
│  └─ ux_mat_v1.uxm
├─ runtime/
│  └─ runtime_matrix_services.bas
├─ compiler/
│  └─ arge_parse_matrix_additions.bas
├─ tests_matrix/
│  ├─ test_mat01_init_set_get.uxm
│  ├─ test_mat02_add_2x2.uxm
│  ├─ test_mat03_mul_2x2.uxm
│  ├─ test_mat04_transpose_2x3.uxm
│  ├─ test_mat05_identity_trace_det2.uxm
│  ├─ test_mat06_screen_chars.uxm
│  └─ test_mat07_fixed_mul_scale.uxm
├─ docs/
│  └─ UX_MAT_V1_SPEC.md
├─ README.md
└─ FILE_MANIFEST.txt
```

Bu paketteki ana servisler:

```text
m160 MAT_INIT
m161 MAT_CLEAR
m162 MAT_SET
m163 MAT_GET
m164 MAT_FILL
m165 MAT_COPY
m166 MAT_PRINT
m167 MAT_ADD
m168 MAT_SUB
m169 MAT_SCALAR_MUL
m170 MAT_MUL
m171 MAT_TRANSPOSE_COPY
m172 MAT_IDENTITY
m173 MAT_TRACE
m174 MAT_SHAPE
m175 MAT_DET2
m176 MAT_PRINT_RAW
m177 MAT_ROW_SWAP
m178 MAT_ROW_SCALE
m179 MAT_ROW_ADD
m180 VEC_DOT
m181 VEC_NORM2_INT
m182 MAT_COMPARE_SHAPE
m183 MAT_IS_SQUARE
m184 MAT_TO_SCREEN_CHARS
m185 MAT_FROM_SCREEN_CHARS
```

Runtime entegrasyonu için `ux_meta_call_ex` içine şu dal eklenecek:

```freebasic
ElseIf metaId>=160 And metaId<=199 Then
    MetaMatrix metaId
```

Sonra `runtime/runtime_matrix_services.bas` içeriği `uxm31_runtime_fb_full.bas` içine dahil edilecek veya yapıştırılacak.

Dürüst not: Bu paketi burada FreeBASIC/NASM ile derleyemedim; ama dosyalar boş değil, manifest var ve runtime servisleri gerçek FreeBASIC kodu olarak yazıldı. İlk derlemede FreeBASIC’in mevcut runtime’daki fonksiyon isimleriyle küçük uyum hatası çıkarırsa, doğrudan o hatalara göre düzeltiriz.


Tamam Mete abi. Şimdi UX-MAT V1’i gerçek dosya paketi gibi yazıyorum: macro başlığı, runtime servis kodu, compiler ARGE komut taslağı ve test dosyaları olacak. Bu paket “tek başına matematik kütüphanesi” değil; mevcut V3.1 runtime/compiler içine eklenecek sağlam matris/dizi katmanı olacak.

Thought for 3m 40s

Tamam Mete abi. UX-MAT V1 paketini yazdım:

UX-MAT V1 paketini indir

İçinde şunlar var:

ux_mat_v1_package/
├─ lib/
│  └─ ux_mat_v1.uxm
├─ runtime/
│  └─ runtime_matrix_services.bas
├─ compiler/
│  └─ arge_parse_matrix_additions.bas
├─ tests_matrix/
│  ├─ test_matrix01_init_set_get.uxm
│  ├─ test_matrix02_add.uxm
│  ├─ test_matrix03_mul.uxm
│  ├─ test_matrix04_transpose.uxm
│  ├─ test_matrix05_identity_trace_det2.uxm
│  ├─ test_matrix06_fixed_mul.uxm
│  ├─ test_matrix07_screen_chars.uxm
│  └─ test_matrix08_dim_mismatch.uxm
└─ docs/
   └─ UX_MAT_V1.md

Bu paket şunları içeriyor:

m160 MAT_INIT
m161 MAT_CLEAR
m162 MAT_SET
m163 MAT_GET
m164 MAT_FILL
m165 MAT_COPY
m166 MAT_PRINT
m167 MAT_ADD
m168 MAT_SUB
m169 MAT_SCALAR_MUL
m170 MAT_MUL
m171 MAT_TRANSPOSE_COPY
m172 MAT_IDENTITY
m173 MAT_TRACE
m174 MAT_SHAPE
m175 MAT_DET2
m176 MAT_PRINT_RAW
m177 MAT_ROW_SWAP
m178 MAT_ROW_SCALE
m179 MAT_ROW_ADD
m180 VEC_DOT
m181 VEC_NORM2_INT
m182 MAT_COMPARE_SHAPE
m183 MAT_IS_SQUARE
m184 MAT_TO_SCREEN_CHARS

Compiler ARGE komutları da eklendi:

#matrix BASE ROWS COLS = values...
#matrix-signed BASE ROWS COLS = values...
#matrix-fixed BASE ROWS COLS SCALE = values...
#identity BASE SIZE
#zeros BASE ROWS COLS
#ones BASE ROWS COLS

Entegrasyon için runtime_matrix_services.bas içeriğini runtime’a ekleyip ux_meta_call_ex içine şu yönlendirmeyi koyman gerekiyor:

ElseIf metaId>=160 And metaId<=199 Then
    MetaMatrix metaId

Compiler tarafında ise preprocessing aşamasına şu çağrı eklenmeli:

Src = UXMatPreprocess(Src)

Dürüst not: Bu paketi burada FreeBASIC ile derleyemedim; ama dosyalar bu kez boş değil, gerçek runtime servisleri, macro header, parser eklentisi, testler ve doküman içeriyor.
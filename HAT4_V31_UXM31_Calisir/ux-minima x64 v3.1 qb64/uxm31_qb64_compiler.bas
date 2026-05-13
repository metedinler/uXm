' Bu tek dosya, önceki compiler kodunun düzeltilmiş hâlidir. Şimdiki set şu iki ana dosyadan oluşuyor:

' ```text
' uxm31_qb64_compiler.bas
' uxm31_runtime.bas
' ```

' Bundan sonraki devamda sana **test `.uxm` dosyalarını**, beklenen çıktıları ve Windows build sırasını vereceğim.

' ## Dosya 1 — Düzeltilmiş Tam Sürüm

' # `uxm31_qb64_compiler.bas`

' ```basic
OPTION _EXPLICIT
CONST UXM_VERSION$="3.1"
CONST MAX_SRC=2000000
CONST MAX_INSTR=200000
CONST MAX_STRINGS=1024
CONST MAX_MACROS=128
CONST MAX_LOOP=8192
CONST MAX_LABELS=200000
CONST UXM_TOTAL_BYTES=65536
CONST OP_NOP=0
CONST OP_RIGHT=1
CONST OP_LEFT=2
CONST OP_INC=3
CONST OP_DEC=4
CONST OP_CLEAR=5
CONST OP_PUTC=6
CONST OP_GETC=7
CONST OP_LOOP_BEG=8
CONST OP_LOOP_END=9
CONST OP_PUSH=10
CONST OP_POP=11
CONST OP_EQ=12
CONST OP_GT=13
CONST OP_LT=14
CONST OP_AND=15
CONST OP_OR=16
CONST OP_XOR=17
CONST OP_NOT=18
CONST OP_SHL=19
CONST OP_SHR=20
CONST OP_STATUS=21
CONST OP_META=22
CONST OP_BRANCH=23
CONST OP_PRINT_STRING=24
CONST ADDR_T=0
CONST ADDR_T_REL=1
CONST ADDR_T_ABS=2
CONST ADDR_D_ABS=3
CONST ADDR_S_ABS=4
CONST ADDR_SP=5
CONST ADDR_P=6
CONST ADDR_E=7
CONST ADDR_F=8
CONST ADDR_IND_T=9
CONST ADDR_IND_T_REL=10
CONST BR_CUR_NZ=1
CONST BR_CUR_Z=2
CONST BR_ALWAYS=3
CONST BR_Z_SET=4
CONST BR_Z_CLR=5
CONST BR_C_SET=6
CONST BR_C_CLR=7
CONST BR_O_SET=8
CONST BR_O_CLR=9
CONST BR_S_SET=10
CONST BR_S_CLR=11
CONST MODE_SAFE=0
CONST MODE_NORMAL=1
CONST MODE_WILD=2
CONST CELL_BYTE=8
CONST CELL_WORD=16
CONST CELL_DWORD=32
DECLARE SUB Main()
DECLARE SUB InitDefaults()
DECLARE SUB ReadFileToSrc(fileName AS STRING)
DECLARE SUB FirstPassDefinitions()
DECLARE SUB ParseProgram(code AS STRING, depth AS LONG)
DECLARE SUB ParseOneInstruction(code AS STRING, BYREF p AS LONG, depth AS LONG)
DECLARE SUB ParseStringDef(code AS STRING, BYREF p AS LONG)
DECLARE SUB ParseMacroDef(code AS STRING, BYREF p AS LONG)
DECLARE SUB ParsePrintString(code AS STRING, BYREF p AS LONG)
DECLARE SUB ParseMeta(code AS STRING, BYREF p AS LONG, depth AS LONG)
DECLARE SUB ParseBranch(code AS STRING, BYREF p AS LONG)
DECLARE SUB AddInstr(op AS LONG, amount AS LONG, addrKind AS LONG, addrVal AS LONG, txt AS STRING)
DECLARE SUB AddMetaInstr(metaId AS LONG, dynamicFlag AS LONG, txt AS STRING)
DECLARE SUB AddBranchInstr(cond AS LONG, dir AS LONG, dist AS LONG, txt AS STRING)
DECLARE SUB AddStringDef(id AS LONG, startCell AS LONG, txt AS STRING)
DECLARE SUB AddMacroDef(id AS LONG, txt AS STRING)
DECLARE SUB SkipLine(code AS STRING, BYREF p AS LONG)
DECLARE SUB SyntaxError(msg AS STRING, p AS LONG)
DECLARE SUB ValidateBranches()
DECLARE SUB GenerateASM()
DECLARE SUB EmitHeader()
DECLARE SUB EmitStringInitializers()
DECLARE SUB EmitInstr(i AS LONG)
DECLARE SUB EmitFooter()
DECLARE SUB EmitLine(s AS STRING)
DECLARE SUB EmitAddrLoad(addrKind AS LONG, addrVal AS LONG, regName AS STRING)
DECLARE SUB EmitAddrStore(addrKind AS LONG, addrVal AS LONG, regName AS STRING)
DECLARE SUB EmitAddrPtr(addrKind AS LONG, addrVal AS LONG, outReg AS STRING)
DECLARE SUB EmitSetFlagsFromRAX()
DECLARE SUB EmitMetaCall(metaId AS LONG, dynamicFlag AS LONG)
DECLARE SUB EmitBranch(i AS LONG)
DECLARE SUB EmitLoopBegin(i AS LONG)
DECLARE SUB EmitLoopEnd(i AS LONG)
DECLARE SUB EmitAsmLabelIfNeeded(i AS LONG)
DECLARE SUB EmitDataSizeStore(memExpr AS STRING, regName AS STRING)
DECLARE FUNCTION ParseUnsignedLong&(code AS STRING, BYREF p AS LONG, BYREF ok AS LONG)
DECLARE FUNCTION ParseBracedText$(code AS STRING, BYREF p AS LONG, BYREF ok AS LONG)
DECLARE FUNCTION ParseAddress%(code AS STRING, BYREF p AS LONG, BYREF kind AS LONG, BYREF val AS LONG)
DECLARE FUNCTION ParseAddressBody%(body AS STRING, BYREF kind AS LONG, BYREF val AS LONG)
DECLARE FUNCTION FindStringIndex%(id AS LONG)
DECLARE FUNCTION FindMacroIndex%(id AS LONG)
DECLARE FUNCTION IsDigit%(c AS STRING)
DECLARE FUNCTION IsSpace%(c AS STRING)
DECLARE FUNCTION IsCommandChar%(c AS STRING)
DECLARE FUNCTION CellSize&()
DECLARE FUNCTION MemSizePrefix$()
DECLARE FUNCTION Reg8$(regName AS STRING)
DECLARE FUNCTION Reg16$(regName AS STRING)
DECLARE FUNCTION Reg32$(regName AS STRING)
DECLARE FUNCTION TrimAll$(s AS STRING)
DECLARE FUNCTION AddressText$(kind AS LONG, val AS LONG)
DECLARE FUNCTION RemoveBOM$(s AS STRING)
DECLARE FUNCTION NewAsmId&()
DIM SHARED Src AS STRING
DIM SHARED InFile AS STRING
DIM SHARED OutAsm AS STRING
DIM SHARED HadError AS LONG
DIM SHARED ErrMsg AS STRING
DIM SHARED InstrCount AS LONG
DIM SHARED IOp(1 TO MAX_INSTR) AS LONG
DIM SHARED IAmt(1 TO MAX_INSTR) AS LONG
DIM SHARED IAddrKind(1 TO MAX_INSTR) AS LONG
DIM SHARED IAddrVal(1 TO MAX_INSTR) AS LONG
DIM SHARED IText(1 TO MAX_INSTR) AS STRING
DIM SHARED IMetaId(1 TO MAX_INSTR) AS LONG
DIM SHARED IMetaDyn(1 TO MAX_INSTR) AS LONG
DIM SHARED IBrCond(1 TO MAX_INSTR) AS LONG
DIM SHARED IBrDir(1 TO MAX_INSTR) AS LONG
DIM SHARED IBrDist(1 TO MAX_INSTR) AS LONG
DIM SHARED IBrTarget(1 TO MAX_INSTR) AS LONG
DIM SHARED NeedLabel(1 TO MAX_LABELS) AS LONG
DIM SHARED StrCount AS LONG
DIM SHARED StrId(1 TO MAX_STRINGS) AS LONG
DIM SHARED StrStart(1 TO MAX_STRINGS) AS LONG
DIM SHARED StrText(1 TO MAX_STRINGS) AS STRING
DIM SHARED MacroCount AS LONG
DIM SHARED MacroId(1 TO MAX_MACROS) AS LONG
DIM SHARED MacroText(1 TO MAX_MACROS) AS STRING
DIM SHARED LoopStack(1 TO MAX_LOOP) AS LONG
DIM SHARED LoopSP AS LONG
DIM SHARED LoopId(1 TO MAX_INSTR) AS LONG
DIM SHARED LoopCounter AS LONG
DIM SHARED CellBits AS LONG
DIM SHARED TapeKB AS LONG
DIM SHARED StackKB AS LONG
DIM SHARED DataKB AS LONG
DIM SHARED TapeCells AS LONG
DIM SHARED StackCells AS LONG
DIM SHARED DataCells AS LONG
DIM SHARED TapeBytes AS LONG
DIM SHARED StackBytes AS LONG
DIM SHARED DataBytes AS LONG
DIM SHARED DataOffset AS LONG
DIM SHARED StackOffset AS LONG
DIM SHARED Mode AS LONG
DIM SHARED BoundsOn AS LONG
DIM SHARED OverflowCheck AS LONG
DIM SHARED OutFF AS LONG
DIM SHARED EmitLabelCounter AS LONG
Main
END
SUB Main()
    DIM s AS STRING
    InitDefaults
    PRINT "UX-MINIMA x64 V3.1 QB64 compiler"
    PRINT "Kaynak .uxm dosyasi: ";
    LINE INPUT InFile
    InFile=TrimAll$(InFile)
    IF LEN(InFile)=0 THEN
        PRINT "Dosya adi bos."
        END
    END IF
    PRINT "ASM cikis dosyasi [otomatik]: ";
    LINE INPUT s
    s=TrimAll$(s)
    IF LEN(s)=0 THEN
        OutAsm=InFile+".asm"
    ELSE
        OutAsm=s
    END IF
    ReadFileToSrc InFile
    IF HadError THEN PRINT ErrMsg:END
    FirstPassDefinitions
    IF HadError THEN PRINT ErrMsg:END
    ParseProgram Src,0
    IF HadError THEN PRINT ErrMsg:END
    ValidateBranches
    IF HadError THEN PRINT ErrMsg:END
    GenerateASM
    IF HadError THEN PRINT ErrMsg:END
    PRINT "ASM uretildi: ";OutAsm
    PRINT "NASM:"
    PRINT "nasm -f win64 ";OutAsm;" -o program.obj"
    PRINT "FreeBASIC runtime ile link:"
    PRINT "fbc uxm31_runtime.bas program.obj -x program.exe"
END SUB
SUB InitDefaults()
    CellBits=8
    TapeKB=32
    StackKB=8
    DataKB=24
    Mode=MODE_NORMAL
    BoundsOn=1
    OverflowCheck=0
    TapeBytes=TapeKB*1024
    StackBytes=StackKB*1024
    DataBytes=DataKB*1024
    StackOffset=TapeBytes
    DataOffset=TapeBytes+StackBytes
    TapeCells=TapeBytes\CellSize&
    StackCells=StackBytes\CellSize&
    DataCells=DataBytes\CellSize&
END SUB
SUB ReadFileToSrc(fileName AS STRING)
    DIM ff AS LONG
    DIM sz AS LONG
    IF _FILEEXISTS(fileName)=0 THEN
        HadError=1
        ErrMsg="HATA: kaynak dosya bulunamadi: "+fileName
        EXIT SUB
    END IF
    ff=FREEFILE
    OPEN fileName FOR BINARY AS #ff
    sz=LOF(ff)
    IF sz>MAX_SRC THEN
        CLOSE #ff
        HadError=1
        ErrMsg="HATA: kaynak dosya cok buyuk."
        EXIT SUB
    END IF
    IF sz>0 THEN
        Src=SPACE$(sz)
        GET #ff,,Src
    ELSE
        Src=""
    END IF
    CLOSE #ff
    Src=RemoveBOM$(Src)
END SUB
FUNCTION RemoveBOM$(s AS STRING)
    IF LEN(s)>=3 THEN
        IF (ASC(MID$(s,1,1)) AND &HFF)=&HEF AND (ASC(MID$(s,2,1)) AND &HFF)=&HBB AND (ASC(MID$(s,3,1)) AND &HFF)=&HBF THEN
            RemoveBOM$=MID$(s,4)
            EXIT FUNCTION
        END IF
    END IF
    RemoveBOM$=s
END FUNCTION
SUB FirstPassDefinitions()
    DIM p AS LONG
    DIM c AS STRING
    p=1
    DO WHILE p<=LEN(Src) AND HadError=0
        c=MID$(Src,p,1)
        IF c="#" THEN
            SkipLine Src,p
        ELSEIF c="s" OR c="S" THEN
            ParseStringDef Src,p
        ELSEIF c="m" OR c="M" THEN
            ParseMacroDef Src,p
        ELSE
            p=p+1
        END IF
    LOOP
END SUB
SUB ParseProgram(code AS STRING, depth AS LONG)
    DIM p AS LONG
    IF depth>32 THEN
        HadError=1
        ErrMsg="HATA: macro expansion derinligi 32'yi asti."
        EXIT SUB
    END IF
    p=1
    DO WHILE p<=LEN(code) AND HadError=0
        IF IsSpace%(MID$(code,p,1)) THEN
            p=p+1
        ELSEIF MID$(code,p,1)="#" THEN
            SkipLine code,p
        ELSEIF MID$(code,p,1)="s" OR MID$(code,p,1)="S" THEN
            ParseStringDef code,p
        ELSEIF MID$(code,p,1)="m" OR MID$(code,p,1)="M" THEN
            ParseMacroDef code,p
        ELSE
            ParseOneInstruction code,p,depth
        END IF
    LOOP
END SUB
SUB ParseOneInstruction(code AS STRING, BYREF p AS LONG, depth AS LONG)
    DIM c AS STRING
    DIM kind AS LONG
    DIM val AS LONG
    DIM hasAddr AS LONG
    DIM amt AS LONG
    DIM ok AS LONG
    DIM startP AS LONG
    DIM c2 AS STRING
    DIM p2 AS LONG
    DIM amt2 AS LONG
    DIM ok2 AS LONG
    startP=p
    c=MID$(code,p,1)
    IF c="p" OR c="P" THEN
        ParsePrintString code,p
        EXIT SUB
    END IF
    IF c="@" THEN
        ParseMeta code,p,depth
        EXIT SUB
    END IF
    IF c=":" THEN
        ParseBranch code,p
        EXIT SUB
    END IF
    IF IsCommandChar%(c)=0 THEN
        SyntaxError "gecersiz komut karakteri: "+c,p
        EXIT SUB
    END IF
    p=p+1
    kind=ADDR_T
    val=0
    amt=1
    IF c="+" OR c="-" THEN
        IF p<=LEN(code) THEN
            IF MID$(code,p,1)="k" OR MID$(code,p,1)="K" THEN
                p=p+1
                amt=ParseUnsignedLong&(code,p,ok)
                IF ok=0 THEN SyntaxError "k sonrasi sayi bekleniyor",p:EXIT SUB
            END IF
        END IF
    END IF
    hasAddr=ParseAddress%(code,p,kind,val)
    IF HadError THEN EXIT SUB
    SELECT CASE c
        CASE ">"
            IF hasAddr THEN SyntaxError "> adresleme alamaz",startP:EXIT SUB
            AddInstr OP_RIGHT,amt,ADDR_T,0,MID$(code,startP,p-startP)
        CASE "<"
            IF hasAddr THEN SyntaxError "< adresleme alamaz",startP:EXIT SUB
            AddInstr OP_LEFT,amt,ADDR_T,0,MID$(code,startP,p-startP)
        CASE "+"
            AddInstr OP_INC,amt,kind,val,MID$(code,startP,p-startP)
        CASE "-"
            AddInstr OP_DEC,amt,kind,val,MID$(code,startP,p-startP)
        CASE "0"
            AddInstr OP_CLEAR,0,kind,val,MID$(code,startP,p-startP)
            IF p<=LEN(code) THEN
                IF MID$(code,p,1)="+" OR MID$(code,p,1)="-" THEN
                    c2=MID$(code,p,1)
                    p2=p+1
                    amt2=1
                    ok2=0
                    IF p2<=LEN(code) THEN
                        IF MID$(code,p2,1)="k" OR MID$(code,p2,1)="K" THEN
                            p2=p2+1
                            amt2=ParseUnsignedLong&(code,p2,ok2)
                            IF ok2=0 THEN SyntaxError "0(addr)+kN kisminda sayi bekleniyor",p2:EXIT SUB
                            IF c2="+" THEN
                                AddInstr OP_INC,amt2,kind,val,"+k"+LTRIM$(STR$(amt2))+" inherit "+AddressText$(kind,val)
                            ELSE
                                AddInstr OP_DEC,amt2,kind,val,"-k"+LTRIM$(STR$(amt2))+" inherit "+AddressText$(kind,val)
                            END IF
                            p=p2
                        END IF
                    END IF
                END IF
            END IF
        CASE "."
            AddInstr OP_PUTC,0,kind,val,MID$(code,startP,p-startP)
        CASE ","
            AddInstr OP_GETC,0,kind,val,MID$(code,startP,p-startP)
        CASE "["
            IF hasAddr THEN SyntaxError "[ adresleme alamaz; loop aktif hucreye gore calisir",startP:EXIT SUB
            AddInstr OP_LOOP_BEG,0,kind,val,MID$(code,startP,p-startP)
        CASE "]"
            IF hasAddr THEN SyntaxError "] adresleme alamaz",startP:EXIT SUB
            AddInstr OP_LOOP_END,0,kind,val,MID$(code,startP,p-startP)
        CASE "$"
            AddInstr OP_PUSH,0,kind,val,MID$(code,startP,p-startP)
        CASE "%"
            AddInstr OP_POP,0,kind,val,MID$(code,startP,p-startP)
        CASE "?"
            AddInstr OP_EQ,0,kind,val,MID$(code,startP,p-startP)
        CASE "!"
            AddInstr OP_GT,0,kind,val,MID$(code,startP,p-startP)
        CASE ";"
            AddInstr OP_LT,0,kind,val,MID$(code,startP,p-startP)
        CASE "&"
            AddInstr OP_AND,0,kind,val,MID$(code,startP,p-startP)
        CASE "|"
            AddInstr OP_OR,0,kind,val,MID$(code,startP,p-startP)
        CASE "^"
            AddInstr OP_XOR,0,kind,val,MID$(code,startP,p-startP)
        CASE "~"
            AddInstr OP_NOT,0,kind,val,MID$(code,startP,p-startP)
        CASE "{"
            AddInstr OP_SHL,0,kind,val,MID$(code,startP,p-startP)
        CASE "}"
            AddInstr OP_SHR,0,kind,val,MID$(code,startP,p-startP)
        CASE "e","E"
            AddInstr OP_STATUS,0,kind,val,MID$(code,startP,p-startP)
        CASE ELSE
            SyntaxError "beklenmeyen komut: "+c,startP
    END SELECT
END SUB
SUB ParseStringDef(code AS STRING, BYREF p AS LONG)
    DIM ok AS LONG
    DIM id AS LONG
    DIM startCell AS LONG
    DIM txt AS STRING
    p=p+1
    id=ParseUnsignedLong&(code,p,ok)
    IF ok=0 THEN SyntaxError "sN taniminda N bekleniyor",p:EXIT SUB
    IF p>LEN(code) OR MID$(code,p,1)<>"=" THEN SyntaxError "sN taniminda '=' bekleniyor",p:EXIT SUB
    p=p+1
    startCell=ParseUnsignedLong&(code,p,ok)
    IF ok=0 THEN SyntaxError "sN baslangic hucre no bekleniyor",p:EXIT SUB
    IF p>LEN(code) OR MID$(code,p,1)<>"," THEN SyntaxError "sN taniminda ',' bekleniyor",p:EXIT SUB
    p=p+1
    txt=ParseBracedText$(code,p,ok)
    IF ok=0 THEN SyntaxError "sN taniminda {metin} bekleniyor",p:EXIT SUB
    AddStringDef id,startCell,txt
END SUB
SUB ParseMacroDef(code AS STRING, BYREF p AS LONG)
    DIM ok AS LONG
    DIM id AS LONG
    DIM txt AS STRING
    p=p+1
    id=ParseUnsignedLong&(code,p,ok)
    IF ok=0 THEN SyntaxError "mN taniminda N bekleniyor",p:EXIT SUB
    IF id<128 OR id>255 THEN SyntaxError "mN kullanici macro id 128..255 araliginda olmali",p:EXIT SUB
    IF p>LEN(code) OR MID$(code,p,1)<>"=" THEN SyntaxError "mN taniminda '=' bekleniyor",p:EXIT SUB
    p=p+1
    txt=ParseBracedText$(code,p,ok)
    IF ok=0 THEN SyntaxError "mN taniminda {UXM kodu} bekleniyor",p:EXIT SUB
    AddMacroDef id,txt
END SUB
SUB ParsePrintString(code AS STRING, BYREF p AS LONG)
    DIM ok AS LONG
    DIM id AS LONG
    DIM idx AS LONG
    DIM startP AS LONG
    startP=p
    p=p+1
    id=ParseUnsignedLong&(code,p,ok)
    IF ok=0 THEN SyntaxError "pN komutunda N bekleniyor",p:EXIT SUB
    idx=FindStringIndex%(id)
    IF idx=0 THEN SyntaxError "tanimlanmamis string: p"+LTRIM$(STR$(id)),startP:EXIT SUB
    AddInstr OP_PRINT_STRING,id,ADDR_T,0,MID$(code,startP,p-startP)
END SUB
SUB ParseMeta(code AS STRING, BYREF p AS LONG, depth AS LONG)
    DIM startP AS LONG
    DIM ok AS LONG
    DIM id AS LONG
    DIM idx AS LONG
    startP=p
    p=p+1
    IF p>LEN(code) THEN SyntaxError "@ sonrasi meta id veya # bekleniyor",p:EXIT SUB
    IF MID$(code,p,1)="#" THEN
        p=p+1
        AddMetaInstr -1,1,"@#"
        EXIT SUB
    END IF
    id=ParseUnsignedLong&(code,p,ok)
    IF ok=0 THEN SyntaxError "@ sonrasi meta id bekleniyor",p:EXIT SUB
    IF id<0 OR id>255 THEN SyntaxError "meta id 0..255 araliginda olmali",startP:EXIT SUB
    idx=FindMacroIndex%(id)
    IF idx<>0 THEN
        ParseProgram MacroText(idx),depth+1
    ELSE
        AddMetaInstr id,0,MID$(code,startP,p-startP)
    END IF
END SUB
SUB ParseBranch(code AS STRING, BYREF p AS LONG)
    DIM startP AS LONG
    DIM cond AS LONG
    DIM dir AS LONG
    DIM dist AS LONG
    DIM ok AS LONG
    DIM c AS STRING
    startP=p
    p=p+1
    IF p>LEN(code) THEN SyntaxError ": sonrasi branch govdesi bekleniyor",p:EXIT SUB
    c=MID$(code,p,1)
    IF c=":" THEN
        cond=BR_ALWAYS
        p=p+1
    ELSEIF c="0" THEN
        cond=BR_CUR_Z
        p=p+1
    ELSEIF c="z" THEN
        cond=BR_Z_SET
        p=p+1
    ELSEIF c="Z" THEN
        cond=BR_Z_CLR
        p=p+1
    ELSEIF c="c" THEN
        cond=BR_C_SET
        p=p+1
    ELSEIF c="C" THEN
        cond=BR_C_CLR
        p=p+1
    ELSEIF c="o" THEN
        cond=BR_O_SET
        p=p+1
    ELSEIF c="O" THEN
        cond=BR_O_CLR
        p=p+1
    ELSEIF c="s" THEN
        cond=BR_S_SET
        p=p+1
    ELSEIF c="S" THEN
        cond=BR_S_CLR
        p=p+1
    ELSEIF c="+" OR c="-" THEN
        cond=BR_CUR_NZ
    ELSE
        SyntaxError "gecersiz branch tipi",p
        EXIT SUB
    END IF
    IF p>LEN(code) THEN SyntaxError "branch yonu bekleniyor",p:EXIT SUB
    c=MID$(code,p,1)
    IF c="+" THEN
        dir=1
    ELSEIF c="-" THEN
        dir=-1
    ELSE
        SyntaxError "branch icin + veya - yonu bekleniyor",p
        EXIT SUB
    END IF
    p=p+1
    dist=ParseUnsignedLong&(code,p,ok)
    IF ok=0 THEN SyntaxError "branch mesafesi bekleniyor",p:EXIT SUB
    IF dist<=0 THEN SyntaxError "branch mesafesi 1 veya daha buyuk olmali",p:EXIT SUB
    AddBranchInstr cond,dir,dist,MID$(code,startP,p-startP)
END SUB
SUB AddInstr(op AS LONG, amount AS LONG, addrKind AS LONG, addrVal AS LONG, txt AS STRING)
    IF InstrCount>=MAX_INSTR THEN SyntaxError "instruction limiti doldu",1:EXIT SUB
    InstrCount=InstrCount+1
    IOp(InstrCount)=op
    IAmt(InstrCount)=amount
    IAddrKind(InstrCount)=addrKind
    IAddrVal(InstrCount)=addrVal
    IText(InstrCount)=txt
END SUB
SUB AddMetaInstr(metaId AS LONG, dynamicFlag AS LONG, txt AS STRING)
    AddInstr OP_META,0,ADDR_T,0,txt
    IMetaId(InstrCount)=metaId
    IMetaDyn(InstrCount)=dynamicFlag
END SUB
SUB AddBranchInstr(cond AS LONG, dir AS LONG, dist AS LONG, txt AS STRING)
    AddInstr OP_BRANCH,0,ADDR_T,0,txt
    IBrCond(InstrCount)=cond
    IBrDir(InstrCount)=dir
    IBrDist(InstrCount)=dist
END SUB
SUB AddStringDef(id AS LONG, startCell AS LONG, txt AS STRING)
    DIM i AS LONG
    FOR i=1 TO StrCount
        IF StrId(i)=id THEN EXIT SUB
    NEXT i
    IF StrCount>=MAX_STRINGS THEN HadError=1:ErrMsg="HATA: string tablosu doldu.":EXIT SUB
    StrCount=StrCount+1
    StrId(StrCount)=id
    StrStart(StrCount)=startCell
    StrText(StrCount)=txt
END SUB
SUB AddMacroDef(id AS LONG, txt AS STRING)
    DIM i AS LONG
    FOR i=1 TO MacroCount
        IF MacroId(i)=id THEN
            MacroText(i)=txt
            EXIT SUB
        END IF
    NEXT i
    IF MacroCount>=MAX_MACROS THEN HadError=1:ErrMsg="HATA: macro tablosu doldu.":EXIT SUB
    MacroCount=MacroCount+1
    MacroId(MacroCount)=id
    MacroText(MacroCount)=txt
END SUB
FUNCTION FindStringIndex%(id AS LONG)
    DIM i AS LONG
    FOR i=1 TO StrCount
        IF StrId(i)=id THEN FindStringIndex%=i:EXIT FUNCTION
    NEXT i
    FindStringIndex%=0
END FUNCTION
FUNCTION FindMacroIndex%(id AS LONG)
    DIM i AS LONG
    FOR i=1 TO MacroCount
        IF MacroId(i)=id THEN FindMacroIndex%=i:EXIT FUNCTION
    NEXT i
    FindMacroIndex%=0
END FUNCTION
SUB SkipLine(code AS STRING, BYREF p AS LONG)
    DO WHILE p<=LEN(code)
        IF MID$(code,p,1)=CHR$(10) THEN
            p=p+1
            EXIT SUB
        END IF
        p=p+1
    LOOP
END SUB
FUNCTION ParseUnsignedLong&(code AS STRING, BYREF p AS LONG, BYREF ok AS LONG)
    DIM s AS STRING
    s=""
    ok=0
    DO WHILE p<=LEN(code)
        IF IsDigit%(MID$(code,p,1))=0 THEN EXIT DO
        s=s+MID$(code,p,1)
        p=p+1
    LOOP
    IF LEN(s)=0 THEN
        ParseUnsignedLong&=0
    ELSE
        ok=1
        ParseUnsignedLong&=VAL(s)
    END IF
END FUNCTION
FUNCTION ParseBracedText$(code AS STRING, BYREF p AS LONG, BYREF ok AS LONG)
    DIM r AS STRING
    DIM c AS STRING
    DIM n AS STRING
    r=""
    ok=0
    IF p>LEN(code) THEN EXIT FUNCTION
    IF MID$(code,p,1)<>"{" THEN EXIT FUNCTION
    p=p+1
    DO WHILE p<=LEN(code)
        c=MID$(code,p,1)
        IF c="\" THEN
            IF p+1<=LEN(code) THEN
                n=MID$(code,p+1,1)
                SELECT CASE n
                    CASE "n"
                        r=r+CHR$(10)
                    CASE "r"
                        r=r+CHR$(13)
                    CASE "t"
                        r=r+CHR$(9)
                    CASE "{"
                        r=r+"{"
                    CASE "}"
                        r=r+"}"
                    CASE "\"
                        r=r+"\"
                    CASE ELSE
                        r=r+n
                END SELECT
                p=p+2
            ELSE
                r=r+c
                p=p+1
            END IF
        ELSEIF c="}" THEN
            p=p+1
            ok=1
            ParseBracedText$=r
            EXIT FUNCTION
        ELSE
            r=r+c
            p=p+1
        END IF
    LOOP
    ParseBracedText$=r
END FUNCTION
FUNCTION ParseAddress%(code AS STRING, BYREF p AS LONG, BYREF kind AS LONG, BYREF val AS LONG)
    DIM startP AS LONG
    DIM body AS STRING
    DIM bal AS LONG
    DIM c AS STRING
    IF p>LEN(code) THEN ParseAddress%=0:EXIT FUNCTION
    IF MID$(code,p,1)<>"(" THEN ParseAddress%=0:EXIT FUNCTION
    startP=p
    bal=0
    DO WHILE p<=LEN(code)
        c=MID$(code,p,1)
        IF IsSpace%(c) THEN
            SyntaxError "adresleme ifadesi icinde bosluk yasak",p
            EXIT FUNCTION
        END IF
        IF c="(" THEN bal=bal+1
        IF c=")" THEN
            bal=bal-1
            IF bal=0 THEN EXIT DO
        END IF
        p=p+1
    LOOP
    IF p>LEN(code) OR MID$(code,p,1)<>")" THEN SyntaxError "adresleme parantezi kapanmadi",startP:EXIT FUNCTION
    body=MID$(code,startP+1,p-startP-1)
    p=p+1
    IF ParseAddressBody%(body,kind,val)=0 THEN
        SyntaxError "gecersiz adresleme: ("+body+")",startP
        EXIT FUNCTION
    END IF
    ParseAddress%=1
END FUNCTION
FUNCTION ParseAddressBody%(body AS STRING, BYREF kind AS LONG, BYREF val AS LONG)
    DIM b AS STRING
    b=UCASE$(TrimAll$(body))
    val=0
    IF b="T" THEN kind=ADDR_T:ParseAddressBody%=1:EXIT FUNCTION
    IF b="SP" THEN kind=ADDR_SP:ParseAddressBody%=1:EXIT FUNCTION
    IF b="P" THEN kind=ADDR_P:ParseAddressBody%=1:EXIT FUNCTION
    IF b="E" THEN kind=ADDR_E:ParseAddressBody%=1:EXIT FUNCTION
    IF b="F" THEN kind=ADDR_F:ParseAddressBody%=1:EXIT FUNCTION
    IF b="*T" THEN kind=ADDR_IND_T:ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,2)="T+" THEN kind=ADDR_T_REL:val=VAL(MID$(b,3)):ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,2)="T-" THEN kind=ADDR_T_REL:val=-VAL(MID$(b,3)):ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,2)="T:" THEN kind=ADDR_T_ABS:val=VAL(MID$(b,3)):ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,2)="D:" THEN kind=ADDR_D_ABS:val=VAL(MID$(b,3)):ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,2)="S:" THEN kind=ADDR_S_ABS:val=VAL(MID$(b,3)):ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,4)="*(T+" AND RIGHT$(b,1)=")" THEN kind=ADDR_IND_T_REL:val=VAL(MID$(b,5,LEN(b)-5)):ParseAddressBody%=1:EXIT FUNCTION
    IF LEFT$(b,4)="*(T-" AND RIGHT$(b,1)=")" THEN kind=ADDR_IND_T_REL:val=-VAL(MID$(b,5,LEN(b)-5)):ParseAddressBody%=1:EXIT FUNCTION
    ParseAddressBody%=0
END FUNCTION
SUB SyntaxError(msg AS STRING, p AS LONG)
    HadError=1
    ErrMsg="SYNTAX ERROR @" + LTRIM$(STR$(p)) + ": " + msg
END SUB
FUNCTION IsDigit%(c AS STRING)
    IF LEN(c)=0 THEN
        IsDigit%=0
    ELSEIF c>="0" AND c<="9" THEN
        IsDigit%=1
    ELSE
        IsDigit%=0
    END IF
END FUNCTION
FUNCTION IsSpace%(c AS STRING)
    IF c=" " OR c=CHR$(9) OR c=CHR$(10) OR c=CHR$(13) THEN IsSpace%=1 ELSE IsSpace%=0
END FUNCTION
FUNCTION IsCommandChar%(c AS STRING)
    IF INSTR("><+-0.,[]$%?!;&|^~{}eE",c)>0 THEN IsCommandChar%=1 ELSE IsCommandChar%=0
END FUNCTION
FUNCTION TrimAll$(s AS STRING)
    TrimAll$=LTRIM$(RTRIM$(s))
END FUNCTION
FUNCTION CellSize&()
    SELECT CASE CellBits
        CASE 8
            CellSize&=1
        CASE 16
            CellSize&=2
        CASE 32
            CellSize&=4
        CASE ELSE
            CellSize&=1
    END SELECT
END FUNCTION
FUNCTION MemSizePrefix$()
    SELECT CASE CellBits
        CASE 8
            MemSizePrefix$="byte"
        CASE 16
            MemSizePrefix$="word"
        CASE 32
            MemSizePrefix$="dword"
        CASE ELSE
            MemSizePrefix$="byte"
    END SELECT
END FUNCTION
FUNCTION Reg8$(regName AS STRING)
    SELECT CASE LCASE$(regName)
        CASE "rax"
            Reg8$="al"
        CASE "rbx"
            Reg8$="bl"
        CASE "rcx"
            Reg8$="cl"
        CASE "rdx"
            Reg8$="dl"
        CASE "rsi"
            Reg8$="sil"
        CASE "rdi"
            Reg8$="dil"
        CASE "r8"
            Reg8$="r8b"
        CASE "r9"
            Reg8$="r9b"
        CASE "r10"
            Reg8$="r10b"
        CASE "r11"
            Reg8$="r11b"
        CASE "r12"
            Reg8$="r12b"
        CASE "r13"
            Reg8$="r13b"
        CASE "r14"
            Reg8$="r14b"
        CASE "r15"
            Reg8$="r15b"
        CASE ELSE
            Reg8$="al"
    END SELECT
END FUNCTION
FUNCTION Reg16$(regName AS STRING)
    SELECT CASE LCASE$(regName)
        CASE "rax"
            Reg16$="ax"
        CASE "rbx"
            Reg16$="bx"
        CASE "rcx"
            Reg16$="cx"
        CASE "rdx"
            Reg16$="dx"
        CASE "rsi"
            Reg16$="si"
        CASE "rdi"
            Reg16$="di"
        CASE "r8"
            Reg16$="r8w"
        CASE "r9"
            Reg16$="r9w"
        CASE "r10"
            Reg16$="r10w"
        CASE "r11"
            Reg16$="r11w"
        CASE "r12"
            Reg16$="r12w"
        CASE "r13"
            Reg16$="r13w"
        CASE "r14"
            Reg16$="r14w"
        CASE "r15"
            Reg16$="r15w"
        CASE ELSE
            Reg16$="ax"
    END SELECT
END FUNCTION
FUNCTION Reg32$(regName AS STRING)
    SELECT CASE LCASE$(regName)
        CASE "rax"
            Reg32$="eax"
        CASE "rbx"
            Reg32$="ebx"
        CASE "rcx"
            Reg32$="ecx"
        CASE "rdx"
            Reg32$="edx"
        CASE "rsi"
            Reg32$="esi"
        CASE "rdi"
            Reg32$="edi"
        CASE "r8"
            Reg32$="r8d"
        CASE "r9"
            Reg32$="r9d"
        CASE "r10"
            Reg32$="r10d"
        CASE "r11"
            Reg32$="r11d"
        CASE "r12"
            Reg32$="r12d"
        CASE "r13"
            Reg32$="r13d"
        CASE "r14"
            Reg32$="r14d"
        CASE "r15"
            Reg32$="r15d"
        CASE ELSE
            Reg32$="eax"
    END SELECT
END FUNCTION
FUNCTION AddressText$(kind AS LONG, val AS LONG)
    SELECT CASE kind
        CASE ADDR_T
            AddressText$="(T)"
        CASE ADDR_T_REL
            IF val>=0 THEN AddressText$="(T+"+LTRIM$(STR$(val))+")" ELSE AddressText$="(T"+LTRIM$(STR$(val))+")"
        CASE ADDR_T_ABS
            AddressText$="(T:"+LTRIM$(STR$(val))+")"
        CASE ADDR_D_ABS
            AddressText$="(D:"+LTRIM$(STR$(val))+")"
        CASE ADDR_S_ABS
            AddressText$="(S:"+LTRIM$(STR$(val))+")"
        CASE ADDR_SP
            AddressText$="(SP)"
        CASE ADDR_P
            AddressText$="(P)"
        CASE ADDR_E
            AddressText$="(E)"
        CASE ADDR_F
            AddressText$="(F)"
        CASE ADDR_IND_T
            AddressText$="(*T)"
        CASE ADDR_IND_T_REL
            IF val>=0 THEN AddressText$="(*(T+"+LTRIM$(STR$(val))+"))" ELSE AddressText$="(*(T"+LTRIM$(STR$(val))+"))"
        CASE ELSE
            AddressText$="(?)"
    END SELECT
END FUNCTION
FUNCTION NewAsmId&()
    EmitLabelCounter=EmitLabelCounter+1
    NewAsmId&=EmitLabelCounter
END FUNCTION
SUB ValidateBranches()
    DIM i AS LONG
    DIM target AS LONG
    LoopSP=0
    LoopCounter=0
    FOR i=1 TO InstrCount
        IF IOp(i)=OP_LOOP_BEG THEN
            LoopCounter=LoopCounter+1
            LoopId(i)=LoopCounter
            LoopSP=LoopSP+1
            IF LoopSP>MAX_LOOP THEN HadError=1:ErrMsg="HATA: loop stack doldu.":EXIT SUB
            LoopStack(LoopSP)=i
        ELSEIF IOp(i)=OP_LOOP_END THEN
            IF LoopSP<=0 THEN HadError=1:ErrMsg="HATA: fazla ] bulundu.":EXIT SUB
            LoopId(i)=LoopId(LoopStack(LoopSP))
            LoopSP=LoopSP-1
        END IF
    NEXT i
    IF LoopSP<>0 THEN HadError=1:ErrMsg="HATA: kapanmamis [ var.":EXIT SUB
    FOR i=1 TO InstrCount
        IF IOp(i)=OP_BRANCH THEN
            target=i+(IBrDir(i)*IBrDist(i))
            IF target<1 OR target>InstrCount THEN HadError=1:ErrMsg="HATA: branch hedefi token disina cikiyor: "+IText(i):EXIT SUB
            IBrTarget(i)=target
            NeedLabel(target)=1
        END IF
    NEXT i
END SUB
SUB GenerateASM()
    DIM i AS LONG
    OutFF=FREEFILE
    OPEN OutAsm FOR OUTPUT AS #OutFF
    EmitHeader
    EmitStringInitializers
    FOR i=1 TO InstrCount
        EmitAsmLabelIfNeeded i
        EmitInstr i
    NEXT i
    EmitFooter
    CLOSE #OutFF
END SUB
SUB EmitLine(s AS STRING)
    PRINT #OutFF,s
END SUB
SUB EmitHeader()
    EmitLine "; UX-MINIMA x64 V3.1 generated NASM"
    EmitLine "default rel"
    EmitLine "global uxm_entry"
    EmitLine "global ux_mem"
    EmitLine "global ux_status"
    EmitLine "global ux_flags"
    EmitLine "global ux_ptr"
    EmitLine "global ux_sp"
    EmitLine "global ux_cell_bits"
    EmitLine "global ux_cell_bytes"
    EmitLine "global ux_tape_cells"
    EmitLine "global ux_stack_cells"
    EmitLine "global ux_data_cells"
    EmitLine "global ux_stack_offset"
    EmitLine "global ux_data_offset"
    EmitLine "extern ux_putc"
    EmitLine "extern ux_getc"
    EmitLine "extern ux_print_data_string"
    EmitLine "extern ux_meta_call_ex"
    EmitLine "extern ux_runtime_error"
    EmitLine "%define UXM_TOTAL_BYTES 65536"
    EmitLine "%define TAPE_BYTES "+LTRIM$(STR$(TapeBytes))
    EmitLine "%define STACK_BYTES "+LTRIM$(STR$(StackBytes))
    EmitLine "%define DATA_BYTES "+LTRIM$(STR$(DataBytes))
    EmitLine "%define STACK_OFFSET "+LTRIM$(STR$(StackOffset))
    EmitLine "%define DATA_OFFSET "+LTRIM$(STR$(DataOffset))
    EmitLine "%define TAPE_CELLS "+LTRIM$(STR$(TapeCells))
    EmitLine "%define STACK_CELLS "+LTRIM$(STR$(StackCells))
    EmitLine "%define DATA_CELLS "+LTRIM$(STR$(DataCells))
    EmitLine "%define CELL_BITS "+LTRIM$(STR$(CellBits))
    EmitLine "%define CELL_BYTES "+LTRIM$(STR$(CellSize&))
    EmitLine "%define FLAG_Z 1"
    EmitLine "%define FLAG_C 2"
    EmitLine "%define FLAG_O 4"
    EmitLine "%define FLAG_S 8"
    EmitLine "%define FLAG_SGN 16"
    EmitLine "%define FLAG_END 32"
    EmitLine "%define FLAG_WILD 64"
    EmitLine "%define FLAG_BND 128"
    EmitLine "%define FLAG_TRC 256"
    EmitLine "%define FLAG_FIFO 512"
    EmitLine "%define FLAG_ERR 1024"
    EmitLine "%define FLAG_DIRTY 2048"
    EmitLine "%define FLAG_PCHG 4096"
    EmitLine "section .bss"
    EmitLine "align 16"
    EmitLine "ux_mem: resb UXM_TOTAL_BYTES"
    EmitLine "ux_status: resb 1"
    EmitLine "ux_flags: resw 1"
    EmitLine "ux_ptr: resq 1"
    EmitLine "ux_sp: resq 1"
    EmitLine "ux_cell_bits: resd 1"
    EmitLine "ux_cell_bytes: resd 1"
    EmitLine "ux_tape_cells: resd 1"
    EmitLine "ux_stack_cells: resd 1"
    EmitLine "ux_data_cells: resd 1"
    EmitLine "ux_stack_offset: resd 1"
    EmitLine "ux_data_offset: resd 1"
    EmitLine "section .text"
    EmitLine "uxm_entry:"
    EmitLine "    push rbp"
    EmitLine "    mov rbp, rsp"
    EmitLine "    push rbx"
    EmitLine "    push r12"
    EmitLine "    push r13"
    EmitLine "    push r14"
    EmitLine "    push r15"
    EmitLine "    sub rsp, 40"
    EmitLine "    mov dword [ux_cell_bits], CELL_BITS"
    EmitLine "    mov dword [ux_cell_bytes], CELL_BYTES"
    EmitLine "    mov dword [ux_tape_cells], TAPE_CELLS"
    EmitLine "    mov dword [ux_stack_cells], STACK_CELLS"
    EmitLine "    mov dword [ux_data_cells], DATA_CELLS"
    EmitLine "    mov dword [ux_stack_offset], STACK_OFFSET"
    EmitLine "    mov dword [ux_data_offset], DATA_OFFSET"
    EmitLine "    lea r12, [ux_mem]"
    EmitLine "    xor rbx, rbx"
    EmitLine "    lea r13, [ux_mem + STACK_OFFSET]"
    EmitLine "    xor r14, r14"
    EmitLine "    mov qword [ux_ptr], rbx"
    EmitLine "    mov qword [ux_sp], r14"
    EmitLine "    mov byte [ux_status], 0"
    IF BoundsOn THEN
        EmitLine "    mov ax, word [ux_flags]"
        EmitLine "    or ax, FLAG_BND"
        EmitLine "    mov word [ux_flags], ax"
    ELSE
        EmitLine "    mov word [ux_flags], 0"
    END IF
END SUB
SUB EmitStringInitializers()
    DIM i AS LONG
    DIM j AS LONG
    DIM ch AS LONG
    DIM byteOff AS LONG
    IF StrCount=0 THEN EXIT SUB
    EmitLine "    ; data string initializers"
    FOR i=1 TO StrCount
        FOR j=1 TO LEN(StrText(i))
            ch=ASC(MID$(StrText(i),j,1)) AND &HFF
            byteOff=DataOffset+(StrStart(i)+j-1)*CellSize&
            EmitLine "    mov "+MemSizePrefix$+" [ux_mem + "+LTRIM$(STR$(byteOff))+"], "+LTRIM$(STR$(ch))
        NEXT j
        byteOff=DataOffset+(StrStart(i)+LEN(StrText(i)))*CellSize&
        EmitLine "    mov "+MemSizePrefix$+" [ux_mem + "+LTRIM$(STR$(byteOff))+"], 0"
    NEXT i
END SUB
SUB EmitAsmLabelIfNeeded(i AS LONG)
    IF i>=1 AND i<=MAX_LABELS THEN
        IF NeedLabel(i)<>0 THEN EmitLine "__ux_ip_"+LTRIM$(STR$(i))+":"
    END IF
END SUB
SUB EmitInstr(i AS LONG)
    DIM idx AS LONG
    SELECT CASE IOp(i)
        CASE OP_RIGHT
            EmitLine "    ; "+IText(i)
            IF IAmt(i)=1 THEN EmitLine "    inc rbx" ELSE EmitLine "    add rbx, "+LTRIM$(STR$(IAmt(i)))
            IF BoundsOn THEN EmitLine "    cmp rbx, TAPE_CELLS":EmitLine "    jae __ux_err_ptr"
        CASE OP_LEFT
            EmitLine "    ; "+IText(i)
            IF IAmt(i)=1 THEN EmitLine "    dec rbx" ELSE EmitLine "    sub rbx, "+LTRIM$(STR$(IAmt(i)))
            IF BoundsOn THEN EmitLine "    cmp rbx, TAPE_CELLS":EmitLine "    jae __ux_err_ptr"
        CASE OP_INC
            EmitLine "    ; "+IText(i)
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            EmitLine "    add rax, "+LTRIM$(STR$(IAmt(i)))
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_DEC
            EmitLine "    ; "+IText(i)
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            EmitLine "    sub rax, "+LTRIM$(STR$(IAmt(i)))
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_CLEAR
            EmitLine "    ; "+IText(i)
            EmitLine "    xor rax, rax"
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_PUTC
            EmitLine "    ; "+IText(i)
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            EmitLine "    mov ecx, eax"
            EmitLine "    call ux_putc"
        CASE OP_GETC
            EmitLine "    ; "+IText(i)
            EmitLine "    call ux_getc"
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_PUSH
            EmitLine "    ; "+IText(i)
            EmitLine "    cmp r14, STACK_CELLS"
            EmitLine "    jae __ux_err_stack_over"
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    mov byte [r13 + r14], al"
                CASE 16
                    EmitLine "    mov word [r13 + r14*2], ax"
                CASE 32
                    EmitLine "    mov dword [r13 + r14*4], eax"
            END SELECT
            EmitLine "    inc r14"
        CASE OP_POP
            EmitLine "    ; "+IText(i)
            EmitLine "    cmp r14, 0"
            EmitLine "    je __ux_err_stack_under"
            EmitLine "    dec r14"
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    movzx rax, byte [r13 + r14]"
                CASE 16
                    EmitLine "    movzx rax, word [r13 + r14*2]"
                CASE 32
                    EmitLine "    mov eax, dword [r13 + r14*4]"
            END SELECT
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
            EmitLine "    ; "+IText(i)
            EmitLine "    cmp r14, 0"
            EmitLine "    je __ux_err_stack_under"
            EmitLine "    dec r14"
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    movzx r15, byte [r13 + r14]"
                CASE 16
                    EmitLine "    movzx r15, word [r13 + r14*2]"
                CASE 32
                    EmitLine "    mov r15d, dword [r13 + r14*4]"
            END SELECT
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            IF IOp(i)=OP_EQ THEN
                EmitLine "    cmp r15, rax"
                EmitLine "    sete al"
                EmitLine "    movzx rax, al"
            ELSEIF IOp(i)=OP_GT THEN
                EmitLine "    cmp r15, rax"
                EmitLine "    seta al"
                EmitLine "    movzx rax, al"
            ELSEIF IOp(i)=OP_LT THEN
                EmitLine "    cmp r15, rax"
                EmitLine "    setb al"
                EmitLine "    movzx rax, al"
            ELSEIF IOp(i)=OP_AND THEN
                EmitLine "    and rax, r15"
            ELSEIF IOp(i)=OP_OR THEN
                EmitLine "    or rax, r15"
            ELSEIF IOp(i)=OP_XOR THEN
                EmitLine "    xor rax, r15"
            END IF
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_NOT
            EmitLine "    ; "+IText(i)
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            EmitLine "    not rax"
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_SHL
            EmitLine "    ; "+IText(i)
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            EmitLine "    shl rax, 1"
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_SHR
            EmitLine "    ; "+IText(i)
            EmitAddrLoad IAddrKind(i),IAddrVal(i),"rax"
            EmitLine "    shr rax, 1"
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_STATUS
            EmitLine "    ; "+IText(i)
            EmitLine "    movzx rax, byte [ux_status]"
            EmitAddrStore IAddrKind(i),IAddrVal(i),"rax"
            EmitSetFlagsFromRAX
        CASE OP_LOOP_BEG
            EmitLoopBegin i
        CASE OP_LOOP_END
            EmitLoopEnd i
        CASE OP_META
            EmitLine "    ; "+IText(i)
            EmitMetaCall IMetaId(i),IMetaDyn(i)
        CASE OP_BRANCH
            EmitBranch i
        CASE OP_PRINT_STRING
            idx=FindStringIndex%(IAmt(i))
            EmitLine "    ; "+IText(i)
            EmitLine "    mov ecx, "+LTRIM$(STR$(StrStart(idx)))
            EmitLine "    mov edx, CELL_BITS"
            EmitLine "    call ux_print_data_string"
        CASE ELSE
            EmitLine "    nop"
    END SELECT
END SUB
SUB EmitAddrLoad(addrKind AS LONG, addrVal AS LONG, regName AS STRING)
    EmitAddrPtr addrKind,addrVal,"r11"
    SELECT CASE CellBits
        CASE 8
            EmitLine "    movzx "+regName+", byte [r11]"
        CASE 16
            EmitLine "    movzx "+regName+", word [r11]"
        CASE 32
            IF LCASE$(regName)="rax" THEN EmitLine "    mov eax, dword [r11]" ELSE EmitLine "    mov "+Reg32$(regName)+", dword [r11]"
    END SELECT
END SUB
SUB EmitAddrStore(addrKind AS LONG, addrVal AS LONG, regName AS STRING)
    EmitAddrPtr addrKind,addrVal,"r11"
    SELECT CASE CellBits
        CASE 8
            EmitLine "    mov byte [r11], "+Reg8$(regName)
        CASE 16
            EmitLine "    mov word [r11], "+Reg16$(regName)
        CASE 32
            EmitLine "    mov dword [r11], "+Reg32$(regName)
    END SELECT
END SUB
SUB EmitAddrPtr(addrKind AS LONG, addrVal AS LONG, outReg AS STRING)
    SELECT CASE addrKind
        CASE ADDR_T
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    lea "+outReg+", [r12 + rbx]"
                CASE 16
                    EmitLine "    lea "+outReg+", [r12 + rbx*2]"
                CASE 32
                    EmitLine "    lea "+outReg+", [r12 + rbx*4]"
            END SELECT
        CASE ADDR_T_REL
            IF BoundsOn THEN
                EmitLine "    mov r10, rbx"
                IF addrVal>=0 THEN EmitLine "    add r10, "+LTRIM$(STR$(addrVal)) ELSE EmitLine "    sub r10, "+LTRIM$(STR$(ABS(addrVal)))
                EmitLine "    cmp r10, TAPE_CELLS"
                EmitLine "    jae __ux_err_ptr"
                SELECT CASE CellBits
                    CASE 8
                        EmitLine "    lea "+outReg+", [r12 + r10]"
                    CASE 16
                        EmitLine "    lea "+outReg+", [r12 + r10*2]"
                    CASE 32
                        EmitLine "    lea "+outReg+", [r12 + r10*4]"
                END SELECT
            ELSE
                SELECT CASE CellBits
                    CASE 8
                        IF addrVal>=0 THEN EmitLine "    lea "+outReg+", [r12 + rbx + "+LTRIM$(STR$(addrVal))+"]" ELSE EmitLine "    lea "+outReg+", [r12 + rbx - "+LTRIM$(STR$(ABS(addrVal)))+"]"
                    CASE 16
                        IF addrVal>=0 THEN EmitLine "    lea "+outReg+", [r12 + rbx*2 + "+LTRIM$(STR$(addrVal*2))+"]" ELSE EmitLine "    lea "+outReg+", [r12 + rbx*2 - "+LTRIM$(STR$(ABS(addrVal*2)))+"]"
                    CASE 32
                        IF addrVal>=0 THEN EmitLine "    lea "+outReg+", [r12 + rbx*4 + "+LTRIM$(STR$(addrVal*4))+"]" ELSE EmitLine "    lea "+outReg+", [r12 + rbx*4 - "+LTRIM$(STR$(ABS(addrVal*4)))+"]"
                END SELECT
            END IF
        CASE ADDR_T_ABS
            IF BoundsOn THEN
                IF addrVal<0 OR addrVal>=TapeCells THEN EmitLine "    jmp __ux_err_ptr"
            END IF
            EmitLine "    lea "+outReg+", [r12 + "+LTRIM$(STR$(addrVal*CellSize&))+"]"
        CASE ADDR_D_ABS
            IF BoundsOn THEN
                IF addrVal<0 OR addrVal>=DataCells THEN EmitLine "    jmp __ux_err_data"
            END IF
            EmitLine "    lea "+outReg+", [r12 + DATA_OFFSET + "+LTRIM$(STR$(addrVal*CellSize&))+"]"
        CASE ADDR_S_ABS
            IF BoundsOn THEN
                IF addrVal<0 OR addrVal>=StackCells THEN EmitLine "    jmp __ux_err_stack_over"
            END IF
            EmitLine "    lea "+outReg+", [r13 + "+LTRIM$(STR$(addrVal*CellSize&))+"]"
        CASE ADDR_SP
            EmitLine "    cmp r14, 0"
            EmitLine "    je __ux_err_stack_under"
            EmitLine "    mov r10, r14"
            EmitLine "    dec r10"
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    lea "+outReg+", [r13 + r10]"
                CASE 16
                    EmitLine "    lea "+outReg+", [r13 + r10*2]"
                CASE 32
                    EmitLine "    lea "+outReg+", [r13 + r10*4]"
            END SELECT
        CASE ADDR_E
            EmitLine "    lea "+outReg+", [ux_status]"
        CASE ADDR_F
            EmitLine "    lea "+outReg+", [ux_flags]"
        CASE ADDR_P
            EmitLine "    lea "+outReg+", [ux_ptr]"
        CASE ADDR_IND_T
            EmitAddrLoad ADDR_T,0,"rax"
            IF BoundsOn THEN EmitLine "    cmp rax, TAPE_CELLS":EmitLine "    jae __ux_err_ptr"
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    lea "+outReg+", [r12 + rax]"
                CASE 16
                    EmitLine "    lea "+outReg+", [r12 + rax*2]"
                CASE 32
                    EmitLine "    lea "+outReg+", [r12 + rax*4]"
            END SELECT
        CASE ADDR_IND_T_REL
            EmitAddrLoad ADDR_T_REL,addrVal,"rax"
            IF BoundsOn THEN EmitLine "    cmp rax, TAPE_CELLS":EmitLine "    jae __ux_err_ptr"
            SELECT CASE CellBits
                CASE 8
                    EmitLine "    lea "+outReg+", [r12 + rax]"
                CASE 16
                    EmitLine "    lea "+outReg+", [r12 + rax*2]"
                CASE 32
                    EmitLine "    lea "+outReg+", [r12 + rax*4]"
            END SELECT
        CASE ELSE
            EmitLine "    lea "+outReg+", [r12 + rbx]"
    END SELECT
END SUB
SUB EmitSetFlagsFromRAX()
    DIM id AS LONG
    id=NewAsmId&
    EmitLine "    push rax"
    EmitLine "    mov dx, word [ux_flags]"
    EmitLine "    and dx, 0FFF0h"
    EmitLine "    cmp rax, 0"
    EmitLine "    jne __ux_noz_"+LTRIM$(STR$(id))
    EmitLine "    or dx, FLAG_Z"
    EmitLine "__ux_noz_"+LTRIM$(STR$(id))+":"
    SELECT CASE CellBits
        CASE 8
            EmitLine "    test al, 80h"
        CASE 16
            EmitLine "    test ax, 8000h"
        CASE 32
            EmitLine "    test eax, 80000000h"
    END SELECT
    EmitLine "    jz __ux_nos_"+LTRIM$(STR$(id))
    EmitLine "    or dx, FLAG_S"
    EmitLine "__ux_nos_"+LTRIM$(STR$(id))+":"
    EmitLine "    mov word [ux_flags], dx"
    EmitLine "    pop rax"
END SUB
SUB EmitMetaCall(metaId AS LONG, dynamicFlag AS LONG)
    EmitLine "    mov qword [ux_ptr], rbx"
    EmitLine "    mov qword [ux_sp], r14"
    IF dynamicFlag THEN
        EmitAddrLoad ADDR_T,0,"rax"
        EmitLine "    mov ecx, eax"
    ELSE
        EmitLine "    mov ecx, "+LTRIM$(STR$(metaId))
    END IF
    EmitLine "    lea rdx, [ux_mem]"
    EmitLine "    call ux_meta_call_ex"
    EmitLine "    mov rbx, qword [ux_ptr]"
    EmitLine "    mov r14, qword [ux_sp]"
END SUB
SUB EmitBranch(i AS LONG)
    DIM target AS LONG
    target=IBrTarget(i)
    EmitLine "    ; "+IText(i)+" -> __ux_ip_"+LTRIM$(STR$(target))
    SELECT CASE IBrCond(i)
        CASE BR_CUR_NZ
            EmitAddrLoad ADDR_T,0,"rax"
            EmitLine "    cmp rax, 0"
            EmitLine "    jne __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_CUR_Z
            EmitAddrLoad ADDR_T,0,"rax"
            EmitLine "    cmp rax, 0"
            EmitLine "    je __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_ALWAYS
            EmitLine "    jmp __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_Z_SET
            EmitLine "    test word [ux_flags], FLAG_Z"
            EmitLine "    jnz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_Z_CLR
            EmitLine "    test word [ux_flags], FLAG_Z"
            EmitLine "    jz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_C_SET
            EmitLine "    test word [ux_flags], FLAG_C"
            EmitLine "    jnz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_C_CLR
            EmitLine "    test word [ux_flags], FLAG_C"
            EmitLine "    jz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_O_SET
            EmitLine "    test word [ux_flags], FLAG_O"
            EmitLine "    jnz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_O_CLR
            EmitLine "    test word [ux_flags], FLAG_O"
            EmitLine "    jz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_S_SET
            EmitLine "    test word [ux_flags], FLAG_S"
            EmitLine "    jnz __ux_ip_"+LTRIM$(STR$(target))
        CASE BR_S_CLR
            EmitLine "    test word [ux_flags], FLAG_S"
            EmitLine "    jz __ux_ip_"+LTRIM$(STR$(target))
    END SELECT
END SUB
SUB EmitLoopBegin(i AS LONG)
    DIM id AS LONG
    id=LoopId(i)
    EmitLine "__ux_loop_beg_"+LTRIM$(STR$(id))+":"
    EmitAddrLoad ADDR_T,0,"rax"
    EmitLine "    cmp rax, 0"
    EmitLine "    je __ux_loop_end_"+LTRIM$(STR$(id))
END SUB
SUB EmitLoopEnd(i AS LONG)
    DIM id AS LONG
    id=LoopId(i)
    EmitLine "    jmp __ux_loop_beg_"+LTRIM$(STR$(id))
    EmitLine "__ux_loop_end_"+LTRIM$(STR$(id))+":"
END SUB
SUB EmitFooter()
    EmitLine "__ux_ok_exit:"
    EmitLine "    add rsp, 40"
    EmitLine "    pop r15"
    EmitLine "    pop r14"
    EmitLine "    pop r13"
    EmitLine "    pop r12"
    EmitLine "    pop rbx"
    EmitLine "    pop rbp"
    EmitLine "    ret"
    EmitLine "__ux_err_ptr:"
    EmitLine "    mov byte [ux_status], 10"
    EmitLine "    mov ecx, 10"
    EmitLine "    call ux_runtime_error"
    EmitLine "    jmp __ux_ok_exit"
    EmitLine "__ux_err_stack_over:"
    EmitLine "    mov byte [ux_status], 11"
    EmitLine "    mov ecx, 11"
    EmitLine "    call ux_runtime_error"
    EmitLine "    jmp __ux_ok_exit"
    EmitLine "__ux_err_stack_under:"
    EmitLine "    mov byte [ux_status], 12"
    EmitLine "    mov ecx, 12"
    EmitLine "    call ux_runtime_error"
    EmitLine "    jmp __ux_ok_exit"
    EmitLine "__ux_err_data:"
    EmitLine "    mov byte [ux_status], 16"
    EmitLine "    mov ecx, 16"
    EmitLine "    call ux_runtime_error"
    EmitLine "    jmp __ux_ok_exit"
END SUB
```



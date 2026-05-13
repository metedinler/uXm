OPTION _EXPLICIT
CONST UXM_TOTAL_BYTES=65536
CONST MAX_TOKENS=400000
CONST MAX_COMMANDS=64
CONST MAX_PATTERNS=256
CONST MAX_LOOP_STACK=4096
CONST MAX_STRINGS=1024
CONST MAX_REPEAT_COUNT=1000000
CONST OV_WRAP=0
CONST OV_CHECK=1
CONST CMP_EQ=1
CONST CMP_GT=2
CONST CMP_LT=3
CONST BIN_AND=1
CONST BIN_OR=2
CONST BIN_XOR=3
DECLARE SUB LoadCommandTable()
DECLARE SUB LoadPatternTable()
DECLARE SUB SortPatternTable()
DECLARE SUB AskOptions()
DECLARE SUB ReadSourceFile()
DECLARE SUB Lexer()
DECLARE SUB AddToken(t AS STRING)
DECLARE SUB AddRepeatedToken(c AS STRING,countVal AS LONG)
DECLARE SUB SkipLine(pos AS LONG)
DECLARE SUB SkipSpaces(pos AS LONG)
DECLARE SUB AddStringDecl(sid AS LONG,startCell AS LONG,txt AS STRING)
DECLARE SUB GenerateASM()
DECLARE SUB EmitHeader()
DECLARE SUB EmitFooter()
DECLARE SUB EmitLine(s AS STRING)
DECLARE SUB EmitStringInitializers()
DECLARE SUB EmitAsmTemplate(tpl AS STRING)
DECLARE SUB EmitSingleToken(t AS STRING)
DECLARE SUB EmitPointerCheck()
DECLARE SUB EmitNeighborCheck(offCells AS LONG)
DECLARE SUB EmitMovePtr(delta AS LONG)
DECLARE SUB EmitSetCell(offCells AS LONG,value AS LONG)
DECLARE SUB EmitClearCell(offCells AS LONG)
DECLARE SUB EmitAddCell(offCells AS LONG,amount AS LONG)
DECLARE SUB EmitSubCell(offCells AS LONG,amount AS LONG)
DECLARE SUB EmitPutChar()
DECLARE SUB EmitGetChar()
DECLARE SUB EmitMetaFromCell()
DECLARE SUB EmitMetaConst(metaId AS LONG)
DECLARE SUB EmitPushCell()
DECLARE SUB EmitPopCell()
DECLARE SUB EmitCompare(cmpMode AS LONG)
DECLARE SUB EmitBinaryBitwise(opMode AS LONG)
DECLARE SUB EmitNotCell()
DECLARE SUB EmitShiftLeft()
DECLARE SUB EmitShiftRight()
DECLARE SUB EmitLoopStart()
DECLARE SUB EmitLoopEnd()
DECLARE SUB EmitPrintStringById(sid AS LONG)
DECLARE SUB CompileError(msg AS STRING)
DECLARE FUNCTION DefaultASMName$(srcName AS STRING)
DECLARE FUNCTION IsDigitChar%(c AS STRING)
DECLARE FUNCTION TryParseStringDecl%(pos AS LONG)
DECLARE FUNCTION TryParsePrintString%(pos AS LONG)
DECLARE FUNCTION ParseUnsignedNumber&(pos AS LONG,ok AS LONG)
DECLARE FUNCTION ParseBracedString$(pos AS LONG,ok AS LONG)
DECLARE FUNCTION FindStringIndexById%(sid AS LONG)
DECLARE FUNCTION IsTokenPrintString%(t AS STRING)
DECLARE FUNCTION PrintStringIdFromToken%(t AS STRING)
DECLARE FUNCTION RepeatChar$(ch AS STRING,n AS LONG)
DECLARE FUNCTION NormalizePattern$(s AS STRING)
DECLARE FUNCTION PatternIsBalanced%(s AS STRING)
DECLARE FUNCTION SpecificityScore%(p AS STRING)
DECLARE FUNCTION PatternBetter%(a AS LONG,b AS LONG)
DECLARE FUNCTION MatchPattern%(startIdx AS LONG)
DECLARE FUNCTION SizePrefix$()
DECLARE FUNCTION StoreReg$()
DECLARE FUNCTION MaxValueText$()
DECLARE FUNCTION ReduceValue&(v AS LONG)
DECLARE FUNCTION IndexExpr$(baseReg AS STRING,indexReg AS STRING,offCells AS LONG)
DECLARE FUNCTION CellOp$(offCells AS LONG)
DECLARE FUNCTION StackOp$()
DECLARE FUNCTION DataByteOffset&(cellNo AS LONG)
DECLARE FUNCTION DataCellOpConst$(cellNo AS LONG)
DECLARE FUNCTION CommandChars$()
DECLARE FUNCTION ReplaceAll$(src AS STRING,find AS STRING,repl AS STRING)
DECLARE FUNCTION ExpandedTemplate$(tpl AS STRING)
DECLARE FUNCTION Check0Template$()
DECLARE FUNCTION CheckOffsetTemplate$(offCells AS LONG)
DIM SHARED Src AS STRING
DIM SHARED InFileName AS STRING
DIM SHARED OutASMName AS STRING
DIM SHARED Tokens(1 TO MAX_TOKENS) AS STRING
DIM SHARED TokenCount AS LONG
DIM SHARED CmdSymbol(1 TO MAX_COMMANDS) AS STRING
DIM SHARED CmdName(1 TO MAX_COMMANDS) AS STRING
DIM SHARED CmdRole(1 TO MAX_COMMANDS) AS STRING
DIM SHARED CommandCount AS LONG
DIM SHARED Pat(1 TO MAX_PATTERNS) AS STRING
DIM SHARED PatAsm(1 TO MAX_PATTERNS) AS STRING
DIM SHARED PatPriority(1 TO MAX_PATTERNS) AS LONG
DIM SHARED PatOrder(1 TO MAX_PATTERNS) AS LONG
DIM SHARED PatCount AS LONG
DIM SHARED LoopStack(1 TO MAX_LOOP_STACK) AS LONG
DIM SHARED LoopSP AS LONG
DIM SHARED LoopCount AS LONG
DIM SHARED StrId(1 TO MAX_STRINGS) AS LONG
DIM SHARED StrStartCell(1 TO MAX_STRINGS) AS LONG
DIM SHARED StrText(1 TO MAX_STRINGS) AS STRING
DIM SHARED StrCount AS LONG
DIM SHARED OutFF AS LONG
DIM SHARED HadError AS LONG
DIM SHARED CellBits AS LONG
DIM SHARED CellBytes AS LONG
DIM SHARED TapeBytes AS LONG
DIM SHARED StackBytes AS LONG
DIM SHARED DataBytes AS LONG
DIM SHARED TapeCells AS LONG
DIM SHARED StackCells AS LONG
DIM SHARED DataCells AS LONG
DIM SHARED StackOffsetBytes AS LONG
DIM SHARED DataOffsetBytes AS LONG
DIM SHARED BoundsCheck AS LONG
DIM SHARED OverflowMode AS LONG
CLS
PRINT "=============================================================="
PRINT " UXM-64K V3 DATA-DRIVEN COMPILER - QB64"
PRINT " UXM source -> Windows x64 NASM ASM"
PRINT "=============================================================="
PRINT
LoadCommandTable
LoadPatternTable
SortPatternTable
AskOptions
IF HadError=0 THEN ReadSourceFile
IF HadError=0 THEN Lexer
IF HadError=0 THEN GenerateASM
PRINT
IF HadError<>0 THEN
    PRINT "Derleme hatali bitti."
ELSE
    PRINT "ASM uretildi: ";OutASMName
    PRINT "NASM:"
    PRINT "  nasm -f win64 ";OutASMName;" -o build.obj"
    PRINT "FreeBASIC runtime ile link:"
    PRINT "  fbc uxm64_runtime.bas build.obj -x program.exe"
END IF
CommandData:
DATA 26
DATA ">","MOVE_RIGHT","Tape pointer one cell right"
DATA "<","MOVE_LEFT","Tape pointer one cell left"
DATA "+","INC","Increase current cell"
DATA "-","DEC","Decrease current cell"
DATA "0","CLEAR","Set current cell to zero"
DATA ".","PUTC","Print current cell as character"
DATA ",","GETC","Read one character into current cell"
DATA "[","LOOP_BEGIN","Loop or conditional block begin"
DATA "]","LOOP_END","Loop block end"
DATA "$","PUSH","Push current cell to UXM stack"
DATA "%","POP","Pop UXM stack into current cell"
DATA "?","EQ","Compare stack top equal current"
DATA "!","GT","Compare stack top greater than current"
DATA ";","LT","Compare stack top less than current"
DATA "&","AND","Bitwise AND stack top with current"
DATA "|","OR","Bitwise OR stack top with current"
DATA "^","XOR","Bitwise XOR stack top with current"
DATA "~","NOT","Bitwise NOT current cell"
DATA "@","META","Runtime or meta service call"
DATA "sN","STRING_DEF","String definition directive"
DATA "pN","STRING_PRINT","Print string directive"
DATA "kN","REPEAT","Repeat macro after command"
DATA "#","COMMENT","Line comment"
DATA ":","LABEL_RESERVED","Reserved label or separator"
DATA "{","SHL","Shift left current cell"
DATA "}","SHR","Shift right current cell"
PatternData:
DATA 256
DATA "[-]","{CHECK0}|mov {CELL0}, 0"
DATA "[+]","{CHECK0}|mov {CELL0}, 0"
DATA "[->+<]","{CHECK+1}|mov {REG}, {CELL0}|add {CELL+1}, {REG}|mov {CELL0}, 0"
DATA "[>+<-]","{CHECK+1}|mov {REG}, {CELL0}|add {CELL+1}, {REG}|mov {CELL0}, 0"
DATA "[<+>-]","{CHECK-1}|mov {REG}, {CELL0}|add {CELL-1}, {REG}|mov {CELL0}, 0"
DATA "$%","nop"
DATA "+-","nop"
DATA "-+","nop"
DATA "<>","nop"
DATA "><","nop"
DATA "00","{CHECK0}|mov {CELL0}, 0"
DATA "000","{CHECK0}|mov {CELL0}, 0"
DATA "0+@","mov {CELL0}, 1|mov ecx, 1|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0++@","mov {CELL0}, 2|mov ecx, 2|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0+++@","mov {CELL0}, 3|mov ecx, 3|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0++++@","mov {CELL0}, 4|mov ecx, 4|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0+++++@","mov {CELL0}, 5|mov ecx, 5|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0++++++@","mov {CELL0}, 6|mov ecx, 6|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0+++++++@","mov {CELL0}, 7|mov ecx, 7|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0++++++++@","mov {CELL0}, 8|mov ecx, 8|call ux_meta_call|mov {CELL0}, {REG}"
DATA "0+","{CHECK0}|mov {CELL0}, 1"
DATA "0++","{CHECK0}|mov {CELL0}, 2"
DATA "0+++","{CHECK0}|mov {CELL0}, 3"
DATA "0++++","{CHECK0}|mov {CELL0}, 4"
DATA "0+++++","{CHECK0}|mov {CELL0}, 5"
DATA "0++++++","{CHECK0}|mov {CELL0}, 6"
DATA "0+++++++","{CHECK0}|mov {CELL0}, 7"
DATA "0++++++++","{CHECK0}|mov {CELL0}, 8"
DATA "0+++++++++","{CHECK0}|mov {CELL0}, 9"
DATA "0++++++++++","{CHECK0}|mov {CELL0}, 10"
DATA "0+++++++++++","{CHECK0}|mov {CELL0}, 11"
DATA "0++++++++++++","{CHECK0}|mov {CELL0}, 12"
DATA "++","{CHECK0}|add {CELL0}, 2"
DATA "+++","{CHECK0}|add {CELL0}, 3"
DATA "++++","{CHECK0}|add {CELL0}, 4"
DATA "+++++","{CHECK0}|add {CELL0}, 5"
DATA "++++++","{CHECK0}|add {CELL0}, 6"
DATA "+++++++","{CHECK0}|add {CELL0}, 7"
DATA "++++++++","{CHECK0}|add {CELL0}, 8"
DATA "+++++++++","{CHECK0}|add {CELL0}, 9"
DATA "++++++++++","{CHECK0}|add {CELL0}, 10"
DATA "+++++++++++","{CHECK0}|add {CELL0}, 11"
DATA "++++++++++++","{CHECK0}|add {CELL0}, 12"
DATA "+++++++++++++","{CHECK0}|add {CELL0}, 13"
DATA "++++++++++++++","{CHECK0}|add {CELL0}, 14"
DATA "+++++++++++++++","{CHECK0}|add {CELL0}, 15"
DATA "++++++++++++++++","{CHECK0}|add {CELL0}, 16"
DATA "+++++++++++++++++","{CHECK0}|add {CELL0}, 17"
DATA "++++++++++++++++++","{CHECK0}|add {CELL0}, 18"
DATA "+++++++++++++++++++","{CHECK0}|add {CELL0}, 19"
DATA "++++++++++++++++++++","{CHECK0}|add {CELL0}, 20"
DATA "+++++++++++++++++++++","{CHECK0}|add {CELL0}, 21"
DATA "++++++++++++++++++++++","{CHECK0}|add {CELL0}, 22"
DATA "+++++++++++++++++++++++","{CHECK0}|add {CELL0}, 23"
DATA "++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 24"
DATA "+++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 25"
DATA "++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 26"
DATA "+++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 27"
DATA "++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 28"
DATA "+++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 29"
DATA "++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 30"
DATA "+++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 31"
DATA "++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 32"
DATA "+++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 33"
DATA "++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 34"
DATA "+++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 35"
DATA "++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 36"
DATA "+++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 37"
DATA "++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 38"
DATA "+++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 39"
DATA "++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 40"
DATA "+++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 41"
DATA "++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 42"
DATA "+++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 43"
DATA "++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 44"
DATA "+++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 45"
DATA "++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 46"
DATA "+++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 47"
DATA "++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 48"
DATA "+++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 49"
DATA "++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 50"
DATA "+++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 51"
DATA "++++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 52"
DATA "+++++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 53"
DATA "++++++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 54"
DATA "+++++++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 55"
DATA "++++++++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 56"
DATA "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++","{CHECK0}|add {CELL0}, 57"
DATA "--","{CHECK0}|sub {CELL0}, 2"
DATA "---","{CHECK0}|sub {CELL0}, 3"
DATA "----","{CHECK0}|sub {CELL0}, 4"
DATA "-----","{CHECK0}|sub {CELL0}, 5"
DATA "------","{CHECK0}|sub {CELL0}, 6"
DATA "-------","{CHECK0}|sub {CELL0}, 7"
DATA "--------","{CHECK0}|sub {CELL0}, 8"
DATA "---------","{CHECK0}|sub {CELL0}, 9"
DATA "----------","{CHECK0}|sub {CELL0}, 10"
DATA "-----------","{CHECK0}|sub {CELL0}, 11"
DATA "------------","{CHECK0}|sub {CELL0}, 12"
DATA "-------------","{CHECK0}|sub {CELL0}, 13"
DATA "--------------","{CHECK0}|sub {CELL0}, 14"
DATA "---------------","{CHECK0}|sub {CELL0}, 15"
DATA "----------------","{CHECK0}|sub {CELL0}, 16"
DATA "-----------------","{CHECK0}|sub {CELL0}, 17"
DATA "------------------","{CHECK0}|sub {CELL0}, 18"
DATA "-------------------","{CHECK0}|sub {CELL0}, 19"
DATA "--------------------","{CHECK0}|sub {CELL0}, 20"
DATA "---------------------","{CHECK0}|sub {CELL0}, 21"
DATA "----------------------","{CHECK0}|sub {CELL0}, 22"
DATA "-----------------------","{CHECK0}|sub {CELL0}, 23"
DATA "------------------------","{CHECK0}|sub {CELL0}, 24"
DATA "-------------------------","{CHECK0}|sub {CELL0}, 25"
DATA "--------------------------","{CHECK0}|sub {CELL0}, 26"
DATA "---------------------------","{CHECK0}|sub {CELL0}, 27"
DATA "----------------------------","{CHECK0}|sub {CELL0}, 28"
DATA "-----------------------------","{CHECK0}|sub {CELL0}, 29"
DATA "------------------------------","{CHECK0}|sub {CELL0}, 30"
DATA "-------------------------------","{CHECK0}|sub {CELL0}, 31"
DATA "--------------------------------","{CHECK0}|sub {CELL0}, 32"
DATA "---------------------------------","{CHECK0}|sub {CELL0}, 33"
DATA "----------------------------------","{CHECK0}|sub {CELL0}, 34"
DATA "-----------------------------------","{CHECK0}|sub {CELL0}, 35"
DATA "------------------------------------","{CHECK0}|sub {CELL0}, 36"
DATA "-------------------------------------","{CHECK0}|sub {CELL0}, 37"
DATA "--------------------------------------","{CHECK0}|sub {CELL0}, 38"
DATA "---------------------------------------","{CHECK0}|sub {CELL0}, 39"
DATA "----------------------------------------","{CHECK0}|sub {CELL0}, 40"
DATA "-----------------------------------------","{CHECK0}|sub {CELL0}, 41"
DATA "------------------------------------------","{CHECK0}|sub {CELL0}, 42"
DATA "-------------------------------------------","{CHECK0}|sub {CELL0}, 43"
DATA "--------------------------------------------","{CHECK0}|sub {CELL0}, 44"
DATA "---------------------------------------------","{CHECK0}|sub {CELL0}, 45"
DATA "----------------------------------------------","{CHECK0}|sub {CELL0}, 46"
DATA "-----------------------------------------------","{CHECK0}|sub {CELL0}, 47"
DATA "------------------------------------------------","{CHECK0}|sub {CELL0}, 48"
DATA "-------------------------------------------------","{CHECK0}|sub {CELL0}, 49"
DATA "--------------------------------------------------","{CHECK0}|sub {CELL0}, 50"
DATA "---------------------------------------------------","{CHECK0}|sub {CELL0}, 51"
DATA "----------------------------------------------------","{CHECK0}|sub {CELL0}, 52"
DATA "-----------------------------------------------------","{CHECK0}|sub {CELL0}, 53"
DATA "------------------------------------------------------","{CHECK0}|sub {CELL0}, 54"
DATA "-------------------------------------------------------","{CHECK0}|sub {CELL0}, 55"
DATA "--------------------------------------------------------","{CHECK0}|sub {CELL0}, 56"
DATA "---------------------------------------------------------","{CHECK0}|sub {CELL0}, 57"
DATA ">>","add rbx, 2|{PTRCHECK}"
DATA ">>>","add rbx, 3|{PTRCHECK}"
DATA ">>>>","add rbx, 4|{PTRCHECK}"
DATA ">>>>>","add rbx, 5|{PTRCHECK}"
DATA ">>>>>>","add rbx, 6|{PTRCHECK}"
DATA ">>>>>>>","add rbx, 7|{PTRCHECK}"
DATA ">>>>>>>>","add rbx, 8|{PTRCHECK}"
DATA ">>>>>>>>>","add rbx, 9|{PTRCHECK}"
DATA ">>>>>>>>>>","add rbx, 10|{PTRCHECK}"
DATA ">>>>>>>>>>>","add rbx, 11|{PTRCHECK}"
DATA ">>>>>>>>>>>>","add rbx, 12|{PTRCHECK}"
DATA ">>>>>>>>>>>>>","add rbx, 13|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>","add rbx, 14|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>","add rbx, 15|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>","add rbx, 16|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>","add rbx, 17|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>","add rbx, 18|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>","add rbx, 19|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>","add rbx, 20|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>","add rbx, 21|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>","add rbx, 22|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>","add rbx, 23|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 24|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 25|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 26|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 27|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 28|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 29|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 30|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 31|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 32|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 33|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 34|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 35|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 36|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 37|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 38|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 39|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 40|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 41|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 42|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 43|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 44|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 45|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 46|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 47|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 48|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 49|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 50|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 51|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 52|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 53|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 54|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 55|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 56|{PTRCHECK}"
DATA ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>","add rbx, 57|{PTRCHECK}"
DATA "<<","sub rbx, 2|{PTRCHECK}"
DATA "<<<","sub rbx, 3|{PTRCHECK}"
DATA "<<<<","sub rbx, 4|{PTRCHECK}"
DATA "<<<<<","sub rbx, 5|{PTRCHECK}"
DATA "<<<<<<","sub rbx, 6|{PTRCHECK}"
DATA "<<<<<<<","sub rbx, 7|{PTRCHECK}"
DATA "<<<<<<<<","sub rbx, 8|{PTRCHECK}"
DATA "<<<<<<<<<","sub rbx, 9|{PTRCHECK}"
DATA "<<<<<<<<<<","sub rbx, 10|{PTRCHECK}"
DATA "<<<<<<<<<<<","sub rbx, 11|{PTRCHECK}"
DATA "<<<<<<<<<<<<","sub rbx, 12|{PTRCHECK}"
DATA "<<<<<<<<<<<<<","sub rbx, 13|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<","sub rbx, 14|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<","sub rbx, 15|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<","sub rbx, 16|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<","sub rbx, 17|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<","sub rbx, 18|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<","sub rbx, 19|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<","sub rbx, 20|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<","sub rbx, 21|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 22|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 23|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 24|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 25|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 26|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 27|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 28|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 29|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 30|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 31|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 32|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 33|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 34|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 35|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 36|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 37|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 38|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 39|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 40|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 41|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 42|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 43|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 44|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 45|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 46|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 47|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 48|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 49|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 50|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 51|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 52|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 53|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 54|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 55|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 56|{PTRCHECK}"
DATA "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<","sub rbx, 57|{PTRCHECK}"
END
SUB LoadCommandTable
    DIM i AS LONG
    RESTORE CommandData
    READ CommandCount
    IF CommandCount>MAX_COMMANDS THEN CompileError "Command table MAX_COMMANDS limitini asti.":EXIT SUB
    FOR i=1 TO CommandCount
        READ CmdSymbol(i),CmdName(i),CmdRole(i)
    NEXT i
END SUB
SUB LoadPatternTable
    DIM i AS LONG
    RESTORE PatternData
    READ PatCount
    IF PatCount<>MAX_PATTERNS THEN CompileError "Pattern sayisi 256 olmali. DATA sayisi="+LTRIM$(STR$(PatCount)):EXIT SUB
    FOR i=1 TO PatCount
        READ Pat(i),PatAsm(i)
        Pat(i)=NormalizePattern$(Pat(i))
        IF PatternIsBalanced%(Pat(i))=0 THEN CompileError "Dengesiz pattern: "+Pat(i):EXIT SUB
        PatPriority(i)=SpecificityScore%(Pat(i))
        PatOrder(i)=i
    NEXT i
    PRINT "Komut sayisi  : ";CommandCount
    PRINT "Pattern sayisi: ";PatCount
END SUB
SUB SortPatternTable
    DIM i AS LONG
    DIM j AS LONG
    DIM tp AS STRING
    DIM ta AS STRING
    DIM tpri AS LONG
    DIM tord AS LONG
    FOR i=1 TO PatCount-1
        FOR j=i+1 TO PatCount
            IF PatternBetter%(j,i)<>0 THEN
                tp=Pat(i):ta=PatAsm(i):tpri=PatPriority(i):tord=PatOrder(i)
                Pat(i)=Pat(j):PatAsm(i)=PatAsm(j):PatPriority(i)=PatPriority(j):PatOrder(i)=PatOrder(j)
                Pat(j)=tp:PatAsm(j)=ta:PatPriority(j)=tpri:PatOrder(j)=tord
            END IF
        NEXT j
    NEXT i
END SUB
FUNCTION PatternBetter%(a AS LONG,b AS LONG)
    IF LEN(Pat(a))>LEN(Pat(b)) THEN PatternBetter%=1:EXIT FUNCTION
    IF LEN(Pat(a))<LEN(Pat(b)) THEN PatternBetter%=0:EXIT FUNCTION
    IF PatPriority(a)>PatPriority(b) THEN PatternBetter%=1:EXIT FUNCTION
    IF PatPriority(a)<PatPriority(b) THEN PatternBetter%=0:EXIT FUNCTION
    IF PatOrder(a)<PatOrder(b) THEN PatternBetter%=1 ELSE PatternBetter%=0
END FUNCTION
SUB AskOptions
    DIM s AS STRING
    DIM n AS LONG
    DIM totalBytes AS LONG
    PRINT
    PRINT "Kaynak dosya (.uxm veya .txt): ";
    LINE INPUT InFileName
    IF LEN(LTRIM$(RTRIM$(InFileName)))=0 THEN CompileError "Kaynak dosya adi bos.":EXIT SUB
    PRINT "ASM cikis dosyasi [otomatik]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN OutASMName=DefaultASMName$(InFileName) ELSE OutASMName=LTRIM$(RTRIM$(s))
    PRINT "Hucre tipi 8/16/32 [8]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN CellBits=8 ELSE CellBits=VAL(s)
    SELECT CASE CellBits
        CASE 8
            CellBytes=1
        CASE 16
            CellBytes=2
        CASE 32
            CellBytes=4
        CASE ELSE
            CompileError "Gecersiz hucre tipi.":EXIT SUB
    END SELECT
    PRINT "Tape KB [32]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN n=32 ELSE n=VAL(s)
    IF n<1 THEN n=32
    TapeBytes=n*1024
    PRINT "Stack KB [8]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN n=8 ELSE n=VAL(s)
    IF n<1 THEN n=8
    StackBytes=n*1024
    PRINT "Data KB [otomatik kalan]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN
        IF TapeBytes+StackBytes>=UXM_TOTAL_BYTES THEN CompileError "Tape+Stack 64KB sinirini asti.":EXIT SUB
        DataBytes=UXM_TOTAL_BYTES-TapeBytes-StackBytes
    ELSE
        n=VAL(s)
        IF n<1 THEN n=24
        DataBytes=n*1024
    END IF
    totalBytes=TapeBytes+StackBytes+DataBytes
    IF totalBytes<>UXM_TOTAL_BYTES THEN CompileError "Tape+Stack+Data tam 64KB olmali.":PRINT "Toplam KB:";totalBytes\1024:EXIT SUB
    TapeCells=TapeBytes\CellBytes
    StackCells=StackBytes\CellBytes
    DataCells=DataBytes\CellBytes
    StackOffsetBytes=TapeBytes
    DataOffsetBytes=TapeBytes+StackBytes
    PRINT "Overflow 0=wrap 1=check [0]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN OverflowMode=OV_WRAP ELSE OverflowMode=VAL(s)
    IF OverflowMode<>OV_WRAP AND OverflowMode<>OV_CHECK THEN CompileError "Gecersiz overflow modu.":EXIT SUB
    PRINT "Bounds check 1=on 0=off [1]: ";
    LINE INPUT s
    IF LEN(LTRIM$(RTRIM$(s)))=0 THEN BoundsCheck=1 ELSE BoundsCheck=VAL(s)
    IF BoundsCheck<>0 THEN BoundsCheck=1
    PRINT "Ayarlar: cell=";CellBits;" tapeKB=";TapeBytes\1024;" stackKB=";StackBytes\1024;" dataKB=";DataBytes\1024
END SUB
FUNCTION DefaultASMName$(srcName AS STRING)
    DIM i AS LONG
    DIM dotPos AS LONG
    dotPos=0
    FOR i=LEN(srcName) TO 1 STEP -1
        IF MID$(srcName,i,1)="." THEN dotPos=i:EXIT FOR
    NEXT i
    IF dotPos>0 THEN DefaultASMName$=LEFT$(srcName,dotPos-1)+".asm" ELSE DefaultASMName$=srcName+".asm"
END FUNCTION
SUB ReadSourceFile
    DIM ff AS LONG
    DIM sz AS LONG
    IF _FILEEXISTS(InFileName)=0 THEN CompileError "Kaynak dosya bulunamadi: "+InFileName:EXIT SUB
    ff=FREEFILE
    OPEN InFileName FOR BINARY AS #ff
    sz=LOF(ff)
    IF sz<=0 THEN Src="" ELSE Src=SPACE$(sz):GET #ff,,Src
    CLOSE #ff
    IF LEN(Src)>=3 THEN
        IF (ASC(MID$(Src,1,1)) AND &HFF)=&HEF AND (ASC(MID$(Src,2,1)) AND &HFF)=&HBB AND (ASC(MID$(Src,3,1)) AND &HFF)=&HBF THEN Src=MID$(Src,4)
    END IF
END SUB
SUB Lexer
    DIM i AS LONG
    DIM j AS LONG
    DIM c AS STRING
    DIM nextC AS STRING
    DIM numText AS STRING
    DIM repeatCount AS LONG
    DIM chars AS STRING
    TokenCount=0
    StrCount=0
    chars=CommandChars$
    i=1
    DO WHILE i<=LEN(Src) AND HadError=0
        c=MID$(Src,i,1)
        IF c="#" THEN
            SkipLine i
        ELSEIF c="s" OR c="S" THEN
            IF TryParseStringDecl%(i)=0 THEN i=i+1
        ELSEIF c="p" OR c="P" THEN
            IF TryParsePrintString%(i)=0 THEN i=i+1
        ELSEIF INSTR(chars,c)>0 THEN
            IF i+2<=LEN(Src) THEN
                nextC=MID$(Src,i+1,1)
                IF (nextC="k" OR nextC="K") AND IsDigitChar%(MID$(Src,i+2,1))<>0 THEN
                    j=i+2
                    numText=""
                    DO WHILE j<=LEN(Src)
                        IF IsDigitChar%(MID$(Src,j,1))=0 THEN EXIT DO
                        numText=numText+MID$(Src,j,1)
                        j=j+1
                    LOOP
                    repeatCount=VAL(numText)
                    IF repeatCount>MAX_REPEAT_COUNT THEN CompileError "Repeat macro cok buyuk: "+c+"k"+numText:EXIT SUB
                    AddRepeatedToken c,repeatCount
                    i=j
                ELSE
                    AddToken c
                    i=i+1
                END IF
            ELSE
                AddToken c
                i=i+1
            END IF
        ELSE
            i=i+1
        END IF
    LOOP
    PRINT "Token sayisi : ";TokenCount
    PRINT "String sayisi: ";StrCount
END SUB
FUNCTION CommandChars$
    CommandChars$="><+-0.,[]$%?!;&|^~@:{}"
END FUNCTION
SUB AddToken(t AS STRING)
    IF HadError<>0 THEN EXIT SUB
    IF TokenCount>=MAX_TOKENS THEN CompileError "Token dizisi doldu.":EXIT SUB
    TokenCount=TokenCount+1
    Tokens(TokenCount)=t
END SUB
SUB AddRepeatedToken(c AS STRING,countVal AS LONG)
    DIM n AS LONG
    IF HadError<>0 THEN EXIT SUB
    IF countVal<=0 THEN EXIT SUB
    IF TokenCount+countVal>MAX_TOKENS THEN CompileError "Repeat macro token limitini asti: "+c+"k"+LTRIM$(STR$(countVal)):EXIT SUB
    FOR n=1 TO countVal
        TokenCount=TokenCount+1
        Tokens(TokenCount)=c
    NEXT n
END SUB
SUB SkipLine(pos AS LONG)
    DO WHILE pos<=LEN(Src)
        IF MID$(Src,pos,1)=CHR$(10) THEN pos=pos+1:EXIT SUB
        pos=pos+1
    LOOP
END SUB
SUB SkipSpaces(pos AS LONG)
    DO WHILE pos<=LEN(Src)
        SELECT CASE MID$(Src,pos,1)
            CASE " ",CHR$(9),CHR$(13),CHR$(10)
                pos=pos+1
            CASE ELSE
                EXIT DO
        END SELECT
    LOOP
END SUB
FUNCTION TryParseStringDecl%(pos AS LONG)
    DIM p AS LONG
    DIM ok AS LONG
    DIM sid AS LONG
    DIM startCell AS LONG
    DIM txt AS STRING
    p=pos
    IF MID$(Src,p,1)<>"s" AND MID$(Src,p,1)<>"S" THEN TryParseStringDecl%=0:EXIT FUNCTION
    p=p+1
    IF p>LEN(Src) THEN TryParseStringDecl%=0:EXIT FUNCTION
    IF IsDigitChar%(MID$(Src,p,1))=0 THEN TryParseStringDecl%=0:EXIT FUNCTION
    sid=ParseUnsignedNumber&(p,ok)
    IF ok=0 THEN CompileError "String numarasi okunamadi.":TryParseStringDecl%=1:EXIT FUNCTION
    SkipSpaces p
    IF p>LEN(Src) OR MID$(Src,p,1)<>"=" THEN CompileError "String taniminda '=' bekleniyor.":TryParseStringDecl%=1:EXIT FUNCTION
    p=p+1
    SkipSpaces p
    startCell=ParseUnsignedNumber&(p,ok)
    IF ok=0 THEN CompileError "String baslangic data hucre no okunamadi.":TryParseStringDecl%=1:EXIT FUNCTION
    SkipSpaces p
    IF p>LEN(Src) OR MID$(Src,p,1)<>"," THEN CompileError "String taniminda ',' bekleniyor.":TryParseStringDecl%=1:EXIT FUNCTION
    p=p+1
    SkipSpaces p
    txt=ParseBracedString$(p,ok)
    IF ok=0 THEN CompileError "String metni { ... } arasinda okunamadi.":TryParseStringDecl%=1:EXIT FUNCTION
    AddStringDecl sid,startCell,txt
    pos=p
    TryParseStringDecl%=1
END FUNCTION
FUNCTION TryParsePrintString%(pos AS LONG)
    DIM p AS LONG
    DIM ok AS LONG
    DIM sid AS LONG
    p=pos
    IF MID$(Src,p,1)<>"p" AND MID$(Src,p,1)<>"P" THEN TryParsePrintString%=0:EXIT FUNCTION
    p=p+1
    IF p>LEN(Src) THEN TryParsePrintString%=0:EXIT FUNCTION
    IF IsDigitChar%(MID$(Src,p,1))=0 THEN TryParsePrintString%=0:EXIT FUNCTION
    sid=ParseUnsignedNumber&(p,ok)
    IF ok=0 THEN CompileError "p komutunda string numarasi okunamadi.":TryParsePrintString%=1:EXIT FUNCTION
    AddToken "P:"+LTRIM$(STR$(sid))
    pos=p
    TryParsePrintString%=1
END FUNCTION
FUNCTION ParseUnsignedNumber&(pos AS LONG,ok AS LONG)
    DIM s AS STRING
    s=""
    ok=0
    DO WHILE pos<=LEN(Src)
        IF IsDigitChar%(MID$(Src,pos,1))=0 THEN EXIT DO
        s=s+MID$(Src,pos,1)
        pos=pos+1
    LOOP
    IF LEN(s)=0 THEN ParseUnsignedNumber&=0:EXIT FUNCTION
    ok=1
    ParseUnsignedNumber&=VAL(s)
END FUNCTION
FUNCTION ParseBracedString$(pos AS LONG,ok AS LONG)
    DIM r AS STRING
    DIM c AS STRING
    DIM n AS STRING
    r=""
    ok=0
    IF pos>LEN(Src) THEN EXIT FUNCTION
    IF MID$(Src,pos,1)<>"{" THEN EXIT FUNCTION
    pos=pos+1
    DO WHILE pos<=LEN(Src)
        c=MID$(Src,pos,1)
        IF c="\" THEN
            IF pos+1<=LEN(Src) THEN
                n=MID$(Src,pos+1,1)
                SELECT CASE n
                    CASE "n":r=r+CHR$(10)
                    CASE "r":r=r+CHR$(13)
                    CASE "t":r=r+CHR$(9)
                    CASE "{":r=r+"{"
                    CASE "}":r=r+"}"
                    CASE "\":r=r+"\"
                    CASE ELSE:r=r+n
                END SELECT
                pos=pos+2
            ELSE
                r=r+c
                pos=pos+1
            END IF
        ELSEIF c="}" THEN
            pos=pos+1
            ok=1
            ParseBracedString$=r
            EXIT FUNCTION
        ELSE
            r=r+c
            pos=pos+1
        END IF
    LOOP
    ParseBracedString$=r
END FUNCTION
SUB AddStringDecl(sid AS LONG,startCell AS LONG,txt AS STRING)
    DIM i AS LONG
    IF HadError<>0 THEN EXIT SUB
    IF StrCount>=MAX_STRINGS THEN CompileError "String tablosu doldu.":EXIT SUB
    FOR i=1 TO StrCount
        IF StrId(i)=sid THEN CompileError "Ayni string numarasi tekrar kullanildi: s"+LTRIM$(STR$(sid)):EXIT SUB
    NEXT i
    IF startCell+LEN(txt)+1>=DataCells THEN CompileError "String data alanini asiyor: s"+LTRIM$(STR$(sid)):EXIT SUB
    StrCount=StrCount+1
    StrId(StrCount)=sid
    StrStartCell(StrCount)=startCell
    StrText(StrCount)=txt
END SUB
FUNCTION FindStringIndexById%(sid AS LONG)
    DIM i AS LONG
    FOR i=1 TO StrCount
        IF StrId(i)=sid THEN FindStringIndexById%=i:EXIT FUNCTION
    NEXT i
    FindStringIndexById%=0
END FUNCTION
FUNCTION IsDigitChar%(c AS STRING)
    IF LEN(c)=0 THEN IsDigitChar%=0 ELSEIF c>="0" AND c<="9" THEN IsDigitChar%=1 ELSE IsDigitChar%=0
END FUNCTION
FUNCTION IsTokenPrintString%(t AS STRING)
    IF LEFT$(t,2)="P:" THEN IsTokenPrintString%=1 ELSE IsTokenPrintString%=0
END FUNCTION
FUNCTION PrintStringIdFromToken%(t AS STRING)
    PrintStringIdFromToken%=VAL(MID$(t,3))
END FUNCTION
FUNCTION RepeatChar$(ch AS STRING,n AS LONG)
    DIM i AS LONG
    DIM r AS STRING
    r=""
    FOR i=1 TO n
        r=r+ch
    NEXT i
    RepeatChar$=r
END FUNCTION
FUNCTION NormalizePattern$(s AS STRING)
    DIM i AS LONG
    DIM c AS STRING
    DIM r AS STRING
    r=""
    FOR i=1 TO LEN(s)
        c=MID$(s,i,1)
        IF c<>" " AND c<>CHR$(9) THEN r=r+c
    NEXT i
    NormalizePattern$=r
END FUNCTION
FUNCTION PatternIsBalanced%(s AS STRING)
    DIM i AS LONG
    DIM bal AS LONG
    DIM c AS STRING
    bal=0
    FOR i=1 TO LEN(s)
        c=MID$(s,i,1)
        IF c="[" THEN bal=bal+1 ELSEIF c="]" THEN bal=bal-1:IF bal<0 THEN PatternIsBalanced%=0:EXIT FUNCTION
    NEXT i
    IF bal=0 THEN PatternIsBalanced%=1 ELSE PatternIsBalanced%=0
END FUNCTION
FUNCTION SpecificityScore%(p AS STRING)
    DIM i AS LONG
    DIM c AS STRING
    DIM score AS LONG
    DIM seen AS STRING
    DIM uniqueChars AS LONG
    DIM allSame AS LONG
    score=0
    seen=""
    uniqueChars=0
    allSame=1
    FOR i=1 TO LEN(p)
        c=MID$(p,i,1)
        IF INSTR(seen,c)=0 THEN seen=seen+c:uniqueChars=uniqueChars+1
        IF i>1 THEN IF c<>MID$(p,1,1) THEN allSame=0
        SELECT CASE c
            CASE "[","]":score=score+100
            CASE "@":score=score+90
            CASE "$","%":score=score+80
            CASE "?","!",";","&","|","^","~","{","}":score=score+70
            CASE ".",",":score=score+50
            CASE "0":score=score+40
            CASE ">","<":score=score+20
            CASE "+","-":score=score+15
            CASE ELSE:score=score+1
        END SELECT
    NEXT i
    score=score+uniqueChars*25
    IF allSame<>0 THEN score=score-40
    SpecificityScore%=score
END FUNCTION
FUNCTION MatchPattern%(startIdx AS LONG)
    DIM p AS LONG
    DIM j AS LONG
    DIM pLen AS LONG
    DIM ok AS LONG
    IF startIdx<1 OR startIdx>TokenCount THEN MatchPattern%=0:EXIT FUNCTION
    IF IsTokenPrintString%(Tokens(startIdx))<>0 THEN MatchPattern%=0:EXIT FUNCTION
    FOR p=1 TO PatCount
        pLen=LEN(Pat(p))
        IF startIdx+pLen-1<=TokenCount THEN
            ok=1
            FOR j=0 TO pLen-1
                IF IsTokenPrintString%(Tokens(startIdx+j))<>0 THEN ok=0:EXIT FOR
                IF Tokens(startIdx+j)<>MID$(Pat(p),j+1,1) THEN ok=0:EXIT FOR
            NEXT j
            IF ok<>0 THEN MatchPattern%=p:EXIT FUNCTION
        END IF
    NEXT p
    MatchPattern%=0
END FUNCTION
FUNCTION SizePrefix$()
    SELECT CASE CellBits
        CASE 8:SizePrefix$="byte"
        CASE 16:SizePrefix$="word"
        CASE 32:SizePrefix$="dword"
        CASE ELSE:SizePrefix$="byte"
    END SELECT
END FUNCTION
FUNCTION StoreReg$()
    SELECT CASE CellBits
        CASE 8:StoreReg$="al"
        CASE 16:StoreReg$="ax"
        CASE 32:StoreReg$="eax"
        CASE ELSE:StoreReg$="al"
    END SELECT
END FUNCTION
FUNCTION MaxValueText$()
    SELECT CASE CellBits
        CASE 8:MaxValueText$="255"
        CASE 16:MaxValueText$="65535"
        CASE 32:MaxValueText$="4294967295"
        CASE ELSE:MaxValueText$="255"
    END SELECT
END FUNCTION
FUNCTION ReduceValue&(v AS LONG)
    SELECT CASE CellBits
        CASE 8:ReduceValue&=v MOD 256
        CASE 16:ReduceValue&=v MOD 65536
        CASE 32:ReduceValue&=v
        CASE ELSE:ReduceValue&=v MOD 256
    END SELECT
END FUNCTION
FUNCTION IndexExpr$(baseReg AS STRING,indexReg AS STRING,offCells AS LONG)
    DIM s AS STRING
    DIM disp AS LONG
    SELECT CASE CellBytes
        CASE 1:s=baseReg+" + "+indexReg
        CASE 2:s=baseReg+" + "+indexReg+"*2"
        CASE 4:s=baseReg+" + "+indexReg+"*4"
        CASE ELSE:s=baseReg+" + "+indexReg
    END SELECT
    disp=offCells*CellBytes
    IF disp>0 THEN s=s+" + "+LTRIM$(STR$(disp)) ELSEIF disp<0 THEN s=s+" - "+LTRIM$(STR$(ABS(disp)))
    IndexExpr$="["+s+"]"
END FUNCTION
FUNCTION CellOp$(offCells AS LONG)
    CellOp$=SizePrefix$+" "+IndexExpr$("r12","rbx",offCells)
END FUNCTION
FUNCTION StackOp$()
    StackOp$=SizePrefix$+" "+IndexExpr$("r13","r14",0)
END FUNCTION
FUNCTION DataByteOffset&(cellNo AS LONG)
    DataByteOffset&=cellNo*CellBytes
END FUNCTION
FUNCTION DataCellOpConst$(cellNo AS LONG)
    DataCellOpConst$=SizePrefix$+" [ux_mem + DATA_OFFSET + "+LTRIM$(STR$(DataByteOffset&(cellNo)))+"]"
END FUNCTION
FUNCTION Check0Template$()
    IF BoundsCheck=0 THEN
        Check0Template$=""
    ELSE
        Check0Template$="cmp rbx, TAPE_CELLS|jae __ux_ptr_oob"
    END IF
END FUNCTION
FUNCTION CheckOffsetTemplate$(offCells AS LONG)
    IF BoundsCheck=0 THEN
        CheckOffsetTemplate$=""
        EXIT FUNCTION
    END IF
    IF offCells>0 THEN
        CheckOffsetTemplate$="cmp rbx, TAPE_CELLS - "+LTRIM$(STR$(offCells))+"|jae __ux_ptr_oob"
    ELSEIF offCells<0 THEN
        CheckOffsetTemplate$="cmp rbx, "+LTRIM$(STR$(ABS(offCells)))+"|jb __ux_ptr_oob"
    ELSE
        CheckOffsetTemplate$=Check0Template$
    END IF
END FUNCTION
FUNCTION ReplaceAll$(src AS STRING,find AS STRING,repl AS STRING)
    DIM r AS STRING
    DIM p AS LONG
    r=src
    DO
        p=INSTR(r,find)
        IF p=0 THEN EXIT DO
        r=LEFT$(r,p-1)+repl+MID$(r,p+LEN(find))
    LOOP
    ReplaceAll$=r
END FUNCTION
FUNCTION ExpandedTemplate$(tpl AS STRING)
    DIM r AS STRING
    r=tpl
    r=ReplaceAll$(r,"{CELL0}",CellOp$(0))
    r=ReplaceAll$(r,"{CELL+1}",CellOp$(1))
    r=ReplaceAll$(r,"{CELL-1}",CellOp$(-1))
    r=ReplaceAll$(r,"{REG}",StoreReg$)
    r=ReplaceAll$(r,"{CHECK0}",Check0Template$)
    r=ReplaceAll$(r,"{CHECK+1}",CheckOffsetTemplate$(1))
    r=ReplaceAll$(r,"{CHECK-1}",CheckOffsetTemplate$(-1))
    IF BoundsCheck=0 THEN
        r=ReplaceAll$(r,"{PTRCHECK}","")
    ELSE
        r=ReplaceAll$(r,"{PTRCHECK}","cmp rbx, TAPE_CELLS|jae __ux_ptr_oob")
    END IF
    ExpandedTemplate$=r
END FUNCTION
SUB GenerateASM
    DIM i AS LONG
    DIM pIdx AS LONG
    OutFF=FREEFILE
    OPEN OutASMName FOR OUTPUT AS #OutFF
    EmitHeader
    EmitStringInitializers
    i=1
    DO WHILE i<=TokenCount AND HadError=0
        IF IsTokenPrintString%(Tokens(i))<>0 THEN
            EmitPrintStringById PrintStringIdFromToken%(Tokens(i))
            i=i+1
        ELSE
            pIdx=MatchPattern%(i)
            IF pIdx>0 THEN
                EmitLine "    ; pattern "+Pat(pIdx)
                EmitAsmTemplate PatAsm(pIdx)
                i=i+LEN(Pat(pIdx))
            ELSE
                EmitSingleToken Tokens(i)
                i=i+1
            END IF
        END IF
    LOOP
    IF LoopSP<>0 THEN CompileError "Eksik ']' var. Acilan loop kapatilmamis.":EmitLine "    ; ERROR: unclosed loop"
    EmitFooter
    CLOSE #OutFF
END SUB
SUB EmitAsmTemplate(tpl AS STRING)
    DIM expanded AS STRING
    DIM p AS LONG
    DIM part AS STRING
    expanded=ExpandedTemplate$(tpl)
    DO WHILE LEN(expanded)>0
        p=INSTR(expanded,"|")
        IF p=0 THEN
            part=LTRIM$(RTRIM$(expanded))
            expanded=""
        ELSE
            part=LTRIM$(RTRIM$(LEFT$(expanded,p-1)))
            expanded=MID$(expanded,p+1)
        END IF
        IF LEN(part)>0 THEN EmitLine "    "+part
    LOOP
END SUB
SUB EmitHeader
    EmitLine "; UXM-64K V3 generated Windows x64 NASM output"
    EmitLine "default rel"
    EmitLine "global uxm_entry"
    EmitLine "extern ux_putc"
    EmitLine "extern ux_getc"
    EmitLine "extern ux_print_cells"
    EmitLine "extern ux_meta_call"
    EmitLine "extern ux_ptr_oob"
    EmitLine "extern ux_stack_overflow"
    EmitLine "extern ux_stack_underflow"
    EmitLine "extern ux_overflow_error"
    EmitLine "extern ux_exit"
    EmitLine "%define UXM_TOTAL_BYTES 65536"
    EmitLine "%define TAPE_BYTES      "+LTRIM$(STR$(TapeBytes))
    EmitLine "%define STACK_BYTES     "+LTRIM$(STR$(StackBytes))
    EmitLine "%define DATA_BYTES      "+LTRIM$(STR$(DataBytes))
    EmitLine "%define TAPE_CELLS      "+LTRIM$(STR$(TapeCells))
    EmitLine "%define STACK_CELLS     "+LTRIM$(STR$(StackCells))
    EmitLine "%define DATA_CELLS      "+LTRIM$(STR$(DataCells))
    EmitLine "%define STACK_OFFSET    "+LTRIM$(STR$(StackOffsetBytes))
    EmitLine "%define DATA_OFFSET     "+LTRIM$(STR$(DataOffsetBytes))
    EmitLine "%define CELL_BITS       "+LTRIM$(STR$(CellBits))
    EmitLine "%define CELL_BYTES      "+LTRIM$(STR$(CellBytes))
    EmitLine "section .bss"
    EmitLine "align 16"
    EmitLine "ux_mem: resb UXM_TOTAL_BYTES"
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
    EmitLine "    lea r12, [ux_mem]"
    EmitLine "    xor rbx, rbx"
    EmitLine "    lea r13, [ux_mem + STACK_OFFSET]"
    EmitLine "    xor r14, r14"
END SUB
SUB EmitFooter
    EmitLine "    xor ecx, ecx"
    EmitLine "    call ux_exit"
    EmitLine "__ux_return:"
    EmitLine "    add rsp, 40"
    EmitLine "    pop r15"
    EmitLine "    pop r14"
    EmitLine "    pop r13"
    EmitLine "    pop r12"
    EmitLine "    pop rbx"
    EmitLine "    pop rbp"
    EmitLine "    ret"
    EmitLine "__ux_ptr_oob:"
    EmitLine "    call ux_ptr_oob"
    EmitLine "    jmp __ux_return"
    EmitLine "__ux_stack_overflow:"
    EmitLine "    call ux_stack_overflow"
    EmitLine "    jmp __ux_return"
    EmitLine "__ux_stack_underflow:"
    EmitLine "    call ux_stack_underflow"
    EmitLine "    jmp __ux_return"
    EmitLine "__ux_overflow:"
    EmitLine "    call ux_overflow_error"
    EmitLine "    jmp __ux_return"
END SUB
SUB EmitLine(s AS STRING)
    PRINT #OutFF,s
END SUB
SUB EmitStringInitializers
    DIM i AS LONG
    DIM j AS LONG
    DIM chVal AS LONG
    DIM startCell AS LONG
    DIM txt AS STRING
    IF StrCount=0 THEN EXIT SUB
    EmitLine "    ; string initializers"
    FOR i=1 TO StrCount
        startCell=StrStartCell(i)
        txt=StrText(i)
        FOR j=1 TO LEN(txt)
            chVal=ASC(MID$(txt,j,1)) AND &HFF
            EmitLine "    mov "+DataCellOpConst$(startCell+j-1)+", "+LTRIM$(STR$(chVal))
        NEXT j
        EmitLine "    mov "+DataCellOpConst$(startCell+LEN(txt))+", 0"
    NEXT i
END SUB
SUB EmitSingleToken(t AS STRING)
    SELECT CASE t
        CASE ">":EmitMovePtr 1
        CASE "<":EmitMovePtr -1
        CASE "+":EmitAddCell 0,1
        CASE "-":EmitSubCell 0,1
        CASE "0":EmitClearCell 0
        CASE ".":EmitPutChar
        CASE ",":EmitGetChar
        CASE "[":EmitLoopStart
        CASE "]":EmitLoopEnd
        CASE "$":EmitPushCell
        CASE "%":EmitPopCell
        CASE "?":EmitCompare CMP_EQ
        CASE "!":EmitCompare CMP_GT
        CASE ";":EmitCompare CMP_LT
        CASE "&":EmitBinaryBitwise BIN_AND
        CASE "|":EmitBinaryBitwise BIN_OR
        CASE "^":EmitBinaryBitwise BIN_XOR
        CASE "~":EmitNotCell
        CASE "{":EmitShiftLeft
        CASE "}":EmitShiftRight
        CASE "@":EmitMetaFromCell
        CASE ":":EmitLine "    ; ':' reserved"
        CASE ELSE:EmitLine "    ; ignored token: "+t
    END SELECT
END SUB
SUB EmitPointerCheck
    IF BoundsCheck=0 THEN EXIT SUB
    EmitLine "    cmp rbx, TAPE_CELLS"
    EmitLine "    jae __ux_ptr_oob"
END SUB
SUB EmitNeighborCheck(offCells AS LONG)
    IF BoundsCheck=0 THEN EXIT SUB
    IF offCells>0 THEN
        EmitLine "    cmp rbx, TAPE_CELLS - "+LTRIM$(STR$(offCells))
        EmitLine "    jae __ux_ptr_oob"
    ELSEIF offCells<0 THEN
        EmitLine "    cmp rbx, "+LTRIM$(STR$(ABS(offCells)))
        EmitLine "    jb __ux_ptr_oob"
    END IF
END SUB
SUB EmitMovePtr(delta AS LONG)
    IF delta=0 THEN EXIT SUB
    IF delta=1 THEN EmitLine "    inc rbx" ELSEIF delta=-1 THEN EmitLine "    dec rbx" ELSEIF delta>0 THEN EmitLine "    add rbx, "+LTRIM$(STR$(delta)) ELSE EmitLine "    sub rbx, "+LTRIM$(STR$(ABS(delta)))
    EmitPointerCheck
END SUB
SUB EmitSetCell(offCells AS LONG,value AS LONG)
    DIM v AS LONG
    EmitNeighborCheck offCells
    IF OverflowMode=OV_CHECK THEN
        EmitLine "    mov rax, "+LTRIM$(STR$(value))
        EmitLine "    cmp rax, "+MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov "+CellOp$(offCells)+", "+StoreReg$
    ELSE
        v=ReduceValue&(value)
        EmitLine "    mov "+CellOp$(offCells)+", "+LTRIM$(STR$(v))
    END IF
END SUB
SUB EmitClearCell(offCells AS LONG)
    EmitNeighborCheck offCells
    EmitLine "    mov "+CellOp$(offCells)+", 0"
END SUB
SUB EmitAddCell(offCells AS LONG,amount AS LONG)
    DIM v AS LONG
    IF amount=0 THEN EXIT SUB
    EmitNeighborCheck offCells
    IF OverflowMode=OV_WRAP THEN
        v=ReduceValue&(amount)
        IF v=0 THEN EXIT SUB
        IF v=1 THEN EmitLine "    inc "+CellOp$(offCells) ELSE EmitLine "    add "+CellOp$(offCells)+", "+LTRIM$(STR$(v))
    ELSE
        SELECT CASE CellBits
            CASE 8,16:EmitLine "    movzx eax, "+CellOp$(offCells)
            CASE 32:EmitLine "    mov eax, "+CellOp$(offCells)
        END SELECT
        EmitLine "    add rax, "+LTRIM$(STR$(amount))
        EmitLine "    cmp rax, "+MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov "+CellOp$(offCells)+", "+StoreReg$
    END IF
END SUB
SUB EmitSubCell(offCells AS LONG,amount AS LONG)
    DIM v AS LONG
    IF amount=0 THEN EXIT SUB
    EmitNeighborCheck offCells
    IF OverflowMode=OV_WRAP THEN
        v=ReduceValue&(amount)
        IF v=0 THEN EXIT SUB
        IF v=1 THEN EmitLine "    dec "+CellOp$(offCells) ELSE EmitLine "    sub "+CellOp$(offCells)+", "+LTRIM$(STR$(v))
    ELSE
        SELECT CASE CellBits
            CASE 8,16:EmitLine "    movzx eax, "+CellOp$(offCells)
            CASE 32:EmitLine "    mov eax, "+CellOp$(offCells)
        END SELECT
        EmitLine "    cmp rax, "+LTRIM$(STR$(amount))
        EmitLine "    jb __ux_overflow"
        EmitLine "    sub rax, "+LTRIM$(STR$(amount))
        EmitLine "    mov "+CellOp$(offCells)+", "+StoreReg$
    END IF
END SUB
SUB EmitPutChar
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx ecx, "+CellOp$(0)
        CASE 32:EmitLine "    mov ecx, "+CellOp$(0)
    END SELECT
    EmitLine "    call ux_putc"
END SUB
SUB EmitGetChar
    EmitLine "    call ux_getc"
    EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
END SUB
SUB EmitMetaFromCell
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx ecx, "+CellOp$(0)
        CASE 32:EmitLine "    mov ecx, "+CellOp$(0)
    END SELECT
    EmitLine "    call ux_meta_call"
    EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
END SUB
SUB EmitMetaConst(metaId AS LONG)
    EmitLine "    mov ecx, "+LTRIM$(STR$(metaId))
    EmitLine "    call ux_meta_call"
    EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
END SUB
SUB EmitPushCell
    EmitLine "    cmp r14, STACK_CELLS"
    EmitLine "    jae __ux_stack_overflow"
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx eax, "+CellOp$(0)
        CASE 32:EmitLine "    mov eax, "+CellOp$(0)
    END SELECT
    EmitLine "    mov "+StackOp$+", "+StoreReg$
    EmitLine "    inc r14"
END SUB
SUB EmitPopCell
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx eax, "+StackOp$
        CASE 32:EmitLine "    mov eax, "+StackOp$
    END SELECT
    EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
END SUB
SUB EmitCompare(cmpMode AS LONG)
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx eax, "+StackOp$
        CASE 32:EmitLine "    mov eax, "+StackOp$
    END SELECT
    EmitLine "    mov r15, rax"
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx eax, "+CellOp$(0)
        CASE 32:EmitLine "    mov eax, "+CellOp$(0)
    END SELECT
    EmitLine "    cmp r15, rax"
    SELECT CASE cmpMode
        CASE CMP_EQ:EmitLine "    sete al"
        CASE CMP_GT:EmitLine "    seta al"
        CASE CMP_LT:EmitLine "    setb al"
    END SELECT
    EmitLine "    movzx eax, al"
    EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
END SUB
SUB EmitBinaryBitwise(opMode AS LONG)
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx eax, "+StackOp$
        CASE 32:EmitLine "    mov eax, "+StackOp$
    END SELECT
    EmitLine "    mov r15, rax"
    SELECT CASE CellBits
        CASE 8,16:EmitLine "    movzx eax, "+CellOp$(0)
        CASE 32:EmitLine "    mov eax, "+CellOp$(0)
    END SELECT
    SELECT CASE opMode
        CASE BIN_AND:EmitLine "    and rax, r15"
        CASE BIN_OR:EmitLine "    or rax, r15"
        CASE BIN_XOR:EmitLine "    xor rax, r15"
    END SELECT
    EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
END SUB
SUB EmitNotCell
    EmitLine "    not "+CellOp$(0)
END SUB
SUB EmitShiftLeft
    IF OverflowMode=OV_WRAP THEN
        EmitLine "    shl "+CellOp$(0)+", 1"
    ELSE
        SELECT CASE CellBits
            CASE 8,16:EmitLine "    movzx eax, "+CellOp$(0)
            CASE 32:EmitLine "    mov eax, "+CellOp$(0)
        END SELECT
        EmitLine "    shl rax, 1"
        EmitLine "    cmp rax, "+MaxValueText$
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov "+CellOp$(0)+", "+StoreReg$
    END IF
END SUB
SUB EmitShiftRight
    EmitLine "    shr "+CellOp$(0)+", 1"
END SUB
SUB EmitLoopStart
    IF LoopSP>=MAX_LOOP_STACK THEN CompileError "Loop stack doldu.":EXIT SUB
    LoopCount=LoopCount+1
    LoopSP=LoopSP+1
    LoopStack(LoopSP)=LoopCount
    EmitLine "L"+LTRIM$(STR$(LoopCount))+":"
    EmitLine "    cmp "+CellOp$(0)+", 0"
    EmitLine "    je E"+LTRIM$(STR$(LoopCount))
END SUB
SUB EmitLoopEnd
    DIM id AS LONG
    IF LoopSP<=0 THEN CompileError "Fazla ']' bulundu.":EXIT SUB
    id=LoopStack(LoopSP)
    LoopSP=LoopSP-1
    EmitLine "    jmp L"+LTRIM$(STR$(id))
    EmitLine "E"+LTRIM$(STR$(id))+":"
END SUB
SUB EmitPrintStringById(sid AS LONG)
    DIM idx AS LONG
    DIM offsetBytes AS LONG
    idx=FindStringIndexById%(sid)
    IF idx=0 THEN CompileError "Tanimlanmamis string basiliyor: p"+LTRIM$(STR$(sid)):EXIT SUB
    offsetBytes=DataOffsetBytes+DataByteOffset&(StrStartCell(idx))
    EmitLine "    lea rcx, [ux_mem + "+LTRIM$(STR$(offsetBytes))+"]"
    EmitLine "    mov edx, CELL_BITS"
    EmitLine "    call ux_print_cells"
END SUB
SUB CompileError(msg AS STRING)
    HadError=1
    PRINT "HATA: ";msg
END SUB
#ifndef UXM_V20_COMMANDS_BI
#define UXM_V20_COMMANDS_BI

Enum UXMCommandOp
    UXM_CMD_NOP = 0
    UXM_CMD_PTR_RIGHT = 1
    UXM_CMD_PTR_LEFT = 2
    UXM_CMD_CELL_INC = 3
    UXM_CMD_CELL_DEC = 4
    UXM_CMD_PUTC = 5
    UXM_CMD_GETC = 6
    UXM_CMD_LOOP_BEGIN = 7
    UXM_CMD_LOOP_END = 8
    UXM_CMD_META_NORMAL = 9
    UXM_CMD_META_HOST = 10
    UXM_CMD_META_USER = 11
    UXM_CMD_META_DYNAMIC = 12
    UXM_CMD_STRING_PRINT = 13
    UXM_CMD_BRANCH = 14
    UXM_CMD_MACRO_DEF = 15
    UXM_CMD_MACRO_CALL = 16
End Enum

Function UXMCommandFromText(ByVal text As String) As Long
    Select Case text
    Case ">": Return UXM_CMD_PTR_RIGHT
    Case "<": Return UXM_CMD_PTR_LEFT
    Case "+": Return UXM_CMD_CELL_INC
    Case "-": Return UXM_CMD_CELL_DEC
    Case ".": Return UXM_CMD_PUTC
    Case ",": Return UXM_CMD_GETC
    Case "[": Return UXM_CMD_LOOP_BEGIN
    Case "]": Return UXM_CMD_LOOP_END
    Case "@": Return UXM_CMD_META_NORMAL
    Case "@#": Return UXM_CMD_META_HOST
    Case "@@": Return UXM_CMD_META_USER
    Case "@*": Return UXM_CMD_META_DYNAMIC
    Case Else: Return UXM_CMD_NOP
    End Select
End Function

Function UXMCommandName(ByVal op As Long) As String
    Select Case op
    Case UXM_CMD_PTR_RIGHT: Return "PTR_RIGHT"
    Case UXM_CMD_PTR_LEFT: Return "PTR_LEFT"
    Case UXM_CMD_CELL_INC: Return "CELL_INC"
    Case UXM_CMD_CELL_DEC: Return "CELL_DEC"
    Case UXM_CMD_PUTC: Return "PUTC"
    Case UXM_CMD_GETC: Return "GETC"
    Case UXM_CMD_LOOP_BEGIN: Return "LOOP_BEGIN"
    Case UXM_CMD_LOOP_END: Return "LOOP_END"
    Case UXM_CMD_META_NORMAL: Return "META_NORMAL"
    Case UXM_CMD_META_HOST: Return "META_HOST"
    Case UXM_CMD_META_USER: Return "META_USER"
    Case UXM_CMD_META_DYNAMIC: Return "META_DYNAMIC"
    Case UXM_CMD_STRING_PRINT: Return "STRING_PRINT"
    Case UXM_CMD_BRANCH: Return "BRANCH"
    Case UXM_CMD_MACRO_DEF: Return "MACRO_DEF"
    Case UXM_CMD_MACRO_CALL: Return "MACRO_CALL"
    Case Else: Return "NOP"
    End Select
End Function

#endif

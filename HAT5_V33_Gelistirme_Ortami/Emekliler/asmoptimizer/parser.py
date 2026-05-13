
# 1. PARSER MODÜLÜ - x64 ASM Parser
parser_code = """x64 ASM Parser Module - Intel Syntax"""
import re
from dataclasses import dataclass
from typing import List, Optional, Tuple
from .nop_hook import nop_hook

@dataclass
class Operand:
    """Represents a single operand."""
    raw: str
    type: str  # 'register', 'immediate', 'memory', 'label'
    reg: Optional[str] = None
    size: Optional[int] = None  # 8, 16, 32, 64, 128, 256
    
    # Memory specific
    base: Optional[str] = None
    index: Optional[str] = None
    scale: int = 1
    displacement: int = 0

@dataclass  
class Instruction:
    """Represents a parsed x64 instruction."""
    raw_line: str
    line_num: int
    label: Optional[str] = None
    mnemonic: Optional[str] = None
    operands: List[Operand] = None
    prefix: Optional[str] = None  # rep, lock, etc.
    comment: Optional[str] = None
    is_directive: bool = False
    is_data: bool = False
    
    def __post_init__(self):
        if self.operands is None:
            self.operands = []

# x64 Register definitions
REGISTERS_64 = {'rax','rbx','rcx','rdx','rsi','rdi','rbp','rsp',
                'r8','r9','r10','r11','r12','r13','r14','r15',
                'rip'}
REGISTERS_32 = {'eax','ebx','ecx','edx','esi','edi','ebp','esp',
                'r8d','r9d','r10d','r11d','r12d','r13d','r14d','r15d'}
REGISTERS_16 = {'ax','bx','cx','dx','si','di','bp','sp',
                'r8w','r9w','r10w','r11w','r12w','r13w','r14w','r15w'}
REGISTERS_8H = {'ah','bh','ch','dh'}
REGISTERS_8L = {'al','bl','cl','dl','sil','dil','bpl','spl',
                'r8b','r9b','r10b','r11b','r12b','r13b','r14b','r15b'}
ALL_REGISTERS = REGISTERS_64 | REGISTERS_32 | REGISTERS_16 | REGISTERS_8H | REGISTERS_8L

# Register family mapping (for liveness analysis)
REGISTER_FAMILY = {
    'rax': {'rax','eax','ax','ah','al'},
    'rbx': {'rbx','ebx','bx','bh','bl'},
    'rcx': {'rcx','ecx','cx','ch','cl'},
    'rdx': {'rdx','edx','dx','dh','dl'},
    'rsi': {'rsi','esi','si','sil'},
    'rdi': {'rdi','edi','di','dil'},
    'rbp': {'rbp','ebp','bp','bpl'},
    'rsp': {'rsp','esp','sp','spl'},
    'r8':  {'r8','r8d','r8w','r8b'},
    'r9':  {'r9','r9d','r9w','r9b'},
    'r10': {'r10','r10d','r10w','r10b'},
    'r11': {'r11','r11d','r11w','r11b'},
    'r12': {'r12','r12d','r12w','r12b'},
    'r13': {'r13','r13d','r13w','r13b'},
    'r14': {'r14','r14d','r14w','r14b'},
    'r15': {'r15','r15d','r15w','r15b'},
}

# Build reverse lookup
REG_TO_FAMILY = {}
for family, regs in REGISTER_FAMILY.items():
    for reg in regs:
        REG_TO_FAMILY[reg] = family

# Jump/branch instructions
JUMP_INSTRUCTIONS = {
    'jmp', 'je', 'jne', 'jz', 'jnz', 'ja', 'jae', 'jb', 'jbe',
    'jg', 'jge', 'jl', 'jle', 'jo', 'jno', 'js', 'jns', 'jp',
    'jnp', 'jc', 'jnc', 'call', 'ret', 'iret', 'syscall', 'sysret'
}

CONDITIONAL_JUMPS = {
    'je', 'jne', 'jz', 'jnz', 'ja', 'jae', 'jb', 'jbe',
    'jg', 'jge', 'jl', 'jle', 'jo', 'jno', 'js', 'jns', 'jp', 'jnp'
}

# Instructions that affect flags
FLAG_AFFECTING = {
    'add', 'sub', 'cmp', 'test', 'and', 'or', 'xor', 'not',
    'inc', 'dec', 'neg', 'mul', 'imul', 'div', 'idiv',
    'shl', 'shr', 'sal', 'sar', 'rol', 'ror', 'rcl', 'rcr',
    'adc', 'sbb', 'shld', 'shrd'
}

# Instructions that read flags
FLAG_READING = {
    'adc', 'sbb', 'cmova', 'cmovae', 'cmovb', 'cmovbe',
    'cmovg', 'cmovge', 'cmovl', 'cmovle', 'cmovo', 'cmovno',
    'cmovs', 'cmovns', 'cmovp', 'cmovnp', 'cmovc', 'cmovnc',
    'seta', 'setae', 'setb', 'setbe', 'setg', 'setge',
    'setl', 'setle', 'seto', 'setno', 'sets', 'setns',
    'setp', 'setnp', 'setc', 'setnc'
}

class ASMParser:
    """x64 ASM Parser for Intel syntax."""
    
    def __init__(self):
        self.instructions: List[Instruction] = []
        nop_hook()
    
    def _detect_operand_type(self, op_str: str) -> Tuple[str, dict]:
        """Detect operand type and extract properties."""
        op_str = op_str.strip()
        info = {'raw': op_str}
        
        # Immediate value
        if op_str.startswith(('0x', '0X')) or op_str.lstrip('-').isdigit():
            info['type'] = 'immediate'
            try:
                info['value'] = int(op_str, 0)
            except ValueError:
                info['value'] = 0
            return 'immediate', info
        
        # Label reference
        if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', op_str) and op_str not in ALL_REGISTERS:
            info['type'] = 'label'
            return 'label', info
        
        # Memory reference [base+index*scale+disp]
        if op_str.startswith('[') and op_str.endswith(']'):
            info['type'] = 'memory'
            mem_content = op_str[1:-1].strip()
            
            # Parse memory expression
            # Simple cases: [rax], [rax+8], [rax+rbx*4+16]
            parts = re.split(r'([\+\-])', mem_content)
            parts = [p for p in parts if p]
            
            info['base'] = None
            info['index'] = None
            info['scale'] = 1
            info['displacement'] = 0
            
            i = 0
            while i < len(parts):
                part = parts[i].strip()
                sign = 1
                if part in '+-':
                    sign = -1 if part == '-' else 1
                    i += 1
                    if i >= len(parts):
                        break
                    part = parts[i].strip()
                
                if part in ALL_REGISTERS:
                    if info['base'] is None:
                        info['base'] = part
                    elif info['index'] is None and '*' not in part:
                        info['index'] = part
                elif '*' in part:
                    # index*scale
                    idx_scale = part.split('*')
                    if len(idx_scale) == 2:
                        idx, scale = idx_scale[0].strip(), idx_scale[1].strip()
                        if idx in ALL_REGISTERS:
                            info['index'] = idx
                            try:
                                info['scale'] = int(scale)
                            except:
                                info['scale'] = 1
                else:
                    # displacement
                    try:
                        disp = int(part, 0) * sign
                        info['displacement'] += disp
                    except ValueError:
                        pass
                i += 1
            
            return 'memory', info
        
        # Register
        op_lower = op_str.lower()
        if op_lower in ALL_REGISTERS:
            info['type'] = 'register'
            info['reg'] = op_lower
            if op_lower in REGISTERS_64:
                info['size'] = 64
            elif op_lower in REGISTERS_32:
                info['size'] = 32
            elif op_lower in REGISTERS_16:
                info['size'] = 16
            elif op_lower in REGISTERS_8H:
                info['size'] = 8
            elif op_lower in REGISTERS_8L:
                info['size'] = 8
            return 'register', info
        
        # Unknown
        info['type'] = 'unknown'
        return 'unknown', info
    
    def parse_line(self, line: str, line_num: int) -> Instruction:
        """Parse a single line of ASM code."""
        raw = line.strip()
        
        # Empty line
        if not raw:
            return Instruction(raw_line=line, line_num=line_num)
        
        # Comment-only line
        if raw.startswith(';'):
            return Instruction(raw_line=line, line_num=line_num, comment=raw[1:].strip())
        
        # Extract inline comment
        comment = None
        if ';' in raw:
            parts = raw.split(';', 1)
            raw = parts[0].strip()
            comment = parts[1].strip()
        
        # Label (line ending with :)
        if raw.endswith(':'):
            return Instruction(
                raw_line=line, 
                line_num=line_num,
                label=raw[:-1].strip(),
                comment=comment
            )
        
        # Directive (starts with .)
        if raw.startswith('.'):
            return Instruction(
                raw_line=line,
                line_num=line_num, 
                is_directive=True,
                comment=comment
            )
        
        # Parse instruction
        # Format: [prefix] mnemonic [operand1[, operand2[, operand3]]]
        tokens = raw.split(None, 1)
        if not tokens:
            return Instruction(raw_line=line, line_num=line_num, comment=comment)
        
        mnemonic = tokens[0].lower()
        
        # Check for prefix
        prefix = None
        if mnemonic in ('rep', 'repe', 'repz', 'repne', 'repnz', 'lock'):
            prefix = mnemonic
            if len(tokens) > 1:
                rest = tokens[1].split(None, 1)
                mnemonic = rest[0].lower()
                operands_str = rest[1] if len(rest) > 1 else ''
            else:
                operands_str = ''
        else:
            operands_str = tokens[1] if len(tokens) > 1 else ''
        
        # Parse operands
        operands = []
        if operands_str:
            # Split by comma, but handle nested brackets
            op_parts = []
            current = ''
            depth = 0
            for char in operands_str:
                if char == '[':
                    depth += 1
                elif char == ']':
                    depth -= 1
                elif char == ',' and depth == 0:
                    op_parts.append(current.strip())
                    current = ''
                    continue
                current += char
            if current.strip():
                op_parts.append(current.strip())
            
            for op_str in op_parts:
                op_type, op_info = self._detect_operand_type(op_str)
                operands.append(Operand(**op_info))
        
        return Instruction(
            raw_line=line,
            line_num=line_num,
            mnemonic=mnemonic,
            operands=operands,
            prefix=prefix,
            comment=comment
        )
    
    def parse(self, lines: List[str]) -> List[Instruction]:
        """Parse multiple lines of ASM code."""
        self.instructions = []
        for i, line in enumerate(lines):
            instr = self.parse_line(line, i)
            self.instructions.append(instr)
        return self.instructions
    
    def get_labels(self) -> dict:
        """Get all labels and their line numbers."""
        return {instr.label: instr.line_num 
                for instr in self.instructions if instr.label}
    
    def is_jump(self, instr: Instruction) -> bool:
        """Check if instruction is a jump/branch."""
        return instr.mnemonic in JUMP_INSTRUCTIONS if instr.mnemonic else False
    
    def is_conditional_jump(self, instr: Instruction) -> bool:
        """Check if instruction is a conditional jump."""
        return instr.mnemonic in CONDITIONAL_JUMPS if instr.mnemonic else False
    
    def affects_flags(self, instr: Instruction) -> bool:
        """Check if instruction affects flags."""
        return instr.mnemonic in FLAG_AFFECTING if instr.mnemonic else False
    
    def reads_flags(self, instr: Instruction) -> bool:
        """Check if instruction reads flags."""
        return instr.mnemonic in FLAG_READING if instr.mnemonic else False


with open(os.path.join(base_dir, "parser", "asm_parser.py"), "w") as f:
    f.write(parser_code)

print("✅ Parser modülü oluşturuldu")

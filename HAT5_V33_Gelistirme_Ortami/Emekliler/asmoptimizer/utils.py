
# 7. UTILS MODÜLÜ - Yardımcı Fonksiyonlar
utils_code = r'''"""Utility Functions for UXM ASM Optimizer"""
import re
from typing import List, Tuple
from .nop_hook import nop_hook

def strip_comments(line: str) -> str:
    """Remove comments from a line."""
    return line.split(';')[0].strip()

def is_label(line: str) -> bool:
    """Check if line is a label."""
    stripped = strip_comments(line).strip()
    return stripped.endswith(':')

def is_directive(line: str) -> bool:
    """Check if line is an assembler directive."""
    stripped = strip_comments(line).strip()
    return stripped.startswith('.')

def is_empty(line: str) -> bool:
    """Check if line is empty or comment-only."""
    stripped = strip_comments(line).strip()
    return not stripped

def extract_label(line: str) -> str:
    """Extract label name from label line."""
    stripped = strip_comments(line).strip()
    if stripped.endswith(':'):
        return stripped[:-1].strip()
    return ""

def format_hex(val: int, bits: int = 64) -> str:
    """Format integer as hex string."""
    if bits == 64:
        return f"0x{val:016x}"
    elif bits == 32:
        return f"0x{val:08x}"
    elif bits == 16:
        return f"0x{val:04x}"
    else:
        return f"0x{val:02x}"

def align_up(val: int, alignment: int) -> int:
    """Align value up to alignment boundary."""
    return (val + alignment - 1) & ~(alignment - 1)

def estimate_instruction_size(mnemonic: str, operands: List) -> int:
    """Rough estimate of x64 instruction size in bytes."""
    # Very rough estimates for common cases
    size_map = {
        'nop': 1,
        'ret': 1,
        'push': 1,  # register
        'pop': 1,   # register
        'inc': 3,   # register
        'dec': 3,   # register
        'jmp': 5,   # near
        'je': 6,    # near
        'jne': 6,   # near
        'call': 5,  # near
        'mov': 5,   # reg, imm32
        'add': 3,   # reg, imm8
        'sub': 3,   # reg, imm8
        'xor': 3,   # reg, reg
        'and': 3,   # reg, reg
        'or': 3,    # reg, reg
        'shl': 3,   # reg, imm8
        'shr': 3,   # reg, imm8
        'cmp': 3,   # reg, imm8
        'test': 3,  # reg, reg
        'lea': 7,   # reg, [mem]
        'movzx': 4, # reg, reg8
    }
    return size_map.get(mnemonic.lower(), 5)

def diff_lines(old_lines: List[str], new_lines: List[str]) -> List[str]:
    """Generate unified diff between two line lists."""
    # Simple line-by-line diff
    result = []
    max_len = max(len(old_lines), len(new_lines))
    
    for i in range(max_len):
        old = old_lines[i] if i < len(old_lines) else None
        new = new_lines[i] if i < len(new_lines) else None
        
        if old is None:
            result.append(f"+ {new}")
        elif new is None:
            result.append(f"- {old}")
        elif old != new:
            result.append(f"- {old}")
            result.append(f"+ {new}")
        else:
            result.append(f"  {old}")
    
    return result

def get_register_size(reg: str) -> int:
    """Get size of register in bits."""
    reg_lower = reg.lower()
    
    # 64-bit
    if reg_lower in {'rax','rbx','rcx','rdx','rsi','rdi','rbp','rsp',
                     'r8','r9','r10','r11','r12','r13','r14','r15'}:
        return 64
    # 32-bit
    if reg_lower in {'eax','ebx','ecx','edx','esi','edi','ebp','esp',
                     'r8d','r9d','r10d','r11d','r12d','r13d','r14d','r15d'}:
        return 32
    # 16-bit
    if reg_lower in {'ax','bx','cx','dx','si','di','bp','sp',
                     'r8w','r9w','r10w','r11w','r12w','r13w','r14w','r15w'}:
        return 16
    # 8-bit high
    if reg_lower in {'ah','bh','ch','dh'}:
        return 8
    # 8-bit low
    if reg_lower in {'al','bl','cl','dl','sil','dil','bpl','spl',
                     'r8b','r9b','r10b','r11b','r12b','r13b','r14b','r15b'}:
        return 8
    
    return 64  # default

def is_power_of_two(n: int) -> bool:
    """Check if n is a power of two."""
    return n > 0 and (n & (n - 1)) == 0

def log2_int(n: int) -> int:
    """Integer log2 (n must be power of 2)."""
    return n.bit_length() - 1
'''

with open(os.path.join(base_dir, "utils", "asm_utils.py"), "w") as f:
    f.write(utils_code)

print("✅ Utils modülü oluşturuldu")

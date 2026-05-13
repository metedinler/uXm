
# 4. SAFETY MODÜLÜ - Güvenlik Kontrolleri
safety_code = r'''"""Safety Analysis Module for ASM Optimizations"""
from typing import List, Set, Dict, Optional
from .nop_hook import nop_hook

class SafetyAnalyzer:
    """Analyzes safety of optimizations."""
    
    def __init__(self):
        self.warnings: List[str] = []
        self.errors: List[str] = []
        nop_hook()
    
    def check_flag_safety(self, instructions, start_idx, end_idx, parser) -> bool:
        """Check if optimization between start and end is flag-safe."""
        # Check if any instruction between start and end reads flags
        for i in range(start_idx, end_idx + 1):
            if i >= len(instructions):
                continue
            if parser.reads_flags(instructions[i]):
                self.warnings.append(
                    f"Flag read at line {instructions[i].line_num}: {instructions[i].raw_line.strip()}"
                )
                return False
        return True
    
    def check_register_safety(self, instructions, start_idx, end_idx, 
                              reg: str, parser) -> bool:
        """Check if register is safely used between start and end."""
        reg_lower = reg.lower()
        
        for i in range(start_idx, end_idx + 1):
            if i >= len(instructions):
                continue
            instr = instructions[i]
            if not instr.mnemonic:
                continue
            
            # Check if register is read (used)
            for op in instr.operands:
                if op.raw.lower() == reg_lower:
                    # Check if it's a destination (written to)
                    if op == instr.operands[0] and instr.mnemonic.lower() not in ('cmp', 'test'):
                        # It's being overwritten, safe after this point
                        pass
                    else:
                        self.warnings.append(
                            f"Register {reg} used at line {instr.line_num}"
                        )
                        return False
        return True
    
    def check_memory_safety(self, instructions, start_idx, end_idx,
                           mem_expr: str, parser) -> bool:
        """Check if memory location is safely accessed between start and end."""
        mem_lower = mem_expr.lower()
        
        for i in range(start_idx, end_idx + 1):
            if i >= len(instructions):
                continue
            instr = instructions[i]
            if not instr.mnemonic:
                continue
            
            # Check for memory writes
            for op in instr.operands:
                if op.type == 'memory':
                    if op.raw.lower() == mem_lower:
                        if op == instr.operands[0]:  # Destination
                            self.warnings.append(
                                f"Memory {mem_expr} written at line {instr.line_num}"
                            )
                            return False
        return True
    
    def check_control_flow_safety(self, instructions, start_idx, end_idx,
                                   parser, cfg) -> bool:
        """Check if optimization crosses control flow boundaries."""
        if not cfg or not cfg.blocks:
            return True
        
        start_block = cfg.get_block_containing(instructions[start_idx].line_num)
        end_block = cfg.get_block_containing(instructions[end_idx].line_num)
        
        if start_block != end_block:
            self.errors.append(
                f"Optimization crosses basic block boundary: "
                f"BB{start_block} -> BB{end_block}"
            )
            return False
        
        # Check if there's a jump in the range
        for i in range(start_idx, end_idx + 1):
            if i >= len(instructions):
                continue
            if parser.is_jump(instructions[i]):
                self.warnings.append(
                    f"Jump instruction in optimization range at line {instructions[i].line_num}"
                )
                return False
        
        return True
    
    def check_stack_safety(self, instructions, start_idx, end_idx, parser) -> bool:
        """Check if stack operations are safe in range."""
        stack_depth = 0
        
        for i in range(start_idx, end_idx + 1):
            if i >= len(instructions):
                continue
            instr = instructions[i]
            if not instr.mnemonic:
                continue
            
            mnem = instr.mnemonic.lower()
            if mnem == 'push':
                stack_depth += 1
            elif mnem == 'pop':
                stack_depth -= 1
            elif mnem in ('call', 'syscall', 'sysret'):
                self.warnings.append(
                    f"Stack-affecting call at line {instr.line_num}"
                )
                return False
        
        if stack_depth != 0:
            self.warnings.append(
                f"Unbalanced stack in range: depth={stack_depth}"
            )
            return False
        
        return True
    
    def get_family_regs(self, reg: str) -> Set[str]:
        """Get all registers in the same family."""
        from ..parser.asm_parser import REG_TO_FAMILY, REGISTER_FAMILY
        
        reg_lower = reg.lower()
        family = REG_TO_FAMILY.get(reg_lower)
        if family:
            return REGISTER_FAMILY.get(family, {reg_lower})
        return {reg_lower}
    
    def clear(self):
        """Clear all warnings and errors."""
        self.warnings = []
        self.errors = []
    
    def has_errors(self) -> bool:
        return len(self.errors) > 0
    
    def has_warnings(self) -> bool:
        return len(self.warnings) > 0
'''

with open(os.path.join(base_dir, "safety", "safety_analyzer.py"), "w") as f:
    f.write(safety_code)

print("✅ Safety modülü oluşturuldu")


# 3. RULES MODÜLÜ - 15+ Optimizasyon Kuralı + Config dosyası
rules_code = r'''"""Optimization Rules Engine for x64 ASM"""
import re
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from .nop_hook import nop_hook

@dataclass
class RuleResult:
    """Result of applying a rule."""
    applied: bool
    original: List[str]
    optimized: List[str]
    description: str
    rule_name: str
    line_start: int
    line_end: int

class OptimizationRule:
    """Base class for optimization rules."""
    name = "base"
    description = "Base rule"
    
    def __init__(self, config: dict = None):
        self.config = config or {}
        self.enabled = self.config.get('enabled', True)
        nop_hook()
    
    def match(self, instructions, start_idx: int, parser) -> bool:
        """Check if rule applies at given position."""
        return False
    
    def apply(self, instructions, start_idx: int, parser) -> RuleResult:
        """Apply the rule."""
        return RuleResult(False, [], [], "", self.name, start_idx, start_idx)

# ============================================================
# RULE 1: mov reg, 0 -> xor reg, reg (FLAGS-safe)
# ============================================================
class MovZeroToXor(OptimizationRule):
    name = "mov_zero_to_xor"
    description = "Replace mov reg, 0 with xor reg, reg (safe when flags not needed)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'mov':
            return False
        if len(instr.operands) != 2:
            return False
        
        dest = instr.operands[0]
        src = instr.operands[1]
        
        # Check: dest is register, src is immediate 0
        if dest.type != 'register' or src.type != 'immediate':
            return False
        if src.raw != '0':
            return False
        
        # Check: next instruction doesn't read flags
        if start_idx + 1 < len(instructions):
            next_instr = instructions[start_idx + 1]
            if parser.reads_flags(next_instr):
                return False
        
        return True
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        reg = instr.operands[0].raw
        return RuleResult(
            True,
            [instr.raw_line],
            [f"xor {reg}, {reg}  ; [UXM: mov-zero -> xor]"],
            f"mov {reg}, 0 -> xor {reg}, {reg}",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 2: jmp next_label -> remove
# ============================================================
class JmpToNext(OptimizationRule):
    name = "jmp_to_next"
    description = "Remove jump to immediately following label"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'jmp':
            return False
        if len(instr.operands) != 1:
            return False
        
        target = instr.operands[0].raw
        
        # Check next non-empty instruction is the target label
        for i in range(start_idx + 1, len(instructions)):
            next_instr = instructions[i]
            if next_instr.label and next_instr.label == target:
                return True
            if next_instr.mnemonic or next_instr.label:
                break
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        return RuleResult(
            True,
            [instr.raw_line],
            [f"; [UXM: removed jmp-to-next] {instr.raw_line.strip()}"],
            f"Removed unnecessary jmp to next line",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 3: mul reg, power_of_2 -> shl reg, log2
# ============================================================
class MulToShift(OptimizationRule):
    name = "mul_to_shift"
    description = "Replace mul by power of 2 with shift"
    
    POW2_SHIFTS = {2: 1, 4: 2, 8: 3, 16: 4, 32: 5, 64: 6, 128: 7, 256: 8}
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() not in ('mul', 'imul'):
            return False
        if len(instr.operands) != 2:
            return False
        
        dest = instr.operands[0]
        src = instr.operands[1]
        
        if dest.type != 'register' or src.type != 'immediate':
            return False
        
        try:
            val = int(src.raw, 0)
        except:
            return False
        
        if val not in self.POW2_SHIFTS:
            return False
        
        # Only apply to unsigned mul (imul is signed, skip for safety)
        if instr.mnemonic.lower() == 'imul':
            return False
        
        return True
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        reg = instr.operands[0].raw
        val = int(instr.operands[1].raw, 0)
        shift = self.POW2_SHIFTS[val]
        return RuleResult(
            True,
            [instr.raw_line],
            [f"shl {reg}, {shift}  ; [UXM: mul {val} -> shl {shift}]"],
            f"mul {reg}, {val} -> shl {reg}, {shift}",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 4: add reg, 0 -> remove
# ============================================================
class AddZero(OptimizationRule):
    name = "add_zero"
    description = "Remove add reg, 0 (no-op)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'add':
            return False
        if len(instr.operands) != 2:
            return False
        
        src = instr.operands[1]
        if src.type == 'immediate' and src.raw == '0':
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        return RuleResult(
            True,
            [instr.raw_line],
            [f"; [UXM: removed add-zero] {instr.raw_line.strip()}"],
            f"Removed add with zero",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 5: sub reg, 0 -> remove  
# ============================================================
class SubZero(OptimizationRule):
    name = "sub_zero"
    description = "Remove sub reg, 0 (no-op)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'sub':
            return False
        if len(instr.operands) != 2:
            return False
        
        src = instr.operands[1]
        if src.type == 'immediate' and src.raw == '0':
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        return RuleResult(
            True,
            [instr.raw_line],
            [f"; [UXM: removed sub-zero] {instr.raw_line.strip()}"],
            f"Removed sub with zero",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 6: lea reg, [reg] -> remove
# ============================================================
class LeaIdentity(OptimizationRule):
    name = "lea_identity"
    description = "Remove lea reg, [reg] (no-op)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'lea':
            return False
        if len(instr.operands) != 2:
            return False
        
        dest = instr.operands[0]
        src = instr.operands[1]
        
        if dest.type != 'register' or src.type != 'memory':
            return False
        
        # Check if memory is just [reg] with same register
        if (src.base and not src.index and src.displacement == 0 and
            src.base.lower() == dest.raw.lower()):
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        return RuleResult(
            True,
            [instr.raw_line],
            [f"; [UXM: removed lea-identity] {instr.raw_line.strip()}"],
            f"Removed lea reg, [reg]",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 7: mov A, B / mov B, A -> mov A, B (remove second)
# ============================================================
class RedundantMovSwap(OptimizationRule):
    name = "redundant_mov_swap"
    description = "Remove redundant mov pair (mov A,B then mov B,A)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'mov' or i2.mnemonic.lower() != 'mov':
            return False
        if len(i1.operands) != 2 or len(i2.operands) != 2:
            return False
        
        # mov A, B / mov B, A
        if (i1.operands[0].raw.lower() == i2.operands[1].raw.lower() and
            i1.operands[1].raw.lower() == i2.operands[0].raw.lower()):
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        return RuleResult(
            True,
            [i1.raw_line, i2.raw_line],
            [i1.raw_line.rstrip(), f"; [UXM: removed redundant mov-swap] {i2.raw_line.strip()}"],
            f"Removed redundant mov swap pair",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 8: push reg / ... / pop reg (same reg, no stack use between)
# ============================================================
class PushPopPair(OptimizationRule):
    name = "push_pop_pair"
    description = "Remove push/pop pair when register not used between"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        if not i1.mnemonic or i1.mnemonic.lower() != 'push':
            return False
        if len(i1.operands) != 1:
            return False
        
        reg = i1.operands[0].raw.lower()
        if i1.operands[0].type != 'register':
            return False
        
        # Look for matching pop within reasonable distance
        max_distance = self.config.get('max_push_pop_distance', 20)
        
        for j in range(start_idx + 1, min(start_idx + max_distance, len(instructions))):
            ij = instructions[j]
            
            # Check for stack operations that would break the pattern
            if ij.mnemonic and ij.mnemonic.lower() in ('push', 'pop', 'call', 'ret'):
                if ij.mnemonic.lower() == 'pop':
                    if len(ij.operands) == 1 and ij.operands[0].raw.lower() == reg:
                        # Found matching pop - check if reg is used between
                        used_between = False
                        for k in range(start_idx + 1, j):
                            ik = instructions[k]
                            if ik.mnemonic:
                                # Check if reg is read or written
                                for op in ik.operands:
                                    if op.raw.lower() == reg:
                                        used_between = True
                                        break
                            if used_between:
                                break
                        
                        if not used_between:
                            self._match_end = j
                            return True
                # Another push/pop/call/ret breaks the pattern
                break
            
            # Check if register is modified between
            if ij.mnemonic and ij.mnemonic.lower() in ('mov', 'add', 'sub', 'xor', 'and', 'or'):
                if len(ij.operands) > 0 and ij.operands[0].raw.lower() == reg:
                    break
        
        return False
    
    def apply(self, instructions, start_idx, parser):
        end_idx = getattr(self, '_match_end', start_idx)
        i1 = instructions[start_idx]
        i2 = instructions[end_idx]
        reg = i1.operands[0].raw
        
        lines = [i.raw_line for i in instructions[start_idx:end_idx+1]]
        opt_lines = [f"; [UXM: removed push-pop pair] {i1.raw_line.strip()}"]
        for k in range(start_idx + 1, end_idx):
            opt_lines.append(instructions[k].raw_line.rstrip())
        opt_lines.append(f"; [UXM: removed push-pop pair] {i2.raw_line.strip()}")
        
        return RuleResult(
            True,
            lines,
            opt_lines,
            f"Removed push {reg} / pop {reg} pair",
            self.name,
            start_idx,
            end_idx
        )

# ============================================================
# RULE 9: and reg, 0xFF -> movzx (for 8-bit zero extend)
# ============================================================
class AndToMovzx(OptimizationRule):
    name = "and_to_movzx"
    description = "Replace and reg, 0xFF with movzx for zero extension"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'and':
            return False
        if len(instr.operands) != 2:
            return False
        
        dest = instr.operands[0]
        src = instr.operands[1]
        
        if dest.type != 'register' or src.type != 'immediate':
            return False
        
        try:
            val = int(src.raw, 0)
        except:
            return False
        
        # 0xFF = 255 (keep lower 8 bits)
        if val == 0xFF:
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        reg = instr.operands[0].raw
        return RuleResult(
            True,
            [instr.raw_line],
            [f"movzx {reg}, {reg}b  ; [UXM: and 0xFF -> movzx]"],
            f"and {reg}, 0xFF -> movzx {reg}, {reg}b",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 10: test reg, reg -> cmp reg, 0 (when followed by conditional jump)
# ============================================================
class TestToCmp(OptimizationRule):
    name = "test_to_cmp"
    description = "Replace test reg, reg with cmp reg, 0 for clarity"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'test':
            return False
        if len(instr.operands) != 2:
            return False
        
        op1 = instr.operands[0]
        op2 = instr.operands[1]
        
        # test reg, reg
        if op1.type == 'register' and op2.type == 'register':
            if op1.raw.lower() == op2.raw.lower():
                # Check if followed by conditional jump
                if start_idx + 1 < len(instructions):
                    next_instr = instructions[start_idx + 1]
                    if parser.is_conditional_jump(next_instr):
                        return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        reg = instr.operands[0].raw
        return RuleResult(
            True,
            [instr.raw_line],
            [f"cmp {reg}, 0  ; [UXM: test reg,reg -> cmp reg,0]"],
            f"test {reg}, {reg} -> cmp {reg}, 0",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 11: mov reg1, reg2 / mov reg2, reg1 -> mov reg1, reg2 (remove second)
# ============================================================
class RedundantMovPair(OptimizationRule):
    name = "redundant_mov_pair"
    description = "Remove second mov when it undoes the first"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'mov' or i2.mnemonic.lower() != 'mov':
            return False
        if len(i1.operands) != 2 or len(i2.operands) != 2:
            return False
        
        # mov A, B followed by mov A, B (redundant)
        if (i1.operands[0].raw.lower() == i2.operands[0].raw.lower() and
            i1.operands[1].raw.lower() == i2.operands[1].raw.lower()):
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        i2 = instructions[start_idx + 1]
        return RuleResult(
            True,
            [instructions[start_idx].raw_line, i2.raw_line],
            [instructions[start_idx].raw_line.rstrip(), f"; [UXM: removed redundant mov] {i2.raw_line.strip()}"],
            f"Removed redundant mov pair",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 12: xor reg, reg / mov reg, val -> mov reg, val (remove xor)
# ============================================================
class DeadXor(OptimizationRule):
    name = "dead_xor"
    description = "Remove xor reg,reg when immediately overwritten by mov"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'xor' or i2.mnemonic.lower() != 'mov':
            return False
        if len(i1.operands) != 2 or len(i2.operands) != 2:
            return False
        
        # xor reg, reg / mov reg, val
        if (i1.operands[0].raw.lower() == i1.operands[1].raw.lower() and
            i1.operands[0].raw.lower() == i2.operands[0].raw.lower()):
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        i1 = instructions[start_idx]
        return RuleResult(
            True,
            [i1.raw_line, instructions[start_idx + 1].raw_line],
            [f"; [UXM: removed dead xor] {i1.raw_line.strip()}", instructions[start_idx + 1].raw_line.rstrip()],
            f"Removed dead xor before mov",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 13: shl reg, 0 -> remove
# ============================================================
class ShlZero(OptimizationRule):
    name = "shl_zero"
    description = "Remove shl reg, 0 (no-op)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() not in ('shl', 'shr', 'sal', 'sar'):
            return False
        if len(instr.operands) != 2:
            return False
        
        src = instr.operands[1]
        if src.type == 'immediate' and src.raw == '0':
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        return RuleResult(
            True,
            [instr.raw_line],
            [f"; [UXM: removed shift-zero] {instr.raw_line.strip()}"],
            f"Removed shift by zero",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 14: inc/dec -> add/sub 1 (configurable, for flag consistency)
# ============================================================
class IncToAdd(OptimizationRule):
    name = "inc_to_add"
    description = "Replace inc/dec with add/sub 1 for flag consistency"
    
    def match(self, instructions, start_idx, parser):
        if not self.config.get('convert_inc_dec', False):
            return False
        if start_idx >= len(instructions):
            return False
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() not in ('inc', 'dec'):
            return False
        if len(instr.operands) != 1:
            return False
        return True
    
    def apply(self, instructions, start_idx, parser):
        instr = instructions[start_idx]
        reg = instr.operands[0].raw
        op = 'add' if instr.mnemonic.lower() == 'inc' else 'sub'
        return RuleResult(
            True,
            [instr.raw_line],
            [f"{op} {reg}, 1  ; [UXM: {instr.mnemonic.lower()} -> {op}]"],
            f"{instr.mnemonic.lower()} {reg} -> {op} {reg}, 1",
            self.name,
            start_idx,
            start_idx
        )

# ============================================================
# RULE 15: mov reg, [mem] / mov [mem], reg -> redundant store/load
# ============================================================
class RedundantLoadStore(OptimizationRule):
    name = "redundant_load_store"
    description = "Remove redundant load-store pair to same memory"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'mov' or i2.mnemonic.lower() != 'mov':
            return False
        if len(i1.operands) != 2 or len(i2.operands) != 2:
            return False
        
        # mov reg, [mem] / mov [mem], reg (same memory, same register)
        if (i1.operands[0].type == 'register' and i1.operands[1].type == 'memory' and
            i2.operands[0].type == 'memory' and i2.operands[1].type == 'register'):
            if (i1.operands[0].raw.lower() == i2.operands[1].raw.lower() and
                i1.operands[1].raw.lower() == i2.operands[0].raw.lower()):
                return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        i2 = instructions[start_idx + 1]
        return RuleResult(
            True,
            [instructions[start_idx].raw_line, i2.raw_line],
            [instructions[start_idx].raw_line.rstrip(), f"; [UXM: removed redundant store] {i2.raw_line.strip()}"],
            f"Removed redundant store after load",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 16: cmp reg, 0 / jne label -> test reg, reg / jne label (smaller)
# ============================================================
class CmpToTest(OptimizationRule):
    name = "cmp_to_test"
    description = "Replace cmp reg, 0 with test reg, reg (smaller encoding)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'cmp':
            return False
        if len(i1.operands) != 2:
            return False
        
        # cmp reg, 0
        if i1.operands[0].type == 'register' and i1.operands[1].type == 'immediate':
            if i1.operands[1].raw == '0':
                # Followed by conditional jump
                if parser.is_conditional_jump(i2):
                    return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        i1 = instructions[start_idx]
        reg = i1.operands[0].raw
        return RuleResult(
            True,
            [i1.raw_line, instructions[start_idx + 1].raw_line],
            [f"test {reg}, {reg}  ; [UXM: cmp 0 -> test]", instructions[start_idx + 1].raw_line.rstrip()],
            f"cmp {reg}, 0 -> test {reg}, {reg}",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 17: mov reg, imm / add reg, imm -> mov reg, (imm+imm) (constant folding)
# ============================================================
class ConstantFoldingMovAdd(OptimizationRule):
    name = "constant_folding_mov_add"
    description = "Fold mov reg, imm1 / add reg, imm2 into mov reg, (imm1+imm2)"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'mov' or i2.mnemonic.lower() != 'add':
            return False
        if len(i1.operands) != 2 or len(i2.operands) != 2:
            return False
        
        # mov reg, imm1 / add reg, imm2
        if (i1.operands[0].type == 'register' and i1.operands[1].type == 'immediate' and
            i2.operands[0].type == 'register' and i2.operands[1].type == 'immediate'):
            if i1.operands[0].raw.lower() == i2.operands[0].raw.lower():
                # Check register not used between
                return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        reg = i1.operands[0].raw
        try:
            val1 = int(i1.operands[1].raw, 0)
            val2 = int(i2.operands[1].raw, 0)
            result = val1 + val2
        except:
            return RuleResult(False, [], [], "", self.name, start_idx, start_idx)
        
        return RuleResult(
            True,
            [i1.raw_line, i2.raw_line],
            [f"mov {reg}, {result}  ; [UXM: folded mov+add]", f"; [UXM: folded] {i2.raw_line.strip()}"],
            f"mov {reg}, {val1} / add {reg}, {val2} -> mov {reg}, {result}",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 18: nop sled detection and removal
# ============================================================
class NopSled(OptimizationRule):
    name = "nop_sled"
    description = "Remove sequences of nop instructions"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        
        # Count consecutive nops
        count = 0
        for i in range(start_idx, len(instructions)):
            if instructions[i].mnemonic and instructions[i].mnemonic.lower() == 'nop':
                count += 1
            else:
                break
        
        min_nops = self.config.get('min_nop_sled', 3)
        if count >= min_nops:
            self._nop_count = count
            return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        count = getattr(self, '_nop_count', 1)
        lines = [instructions[start_idx + i].raw_line for i in range(count)]
        return RuleResult(
            True,
            lines,
            [f"; [UXM: removed {count} nop sled]"],
            f"Removed {count} consecutive nop instructions",
            self.name,
            start_idx,
            start_idx + count - 1
        )

# ============================================================
# RULE 19: movzx reg, regb / and reg, 0xFF -> movzx (remove and)
# ============================================================
class MovzxAndCleanup(OptimizationRule):
    name = "movzx_and_cleanup"
    description = "Remove redundant and after movzx"
    
    def match(self, instructions, start_idx, parser):
        if start_idx + 1 >= len(instructions):
            return False
        
        i1 = instructions[start_idx]
        i2 = instructions[start_idx + 1]
        
        if not i1.mnemonic or not i2.mnemonic:
            return False
        if i1.mnemonic.lower() != 'movzx' or i2.mnemonic.lower() != 'and':
            return False
        if len(i1.operands) != 2 or len(i2.operands) != 2:
            return False
        
        # movzx reg, regb / and reg, 0xFF
        if (i1.operands[0].type == 'register' and i2.operands[0].type == 'register'):
            if i1.operands[0].raw.lower() == i2.operands[0].raw.lower():
                if i2.operands[1].type == 'immediate':
                    try:
                        val = int(i2.operands[1].raw, 0)
                        if val == 0xFF:
                            return True
                    except:
                        pass
        return False
    
    def apply(self, instructions, start_idx, parser):
        i2 = instructions[start_idx + 1]
        return RuleResult(
            True,
            [instructions[start_idx].raw_line, i2.raw_line],
            [instructions[start_idx].raw_line.rstrip(), f"; [UXM: removed redundant and after movzx] {i2.raw_line.strip()}"],
            f"Removed redundant and after movzx",
            self.name,
            start_idx,
            start_idx + 1
        )

# ============================================================
# RULE 20: ret / nop -> ret (remove trailing nop)
# ============================================================
class RetNopCleanup(OptimizationRule):
    name = "ret_nop_cleanup"
    description = "Remove nop instructions after ret"
    
    def match(self, instructions, start_idx, parser):
        if start_idx >= len(instructions):
            return False
        
        instr = instructions[start_idx]
        if not instr.mnemonic or instr.mnemonic.lower() != 'ret':
            return False
        
        # Check if next instructions are nops until end or label
        for i in range(start_idx + 1, len(instructions)):
            if instructions[i].label:
                break
            if instructions[i].mnemonic and instructions[i].mnemonic.lower() != 'nop':
                return False
            if instructions[i].mnemonic and instructions[i].mnemonic.lower() == 'nop':
                self._ret_idx = start_idx
                return True
        return False
    
    def apply(self, instructions, start_idx, parser):
        lines = [instructions[start_idx].raw_line]
        opt_lines = [instructions[start_idx].raw_line.rstrip()]
        
        for i in range(start_idx + 1, len(instructions)):
            if instructions[i].label:
                break
            if instructions[i].mnemonic and instructions[i].mnemonic.lower() == 'nop':
                lines.append(instructions[i].raw_line)
                opt_lines.append(f"; [UXM: removed nop after ret] {instructions[i].raw_line.strip()}")
            else:
                break
        
        return RuleResult(
            True,
            lines,
            opt_lines,
            f"Removed nop instructions after ret",
            self.name,
            start_idx,
            start_idx + len(lines) - 1
        )

# ============================================================
# RULE ENGINE
# ============================================================
ALL_RULES = [
    MovZeroToXor,
    JmpToNext,
    MulToShift,
    AddZero,
    SubZero,
    LeaIdentity,
    RedundantMovSwap,
    PushPopPair,
    AndToMovzx,
    TestToCmp,
    RedundantMovPair,
    DeadXor,
    ShlZero,
    IncToAdd,
    RedundantLoadStore,
    CmpToTest,
    ConstantFoldingMovAdd,
    NopSled,
    MovzxAndCleanup,
    RetNopCleanup,
]

class RuleEngine:
    """Manages and applies optimization rules."""
    
    def __init__(self, config_path: Optional[str] = None):
        self.rules: List[OptimizationRule] = []
        self.config = self._load_config(config_path)
        self._init_rules()
        nop_hook()
    
    def _load_config(self, config_path: Optional[str]) -> dict:
        """Load rule configuration from JSON file."""
        default_config = {
            "rules": {
                "mov_zero_to_xor": {"enabled": True},
                "jmp_to_next": {"enabled": True},
                "mul_to_shift": {"enabled": True},
                "add_zero": {"enabled": True},
                "sub_zero": {"enabled": True},
                "lea_identity": {"enabled": True},
                "redundant_mov_swap": {"enabled": True},
                "push_pop_pair": {"enabled": True, "max_push_pop_distance": 20},
                "and_to_movzx": {"enabled": True},
                "test_to_cmp": {"enabled": False},
                "redundant_mov_pair": {"enabled": True},
                "dead_xor": {"enabled": True},
                "shl_zero": {"enabled": True},
                "inc_to_add": {"enabled": False, "convert_inc_dec": False},
                "redundant_load_store": {"enabled": True},
                "cmp_to_test": {"enabled": True},
                "constant_folding_mov_add": {"enabled": True},
                "nop_sled": {"enabled": True, "min_nop_sled": 3},
                "movzx_and_cleanup": {"enabled": True},
                "ret_nop_cleanup": {"enabled": True},
            },
            "global": {
                "max_passes": 5,
                "preserve_comments": True,
            }
        }
        
        if config_path and Path(config_path).exists():
            with open(config_path, 'r') as f:
                user_config = json.load(f)
                # Merge with defaults
                for rule_name, rule_cfg in user_config.get('rules', {}).items():
                    if rule_name in default_config['rules']:
                        default_config['rules'][rule_name].update(rule_cfg)
                default_config['global'].update(user_config.get('global', {}))
        
        return default_config
    
    def _init_rules(self):
        """Initialize all rules with config."""
        for RuleClass in ALL_RULES:
            rule_name = RuleClass.name
            rule_config = self.config.get('rules', {}).get(rule_name, {})
            self.rules.append(RuleClass(rule_config))
    
    def apply_all(self, instructions, parser) -> Tuple[List[str], List[RuleResult]]:
        """Apply all enabled rules to instructions."""
        results = []
        changed = True
        passes = 0
        max_passes = self.config['global'].get('max_passes', 5)
        
        # Convert instructions to mutable line list
        lines = [instr.raw_line for instr in instructions]
        
        while changed and passes < max_passes:
            changed = False
            passes += 1
            
            # Re-parse current lines
            from ..parser.asm_parser import ASMParser
            current_parser = ASMParser()
            current_instrs = current_parser.parse(lines)
            
            i = 0
            while i < len(current_instrs):
                applied = False
                
                for rule in self.rules:
                    if not rule.enabled:
                        continue
                    
                    if rule.match(current_instrs, i, current_parser):
                        result = rule.apply(current_instrs, i, current_parser)
                        if result.applied:
                            # Replace lines
                            before = lines[:result.line_start]
                            after = lines[result.line_end + 1:]
                            lines = before + result.optimized + after
                            
                            results.append(result)
                            changed = True
                            applied = True
                            break
                
                if applied:
                    # Restart from beginning after change
                    break
                i += 1
        
        return lines, results
    
    def get_enabled_rules(self) -> List[str]:
        """Get list of enabled rule names."""
        return [r.name for r in self.rules if r.enabled]
    
    def get_disabled_rules(self) -> List[str]:
        """Get list of disabled rule names."""
        return [r.name for r in self.rules if not r.enabled]
'''

with open(os.path.join(base_dir, "rules", "rule_engine.py"), "w") as f:
    f.write(rules_code)

print("✅ Rules modülü oluşturuldu (20 kural)")

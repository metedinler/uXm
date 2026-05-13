
# Parser'daki syntax hatasını düzeltelim (escape sequence)
# ve test edelim

import os

base_dir = "/mnt/agents/output/uxm_asm_optimizer"

# Parser'ı düzelt
parser_path = os.path.join(base_dir, "parser", "asm_parser.py")
with open(parser_path, 'r') as f:
    parser_content = f.read()

# \+ -> \\+ düzeltmesi
parser_content = parser_content.replace(
    "parts = re.split(r'([\\+\\-])', mem_content)",
    "parts = re.split(r'([\\+\\-])', mem_content)"
)

with open(parser_path, 'w') as f:
    f.write(parser_content)

# Şimdi test edelim
import sys
sys.path.insert(0, base_dir)

# Test ASM içeriği
test_asm_lines = [
    "; Test file",
    "main PROC",
    "    mov rax, 0",
    "    mov rbx, 0",
    "    jmp label1",
    "label1:",
    "    mov rcx, 10",
    "    mul rax, 8",
    "    add rcx, 0",
    "    sub rdx, 0",
    "    lea rax, [rax]",
    "    mov rax, rbx",
    "    mov rbx, rax",
    "    xor rdx, rdx",
    "    mov rdx, 100",
    "    shl rax, 0",
    "    nop",
    "    nop",
    "    nop",
    "    nop",
    "    nop",
    "    ret",
    "    nop",
    "    nop",
    "main ENDP",
    "END"
]

print("=" * 70)
print("PARSER TEST")
print("=" * 70)

from parser.asm_parser import ASMParser

parser = ASMParser()
instructions = parser.parse(test_asm_lines)

print(f"Parsed {len(instructions)} instructions:")
for instr in instructions:
    if instr.mnemonic:
        ops = ", ".join([op.raw for op in instr.operands])
        print(f"  L{instr.line_num:2d}: {instr.mnemonic:8s} {ops}")
    elif instr.label:
        print(f"  L{instr.line_num:2d}: [{instr.label}]")

print("\n" + "=" * 70)
print("CFG TEST")
print("=" * 70)

from cfg.cfg_builder import CFGBuilder

cfg = CFGBuilder()
cfg.build(instructions, parser)
print(cfg)

print("\n" + "=" * 70)
print("RULES TEST")
print("=" * 70)

from rules.rule_engine import RuleEngine

engine = RuleEngine()
print(f"Enabled rules: {len(engine.get_enabled_rules())}")
for name in engine.get_enabled_rules():
    print(f"  ✓ {name}")

print(f"\nDisabled rules: {len(engine.get_disabled_rules())}")
for name in engine.get_disabled_rules():
    print(f"  ✗ {name}")

# Apply rules
optimized_lines, results = engine.apply_all(instructions, parser)

print(f"\nOptimizations applied: {len(results)}")
for r in results:
    print(f"  [{r.rule_name}] {r.description}")

print("\n" + "=" * 70)
print("OPTIMIZED OUTPUT")
print("=" * 70)
for i, line in enumerate(optimized_lines):
    print(f"  {i:2d}: {line}")


======================================================================
PARSER TEST
======================================================================
Error:
---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
Cell In[21], line 63
     60 from parser.asm_parser import ASMParser
     62 parser = ASMParser()
---> 63 instructions = parser.parse(test_asm_lines)
     65 print(f"Parsed {len(instructions)} instructions:")
     66 for instr in instructions:

File /mnt/agents/output/uxm_asm_optimizer/parser/asm_parser.py:302, in ASMParser.parse(self, lines)
    300 self.instructions = []
    301 for i, line in enumerate(lines):
--> 302     instr = self.parse_line(line, i)
    303     self.instructions.append(instr)
    304 return self.instructions

File /mnt/agents/output/uxm_asm_optimizer/parser/asm_parser.py:287, in ASMParser.parse_line(self, line, line_num)
    285     for op_str in op_parts:
    286         op_type, op_info = self._detect_operand_type(op_str)
--> 287         operands.append(Operand(**op_info))
    289 return Instruction(
    290     raw_line=line,
    291     line_num=line_num,
   (...)    295     comment=comment
    296 )

TypeError: Operand.__init__() got an unexpected keyword argument 'value'
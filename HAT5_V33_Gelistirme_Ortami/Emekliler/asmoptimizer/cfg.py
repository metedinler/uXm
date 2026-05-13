
# 2. CFG MODÜLÜ - Kontrol Akışı Grafiği
cfg_code = r'''"""Control Flow Graph (CFG) Module for x64 ASM"""
from dataclasses import dataclass, field
from typing import List, Set, Dict, Optional
from .nop_hook import nop_hook

@dataclass
class BasicBlock:
    """Represents a basic block in the CFG."""
    id: int
    start_line: int  # inclusive
    end_line: int    # inclusive
    instructions: List = field(default_factory=list)
    predecessors: Set[int] = field(default_factory=set)
    successors: Set[int] = field(default_factory=set)
    is_entry: bool = False
    is_exit: bool = False
    
    def __repr__(self):
        preds = ','.join(map(str, sorted(self.predecessors))) or 'None'
        succs = ','.join(map(str, sorted(self.successors))) or 'None'
        return f"BB{self.id}[{self.start_line}-{self.end_line}] preds={preds} succ={succs}"

class CFGBuilder:
    """Builds Control Flow Graph from parsed instructions."""
    
    def __init__(self):
        self.blocks: Dict[int, BasicBlock] = {}
        self.entry_block: Optional[int] = None
        self.exit_blocks: Set[int] = set()
        self.label_to_block: Dict[str, int] = {}
        nop_hook()
    
    def build(self, instructions, parser):
        """Build CFG from parsed instructions."""
        if not instructions:
            return
        
        # Step 1: Find all leader instructions
        # Leaders are:
        # - First instruction
        # - Target of any jump
        # - Instruction after any jump
        
        leaders = {0}  # First instruction is always a leader
        labels = parser.get_labels()
        
        for i, instr in enumerate(instructions):
            if parser.is_jump(instr):
                # Instruction after jump is a leader (if exists)
                if i + 1 < len(instructions):
                    leaders.add(i + 1)
                
                # Target of jump is a leader
                if instr.operands:
                    target = instr.operands[0].raw
                    if target in labels:
                        target_line = labels[target]
                        # Find which instruction index corresponds to this line
                        for idx, inst in enumerate(instructions):
                            if inst.line_num == target_line:
                                leaders.add(idx)
                                break
        
        # Step 2: Create basic blocks
        sorted_leaders = sorted(leaders)
        block_id = 0
        
        for i, leader_idx in enumerate(sorted_leaders):
            start = leader_idx
            end = sorted_leaders[i + 1] - 1 if i + 1 < len(sorted_leaders) else len(instructions) - 1
            
            # Find actual end (before next leader)
            while end >= start and not instructions[end].mnemonic and not instructions[end].label:
                end -= 1
            
            if end < start:
                continue
            
            block = BasicBlock(
                id=block_id,
                start_line=instructions[start].line_num,
                end_line=instructions[end].line_num,
                instructions=instructions[start:end+1]
            )
            
            # Map line numbers to block
            for idx in range(start, end + 1):
                if instructions[idx].label:
                    self.label_to_block[instructions[idx].label] = block_id
            
            self.blocks[block_id] = block
            block_id += 1
        
        # Step 3: Connect blocks (successors/predecessors)
        block_ids = sorted(self.blocks.keys())
        
        for i, bid in enumerate(block_ids):
            block = self.blocks[bid]
            last_instr = block.instructions[-1] if block.instructions else None
            
            if not last_instr or not last_instr.mnemonic:
                # Fall-through to next block
                if i + 1 < len(block_ids):
                    next_bid = block_ids[i + 1]
                    block.successors.add(next_bid)
                    self.blocks[next_bid].predecessors.add(bid)
                continue
            
            mnemonic = last_instr.mnemonic.lower()
            
            # Unconditional jump
            if mnemonic == 'jmp':
                if last_instr.operands:
                    target = last_instr.operands[0].raw
                    if target in self.label_to_block:
                        target_bid = self.label_to_block[target]
                        block.successors.add(target_bid)
                        self.blocks[target_bid].predecessors.add(bid)
            
            # Conditional jump
            elif parser.is_conditional_jump(last_instr):
                # Target block
                if last_instr.operands:
                    target = last_instr.operands[0].raw
                    if target in self.label_to_block:
                        target_bid = self.label_to_block[target]
                        block.successors.add(target_bid)
                        self.blocks[target_bid].predecessors.add(bid)
                
                # Fall-through block
                if i + 1 < len(block_ids):
                    next_bid = block_ids[i + 1]
                    block.successors.add(next_bid)
                    self.blocks[next_bid].predecessors.add(bid)
            
            # Return instructions
            elif mnemonic in ('ret', 'iret', 'retn'):
                block.is_exit = True
                self.exit_blocks.add(bid)
            
            # Call - fall through
            elif mnemonic == 'call':
                if i + 1 < len(block_ids):
                    next_bid = block_ids[i + 1]
                    block.successors.add(next_bid)
                    self.blocks[next_bid].predecessors.add(bid)
            
            # Default: fall through
            else:
                if i + 1 < len(block_ids):
                    next_bid = block_ids[i + 1]
                    block.successors.add(next_bid)
                    self.blocks[next_bid].predecessors.add(bid)
        
        # Set entry block
        if block_ids:
            self.entry_block = block_ids[0]
            self.blocks[self.entry_block].is_entry = True
        
        return self.blocks
    
    def get_block_containing(self, line_num: int) -> Optional[int]:
        """Get block ID containing given line number."""
        for bid, block in self.blocks.items():
            if block.start_line <= line_num <= block.end_line:
                return bid
        return None
    
    def get_dominators(self) -> Dict[int, Set[int]]:
        """Compute dominators for each block."""
        if not self.blocks:
            return {}
        
        all_blocks = set(self.blocks.keys())
        dominators = {bid: all_blocks.copy() for bid in self.blocks}
        
        if self.entry_block is not None:
            dominators[self.entry_block] = {self.entry_block}
        
        changed = True
        while changed:
            changed = False
            for bid in self.blocks:
                if bid == self.entry_block:
                    continue
                
                preds = self.blocks[bid].predecessors
                if not preds:
                    continue
                
                new_dom = all_blocks.copy()
                for pred in preds:
                    new_dom &= dominators[pred]
                new_dom.add(bid)
                
                if new_dom != dominators[bid]:
                    dominators[bid] = new_dom
                    changed = True
        
        return dominators
    
    def get_post_dominators(self) -> Dict[int, Set[int]]:
        """Compute post-dominators for each block."""
        if not self.blocks:
            return {}
        
        all_blocks = set(self.blocks.keys())
        post_dominators = {bid: all_blocks.copy() for bid in self.blocks}
        
        for exit_bid in self.exit_blocks:
            post_dominators[exit_bid] = {exit_bid}
        
        changed = True
        while changed:
            changed = False
            for bid in self.blocks:
                if bid in self.exit_blocks:
                    continue
                
                succs = self.blocks[bid].successors
                if not succs:
                    continue
                
                new_pdom = all_blocks.copy()
                for succ in succs:
                    new_pdom &= post_dominators[succ]
                new_pdom.add(bid)
                
                if new_pdom != post_dominators[bid]:
                    post_dominators[bid] = new_pdom
                    changed = True
        
        return post_dominators
    
    def find_unreachable_blocks(self) -> Set[int]:
        """Find unreachable blocks from entry."""
        if self.entry_block is None:
            return set(self.blocks.keys())
        
        reachable = set()
        queue = [self.entry_block]
        
        while queue:
            bid = queue.pop(0)
            if bid in reachable:
                continue
            reachable.add(bid)
            queue.extend(self.blocks[bid].successors)
        
        return set(self.blocks.keys()) - reachable
    
    def __repr__(self):
        lines = ["CFG:"]
        for bid in sorted(self.blocks.keys()):
            lines.append(f"  {self.blocks[bid]}")
        return "\n".join(lines)
'''

with open(os.path.join(base_dir, "cfg", "cfg_builder.py"), "w") as f:
    f.write(cfg_code)

print("✅ CFG modülü oluşturuldu")
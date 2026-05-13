
# 6. CORE MODÜLÜ - Ana Motor
core_code = r'''"""Core Engine - Main ASM Optimizer"""
import sys
import os
from pathlib import Path
from typing import List, Optional

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from parser.asm_parser import ASMParser
from cfg.cfg_builder import CFGBuilder
from rules.rule_engine import RuleEngine
from safety.safety_analyzer import SafetyAnalyzer
from report.report_generator import ReportGenerator
from .nop_hook import nop_hook

class UXMOptimizer:
    """Main ASM Optimizer Engine."""
    
    def __init__(self, base_path: str, config_path: Optional[str] = None):
        self.base_path = Path(base_path)
        self.config_path = config_path
        
        # Setup directories
        self.asm_dir = self._find_asm_dir()
        self.opt_dir = self.base_path / "yeni_optimize_asm"
        self.report_dir = self.base_path / "optimizasyon"
        
        for d in [self.opt_dir, self.report_dir]:
            d.mkdir(parents=True, exist_ok=True)
        
        # Initialize components
        self.parser = ASMParser()
        self.cfg_builder = CFGBuilder()
        self.rule_engine = RuleEngine(config_path)
        self.safety = SafetyAnalyzer()
        
        nop_hook()
    
    def _find_asm_dir(self) -> Path:
        """Find ASM directory - prefer build/asm, fallback to newest build*/asm."""
        active = self.base_path / "build" / "asm"
        if active.exists():
            return active
        
        candidates = []
        for d in self.base_path.iterdir():
            if d.is_dir() and d.name.lower().startswith("build"):
                asm_path = d / "asm"
                if asm_path.exists():
                    try:
                        mtime = d.stat().st_mtime
                        candidates.append((mtime, asm_path))
                    except OSError:
                        continue
        
        if candidates:
            candidates.sort(reverse=True)
            return candidates[0][1]
        
        return active  # Will fail later with clear error
    
    def process_file(self, asm_file: Path) -> tuple:
        """Process a single ASM file."""
        print(f"  Processing: {asm_file.name}")
        
        # Read file
        try:
            content = asm_file.read_text(encoding='utf-8', errors='replace')
        except Exception as e:
            print(f"    ERROR reading file: {e}")
            return None, None, []
        
        lines = content.splitlines()
        
        # Parse
        instructions = self.parser.parse(lines)
        
        # Build CFG
        self.cfg_builder = CFGBuilder()  # Fresh instance
        cfg = self.cfg_builder.build(instructions, self.parser)
        
        # Apply rules
        optimized_lines, rule_results = self.rule_engine.apply_all(instructions, self.parser)
        
        # Pattern stats
        stats, _ = self._analyze_patterns(instructions)
        
        return optimized_lines, stats, rule_results, cfg
    
    def _analyze_patterns(self, instructions):
        """Analyze instruction patterns."""
        from collections import Counter
        
        instr_list = []
        for instr in instructions:
            if instr.mnemonic and not instr.is_directive:
                instr_list.append(instr.mnemonic.lower())
        
        bigrams = [f"{instr_list[i]} -> {instr_list[i+1]}" 
                   for i in range(len(instr_list)-1)]
        trigrams = [f"{instr_list[i]} -> {instr_list[i+1]} -> {instr_list[i+2]}"
                    for i in range(len(instr_list)-2)]
        
        jump_count = len([x for x in instr_list 
                         if x.startswith(('j', 'call', 'ret'))])
        
        stats = {
            "top_instr": Counter(instr_list).most_common(20),
            "top_bigrams": Counter(bigrams).most_common(20),
            "top_trigrams": Counter(trigrams).most_common(20),
            "jump_density": jump_count / (len(instr_list) + 1) if instr_list else 0,
        }
        return stats, instr_list
    
    def run(self):
        """Run optimizer on all ASM files."""
        if not self.asm_dir.exists():
            raise FileNotFoundError(f"ASM directory not found: {self.asm_dir}")
        
        print(f"UXM ASM Optimizer")
        print(f"=================")
        print(f"ASM Source: {self.asm_dir}")
        print(f"Output: {self.opt_dir}")
        print(f"Config: {self.config_path or 'default'}")
        print(f"Enabled Rules: {len(self.rule_engine.get_enabled_rules())}")
        print(f"  {', '.join(self.rule_engine.get_enabled_rules())}")
        print()
        
        # Setup report
        report = ReportGenerator(self.report_dir / "asm_optimizer_report.txt")
        report.add_header(str(self.asm_dir))
        
        # Process files
        asm_files = sorted(self.asm_dir.glob("*.asm"))
        
        if not asm_files:
            print("WARNING: No .asm files found!")
            return
        
        for asm_file in asm_files:
            result = self.process_file(asm_file)
            if result is None:
                continue
            
            optimized_lines, stats, rule_results, cfg = result
            
            # Save optimized file
            opt_file = self.opt_dir / asm_file.name
            opt_file.write_text("\n".join(optimized_lines), encoding='utf-8')
            
            # Add to report
            report.add_file_section(asm_file.name, stats, rule_results)
            report.add_pattern_stats(stats)
            report.add_cfg_stats(cfg)
        
        # Finalize report
        report.add_summary()
        report_path = report.save()
        
        print()
        print(f"Optimization complete!")
        print(f"Report saved: {report_path}")
        print(f"Optimized files: {self.opt_dir}")


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description='UXM ASM Optimizer')
    parser.add_argument('path', nargs='?', default=os.getcwd(),
                       help='Base path to project (default: current directory)')
    parser.add_argument('-c', '--config', default=None,
                       help='Path to rule configuration JSON')
    parser.add_argument('-o', '--output', default=None,
                       help='Output directory for optimized files')
    
    args = parser.parse_args()
    
    try:
        optimizer = UXMOptimizer(args.path, args.config)
        if args.output:
            optimizer.opt_dir = Path(args.output)
            optimizer.opt_dir.mkdir(parents=True, exist_ok=True)
        optimizer.run()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
'''

with open(os.path.join(base_dir, "core", "optimizer.py"), "w") as f:
    f.write(core_code)

print("✅ Core modülü oluşturuldu")

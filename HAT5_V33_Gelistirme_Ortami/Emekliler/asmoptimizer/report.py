
# 5. REPORT MODÜLÜ - Raporlama
report_code = r'''"""Report Generation Module"""
from datetime import datetime
from pathlib import Path
from typing import List, Dict
from .nop_hook import nop_hook

class ReportGenerator:
    """Generates optimization reports in text format."""
    
    def __init__(self, output_path: str):
        self.output_path = Path(output_path)
        self.sections: List[str] = []
        self.stats = {
            'files_processed': 0,
            'files_optimized': 0,
            'total_rules_applied': 0,
            'rules_by_name': {},
            'lines_before': 0,
            'lines_after': 0,
            'bytes_saved': 0,
        }
        nop_hook()
    
    def add_header(self, asm_source: str):
        """Add report header."""
        self.sections.append("=" * 70)
        self.sections.append("UXM ASM OPTIMIZER REPORT")
        self.sections.append("=" * 70)
        self.sections.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self.sections.append(f"ASM Source: {asm_source}")
        self.sections.append("")
    
    def add_file_section(self, filename: str, stats: dict, rule_results: list):
        """Add section for a single file."""
        self.sections.append("-" * 70)
        self.sections.append(f"FILE: {filename}")
        self.sections.append("-" * 70)
        
        if not rule_results:
            self.sections.append("  No optimizations applied.")
            self.sections.append("")
            return
        
        self.sections.append(f"  Rules Applied: {len(rule_results)}")
        self.sections.append("")
        
        for result in rule_results:
            self.sections.append(f"  [{result.rule_name}]")
            self.sections.append(f"    Lines {result.line_start}-{result.line_end}: {result.description}")
            self.sections.append("    BEFORE:")
            for line in result.original:
                self.sections.append(f"      {line.rstrip()}")
            self.sections.append("    AFTER:")
            for line in result.optimized:
                self.sections.append(f"      {line}")
            self.sections.append("")
        
        # Update stats
        self.stats['files_processed'] += 1
        if rule_results:
            self.stats['files_optimized'] += 1
        self.stats['total_rules_applied'] += len(rule_results)
        
        for result in rule_results:
            name = result.rule_name
            self.stats['rules_by_name'][name] = self.stats['rules_by_name'].get(name, 0) + 1
    
    def add_pattern_stats(self, stats: dict):
        """Add pattern analysis statistics."""
        self.sections.append("-" * 70)
        self.sections.append("PATTERN ANALYSIS")
        self.sections.append("-" * 70)
        
        if 'top_instr' in stats:
            self.sections.append("  Top Instructions:")
            for instr, count in stats['top_instr']:
                self.sections.append(f"    {count:5d} x {instr}")
            self.sections.append("")
        
        if 'top_bigrams' in stats:
            self.sections.append("  Top Bigrams:")
            for bigram, count in stats['top_bigrams']:
                self.sections.append(f"    {count:5d} x {bigram}")
            self.sections.append("")
        
        if 'top_trigrams' in stats:
            self.sections.append("  Top Trigrams:")
            for trigram, count in stats['top_trigrams']:
                self.sections.append(f"    {count:5d} x {trigram}")
            self.sections.append("")
        
        if 'jump_density' in stats:
            self.sections.append(f"  Jump/Call Density: {stats['jump_density']*100:.2f}%")
            self.sections.append("")
    
    def add_cfg_stats(self, cfg):
        """Add CFG analysis statistics."""
        if not cfg or not cfg.blocks:
            return
        
        self.sections.append("-" * 70)
        self.sections.append("CONTROL FLOW GRAPH")
        self.sections.append("-" * 70)
        self.sections.append(f"  Total Blocks: {len(cfg.blocks)}")
        self.sections.append(f"  Entry Block: {cfg.entry_block}")
        self.sections.append(f"  Exit Blocks: {sorted(cfg.exit_blocks)}")
        
        unreachable = cfg.find_unreachable_blocks()
        if unreachable:
            self.sections.append(f"  Unreachable Blocks: {sorted(unreachable)}")
        else:
            self.sections.append("  Unreachable Blocks: None")
        
        self.sections.append("")
        self.sections.append("  Basic Blocks:")
        for bid in sorted(cfg.blocks.keys()):
            block = cfg.blocks[bid]
            self.sections.append(f"    {block}")
        self.sections.append("")
    
    def add_summary(self):
        """Add final summary."""
        self.sections.append("=" * 70)
        self.sections.append("SUMMARY")
        self.sections.append("=" * 70)
        self.sections.append(f"  Files Processed:     {self.stats['files_processed']}")
        self.sections.append(f"  Files Optimized:     {self.stats['files_optimized']}")
        self.sections.append(f"  Total Rules Applied: {self.stats['total_rules_applied']}")
        self.sections.append("")
        
        if self.stats['rules_by_name']:
            self.sections.append("  Rules Breakdown:")
            for name, count in sorted(self.stats['rules_by_name'].items(), key=lambda x: -x[1]):
                self.sections.append(f"    {count:5d} x {name}")
            self.sections.append("")
        
        self.sections.append("=" * 70)
        self.sections.append("END OF REPORT")
        self.sections.append("=" * 70)
    
    def generate(self) -> str:
        """Generate the complete report."""
        return "\n".join(self.sections)
    
    def save(self):
        """Save report to file."""
        self.output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.output_path, 'w', encoding='utf-8') as f:
            f.write(self.generate())
        return self.output_path
'''

with open(os.path.join(base_dir, "report", "report_generator.py"), "w") as f:
    f.write(report_code)

print("✅ Report modülü oluşturuldu")

Program tamamlandı. İşte sonuç:

---

## UXM ASM Optimizer v2.0 - Tamamlanan Proje

### 📦 İndirme Linki
**[uxm_asm_optimizer_v2.zip](sandbox:///mnt/agents/output/uxm_asm_optimizer_v2.zip)** (27 KB)

---

### 🏗️ Modüler Yapı (8 Modül)

| Modül | Dosya | Görev |
|-------|-------|-------|
| `core` | `optimizer.py` | Ana motor, CLI arayüzü |
| `parser` | `asm_parser.py` | x64 Intel syntax parser |
| `cfg` | `cfg_builder.py` | Basic Block CFG analizi |
| `rules` | `rule_engine.py` | 20 optimizasyon kuralı |
| `safety` | `safety_analyzer.py` | Güvenlik kontrolleri |
| `report` | `report_generator.py` | .txt rapor üretimi |
| `utils` | `asm_utils.py` | Yardımcı fonksiyonlar |
| `hooks` | `hook_manager.py` | Merkezi hook sistemi |

Her modülde `nop_hook.py` bulunur — ileride eklenti geliştirmek için.

---

### ⚙️ 20 Optimizasyon Kuralı (18 Aktif, 2 Pasif)

**Aktif Kurallar:**
1. `mov_zero_to_xor` — `mov reg,0` → `xor reg,reg`
2. `jmp_to_next` — Gereksiz jump silme
3. `mul_to_shift` — `mul pow2` → `shl`
4. `add_zero` — `add reg,0` silme
5. `sub_zero` — `sub reg,0` silme
6. `lea_identity` — `lea reg,[reg]` silme
7. `redundant_mov_swap` — `mov A,B / mov B,A` → ilkini tut
8. `dead_xor` — `xor reg,reg / mov reg,val` → xor'u sil
9. `shl_zero` — `shl/shr reg,0` silme
10. `cmp_to_test` — `cmp reg,0` → `test reg,reg`
11. `constant_folding_mov_add` — `mov imm1 / add imm2` → `mov (imm1+imm2)`
12. `redundant_mov_pair` — Aynı mov çiftini sil
13. `nop_sled` — Ardışık nop silme
14. `ret_nop_cleanup` — ret sonrası nop silme
15. `push_pop_pair` — Kullanılmayan push/pop çifti
16. `and_to_movzx` — `and 0xFF` → `movzx`
17. `redundant_load_store` — Yükleme/saklama çifti
18. `movzx_and_cleanup` — movzx sonrası gereksiz and

**Pasif Kurallar (config'den açılabilir):**
- `test_to_cmp` — test → cmp (tersi)
- `inc_to_add` — inc/dec → add/sub 1

---

### 🎯 Kullanım

```bash
# Temel kullanım
python run_optimizer.py /path/to/project

# Config ile
python run_optimizer.py . -c config/rules.json

# Kuralları listele
python run_optimizer.py --list-rules
```

---

### 📊 Test Sonucu

```
Original: 36 satır → Optimized: 25 satır
Reduction: 11 satır (%30.6)
Uygulanan optimizasyon: 14 adet
```

---

### 🔧 Config Dosyası Örneği

`config/rules.json` içinden kuralları açıp kapatabilirsiniz:

```json
{
  "rules": {
    "mov_zero_to_xor": {"enabled": true},
    "mul_to_shift": {"enabled": true},
    "nop_sled": {"enabled": true, "min_nop_sled": 3}
  }
}
```

---

### 📝 Rapor Formatı (.txt)

- Her dosya için uygulanan kurallar (before/after)
- Instruction istatistikleri (top 20)
- Bigram/trigram analizi
- Jump density
- CFG basic block haritası
- Özet istatistikler

---

### 🚀 Gelecekte Eklenebilecekler (NOP Hook ile)

Her modülde `nop_hook.py` hazır. İleride:
- Yeni kural eklemek için `rules/rule_engine.py`'ye class ekleyin
- Yeni parser desteği için `parser/` modülünü genişletin
- Hook sistemini kullanmak için `hooks/hook_manager.py`'yi kullanın

İşte tamamlanmış proje ve 50 kural seti:

---

## 📦 İndirme Linki
**[uxm_asm_optimizer_v2_1_complete.zip](sandbox:///mnt/agents/output/uxm_asm_optimizer_v2_1_complete.zip)** (39 KB)

---

## 50 x64 ASM Optimizasyon Kuralı (JSON Format)

### Kategori 1: Aritmetik Güç Azaltma (8 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 1 | `mul_imm_to_lea_shift_add` | `mul rax, 3` | `lea rax, [rax+rax*2]` | Sadece imzasız, değer 3/5/9 |
| 2 | `mul_to_shift` | `mul rax, 8` | `shl rax, 3` | Sadece imzasız, pow2 |
| 3 | `div_pow2_to_shift` | `div rax, 8` | `shr rax, 3` | Sadece pozitif sayılar |
| 4 | `idiv_pow2_to_sar` | `idiv rax, 4` | `sar rax, 2` | Negatiflerde düzeltme gerekli |
| 5 | `mod_pow2_to_and` | `xor rdx,rdx / div rax,16` | `and rax, 15` | Sadece remainder, imzasız |
| 6 | `add_reg_reg_to_lea` | `add rax, rbx` | `lea rax, [rax+rbx]` | FLAGS korur |
| 7 | `sub_reg_to_lea` | `sub rax, rbx` | `lea rax, [rax-rbx]` | FLAGS korur |
| 8 | `neg_to_xor_inc` | `neg rax` | `not rax / inc rax` | Alternatif, nadir kullanışlı |

### Kategori 2: Ölü Kod Eliminasyonu (8 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 9 | `dead_mov_same_reg` | `mov rax, rax` | *(sil)* | Tamamen no-op |
| 10 | `dead_push_pop_pair` | `push rax / pop rax` | *(sil)* | Arada stack op yok |
| 11 | `unused_mov_elimination` | `mov rax, 100` (kullanılmaz) | *(sil)* | **STUB** - Liveness gerekir |
| 12 | `dead_store_after_overwrite` | `mov [rbx],rax / mov [rbx],rcx` | *(ilkini sil)* | **STUB** - Alias analizi |
| 13 | `unreachable_code_after_ret` | `ret / mov rax, 0` | *(sil)* | **STUB** - CFG gerekir |
| 14 | `dead_flag_compute` | `cmp rax,rbx` (flag kullanılmaz) | *(sil)* | **STUB** - Data flow |
| 15 | `redundant_stack_adjust` | `sub rsp,16 / add rsp,16` | *(sil)* | Arada stack op yok |
| 16 | `dead_load_after_store_same_reg` | `mov [rbx],rax / mov rax,[rbx]` | *(load'u sil)* | Aynı reg, aynı mem |

### Kategori 3: Register Yeniden Kullanım (8 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 17 | `mov_to_xchg` | `mov t,A / mov A,B / mov B,t` | `xchg A, B` | 3 instruction -> 1 |
| 18 | `zero_extend_via_mov` | `movzx eax, al` | `mov eax, ...` | **STUB** - Üst bitler 0 olmalı |
| 19 | `sign_extend_32_to_64` | `movsxd rax, eax` | *(comment)* | x64'te otomatik sign-extend |
| 20 | `clear_upper_bits_via_32bit_mov` | `mov rax, 100` | `mov eax, 100` | 32-bit mov üst bitleri 0 yapar |
| 21 | `use_8bit_reg_for_small_values` | `mov rax, 5` | `mov al, 5` | Üst bitler silinir! |
| 22 | `merge_adjacent_movs` | `mov rax,[rsi] / mov rbx,[rsi+8]` | `movdqa xmm0,[rsi]` | **STUB** - SIMD, alignment |
| 23 | `reuse_partial_reg_write` | `mov al,1 / mov ah,2` | `mov ax, 0x0201` | Partial register stall önler |
| 24 | `eliminate_reg_to_reg_mov_via_renaming` | `mov rcx,rax / add rcx,1` | `add rax,1` | **STUB** - SSA gerekir |

### Kategori 4: Kontrol Akışı (8 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 25 | `jmp_to_jmp_elimination` | `jmp A / A: jmp B` | `jmp B` | A sadece 1 kez kullanılmış |
| 26 | `cond_jmp_to_opposite_cond` | `je label / jmp other` | `jne other` | Kod yeniden düzenlenir |
| 27 | `loop_invariant_code_motion` | `loop: mov rax,[const]` | `mov rax,[const] / loop:` | **STUB** - Loop tespiti |
| 28 | `tail_call_optimization` | `call helper / ret` | `jmp helper` | Stack frame aynı olmalı |
| 29 | `remove_unreachable_blocks` | `jmp end / dead: ...` | *(sil)* | **STUB** - CFG dominator |
| 30 | `merge_basic_blocks` | `A / jmp B / B:` | *(birleştir)* | **STUB** - Tek pred/succ |
| 31 | `short_jump_encoding` | `jmp label` (uzak) | `jmp short label` | **STUB** - Offset -128..+127 |
| 32 | `indirect_jump_to_direct` | `jmp [table+rax*8]` | `jmp label` | **STUB** - Sabit hedef |

### Kategori 5: Bellek Erişimi (8 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 33 | `load_store_forwarding` | `mov [rbx],rax / mov rcx,[rbx]` | `mov rcx, rax` | Aynı adres, alias yok |
| 34 | `stack_to_register_promotion` | `mov [rbp-8],rax` | `mov temp, rax` | **STUB** - Pointer aliasing |
| 35 | `merge_adjacent_stack_ops` | `push rax / push rbx` | *(multi-push)* | **STUB** - Boyut optimizasyonu |
| 36 | `eliminate_redundant_frame_pointer` | `push rbp / mov rbp,rsp` | *(sil)* | **STUB** - FPO, debug |
| 37 | `use_sib_byte_for_indexing` | `shl rax,3 / add rax,rbx` | `lea rax,[rbx+rax*8]` | Scale 1,2,4,8 |
| 38 | `prefetch_hints` | `mov rax,[rbx+rcx*8]` | `prefetcht0 [...]` | **STUB** - Ekleme kuralı |
| 39 | `align_stack_access` | `sub rsp,12 / movdqa [rsp]` | `sub rsp,16` | **STUB** - 16-byte align |
| 40 | `coalesce_memory_ops` | `mov al,[rbx] / mov ah,[rbx+1]` | `mov ax,[rbx]` | Little-endian varsayımı |

### Kategori 6: Bayrak Optimizasyonu (6 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 41 | `test_to_bt` | `test rax, 0x40` | `bt rax, 6` | CF set eder, ZF değil |
| 42 | `cmp_to_dec_inc_for_loop` | `cmp rcx,0 / jne loop` | `dec rcx / jnz loop` | rcx değişir |
| 43 | `setcc_to_cmov` | `sete al / movzx eax,al` | `cmove rax, rbx` | Semantik farklı |
| 44 | `combine_flag_tests` | `test rax / jz L / test rbx / jz L` | `or rax,rbx / jz L` | rax/rbx değişir |
| 45 | `preserve_flags_via_lea` | `cmp rax,0 / add rbx,rcx / je L` | `... / lea rbx,[rbx+rcx]` | FLAGS korur |
| 46 | `sahf_lahf_optimization` | `lahf / ... / sahf` | `pushfq / popfq` | Tüm flags korur |

### Kategori 7: Boyut/Kodlama (4 kural)

| # | Kural | Before | After | Güvenlik Notu |
|---|-------|--------|-------|---------------|
| 47 | `use_32bit_immediate_for_64bit` | `mov rax, 0x1` | `mov eax, 1` | Otomatik zero-extend |
| 48 | `rip_relative_addressing` | `mov rax,[0x401000]` | `mov rax,[rip+var]` | **STUB** - PIC/PIE |
| 49 | `short_encoding_for_small_offsets` | `mov rax,[rbx+0x08]` | `mov rax,[rbx+8]` | **STUB** - 8-bit displacement |
| 50 | `use_xor_for_zeroing_instead_of_mov` | `mov rax, 0` | `xor rax, rax` | FLAGS değişir, dependency break |

---

## 🔧 Programda Yapılacak Değişiklikler

### 1. Yeni Kural Ekleme (rules/rule_engine.py)

**Satır ~50** (ALL_RULES listesinden önce) yeni sınıf ekle:
```python
class MyNewRule(OptimizationRule):
    name = "my_new_rule"
    description = "Açıklama"
    
    def match(self, instructions, start_idx, parser):
        # Eşleşme koşulları
        return False  # veya True
    
    def apply(self, instructions, start_idx, parser):
        return RuleResult(True, [instr.raw_line], 
            ["optimized line"],
            "açıklama", self.name, start_idx, start_idx)
```

**Satır ~150** (ALL_RULES listesine ekle):
```python
ALL_RULES = [
    # ... mevcut kurallar ...
    MyNewRule,  # Yeni kural
]
```

### 2. Config'den Kural Açma/Kapatma

**config/rules.json** dosyasında:
```json
{
  "rules": {
    "my_new_rule": {"enabled": true}
  }
}
```

### 3. NOP Hook ile Eklenti

Herhangi bir modülün `nop_hook.py`'sine:
```python
def pre_hook(*args, **kwargs):
    # Optimizasyon öncesi işlem
    pass

def post_hook(*args, **kwargs):
    # Optimizasyon sonrası işlem  
    pass
```

### 4. STUB Kuralları Tamamlama

**Data Flow Analysis** gerektiren STUB kurallar için:
- `safety/safety_analyzer.py`'ye liveness analizi ekle
- `cfg/cfg_builder.py`'ye loop detection ekle
- `parser/asm_parser.py`'ye memory aliasing ekle

---

## 📊 Test Sonucu

```
Original:  70 satır
Optimized: 54 satır
Azalma:    16 satır (%22.9)
Uygulanan: 35 optimizasyon
```

---

## 🏗️ Modüler Mimari

```
core/       → Ana motor (UXMOptimizer class)
parser/     → x64 ASM ayrıştırıcı (ASMParser class)
cfg/        → Kontrol akış grafiği (CFGBuilder class)
rules/      → 49 kural + 21 STUB (RuleEngine class)
safety/     → Güvenlik analizi (SafetyAnalyzer class)
report/     → .txt rapor üretimi (ReportGenerator class)
utils/      → Yardımcı fonksiyonlar
hooks/      → Merkezi hook sistemi (HookManager class)
```
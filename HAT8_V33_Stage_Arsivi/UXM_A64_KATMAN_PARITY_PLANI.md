# UXM-A64 Katman Parity Planı

Amaç, compiler/interpreter/runtime/VSCode/test katmanlarının aynı mimari seviyede ilerlemesini sağlamaktır. Bu belge, v2 builder sonrası yapılması gereken mimari eşitleme işlerini sıralar.

## 1. Parity ilkesi

Bir komut veya servis gerçek kabul edilecekse şu katmanlarda izi olmalıdır:

```text
1. Kılavuz / servis registry
2. Native parser / meta parser
3. Native ASM emitter
4. Runtime dispatch
5. Runtime servis implementasyonu
6. Interpreter AST/parser desteği veya bilinçli unsupported kaydı
7. VSCode syntax/hover/snippet desteği
8. Test: .uxm + .expect
9. Gate raporu
```

Bu katmanlardan biri eksikse komut “tam parity” sayılmaz.

## 2. UXM-A64 için mevcut otoriteler

```text
Klasör mimarisi: 52 V20 src
Native compiler: 13 Stage12 compiler/native split dosyaları
Runtime servisleri: 52 V20 runtime + V18/V19 servis dosyaları
VSCode kaynak: 52 V20 extension.ts
VSCode release artifact: 39 V15 vscode dizini
Test: 24 final expected + Stage12 tests + V19 stage24 tests
Gate: 47/51 V20 release gate + 50 V22 komut onarımı + yeni A64 gate scriptleri
```

## 3. Katman açıkları

### 3.1 Native compiler ↔ runtime parity

Native compiler, gelişmiş adresleme ve meta çağrıları üretebiliyor. Runtime tarafında servisler geniş; fakat registry/dispatch/kılavuz eşleştirmesi otomatik gate ile karşılaştırılmalıdır.

Gereken program:

```text
tools/uxm_a64_service_parity_gate.py
```

Bu araç sonraki hamlede şunları karşılaştırmalı:

```text
shared/uxm_v20_service_registry.bi
shared/uxm_v20_runtime_service_index.bas
runtime/runtime_meta_dispatch.bas
runtime/hooks/runtime_hook_dispatch_ext.bas
runtime/services/*.bas
```

### 3.2 Native parser ↔ AST/parser parity

V20 AST/parser katmanı minimaldir. Native compiler parserı daha gelişmiştir. Şimdilik karar:

```text
AST/parser = analiz ve interpreter bridge katmanı
Native compiler = gerçek compile otoritesi
```

Tam parity için AST node seti genişletilmelidir:

```text
UXM_AST_ADDR_OP
UXM_AST_META_ADDR
UXM_AST_BRANCH
UXM_AST_MACRO_DEF
UXM_AST_MACRO_CALL
UXM_AST_PRAGMA_MEMORY
UXM_AST_PRAGMA_CELL
UXM_AST_PRAGMA_MODE
UXM_AST_STRING_DEF
UXM_AST_DATA_OP
UXM_AST_STACK_OP
```

### 3.3 MIR/HIR parity

Gerçek MIR/HIR katmanı eldeki ziplerde tamamlanmış dosya olarak yok. Bu yüzden builder MIR/HIR varmış gibi davranmamalı. Doğru yol:

```text
src/compiler/hir/uxm_hir_types.bi
src/compiler/hir/uxm_hir_from_ast.bas
src/compiler/mir/uxm_mir_types.bi
src/compiler/mir/uxm_mir_from_hir.bas
src/compiler/mir/uxm_mir_to_native.bas
```

Ancak bu dosyalar şu an üretim compiler otoritesi yapılmamalı; önce AST parity yükseltilmelidir.

### 3.4 Interpreter parity

Interpreter artık runtime adapter ile derlenebilir hat olmaya yaklaşır. Ama native parser paritesi yoktur. Interpreter sadece şu kapsamda final kabul edilmelidir:

```text
brainfuck temel sembolleri
@N temel meta çağrı
string print
loop
putc/getc
```

Gelişmiş adresleme, branch, macro, file/stat/matrix gibi konular interpreter için ayrı testlenmelidir.

### 3.5 VSCode parity

VSCode katmanı iki parçaya ayrılmalıdır:

```text
src/vscode/extension.ts              kaynak otoritesi
tools/vscode_release/...             kurulum artifact
```

Snippet ve syntax dosyaları registry/kılavuzdan otomatik güncellenmelidir. Elle yazılmış VSCode listeleri zamanla geride kalır.

## 4. Bir sonraki Python builder hedefi

v3 builder şunları eklemelidir:

```text
1. service_parity_gate.py
2. ast_native_parity_report.py
3. vscode_registry_sync.py
4. tests/a64_service_smoke otomatik seçimi
5. reports/UXM_A64_PARITY_MATRIX.csv
```

v2 builder derleme hattını toparlar. v3 builder parity matrisini kod gerçekliğiyle otomatik ölçmelidir.

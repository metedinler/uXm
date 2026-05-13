# UXM servis ve adresleme düzenleme raporu
## Ana teşhis
- Mevcut native parser `@N` için `0..255` sınırı koyuyor. Bu yüzden `@260`, `@360`, `@390`, `@400`, `@440` aileleri parser yaması olmadan çalışmaz.
- Kullanıcı makroları `m128..m255`; host servis çağrısı ile çakışırsa `@!N` kullanılmalı. Üretimde makro alanını `m128..m149` ile sınırlamak en güvenli ilk adımdır.
- `@130..@149` için kaynakta `MetaFlagsEndian` case blokları var, ama dispatcher sadece `150..159` aralığını oraya gönderiyor. Bunlar şu an erişilemez/bug durumunda.
- `@180..@199` matrix advanced için doğru alan; current dispatcher zaten `160..199` aralığını matrix ailesine gönderiyor. Sadece `MetaMatrix` içine ileri case eklemek gerekir.
- File I/O için iki paket varyantı var. Kanonik liste olarak `UXM_FILE_V1` içindeki `@400..@421` setini seçmek daha temizdir.

## Önerilen üretim servis haritası
- `0-19` → **core** / MetaCore / current
- `20-39` → **arithmetic** / MetaArithmetic / current
- `40-59` → **math** / MetaMath / current
- `60-79` → **io** / MetaIO / current
- `80-89` → **pointer_memory** / MetaPointerMemory / current
- `90-127` → **fifo_data_sort_wild** / MetaFifoDataSortWild / current
- `128-149` → **user_macro_safe_zone_or_flags_compare_bug** / macro/MetaFlagsEndian / conflict_design_decision
- `150-159` → **flags_endian** / MetaFlagsEndian / current
- `160-199` → **matrix** / MetaMatrix/UXMMatAdvancedDispatch / current_plus_patch
- `200-239` → **floating_point** / MetaFloatingPoint / current
- `240-254` → **math_extra** / MetaMathExtra / current
- `255` → **reserved** / none / reserved
- `260-356` → **statistics/correlation/regression/posthoc/ai** / MetaStatistics/MetaRegression/MetaAI / requires_meta_id_range_patch
- `360-369` → **probability_random** / MetaProbability / requires_meta_id_range_patch
- `390-401` → **numeric_methods** / MetaNumericMethods / requires_meta_id_range_patch
- `400-421` → **file_io** / MetaFileServices / requires_meta_id_range_patch
- `440-450` → **complex** / MetaComplex / requires_meta_id_range_patch

## Dikkat gerektiren kayıtlar
- `@130` **CMP_EQ_UNSIGNED** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@131` **CMP_GT_UNSIGNED** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@132` **CMP_LT_UNSIGNED** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@133` **CMP_EQ_SIGNED** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@134` **CMP_GT_SIGNED** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@135` **CMP_LT_SIGNED** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@140` **GET_CARRY_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@141` **SET_CARRY_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@142` **CLEAR_CARRY_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@143` **GET_OVERFLOW_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@144` **SET_OVERFLOW_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@145` **CLEAR_OVERFLOW_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@146` **GET_ZERO_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@147` **GET_SIGN_FLAG** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@148` **CLEAR_ZCOS_FLAGS** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@149` **FLAGS_GET_ALIAS** — unreachable_current_bug — Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed.
- `@260` **STAT_COUNT** — extension_requires_meta_id_range_patch — count values
- `@261` **STAT_SUM** — extension_requires_meta_id_range_patch — sum values
- `@262` **STAT_MEAN** — extension_requires_meta_id_range_patch — mean
- `@263` **STAT_MIN** — extension_requires_meta_id_range_patch — min
- `@264` **STAT_MAX** — extension_requires_meta_id_range_patch — max
- `@265` **STAT_RANGE** — extension_requires_meta_id_range_patch — max-min
- `@266` **STAT_VARIANCE** — extension_requires_meta_id_range_patch — sample variance
- `@267` **STAT_STDDEV** — extension_requires_meta_id_range_patch — sample stddev
- `@268` **STAT_MEDIAN** — extension_requires_meta_id_range_patch — median
- `@269` **STAT_MODE** — extension_requires_meta_id_range_patch — mode first
- `@270` **STAT_QUARTILE** — extension_requires_meta_id_range_patch — quartile placeholder
- `@271` **STAT_PERCENTILE** — extension_requires_meta_id_range_patch — percentile placeholder
- `@272` **STAT_SKEWNESS** — extension_requires_meta_id_range_patch — skewness placeholder
- `@273` **STAT_KURTOSIS** — extension_requires_meta_id_range_patch — kurtosis placeholder
- `@274` **STAT_COVARIANCE** — extension_requires_meta_id_range_patch — covariance
- `@275` **STAT_ZSCORE** — extension_requires_meta_id_range_patch — z score
- `@280` **CORR_PEARSON** — extension_requires_meta_id_range_patch — pearson r scaled
- `@281` **CORR_SPEARMAN** — extension_requires_meta_id_range_patch — spearman placeholder
- `@282` **CORR_KENDALL** — extension_requires_meta_id_range_patch — kendall placeholder
- `@290` **REG_LINEAR** — extension_requires_meta_id_range_patch — simple linear regression
- `@291` **REG_MULTIPLE** — extension_requires_meta_id_range_patch — reserved
- `@292` **REG_POLYNOMIAL** — extension_requires_meta_id_range_patch — reserved
- `@293` **REG_LOGISTIC** — extension_requires_meta_id_range_patch — reserved
- `@298` **REG_PREDICT** — extension_requires_meta_id_range_patch — predict y
- `@299` **REG_R2** — extension_requires_meta_id_range_patch — r squared
- `@300` **TTEST_ONE** — extension_requires_meta_id_range_patch — one sample t placeholder
- `@301` **TTEST_INDEPENDENT** — extension_requires_meta_id_range_patch — independent t placeholder
- `@302` **TTEST_PAIRED** — extension_requires_meta_id_range_patch — paired t placeholder
- `@303` **ZTEST_ONE** — extension_requires_meta_id_range_patch — one sample z placeholder
- `@304` **ZTEST_TWO** — extension_requires_meta_id_range_patch — two sample z placeholder
- `@305` **FTEST_VARIANCE** — extension_requires_meta_id_range_patch — f variance placeholder
- `@306` **ANOVA_ONEWAY** — extension_requires_meta_id_range_patch — oneway anova placeholder
- `@307` **ANOVA_TWOWAY** — extension_requires_meta_id_range_patch — reserved
- `@308` **CHI_SQUARE** — extension_requires_meta_id_range_patch — chi square placeholder
- `@309` **CHI_GOODNESS** — extension_requires_meta_id_range_patch — goodness placeholder
- `@320` **POSTHOC_TUKEY** — extension_requires_meta_id_range_patch — tukey placeholder
- `@321` **POSTHOC_DUNCAN** — extension_requires_meta_id_range_patch — duncan placeholder
- `@322` **POSTHOC_DUNNETT** — extension_requires_meta_id_range_patch — dunnett placeholder
- `@323` **POSTHOC_BONFERRONI** — extension_requires_meta_id_range_patch — bonferroni placeholder
- `@324` **POSTHOC_SCHEFFE** — extension_requires_meta_id_range_patch — scheffe placeholder
- `@325` **POSTHOC_LSD** — extension_requires_meta_id_range_patch — lsd placeholder
- `@340` **AI_NORMALIZE_MINMAX** — extension_requires_meta_id_range_patch — minmax normalize
- `@341` **AI_NORMALIZE_ZSCORE** — extension_requires_meta_id_range_patch — zscore normalize
- `@342` **AI_ONEHOT** — extension_requires_meta_id_range_patch — reserved
- `@343` **AI_TRAIN_TEST_SPLIT** — extension_requires_meta_id_range_patch — reserved
- `@344` **AI_SHUFFLE** — extension_requires_meta_id_range_patch — reserved
- `@345` **AI_CONFUSION_MATRIX** — extension_requires_meta_id_range_patch — confusion matrix placeholder
- `@346` **AI_ACCURACY** — extension_requires_meta_id_range_patch — accuracy
- `@347` **AI_PRECISION** — extension_requires_meta_id_range_patch — precision
- `@348` **AI_RECALL** — extension_requires_meta_id_range_patch — recall
- `@349` **AI_F1** — extension_requires_meta_id_range_patch — f1 score
- `@350` **AI_DISTANCE_EUCLIDEAN** — extension_requires_meta_id_range_patch — euclidean distance
- `@351` **AI_DISTANCE_COSINE** — extension_requires_meta_id_range_patch — cosine distance placeholder
- `@352` **AI_KNN_BASIC** — extension_requires_meta_id_range_patch — reserved
- `@353` **AI_LINEAR_LAYER** — extension_requires_meta_id_range_patch — reserved
- `@354` **AI_SIGMOID** — extension_requires_meta_id_range_patch — sigmoid scaled
- `@355` **AI_RELU** — extension_requires_meta_id_range_patch — relu
- `@356` **AI_SOFTMAX** — extension_requires_meta_id_range_patch — reserved
- `@360` **RAND_SEED** — extension_requires_meta_id_range_patch — 
- `@361` **RAND_UNIFORM_01** — extension_requires_meta_id_range_patch — 
- `@362` **RAND_INT_RANGE** — extension_requires_meta_id_range_patch — 
- `@363` **RAND_NORMAL** — extension_requires_meta_id_range_patch — 
- `@364` **RAND_POISSON** — extension_requires_meta_id_range_patch — 
- `@365` **RAND_BINOMIAL** — extension_requires_meta_id_range_patch — 
- `@366` **RAND_WEIGHTED** — extension_requires_meta_id_range_patch — 
- `@367` **RAND_SECURE_BYTE** — extension_requires_meta_id_range_patch — 
- `@368` **RAND_BERNOULLI** — extension_requires_meta_id_range_patch — 
- `@369` **RAND_SHUFFLE_DATA** — extension_requires_meta_id_range_patch — 
- `@390` **NUM_NEWTON_RAPHSON** — extension_requires_meta_id_range_patch — 
- `@391` **NUM_BISECTION** — extension_requires_meta_id_range_patch — 
- `@392` **NUM_SECANT** — extension_requires_meta_id_range_patch — 
- `@393` **NUM_INTEGRAL_TRAPEZOID** — extension_requires_meta_id_range_patch — 
- `@394` **NUM_INTEGRAL_SIMPSON** — extension_requires_meta_id_range_patch — 
- `@395` **NUM_INTERPOLATE_LINEAR** — extension_requires_meta_id_range_patch — 
- `@396` **NUM_BEZIER_QUADRATIC** — extension_requires_meta_id_range_patch — 
- `@397` **NUM_RUNGE_KUTTA4_LINEAR** — extension_requires_meta_id_range_patch — 
- `@398` **NUM_ODE_INFO** — extension_requires_meta_id_range_patch — 
- `@399` **NUM_PDE_RESERVED** — extension_requires_meta_id_range_patch — 
- `@400` **FILE_OPEN_READ_TEXT** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@400` **NUM_SPLINE_RESERVED** — extension_requires_meta_id_range_patch — 
- `@401` **FILE_OPEN_WRITE_TEXT** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@401` **NUM_ADAPTIVE_INTEGRAL_RESERVED** — extension_requires_meta_id_range_patch — 
- `@402` **FILE_OPEN_APPEND_TEXT** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@403` **FILE_OPEN_BINARY_READ** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@404` **FILE_OPEN_BINARY_WRITE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@405` **FILE_CLOSE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@406` **FILE_READ_BYTE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@407` **FILE_WRITE_BYTE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@408` **FILE_READ_LINE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@409` **FILE_WRITE_LINE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@410` **FILE_READ_BLOCK** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@411` **FILE_WRITE_BLOCK** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@412` **FILE_SEEK** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@413` **FILE_TELL** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@414` **FILE_SIZE** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@415` **FILE_EXISTS** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@416` **FILE_DELETE_RESERVED** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@417` **FILE_RENAME_RESERVED** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@418` **FILE_MKDIR_RESERVED** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@419` **FILE_STATUS** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@420` **FILE_FLUSH** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@421` **FILE_OPEN_BINARY_APPEND** — extension_requires_meta_id_range_patch — Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical.
- `@440` **CPLX_INIT** — extension_requires_meta_id_range_patch — 
- `@441` **CPLX_ADD** — extension_requires_meta_id_range_patch — 

## VSCode tarafı
`commands.json` syntax renklendirme, snippet, hover ve lint için; `meta_services.json` ise `@N` servis autocomplete/hover ve çakışma uyarısı için kullanılmalı. Bunlar compiler runtime içine değil, `tools/vscode-uxm/schemas/` veya repo kökünde `config/uxm/` altına konmalı.

## Kod tarafında gerekli yama sırası
1. Registry dosyalarını repo içine ekle.
2. Parser `@N` üst sınırını 255 yerine en az 999 yap.
3. Dispatcher aralıklarını registry ile uyumlu hale getir.
4. `@130..@149` için karar ver: ya dispatcherı aç, ya case bloklarını 150+ alanına taşı, ya da macro-safe zone olarak bırak.
5. V32 adresleme patchlerini parser/interpreter/native ASM emitter üçlüsüne aynı anda uygula.
6. Testleri aile aile çalıştır: native, addressing, matrix, math, fp, file, stat, probability/numeric/complex.

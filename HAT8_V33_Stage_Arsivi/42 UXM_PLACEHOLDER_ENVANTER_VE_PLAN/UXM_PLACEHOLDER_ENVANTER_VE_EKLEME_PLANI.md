# UX-MINIMA x64 — Placeholder Envanteri ve Ekleme Planı

Bu rapor, kullanım kılavuzunda “placeholder” diye görünen servisleri ve mevcut UXMv33 kodunda/registry tablosunda gerçekten tamamlanmamış ya da eski taslaktan kalmış alanları ayırır.

## 1. Kısa sonuç

Kılavuzda yer alan bazı servisler gerçekten hesaplanmış/uygulanmış durumda değildir. Bazıları ise eski servis registry taslağında kalmış, güncel runtime dispatch adresleriyle uyuşmamaktadır.

En önemli düzeltme: Bu sürümde `@300..@319` hypothesis/t-test değil, **string servisleri**dir. `@340..@379` AI değil, **string-ext servisleri**dir. Bu yüzden hypothesis, posthoc ve AI servisleri bu adreslere eklenmemelidir; yeni ve boş bir servis bandına taşınmalıdır.

## 2. Rehberde açıkça placeholder yazan servisler

| Grup | Servisler | Durum | Not |
|---|---:|---|---|
| İstatistik ileri ölçüler | `@270 STAT_QUARTILE`, `@271 STAT_PERCENTILE`, `@272 STAT_SKEWNESS`, `@273 STAT_KURTOSIS` | Tamamlanmamış | `MetaStatistics` içinde case yok. |
| Sıralı korelasyon | `@281 CORR_SPEARMAN`, `@282 CORR_KENDALL` | Tamamlanmamış | Pearson var, Spearman/Kendall yok. |
| Hipotez testleri | Eski registry’de `@300..@309` | Yanlış adreste / tamamlanmamış | Güncel sistemde `@300..@319` string servisleridir. Yeni banda taşınmalı. |
| Posthoc testleri | Eski registry’de `@320..@325` | Dispatch dışı / tamamlanmamış | Güncel dispatch bu aralığı çağırmıyor. Yeni banda taşınmalı. |
| AI/metrik servisleri | Eski registry’de `@345`, `@351` vb. | Yanlış adreste / tamamlanmamış | Güncel sistemde `@340..@379` string-ext’tir. AI yeni banda taşınmalı. |

## 3. Kod/registry karşılaştırmasına göre eksik görünen servisler

Aşağıdaki liste “registry’de var ama güncel runtime case’i yok” veya “reserved/placeholder” olan başlıca alanları gösterir.

### 3.1 Matrix advanced eski bandı

`@180..@199` aralığı registry’de matrix advanced olarak geçiyor ama güncel runtime’da bu aralıkta case yok. Ancak güncel sistemde advanced matrix/tensor için yeni aralıklar kullanılıyor:

- `@512..@519` matrix/tensor advanced
- `@520..@539` linalg advanced
- `@540..@599` tensor/matrix advanced devamı
- `@600..@679` sparse/vector

Bu nedenle `@180..@199` ya tamamen legacy/reserved yapılmalı ya da yeni dispatch’e yönlendirilmemeli.

Eksik görünen eski servisler:

```text
@180 MAT_ND_INIT
@181 MAT_ND_GET
@182 MAT_ND_SET
@183 MAT_DET
@184 MAT_INVERSE
@185 MAT_LU
@186 MAT_QR
@187 MAT_RANK
@188 MAT_COND_EST
@189 MAT_EIG_POWER
@190 MAT_EIG_JACOBI_SYM
@191 MAT_SVD_SYM_HELPER
@192 MAT_SPARSE_CSR_INIT
@193 MAT_SPARSE_CSR_MV
@194 MAT_SPARSE_TO_DENSE
@195 MAT_DENSE_TO_SPARSE
@196 MAT_TRACE
@197 MAT_FROBENIUS
@198 MAT_NORM_INF
@199 MAT_ADV_INFO
```

### 3.2 Statistics/Regression eksikleri

Güncel çalışanlar:

```text
@260 COUNT
@261 SUM
@262 MEAN
@263 MIN
@264 MAX
@265 RANGE
@266 VARIANCE
@267 STDDEV
@268 MEDIAN
@274 COVARIANCE
@275 ZSCORE
@280 PEARSON
@290 LINEAR REGRESSION
@298 REG_PREDICT
@299 REG_R2
```

Eksik/placeholder:

```text
@269 MODE
@270 QUARTILE
@271 PERCENTILE
@272 SKEWNESS
@273 KURTOSIS
@281 SPEARMAN
@282 KENDALL
@291 MULTIPLE REGRESSION
@292 POLYNOMIAL REGRESSION
@293 LOGISTIC REGRESSION
```

### 3.3 Hipotez testleri

Eski registry’de `@300..@309` hipotez testleri gibi görünür. Bu **bu sürümde doğru değildir**, çünkü `@300..@319` string servislerine ayrılmıştır.

Yeni önerilen band:

```text
@760..@789 = hipotez testleri
```

Eklenecekler:

```text
@760 TTEST_ONE
@761 TTEST_INDEPENDENT
@762 TTEST_PAIRED
@763 ZTEST_ONE
@764 ZTEST_TWO
@765 FTEST_VARIANCE
@766 ANOVA_ONEWAY
@767 ANOVA_TWOWAY_RESERVED
@768 CHI_SQUARE
@769 CHI_GOODNESS
```

### 3.4 Posthoc testleri

Eski registry `@320..@325` diyordu. Güncel dispatch içinde bu aralık yok. Yeni önerilen band:

```text
@790..@809 = posthoc servisleri
```

Eklenecekler:

```text
@790 POSTHOC_TUKEY
@791 POSTHOC_DUNCAN
@792 POSTHOC_DUNNETT
@793 POSTHOC_BONFERRONI
@794 POSTHOC_SCHEFFE
@795 POSTHOC_LSD
```

### 3.5 AI/ML metrikleri

Eski registry’de `@340..@356` AI gibi görünüyordu. Bu **güncel sistemde yanlış adrestir**, çünkü `@340..@379` string-ext servisleridir.

Mevcut çalışan ML/Data pipeline bandı:

```text
@700..@759 = ML/Data Pipeline
```

Yeni önerilen AI metrics bandı:

```text
@810..@839 = AI metrics / classifier support
```

Eklenecekler:

```text
@810 AI_CONFUSION_MATRIX
@811 AI_ACCURACY
@812 AI_PRECISION
@813 AI_RECALL
@814 AI_F1
@815 AI_DISTANCE_EUCLIDEAN
@816 AI_DISTANCE_COSINE
@817 AI_KNN_BASIC
@818 AI_LINEAR_LAYER
@819 AI_SIGMOID
@820 AI_RELU
@821 AI_SOFTMAX
```

Not: bazıları `@700..@759` içinde kısmen varsa, yeni bandda alias değil gerçek final servis olarak düzenlenmeli veya registry’de tek kaynak haline getirilmeli.

### 3.6 Random/probability eski bandı

Registry’de `@360..@369` random/probability gibi duruyor ama güncel gerçek probability bandı:

```text
@380..@389
```

Bu nedenle `@360..@369` legacy/reserved yapılmalı. Güncel kullanılacak adresler:

```text
@380 RAND_SEED
@381 RAND_UNIFORM_01
@382 RAND_INT_RANGE
@383 RAND_BERNOULLI
@384 RAND_POISSON
@385 RAND_BINOMIAL
@386 RAND_WEIGHTED
@387 RAND_SHUFFLE_DATA
@388 RAND_NORMAL_SCALED
@389 RAND_STATUS
```

### 3.7 Numeric eski bandı

Registry’de `@390..@399` numeric görünüyor ama güncel gerçek numeric methods bandı:

```text
@420..@439
```

Bu nedenle `@390..@399` legacy/reserved yapılmalı ya da bilinçli alias olarak bağlanmalı. Rastgele alias eklemek önerilmez.

### 3.8 File servisleri eksikleri

Çalışanlar ağırlıklı olarak `@400..@409`, `@413`, `@414`, `@415`, `@420`, `@421` civarında. Eksik görünenler:

```text
@410 FILE_READ_BLOCK
@411 FILE_WRITE_BLOCK
@412 FILE_SEEK
@416 FILE_DELETE_RESERVED
@417 FILE_RENAME_RESERVED
@418 FILE_MKDIR_RESERVED
@419 FILE_STATUS
```

Burada dikkat: `@420..@439` numeric methods ile çakışma riski vardır. Dosya servisleri `@400..@419` içinde tutulmalı, `@420+` numeric’e bırakılmalıdır.

### 3.9 Complex eksik

```text
@450 CPLX_PRINT_RESERVED
```

Çözüm: complex yazdırma servisinin mi ekleneceğine, yoksa print işinin mevcut print/meta servislerine mi bırakılacağına karar verilmeli.

## 4. UX-Minima’ya ekleme planı

### Faz 1 — Registry temizliği

Amaç: Dokümantasyon, registry ve dispatch aynı dili konuşsun.

Yapılacaklar:

1. `service_registry_merged.csv` yeniden üretilecek.
2. `@300..@319` yalnız string olarak işaretlenecek.
3. `@340..@379` yalnız string-ext olarak işaretlenecek.
4. Eski hypothesis/AI satırları yeni banda taşınacak.
5. `reserved`, `legacy`, `implemented`, `planned`, `placeholder` statüleri ayrı kolon yapılacak.

Çıktı:

```text
uxm_registry_output/service_registry_v34_clean.csv
uxm_registry_output/service_registry_v34_clean.json
reports/SERVICE_REGISTRY_CLEANUP_REPORT.md
```

### Faz 2 — Statistics advanced

Önce istatistik ileri fonksiyonları tamamlanmalı.

Dosya:

```text
uxm/core/runtime/services/runtime_statistics_services.bas
```

Eklenecek fonksiyonlar:

```text
StatMode
StatPercentile
StatQuartile
StatSkewness
StatKurtosis
StatSpearman
StatKendall
```

Eklenecek case’ler:

```text
@269, @270, @271, @272, @273, @281, @282
```

Testler:

```text
uxm/tests/stage21_statistics_advanced/
```

### Faz 3 — Hypothesis services

Yeni dosya:

```text
uxm/core/runtime/services/runtime_hypothesis_services.bas
```

Dispatch:

```text
@760..@789 -> MetaHypothesis
```

Eklenecekler:

```text
TTEST_ONE, TTEST_INDEPENDENT, TTEST_PAIRED
ZTEST_ONE, ZTEST_TWO
FTEST_VARIANCE
ANOVA_ONEWAY
CHI_SQUARE, CHI_GOODNESS
```

İlk sürümde p-value tam dağılım hesabı yerine güvenli olarak şunlar verilebilir:

```text
test statistic scaled
df
status
```

Sonra dağılım/p-value yaklaşımı eklenir.

### Faz 4 — Posthoc services

Yeni dosya:

```text
uxm/core/runtime/services/runtime_posthoc_services.bas
```

Dispatch:

```text
@790..@809 -> MetaPosthoc
```

İlk gerçek sürüm:

```text
Tukey HSD için q yerine konservatif fark/eşik hesabı
Bonferroni düzeltmesi
LSD fark testi
```

Duncan/Dunnett/Scheffe daha sonra ama placeholder olarak değil, reserved olarak işaretlenmeli.

### Faz 5 — AI metrics

Yeni dosya:

```text
uxm/core/runtime/services/runtime_ai_metrics_services.bas
```

Dispatch:

```text
@810..@839 -> MetaAIMetrics
```

Eklenecekler:

```text
confusion matrix
accuracy
precision
recall
f1
euclidean distance
cosine distance
```

Veri düzeni:

```text
DATA[y_true_start ..]
DATA[y_pred_start ..]
count
class_count
out_base
```

### Faz 6 — File block/seek/status

Dosya:

```text
uxm/core/runtime/services/runtime_file_services.bas
```

Eklenecekler:

```text
@410 FILE_READ_BLOCK
@411 FILE_WRITE_BLOCK
@412 FILE_SEEK
@416 FILE_DELETE
@417 FILE_RENAME
@418 FILE_MKDIR
@419 FILE_STATUS
```

Güvenlik:

1. path sandbox opsiyonel olmalı.
2. hata kodları status’a yazılmalı.
3. block read/write DATA veya TAPE buffer ile çalışmalı.

### Faz 7 — Test ve dokümantasyon kapısı

Her faz için:

```text
stage21_statistics_advanced
stage22_hypothesis
stage23_posthoc
stage24_ai_metrics
stage25_file_block
```

Her stage için:

1. sadece o stage testleri,
2. her servis için tek test,
3. en az iki birleşik kullanım testi,
4. Türkçe ve İngilizce komut betikleri,
5. registry ve kılavuz güncellemesi.

## 5. Kılavuz düzeltme planı

Kılavuzda “placeholder” yazan servisler öğrenciye gerçek hesaplanıyor gibi anlatılmamalı. Her servis için üç durum kullanılmalı:

| Durum | Anlamı |
|---|---|
| Çalışıyor | Runtime dispatch ve test var. |
| Kısmi | Case var ama algoritma sınırlı veya test az. |
| Planlandı | Registry/tasarım var ama runtime yok. |

Yeni kılavuzda servis tablosu böyle düzenlenmeli:

```text
Servis No | Ad | Durum | Dosya | Test | Örnek
```

## 6. Öncelik sırası

1. Registry temizliği.
2. `@269..@282` statistics advanced.
3. Hypothesis yeni bandı `@760..@789`.
4. AI metrics yeni bandı `@810..@839`.
5. File block/seek/status.
6. Posthoc.
7. Kılavuz güncellemesi.

## 7. Net uyarı

Bu rapor “hepsi zaten hesaplanıyor” demez. Aksine, placeholder görünenlerin bir bölümü gerçekten hesaplanmıyor; bir bölümü ise yanlış/legacy servis adresinde görünüyor. Bunlar UX-Minima’ya bilinçli stage paketleri halinde eklenmelidir.

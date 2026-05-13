# Bölüm 8 — Floating Point, İstatistik, Olasılık, Sayısal Yöntem ve Bilimsel Servisler

Bilimsel programlama için UXM’de hesaplama servisleri kullanılır. Floating point servisleri ondalıklı sayı davranışını, istatistik servisleri ortalama/medyan/varyans gibi özetleri, regression servisleri model kurmayı, probability servisleri olasılık ve random işlemlerini, numeric servisleri türev/integral gibi sayısal yöntemleri taşır.

UXM’de bilimsel servislerin amacı `SIN`, `MEAN`, `REGRESSION` gibi kelimeleri doğrudan dil çekirdeğine eklemek değildir. Bunun yerine küçük çekirdek korunur, büyük iş runtime servislerine verilir. Bu sayede compiler sade kalır, runtime genişler.

## Bilimsel servis aileleri

| ID | Ad | Aile | Frame | Sonuç | Not |
|---|---|---|---|---|---|
| 160 | MAT_INIT | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 161 | MAT_CLEAR | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 162 | MAT_SET | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 163 | MAT_GET | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 164 | MAT_FILL | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 165 | MAT_COPY | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 166 | MAT_PRINT | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 167 | MAT_ADD | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 168 | MAT_SUB | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 169 | MAT_SCALAR_MUL | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 170 | MAT_MUL | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 171 | MAT_TRANSPOSE_COPY | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 172 | MAT_IDENTITY | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 173 | MAT_TRACE | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 174 | MAT_SHAPE | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 175 | MAT_DET2 | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 176 | MAT_PRINT_RAW | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 180 | MAT_ND_INIT | matrix_adv | T-4 rows, T-3 cols, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 181 | MAT_ND_GET | matrix_adv | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 182 | MAT_ND_SET | matrix_adv | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 183 | MAT_DET | matrix_adv | T-4 A, T+1 determinant | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 184 | MAT_INVERSE | matrix_adv | T-4 A, T-2 OUT | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 185 | MAT_LU | matrix_adv | T-4 A, T-2 L, T-3 U | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 186 | MAT_QR | matrix_adv | T-4 A, T-2 Q, T-3 R | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 187 | MAT_RANK | matrix_adv | T-4 A, T+1 rank | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 188 | MAT_COND_EST | matrix_adv | T-4 A, T-2 temp inverse, T+1 cond | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 189 | MAT_EIG_POWER | matrix_adv | T-4 A, T-2 vector out, T-1 iterations, T+1 lambda | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 190 | MAT_EIG_JACOBI_SYM | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 191 | MAT_SVD_SYM_HELPER | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 192 | MAT_SPARSE_CSR_INIT | matrix_adv | T-4 rows, T-3 cols, T-1 nnz, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 193 | MAT_SPARSE_CSR_MV | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 194 | MAT_SPARSE_TO_DENSE | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 195 | MAT_DENSE_TO_SPARSE | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 196 | MAT_TRACE | matrix_adv | T-4 A, T+1 trace | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 197 | MAT_FROBENIUS | matrix_adv | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 198 | MAT_NORM_INF | matrix_adv | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 199 | MAT_ADV_INFO | matrix_adv | prints info | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 200 | FP_INIT16 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 201 | FP_INIT32 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 202 | FP_ZERO | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 203 | FP_COPY | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 204 | FP_NORMALIZE_STORE | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 205 | FP_TO_INT | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 206 | FP_IS_ZERO | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 207 | FP_SIGN | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 208 | FP_ABS_TO_INT | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 209 | FP_PRINT_RAW | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 210 | FP_ADD | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 211 | FP_SUB | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 212 | FP_MUL | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 213 | FP_DIV | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 214 | FP_COMPARE | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 215 | FP_ABS | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 216 | FP_NEG | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 217 | FP_ROUND16 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 218 | FP_ROUND32 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 219 | FP_TRUNC | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 220 | FP_FROM_INT | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 221 | FP_FROM_DEC_STRING | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 222 | FP_TO_DEC_STRING | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 223 | FP_PRINT_DECIMAL | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 224 | FP_SCALE10 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 230 | FP_RESERVED_230 | floating_point | - | - | Reserved/invalid in current source. |
| 231 | FP_RESERVED_231 | floating_point | - | - | Reserved/invalid in current source. |
| 232 | FP_RESERVED_232 | floating_point | - | - | Reserved/invalid in current source. |
| 233 | FP_RESERVED_233 | floating_point | - | - | Reserved/invalid in current source. |
| 234 | FP_RESERVED_234 | floating_point | - | - | Reserved/invalid in current source. |
| 240 | POLY_DERIVATIVE | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 241 | POLY_INTEGRAL | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 242 | POLY_EVAL | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 243 | POLY_PRINT | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 244 | POLY_CLEAR | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 250 | EXPR_RPN_EVAL | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 251 | NUM_DERIV | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 252 | INTEGRAL_TRAPEZOID | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 253 | INTEGRAL_SIMPSON | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 254 | EXPR_RPN_PRINT | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 260 | STAT_COUNT | statistics | - | T+1/status | count values |
| 261 | STAT_SUM | statistics | - | T+1/status | sum values |
| 262 | STAT_MEAN | statistics | - | T+1/status | mean |
| 263 | STAT_MIN | statistics | - | T+1/status | min |
| 264 | STAT_MAX | statistics | - | T+1/status | max |
| 265 | STAT_RANGE | statistics | - | T+1/status | max-min |
| 266 | STAT_VARIANCE | statistics | - | T+1/status | sample variance |
| 267 | STAT_STDDEV | statistics | - | T+1/status | sample stddev |
| 268 | STAT_MEDIAN | statistics | - | T+1/status | median |
| 269 | STAT_MODE | statistics | - | T+1/status | mode first |
| 270 | STAT_QUARTILE | statistics | - | T+1/status | quartile placeholder |
| 271 | STAT_PERCENTILE | statistics | - | T+1/status | percentile placeholder |
| 272 | STAT_SKEWNESS | statistics | - | T+1/status | skewness placeholder |
| 273 | STAT_KURTOSIS | statistics | - | T+1/status | kurtosis placeholder |
| 274 | STAT_COVARIANCE | statistics | - | T+1/status | covariance |
| 275 | STAT_ZSCORE | statistics | - | T+1/status | z score |
| 280 | CORR_PEARSON | correlation | - | T+1/status | pearson r scaled |
| 281 | CORR_SPEARMAN | correlation | - | T+1/status | spearman placeholder |
| 282 | CORR_KENDALL | correlation | - | T+1/status | kendall placeholder |
| 290 | REG_LINEAR | regression | - | T+1/status | simple linear regression |
| 291 | REG_MULTIPLE | regression | - | T+1/status | reserved |
| 292 | REG_POLYNOMIAL | regression | - | T+1/status | reserved |
| 293 | REG_LOGISTIC | regression | - | T+1/status | reserved |
| 298 | REG_PREDICT | regression | - | T+1/status | predict y |
| 299 | REG_R2 | regression | - | T+1/status | r squared |
| 300 | TTEST_ONE | hypothesis | - | T+1/status | one sample t placeholder |
| 301 | TTEST_INDEPENDENT | hypothesis | - | T+1/status | independent t placeholder |
| 302 | TTEST_PAIRED | hypothesis | - | T+1/status | paired t placeholder |
| 303 | ZTEST_ONE | hypothesis | - | T+1/status | one sample z placeholder |
| 304 | ZTEST_TWO | hypothesis | - | T+1/status | two sample z placeholder |
| 305 | FTEST_VARIANCE | hypothesis | - | T+1/status | f variance placeholder |
| 306 | ANOVA_ONEWAY | hypothesis | - | T+1/status | oneway anova placeholder |
| 307 | ANOVA_TWOWAY | hypothesis | - | T+1/status | reserved |
| 308 | CHI_SQUARE | hypothesis | - | T+1/status | chi square placeholder |
| 309 | CHI_GOODNESS | hypothesis | - | T+1/status | goodness placeholder |
| 320 | POSTHOC_TUKEY | posthoc | - | T+1/status | tukey placeholder |
| 321 | POSTHOC_DUNCAN | posthoc | - | T+1/status | duncan placeholder |
| 322 | POSTHOC_DUNNETT | posthoc | - | T+1/status | dunnett placeholder |
| 323 | POSTHOC_BONFERRONI | posthoc | - | T+1/status | bonferroni placeholder |
| 324 | POSTHOC_SCHEFFE | posthoc | - | T+1/status | scheffe placeholder |
| 325 | POSTHOC_LSD | posthoc | - | T+1/status | lsd placeholder |
| 340 | AI_NORMALIZE_MINMAX | ai | - | T+1/status | minmax normalize |
| 341 | AI_NORMALIZE_ZSCORE | ai | - | T+1/status | zscore normalize |
| 342 | AI_ONEHOT | ai | - | T+1/status | reserved |
| 343 | AI_TRAIN_TEST_SPLIT | ai | - | T+1/status | reserved |
| 344 | AI_SHUFFLE | ai | - | T+1/status | reserved |
| 345 | AI_CONFUSION_MATRIX | ai | - | T+1/status | confusion matrix placeholder |
| 346 | AI_ACCURACY | ai | - | T+1/status | accuracy |
| 347 | AI_PRECISION | ai | - | T+1/status | precision |
| 348 | AI_RECALL | ai | - | T+1/status | recall |
| 349 | AI_F1 | ai | - | T+1/status | f1 score |
| 350 | AI_DISTANCE_EUCLIDEAN | ai | - | T+1/status | euclidean distance |
| 351 | AI_DISTANCE_COSINE | ai | - | T+1/status | cosine distance placeholder |
| 352 | AI_KNN_BASIC | ai | - | T+1/status | reserved |
| 353 | AI_LINEAR_LAYER | ai | - | T+1/status | reserved |
| 354 | AI_SIGMOID | ai | - | T+1/status | sigmoid scaled |
| 355 | AI_RELU | ai | - | T+1/status | relu |
| 356 | AI_SOFTMAX | ai | - | T+1/status | reserved |
| 360 | RAND_SEED | probability | - | T+1/status | - |
| 361 | RAND_UNIFORM_01 | probability | - | T+1/status | - |
| 362 | RAND_INT_RANGE | probability | - | T+1/status | - |
| 363 | RAND_NORMAL | probability | - | T+1/status | - |
| 364 | RAND_POISSON | probability | - | T+1/status | - |
| 365 | RAND_BINOMIAL | probability | - | T+1/status | - |
| 366 | RAND_WEIGHTED | probability | - | T+1/status | - |
| 367 | RAND_SECURE_BYTE | probability | - | T+1/status | - |
| 368 | RAND_BERNOULLI | probability | - | T+1/status | - |
| 369 | RAND_SHUFFLE_DATA | probability | - | T+1/status | - |
| 390 | NUM_NEWTON_RAPHSON | numeric | - | T+1/status | - |
| 391 | NUM_BISECTION | numeric | - | T+1/status | - |
| 392 | NUM_SECANT | numeric | - | T+1/status | - |
| 393 | NUM_INTEGRAL_TRAPEZOID | numeric | - | T+1/status | - |
| 394 | NUM_INTEGRAL_SIMPSON | numeric | - | T+1/status | - |
| 395 | NUM_INTERPOLATE_LINEAR | numeric | - | T+1/status | - |
| 396 | NUM_BEZIER_QUADRATIC | numeric | - | T+1/status | - |
| 397 | NUM_RUNGE_KUTTA4_LINEAR | numeric | - | T+1/status | - |
| 398 | NUM_ODE_INFO | numeric | - | T+1/status | - |
| 399 | NUM_PDE_RESERVED | numeric | - | T+1/status | - |
| 400 | NUM_SPLINE_RESERVED | numeric | - | T+1/status | - |
| 401 | NUM_ADAPTIVE_INTEGRAL_RESERVED | numeric | - | T+1/status | - |
| 440 | CPLX_INIT | complex | - | T+1/status | - |
| 441 | CPLX_ADD | complex | - | T+1/status | - |
| 442 | CPLX_SUB | complex | - | T+1/status | - |
| 443 | CPLX_MUL | complex | - | T+1/status | - |
| 444 | CPLX_DIV | complex | - | T+1/status | - |
| 445 | CPLX_CONJ | complex | - | T+1/status | - |
| 446 | CPLX_ABS | complex | - | T+1/status | - |
| 447 | CPLX_ARG | complex | - | T+1/status | - |
| 448 | CPLX_EXP | complex | - | T+1/status | - |
| 449 | CPLX_FROM_POLAR | complex | - | T+1/status | - |
| 450 | CPLX_PRINT_RESERVED | complex | - | T+1/status | - |


## Örnek düşünme: bilimsel hesap

Diyelim ki bir deneyde 5 ölçümün ortalamasını bulacaksın. BASIC’te `FOR` döngüsüyle toplar, bölersin. UXM’de ölçümleri data alanına koyarsın, ilgili istatistik servisine başlangıç adresi ve uzunluk verirsin, sonucu tape veya data alanından alırsın.

Pseudo-code:

```text
DATA[0..4] = ölçümler
T-2 = başlangıç adresi
T-1 = eleman sayısı
@MEAN servis çağrısı
sonuç = T+1
```

Bu yapı, UXM’de yüksek seviyeli bilimsel işlemlerin bile bellek ve servis ABI üzerinden düşünülmesini sağlar.

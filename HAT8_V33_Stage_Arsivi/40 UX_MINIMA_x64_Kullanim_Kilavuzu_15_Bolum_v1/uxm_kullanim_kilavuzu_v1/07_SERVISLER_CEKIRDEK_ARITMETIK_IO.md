# Bölüm 7 — Çekirdek, Aritmetik, Matematik ve I/O Servisleri

UXM servisleri `@N` biçiminde çağrılır. Servis numarası runtime dispatch tablosunda bir fonksiyona bağlanır. Bu bölüm çekirdek, aritmetik, temel matematik, I/O, pointer/memory, FIFO/data ve flag servislerini anlatır. Servislerin ayrıntılı tam tablosu Bölüm 14’tedir.

Servis kullanırken üç soruyu sor: “Servis hangi hücrelerden argüman bekliyor?”, “Sonucu nereye koyuyor?”, “Status/flag değiştiriyor mu?” Registry’de `frame` ve `result` alanları bunun içindir.

## Örnek: toplama servisi

```uxm
#cell dword
#memory tape=1mb,data=1mb

; T-2 ve T-1 alanlarına argüman koyduğunu düşün.
; @20 ADD servisi sonucu T+1 alanına yazar.
@20
```

Gerçek programda bu argümanları hazırlamak için tape hareketleri, adresleme veya data servisleri kullanılır.

## Çekirdek ailelerin servis tablosu

| ID | Ad | Aile | Frame | Sonuç | Not |
|---|---|---|---|---|---|
| 0 | NOP_STATUS_OK | core | - | - | Set status OK |
| 1 | CLS | core | - | - | Clear screen |
| 2 | LOCATE_HOME | core | - | - | Locate 1,1 |
| 3 | RANDOM_BYTE | core | - | - | T+1=random byte |
| 4 | TIMER_MS | core | - | - | T+1=timer ms masked |
| 5 | NEWLINE | core | - | - | Print newline |
| 6 | PRINT_META_PREFIX | core | - | - | Print [UXM META] |
| 7 | CONST_7 | core | - | - | T+1=7 |
| 8 | CONST_8 | core | - | - | T+1=8 |
| 9 | GET_STATUS | core | - | - | T+1=ux_status |
| 10 | STATUS_OK | core | - | - | Set status OK |
| 11 | SET_STATUS_ARG1 | core | - | - | status=Arg1 low byte |
| 12 | PRINT_STATUS | core | - | - | Print status message |
| 13 | STATUS_ASSERT_NONZERO | core | - | - | If status OK set 1 else keep |
| 14 | CLEAR_STATUS | core | - | - | Set status OK |
| 15 | GET_ERROR_FLAG | core | - | - | T+1=1 if FLAG_ERR else 0 |
| 20 | ADD | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 21 | SUB | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 22 | MUL | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 23 | DIV | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 24 | MOD | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 25 | MIN | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 26 | MAX | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 27 | ABS_ARG2 | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 28 | NEG_ARG2 | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 29 | CMP | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 30 | RANDOM_INT_RANGE | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 31 | RANDOM_SEED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 32 | RANDOM_SCALED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 33 | DIV_UNSIGNED_ALIAS | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 34 | DIV_SIGNED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 35 | MOD_UNSIGNED_ALIAS | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 36 | MOD_SIGNED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 40 | SIN_SCALED_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 41 | COS_SCALED_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 42 | TAN_SCALED_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 43 | HYPOTENUSE | math | Arg1/Arg2 depending service | T+1=result | - |
| 44 | ASIN_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 45 | ACOS_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 46 | SQRT | math | Arg1/Arg2 depending service | T+1=result | - |
| 47 | SINH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 48 | COSH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 49 | TANH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 52 | ASINH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 53 | ACOSH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 54 | ATANH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 55 | LN_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 56 | EXP_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 57 | POWER | math | Arg1/Arg2 depending service | T+1=result | - |
| 58 | DEG_TO_RAD_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 59 | RAD_TO_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 60 | PRINT_ARG2_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 61 | PRINT_RESULT_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 62 | PRINT_STACK_POP_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 63 | READ_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 64 | PRINT_SPACE | io | Arg2/result/stack depending service | printed or T+1 | - |
| 67 | PRINT_ARG2_HEX | io | Arg2/result/stack depending service | printed or T+1 | - |
| 68 | PRINT_ARG2_BIN | io | Arg2/result/stack depending service | printed or T+1 | - |
| 69 | PRINT_ARG2_CHAR | io | Arg2/result/stack depending service | printed or T+1 | - |
| 80 | PTR_SET | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 81 | PTR_ADD | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 82 | PTR_GET | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 83 | PTR_VALID | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 84 | LAYOUT_TAPE_CELLS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 85 | LAYOUT_DATA_CELLS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 86 | LAYOUT_STACK_CELLS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 87 | LAYOUT_CELL_BITS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 88 | LAYOUT_CELL_BYTES | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 89 | LAYOUT_PRINT | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 90 | FIFO_PUSH | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 91 | FIFO_POP | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 92 | FIFO_PEEK | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 93 | FIFO_COUNT | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 94 | FIFO_CLEAR | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 95 | DATA_READ | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 96 | DATA_WRITE | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 97 | DATA_DIGIT_ASCII_TO_NUMBER | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 98 | DATA_BLOCK_COPY | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 99 | DATA_BLOCK_CLEAR | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 100 | TAPE_SORT_ASC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 101 | TAPE_SORT_DESC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 102 | DATA_SORT_ASC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 103 | DATA_SORT_DESC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 104 | TAPE_LINEAR_SEARCH | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 105 | DATA_LINEAR_SEARCH | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 106 | TAPE_BLOCK_COPY | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 107 | TAPE_BLOCK_CLEAR | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 120 | SIGNED_MODE_OFF | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 121 | SIGNED_MODE_ON | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 122 | SIGNED_MODE_GET | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 123 | ENDIAN_LITTLE | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 124 | ENDIAN_BIG | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 125 | ENDIAN_GET_BIG | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 126 | FLAGS_GET | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 127 | WILD_LAYOUT_CHANGE | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 130 | CMP_EQ_UNSIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 131 | CMP_GT_UNSIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 132 | CMP_LT_UNSIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 133 | CMP_EQ_SIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 134 | CMP_GT_SIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 135 | CMP_LT_SIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 140 | GET_CARRY_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 141 | SET_CARRY_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 142 | CLEAR_CARRY_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 143 | GET_OVERFLOW_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 144 | SET_OVERFLOW_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 145 | CLEAR_OVERFLOW_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 146 | GET_ZERO_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 147 | GET_SIGN_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 148 | CLEAR_ZCOS_FLAGS | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 149 | FLAGS_GET_ALIAS | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 150 | ENDIAN_LITTLE_ALIAS | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 151 | ENDIAN_BIG_ALIAS | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 152 | ENDIAN_GET_BIG_ALIAS | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 153 | WRITE_WORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 154 | READ_WORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 155 | WRITE_DWORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 156 | READ_DWORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |


## Programcı mantığı

Aritmetik servisler hesaplama yapar; I/O servisleri yazdırır; flag servisleri önceki işlemin durumunu saklar; pointer ve memory servisleri tape/data alanını düzenler. Büyük programlarda önce veri hazırlanır, sonra servis çağrılır, sonra sonuç başka alana aktarılır. Bu, assembly programlamadaki register hazırlama ve fonksiyon çağırma mantığına benzer.

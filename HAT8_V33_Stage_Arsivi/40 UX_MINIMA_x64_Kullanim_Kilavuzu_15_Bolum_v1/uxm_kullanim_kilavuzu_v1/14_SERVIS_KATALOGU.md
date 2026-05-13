# Bölüm 14 — Tam Servis Kataloğu

Bu bölüm, eldeki `service_registry_merged.csv` dosyasından üretilmiş servis kataloğudur. Kod yazarken servis numarası, aile, handler, frame ve result alanlarına bakılmalıdır. `frame` alanı servisin hangi tape konumlarından argüman beklediğini, `result` alanı sonucu nereye koyduğunu anlatır.

Toplam kayıt: **308**

## Aile özeti

| Aile | Servis sayısı | ID aralığı |
|---|---|---|
| core | 16 | 0..15 |
| arithmetic | 17 | 20..36 |
| math | 18 | 40..59 |
| io | 8 | 60..69 |
| pointer_memory | 10 | 80..89 |
| fifo_data_sort_wild | 26 | 90..127 |
| flags_compare | 16 | 130..149 |
| flags_endian | 7 | 150..156 |
| matrix | 17 | 160..176 |
| matrix_adv | 20 | 180..199 |
| floating_point | 30 | 200..234 |
| math_extra | 10 | 240..254 |
| statistics | 16 | 260..275 |
| correlation | 3 | 280..282 |
| regression | 6 | 290..299 |
| hypothesis | 10 | 300..309 |
| posthoc | 6 | 320..325 |
| ai | 17 | 340..356 |
| probability | 10 | 360..369 |
| numeric | 12 | 390..401 |
| file_io | 22 | 400..421 |
| complex | 11 | 440..450 |



## core
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 0 | NOP_STATUS_OK | MetaCore | - | - | Set status OK | runtime_meta_dispatch.bas |
| 1 | CLS | MetaCore | - | - | Clear screen | runtime_meta_dispatch.bas |
| 2 | LOCATE_HOME | MetaCore | - | - | Locate 1,1 | runtime_meta_dispatch.bas |
| 3 | RANDOM_BYTE | MetaCore | - | - | T+1=random byte | runtime_meta_dispatch.bas |
| 4 | TIMER_MS | MetaCore | - | - | T+1=timer ms masked | runtime_meta_dispatch.bas |
| 5 | NEWLINE | MetaCore | - | - | Print newline | runtime_meta_dispatch.bas |
| 6 | PRINT_META_PREFIX | MetaCore | - | - | Print [UXM META] | runtime_meta_dispatch.bas |
| 7 | CONST_7 | MetaCore | - | - | T+1=7 | runtime_meta_dispatch.bas |
| 8 | CONST_8 | MetaCore | - | - | T+1=8 | runtime_meta_dispatch.bas |
| 9 | GET_STATUS | MetaCore | - | - | T+1=ux_status | runtime_meta_dispatch.bas |
| 10 | STATUS_OK | MetaCore | - | - | Set status OK | runtime_meta_dispatch.bas |
| 11 | SET_STATUS_ARG1 | MetaCore | - | - | status=Arg1 low byte | runtime_meta_dispatch.bas |
| 12 | PRINT_STATUS | MetaCore | - | - | Print status message | runtime_meta_dispatch.bas |
| 13 | STATUS_ASSERT_NONZERO | MetaCore | - | - | If status OK set 1 else keep | runtime_meta_dispatch.bas |
| 14 | CLEAR_STATUS | MetaCore | - | - | Set status OK | runtime_meta_dispatch.bas |
| 15 | GET_ERROR_FLAG | MetaCore | - | - | T+1=1 if FLAG_ERR else 0 | runtime_meta_dispatch.bas |

## arithmetic
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 20 | ADD | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 21 | SUB | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 22 | MUL | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 23 | DIV | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 24 | MOD | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 25 | MIN | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 26 | MAX | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 27 | ABS_ARG2 | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 28 | NEG_ARG2 | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 29 | CMP | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 30 | RANDOM_INT_RANGE | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 31 | RANDOM_SEED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 32 | RANDOM_SCALED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 33 | DIV_UNSIGNED_ALIAS | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 34 | DIV_SIGNED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 35 | MOD_UNSIGNED_ALIAS | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 36 | MOD_SIGNED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |

## math
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 40 | SIN_SCALED_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 41 | COS_SCALED_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 42 | TAN_SCALED_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 43 | HYPOTENUSE | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 44 | ASIN_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 45 | ACOS_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 46 | SQRT | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 47 | SINH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 48 | COSH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 49 | TANH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 52 | ASINH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 53 | ACOSH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 54 | ATANH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 55 | LN_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 56 | EXP_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 57 | POWER | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 58 | DEG_TO_RAD_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 59 | RAD_TO_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |

## io
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 60 | PRINT_ARG2_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 61 | PRINT_RESULT_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 62 | PRINT_STACK_POP_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 63 | READ_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 64 | PRINT_SPACE | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 67 | PRINT_ARG2_HEX | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 68 | PRINT_ARG2_BIN | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 69 | PRINT_ARG2_CHAR | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |

## pointer_memory
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 80 | PTR_SET | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 81 | PTR_ADD | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 82 | PTR_GET | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 83 | PTR_VALID | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 84 | LAYOUT_TAPE_CELLS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 85 | LAYOUT_DATA_CELLS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 86 | LAYOUT_STACK_CELLS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 87 | LAYOUT_CELL_BITS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 88 | LAYOUT_CELL_BYTES | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 89 | LAYOUT_PRINT | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |

## fifo_data_sort_wild
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 90 | FIFO_PUSH | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 91 | FIFO_POP | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 92 | FIFO_PEEK | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 93 | FIFO_COUNT | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 94 | FIFO_CLEAR | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 95 | DATA_READ | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 96 | DATA_WRITE | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 97 | DATA_DIGIT_ASCII_TO_NUMBER | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 98 | DATA_BLOCK_COPY | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 99 | DATA_BLOCK_CLEAR | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 100 | TAPE_SORT_ASC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 101 | TAPE_SORT_DESC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 102 | DATA_SORT_ASC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 103 | DATA_SORT_DESC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 104 | TAPE_LINEAR_SEARCH | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 105 | DATA_LINEAR_SEARCH | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 106 | TAPE_BLOCK_COPY | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 107 | TAPE_BLOCK_CLEAR | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 120 | SIGNED_MODE_OFF | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 121 | SIGNED_MODE_ON | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 122 | SIGNED_MODE_GET | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 123 | ENDIAN_LITTLE | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 124 | ENDIAN_BIG | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 125 | ENDIAN_GET_BIG | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 126 | FLAGS_GET | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 127 | WILD_LAYOUT_CHANGE | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |

## flags_compare
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 130 | CMP_EQ_UNSIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 131 | CMP_GT_UNSIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 132 | CMP_LT_UNSIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 133 | CMP_EQ_SIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 134 | CMP_GT_SIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 135 | CMP_LT_SIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 140 | GET_CARRY_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 141 | SET_CARRY_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 142 | CLEAR_CARRY_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 143 | GET_OVERFLOW_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 144 | SET_OVERFLOW_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 145 | CLEAR_OVERFLOW_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 146 | GET_ZERO_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 147 | GET_SIGN_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 148 | CLEAR_ZCOS_FLAGS | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 149 | FLAGS_GET_ALIAS | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |

## flags_endian
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 150 | ENDIAN_LITTLE_ALIAS | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 151 | ENDIAN_BIG_ALIAS | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 152 | ENDIAN_GET_BIG_ALIAS | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 153 | WRITE_WORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 154 | READ_WORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 155 | WRITE_DWORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 156 | READ_DWORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |

## matrix
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 160 | MAT_INIT | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 161 | MAT_CLEAR | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 162 | MAT_SET | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 163 | MAT_GET | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 164 | MAT_FILL | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 165 | MAT_COPY | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 166 | MAT_PRINT | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 167 | MAT_ADD | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 168 | MAT_SUB | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 169 | MAT_SCALAR_MUL | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 170 | MAT_MUL | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 171 | MAT_TRANSPOSE_COPY | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 172 | MAT_IDENTITY | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 173 | MAT_TRACE | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 174 | MAT_SHAPE | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 175 | MAT_DET2 | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 176 | MAT_PRINT_RAW | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |

## matrix_adv
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 180 | MAT_ND_INIT | UXMMatAdvancedDispatch | T-4 rows, T-3 cols, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 181 | MAT_ND_GET | UXMMatAdvancedDispatch | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 182 | MAT_ND_SET | UXMMatAdvancedDispatch | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 183 | MAT_DET | UXMMatAdvancedDispatch | T-4 A, T+1 determinant | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 184 | MAT_INVERSE | UXMMatAdvancedDispatch | T-4 A, T-2 OUT | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 185 | MAT_LU | UXMMatAdvancedDispatch | T-4 A, T-2 L, T-3 U | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 186 | MAT_QR | UXMMatAdvancedDispatch | T-4 A, T-2 Q, T-3 R | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 187 | MAT_RANK | UXMMatAdvancedDispatch | T-4 A, T+1 rank | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 188 | MAT_COND_EST | UXMMatAdvancedDispatch | T-4 A, T-2 temp inverse, T+1 cond | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 189 | MAT_EIG_POWER | UXMMatAdvancedDispatch | T-4 A, T-2 vector out, T-1 iterations, T+1 lambda | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 190 | MAT_EIG_JACOBI_SYM | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 191 | MAT_SVD_SYM_HELPER | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 192 | MAT_SPARSE_CSR_INIT | UXMMatAdvancedDispatch | T-4 rows, T-3 cols, T-1 nnz, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 193 | MAT_SPARSE_CSR_MV | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 194 | MAT_SPARSE_TO_DENSE | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 195 | MAT_DENSE_TO_SPARSE | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 196 | MAT_TRACE | UXMMatAdvancedDispatch | T-4 A, T+1 trace | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 197 | MAT_FROBENIUS | UXMMatAdvancedDispatch | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 198 | MAT_NORM_INF | UXMMatAdvancedDispatch | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 199 | MAT_ADV_INFO | UXMMatAdvancedDispatch | prints info | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |

## floating_point
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 200 | FP_INIT16 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 201 | FP_INIT32 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 202 | FP_ZERO | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 203 | FP_COPY | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 204 | FP_NORMALIZE_STORE | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 205 | FP_TO_INT | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 206 | FP_IS_ZERO | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 207 | FP_SIGN | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 208 | FP_ABS_TO_INT | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 209 | FP_PRINT_RAW | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 210 | FP_ADD | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 211 | FP_SUB | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 212 | FP_MUL | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 213 | FP_DIV | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 214 | FP_COMPARE | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 215 | FP_ABS | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 216 | FP_NEG | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 217 | FP_ROUND16 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 218 | FP_ROUND32 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 219 | FP_TRUNC | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 220 | FP_FROM_INT | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 221 | FP_FROM_DEC_STRING | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 222 | FP_TO_DEC_STRING | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 223 | FP_PRINT_DECIMAL | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 224 | FP_SCALE10 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 230 | FP_RESERVED_230 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 231 | FP_RESERVED_231 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 232 | FP_RESERVED_232 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 233 | FP_RESERVED_233 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 234 | FP_RESERVED_234 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |

## math_extra
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 240 | POLY_DERIVATIVE | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 241 | POLY_INTEGRAL | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 242 | POLY_EVAL | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 243 | POLY_PRINT | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 244 | POLY_CLEAR | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 250 | EXPR_RPN_EVAL | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 251 | NUM_DERIV | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 252 | INTEGRAL_TRAPEZOID | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 253 | INTEGRAL_SIMPSON | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 254 | EXPR_RPN_PRINT | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |

## statistics
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 260 | STAT_COUNT | MetaStatistics | - | T+1/status | count values | service_registry_v33.csv |
| 261 | STAT_SUM | MetaStatistics | - | T+1/status | sum values | service_registry_v33.csv |
| 262 | STAT_MEAN | MetaStatistics | - | T+1/status | mean | service_registry_v33.csv |
| 263 | STAT_MIN | MetaStatistics | - | T+1/status | min | service_registry_v33.csv |
| 264 | STAT_MAX | MetaStatistics | - | T+1/status | max | service_registry_v33.csv |
| 265 | STAT_RANGE | MetaStatistics | - | T+1/status | max-min | service_registry_v33.csv |
| 266 | STAT_VARIANCE | MetaStatistics | - | T+1/status | sample variance | service_registry_v33.csv |
| 267 | STAT_STDDEV | MetaStatistics | - | T+1/status | sample stddev | service_registry_v33.csv |
| 268 | STAT_MEDIAN | MetaStatistics | - | T+1/status | median | service_registry_v33.csv |
| 269 | STAT_MODE | MetaStatistics | - | T+1/status | mode first | service_registry_v33.csv |
| 270 | STAT_QUARTILE | MetaStatistics | - | T+1/status | quartile placeholder | service_registry_v33.csv |
| 271 | STAT_PERCENTILE | MetaStatistics | - | T+1/status | percentile placeholder | service_registry_v33.csv |
| 272 | STAT_SKEWNESS | MetaStatistics | - | T+1/status | skewness placeholder | service_registry_v33.csv |
| 273 | STAT_KURTOSIS | MetaStatistics | - | T+1/status | kurtosis placeholder | service_registry_v33.csv |
| 274 | STAT_COVARIANCE | MetaStatistics | - | T+1/status | covariance | service_registry_v33.csv |
| 275 | STAT_ZSCORE | MetaStatistics | - | T+1/status | z score | service_registry_v33.csv |

## correlation
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 280 | CORR_PEARSON | MetaStatistics | - | T+1/status | pearson r scaled | service_registry_v33.csv |
| 281 | CORR_SPEARMAN | MetaStatistics | - | T+1/status | spearman placeholder | service_registry_v33.csv |
| 282 | CORR_KENDALL | MetaStatistics | - | T+1/status | kendall placeholder | service_registry_v33.csv |

## regression
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 290 | REG_LINEAR | MetaRegression | - | T+1/status | simple linear regression | service_registry_v33.csv |
| 291 | REG_MULTIPLE | MetaRegression | - | T+1/status | reserved | service_registry_v33.csv |
| 292 | REG_POLYNOMIAL | MetaRegression | - | T+1/status | reserved | service_registry_v33.csv |
| 293 | REG_LOGISTIC | MetaRegression | - | T+1/status | reserved | service_registry_v33.csv |
| 298 | REG_PREDICT | MetaRegression | - | T+1/status | predict y | service_registry_v33.csv |
| 299 | REG_R2 | MetaRegression | - | T+1/status | r squared | service_registry_v33.csv |

## hypothesis
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 300 | TTEST_ONE | MetaHypothesis | - | T+1/status | one sample t placeholder | service_registry_v33.csv |
| 301 | TTEST_INDEPENDENT | MetaHypothesis | - | T+1/status | independent t placeholder | service_registry_v33.csv |
| 302 | TTEST_PAIRED | MetaHypothesis | - | T+1/status | paired t placeholder | service_registry_v33.csv |
| 303 | ZTEST_ONE | MetaHypothesis | - | T+1/status | one sample z placeholder | service_registry_v33.csv |
| 304 | ZTEST_TWO | MetaHypothesis | - | T+1/status | two sample z placeholder | service_registry_v33.csv |
| 305 | FTEST_VARIANCE | MetaHypothesis | - | T+1/status | f variance placeholder | service_registry_v33.csv |
| 306 | ANOVA_ONEWAY | MetaHypothesis | - | T+1/status | oneway anova placeholder | service_registry_v33.csv |
| 307 | ANOVA_TWOWAY | MetaHypothesis | - | T+1/status | reserved | service_registry_v33.csv |
| 308 | CHI_SQUARE | MetaHypothesis | - | T+1/status | chi square placeholder | service_registry_v33.csv |
| 309 | CHI_GOODNESS | MetaHypothesis | - | T+1/status | goodness placeholder | service_registry_v33.csv |

## posthoc
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 320 | POSTHOC_TUKEY | MetaPosthoc | - | T+1/status | tukey placeholder | service_registry_v33.csv |
| 321 | POSTHOC_DUNCAN | MetaPosthoc | - | T+1/status | duncan placeholder | service_registry_v33.csv |
| 322 | POSTHOC_DUNNETT | MetaPosthoc | - | T+1/status | dunnett placeholder | service_registry_v33.csv |
| 323 | POSTHOC_BONFERRONI | MetaPosthoc | - | T+1/status | bonferroni placeholder | service_registry_v33.csv |
| 324 | POSTHOC_SCHEFFE | MetaPosthoc | - | T+1/status | scheffe placeholder | service_registry_v33.csv |
| 325 | POSTHOC_LSD | MetaPosthoc | - | T+1/status | lsd placeholder | service_registry_v33.csv |

## ai
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 340 | AI_NORMALIZE_MINMAX | MetaAI | - | T+1/status | minmax normalize | service_registry_v33.csv |
| 341 | AI_NORMALIZE_ZSCORE | MetaAI | - | T+1/status | zscore normalize | service_registry_v33.csv |
| 342 | AI_ONEHOT | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 343 | AI_TRAIN_TEST_SPLIT | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 344 | AI_SHUFFLE | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 345 | AI_CONFUSION_MATRIX | MetaAI | - | T+1/status | confusion matrix placeholder | service_registry_v33.csv |
| 346 | AI_ACCURACY | MetaAI | - | T+1/status | accuracy | service_registry_v33.csv |
| 347 | AI_PRECISION | MetaAI | - | T+1/status | precision | service_registry_v33.csv |
| 348 | AI_RECALL | MetaAI | - | T+1/status | recall | service_registry_v33.csv |
| 349 | AI_F1 | MetaAI | - | T+1/status | f1 score | service_registry_v33.csv |
| 350 | AI_DISTANCE_EUCLIDEAN | MetaAI | - | T+1/status | euclidean distance | service_registry_v33.csv |
| 351 | AI_DISTANCE_COSINE | MetaAI | - | T+1/status | cosine distance placeholder | service_registry_v33.csv |
| 352 | AI_KNN_BASIC | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 353 | AI_LINEAR_LAYER | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 354 | AI_SIGMOID | MetaAI | - | T+1/status | sigmoid scaled | service_registry_v33.csv |
| 355 | AI_RELU | MetaAI | - | T+1/status | relu | service_registry_v33.csv |
| 356 | AI_SOFTMAX | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |

## probability
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 360 | RAND_SEED | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 361 | RAND_UNIFORM_01 | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 362 | RAND_INT_RANGE | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 363 | RAND_NORMAL | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 364 | RAND_POISSON | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 365 | RAND_BINOMIAL | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 366 | RAND_WEIGHTED | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 367 | RAND_SECURE_BYTE | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 368 | RAND_BERNOULLI | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 369 | RAND_SHUFFLE_DATA | MetaProbability | - | T+1/status | - | service_registry_v35.csv |

## numeric
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 390 | NUM_NEWTON_RAPHSON | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 391 | NUM_BISECTION | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 392 | NUM_SECANT | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 393 | NUM_INTEGRAL_TRAPEZOID | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 394 | NUM_INTEGRAL_SIMPSON | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 395 | NUM_INTERPOLATE_LINEAR | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 396 | NUM_BEZIER_QUADRATIC | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 397 | NUM_RUNGE_KUTTA4_LINEAR | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 398 | NUM_ODE_INFO | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 399 | NUM_PDE_RESERVED | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 400 | NUM_SPLINE_RESERVED | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 401 | NUM_ADAPTIVE_INTEGRAL_RESERVED | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |

## file_io
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 400 | FILE_OPEN_READ_TEXT | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 401 | FILE_OPEN_WRITE_TEXT | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 402 | FILE_OPEN_APPEND_TEXT | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 403 | FILE_OPEN_BINARY_READ | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 404 | FILE_OPEN_BINARY_WRITE | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 405 | FILE_CLOSE | MetaFileServices | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 406 | FILE_READ_BYTE | MetaFileServices | T-1=handle | T+1=byte | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 407 | FILE_WRITE_BYTE | MetaFileServices | T-2=handle, T-1=byte | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 408 | FILE_READ_LINE | MetaFileServices | T-3=handle, T-2=dst_data_start, T-1=max_len | T+1=len | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 409 | FILE_WRITE_LINE | MetaFileServices | T-3=handle, T-2=src_data_start, T-1=len | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 410 | FILE_READ_BLOCK | MetaFileServices | T-4=handle, T-3=space, T-2=dst_start, T-1=max_count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 411 | FILE_WRITE_BLOCK | MetaFileServices | T-4=handle, T-3=space, T-2=src_start, T-1=count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 412 | FILE_SEEK | MetaFileServices | T-2=handle, T-1=position_zero_based | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 413 | FILE_TELL | MetaFileServices | T-1=handle | T+1=position | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 414 | FILE_SIZE | MetaFileServices | T-1=handle | T+1=size | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 415 | FILE_EXISTS | MetaFileServices | T-2=name_start, T-1=name_len | T+1=0/1 | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 416 | FILE_DELETE_RESERVED | MetaFileServices | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 417 | FILE_RENAME_RESERVED | MetaFileServices | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 418 | FILE_MKDIR_RESERVED | MetaFileServices | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 419 | FILE_STATUS | MetaFileServices | none | T+1=last_file_status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 420 | FILE_FLUSH | MetaFileServices | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 421 | FILE_OPEN_BINARY_APPEND | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |

## complex
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 440 | CPLX_INIT | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 441 | CPLX_ADD | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 442 | CPLX_SUB | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 443 | CPLX_MUL | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 444 | CPLX_DIV | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 445 | CPLX_CONJ | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 446 | CPLX_ABS | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 447 | CPLX_ARG | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 448 | CPLX_EXP | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 449 | CPLX_FROM_POLAR | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 450 | CPLX_PRINT_RESERVED | MetaComplex | - | T+1/status | - | service_registry_v35.csv |

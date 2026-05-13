# Bölüm 10 — String, Dosya, BIO, ML ve Veri Pipeline Servisleri

UXM’de string verisi çoğunlukla data alanında tutulur. String, sıfır byte ile biten karakter dizisi olarak düşünülebilir. Bu BASIC’teki `STRING` veya Python’daki `str` kadar rahat değildir; ama bellekte metnin nasıl durduğunu öğretir. Dosya servisleri de aynı mantıkla çalışır: aç, oku/yaz, kapat; fakat servis ABI ile argüman hazırlanır.

## String servis tasarım tablosu

| Servis | Ad | Görev |
|---|---|---|
| @300 | STR_LEN_Z | 0 byte görene kadar string uzunluğu bulur (tasarım notu: registry çakışması kontrol edilmeli). |
| @301 | STR_COPY | Data alanında string kopyalar. |
| @302 | STR_CLEAR | Data string/bölge temizler. |
| @303 | STR_FILL | Data alanını karakterle doldurur. |
| @304 | STR_COMPARE | İki string karşılaştırır. |
| @305 | STR_EQUALS | String eşitlik kontrolü yapar. |
| @306 | STR_FIND_CHAR | Karakter arar. |
| @307 | STR_COUNT_CHAR | Karakter sayar. |
| @340 | STR_FIND_TEXT | Substring arar. |
| @341 | STR_COUNT_TEXT | Substring sayar. |
| @342 | STR_REPLACE_CHAR | Karakter değiştirir. |
| @343 | STR_REPLACE_TEXT | Metin parçası değiştirir. |
| @344 | STR_SPLIT_NEXT | Metni parçalara ayırma adımı. |


Not: Eski UX-STR belgelerinde `@300..@379` string servis bandı olarak tasarlanmıştır. Birleşik registry tablosunda aynı bandın bazı bölümlerinde istatistik/hypothesis servisleri görünebilir. Kod yazarken her zaman proje içindeki güncel `service_registry_merged.csv` ve runtime dispatch dosyası esas alınmalıdır. Bu çakışma dokümantasyonda ayrıca işaretlenmiştir; saklanmamalıdır.

## Dosya servisleri

| ID | Ad | Aile | Frame | Sonuç | Not |
|---|---|---|---|---|---|
| 400 | FILE_OPEN_READ_TEXT | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 401 | FILE_OPEN_WRITE_TEXT | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 402 | FILE_OPEN_APPEND_TEXT | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 403 | FILE_OPEN_BINARY_READ | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 404 | FILE_OPEN_BINARY_WRITE | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 405 | FILE_CLOSE | file_io | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 406 | FILE_READ_BYTE | file_io | T-1=handle | T+1=byte | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 407 | FILE_WRITE_BYTE | file_io | T-2=handle, T-1=byte | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 408 | FILE_READ_LINE | file_io | T-3=handle, T-2=dst_data_start, T-1=max_len | T+1=len | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 409 | FILE_WRITE_LINE | file_io | T-3=handle, T-2=src_data_start, T-1=len | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 410 | FILE_READ_BLOCK | file_io | T-4=handle, T-3=space, T-2=dst_start, T-1=max_count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 411 | FILE_WRITE_BLOCK | file_io | T-4=handle, T-3=space, T-2=src_start, T-1=count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 412 | FILE_SEEK | file_io | T-2=handle, T-1=position_zero_based | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 413 | FILE_TELL | file_io | T-1=handle | T+1=position | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 414 | FILE_SIZE | file_io | T-1=handle | T+1=size | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 415 | FILE_EXISTS | file_io | T-2=name_start, T-1=name_len | T+1=0/1 | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 416 | FILE_DELETE_RESERVED | file_io | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 417 | FILE_RENAME_RESERVED | file_io | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 418 | FILE_MKDIR_RESERVED | file_io | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 419 | FILE_STATUS | file_io | none | T+1=last_file_status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 420 | FILE_FLUSH | file_io | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 421 | FILE_OPEN_BINARY_APPEND | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |


## Dosya işlemi pseudo-code

```text
T-2 = dosya adı adresi
T-1 = mod bilgisi
@FILE_OPEN
T+1 = handle

T-2 = handle
T-1 = buffer adresi
T   = uzunluk
@FILE_READ_BLOCK

T-2 = handle
@FILE_CLOSE
```

## BIO/ML veri pipeline mantığı

BIO, ML ve veri pipeline servisleri yüksek seviyeli bilimsel uygulamalar için düşünülür. Bunlar genelde data alanında tutulan dizileri alır, hesap yapar ve sonucu tape veya data alanına yazar. Örneğin biyoloji örneğinde bir ölçüm serisi data alanına yüklenir; istatistik veya ML servisleriyle sınıflandırılır; sonuç rapor edilir.

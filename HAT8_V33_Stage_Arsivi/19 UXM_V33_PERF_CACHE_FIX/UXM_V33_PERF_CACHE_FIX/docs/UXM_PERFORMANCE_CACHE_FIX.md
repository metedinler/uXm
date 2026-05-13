# UXM V3.3 Performans Cache Fix

Bu paket yeni test sistemi veya yeni test dosyası üretmez. Var olan `build_native.bat` ve `build_one_native.bat` dosyalarını hızlandırılmış sürümle değiştirir.

## Sorun

Eski akışta her test için şu işlem yapılıyordu:

```bat
fbc.exe uxm\core\runtime\uxm31_runtime_fb_full.bas build\obj\program.o -x build\exe\program.exe
```

Bu, runtime kaynak dosyasını ve tüm include zincirini her testte tekrar derlediği için 100+ testte belirgin yavaşlama yaratır.

## Çözüm

`build_native.bat`, compiler derlemesinden sonra runtime'ı bir kez object cache'e çevirir:

```bat
build\obj\uxm_runtime_fb_full_cache.o
```

`build_one_native.bat` her testte runtime kaynak dosyasını yeniden derlemek yerine bu cache object ile linklemeyi dener:

```bat
fbc.exe build\obj\uxm_runtime_fb_full_cache.o build\obj\program.o -x build\exe\program.exe
```

Cache link başarısız olursa otomatik olarak eski yavaş kaynak link yöntemine döner. Böylece pipeline kırılmaz.

## Kullanım

Mevcut komutların değişmez:

```powershell
.\build_native.bat
.\run_tests_native.bat
```

Runtime dosyalarında değişiklik yaptığında `build_native.bat` çalıştırman cache'i tazeler.

## Beklenen Etki

NASM aşaması zaten hızlıdır. Asıl gecikme FreeBASIC runtime kaynak linkinden gelir. Runtime object cache ile test başına süre, özellikle 3-8 saniye/test seviyesinden belirgin şekilde aşağı düşmelidir. Kesin kazanç makineye ve FreeBASIC toolchain'e bağlıdır.

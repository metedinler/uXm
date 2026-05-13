# Bölüm 1 — UX-MINIMA x64 Nedir, Ne İşe Yarar?

UX-MINIMA x64, kısa adıyla **UXM**, küçük sembollerle yazılan ama x64 assembly üretmeyi hedefleyen deneysel bir compiler/interpreter dilidir. Başlangıç fikri Brainfuck benzeri küçük bir çekirdektir; fakat UXM yalnızca `+`, `-`, `<`, `>`, `[`, `]` gibi komutlardan ibaret değildir. Üzerine tape, data, private stack, FIFO, pointer kontrolü, hücre tipi, overflow modu, adresleme modları ve `@N` servis çağrıları eklenmiştir.

Bu dilin amacı Python gibi her şeyi hazır keyword olarak vermek değildir. Tam tersine, programcıya bilgisayarın içindeki temel fikirleri öğretmektir: bellek nedir, pointer nedir, hücre tipi nedir, stack ne işe yarar, FIFO neden farklıdır, bir servis çağrısı aslında runtime tarafında neyi tetikler, compiler bir kaynak dosyadan nasıl `.asm`, `.obj`, `.exe` ve rapor dosyaları üretir? UXM bu soruları uygulamalı öğretir.

Bir UXM programcısı kod yazarken şunu düşünür: “Elimde aktif bir tape hücresi var. Bu hücreyi artırabilir, azaltabilir, başka bir adrese taşıyabilir, data alanına yazabilir, stack’e koyabilir, FIFO’ya atabilir, sonra runtime servislerinden birini çağırarak bu değerleri işletebilirim.” Yani UXM’de program yazmak, küçük bellek hareketlerinden büyük işlemler kurmayı öğrenmektir.

UXM’nin güçlü tarafı, küçük çekirdek komutlarının çok sayıda adresleme modu ve servisle birleşmesidir. Örneğin `+` komutu yalnızca aktif hücreyi artırmaz; `+(D:10)` yazarsan data alanındaki 10. hücreyi artırırsın, `+(T+1)` yazarsan pointer’ın sağındaki tape hücresini artırırsın. Aynı mantıkla `@20` bir toplama servisi, `@160` matrix alanı, `@400` dosya servis alanı gibi düşünülebilir.

UXM eğitimde, derleyici tasarımı öğrenmede, düşük seviyeli programlama mantığını kavramada, servis tabanlı runtime mimarisi kurmada ve x64 assembly üretme sürecini anlamada kullanılır. Ayrıca bilimsel hesaplama, istatistik, matrix/tensor, string ve dosya işlemleri gibi alanlar için servis tabanlı genişleme yolu sunar.

## UXM’yi kim öğrenmeli?

BASIC veya Python ile değişken, döngü ve fonksiyon fikrini öğrenmiş biri UXM ile daha alttaki katmana iner. Python’da `liste.append(5)` yazarsın; UXM’de aynı mantığı tape/data/stack/FIFO üzerinde düşünürsün. Python’da `sum(liste)` dendiğinde ne olduğunu görmezsin; UXM’de veri nereye yazıldı, servis hangi hücrelerden argüman aldı, sonuç hangi hücreye geldi sorularını takip edersin.

Bu yüzden UXM, “bilgisayar nasıl düşünüyor?” sorusuna yaklaşmak için iyi bir laboratuvardır. Her şey hazır değil; ama öğrenme değeri de buradan gelir.

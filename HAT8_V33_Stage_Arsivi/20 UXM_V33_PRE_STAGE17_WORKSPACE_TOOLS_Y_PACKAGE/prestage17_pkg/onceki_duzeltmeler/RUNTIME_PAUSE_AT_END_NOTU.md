# Runtime Pause Notu

EXE çıktısını çift tıklayınca görmek için runtime sonuna `Sleep` koymak faydalı olabilir; ancak test runner içinde varsayılan yapılırsa her testte beklemeye girer.

Doğru politika:

- Test runner: pause kapalı.
- Manuel EXE inceleme: `--pause` veya ayrı manual build modu.

Runtime örneği:

```freebasic
Extern "C"
Sub ux_pause_at_end() Export
    Print
    Print "[UXM] Program bitti. Devam etmek icin bir tusa basin..."
    Sleep
End Sub
End Extern
```

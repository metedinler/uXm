# VSCode UXM entegrasyon yerleşimi

Önerilen repo yolu:

```text
tools/vscode-uxm/
  syntaxes/uxm.tmLanguage.json
  language-configuration.json
  schemas/commands.json
  schemas/meta_services.json
  snippets/uxm.code-snippets
```

Alternatif sade yerleşim:

```text
config/uxm/commands.json
config/uxm/meta_services.json
config/uxm/service_registry_merged.csv
```

Bu iki JSON compiler için zorunlu değildir; ama VSCode tarafında autocomplete, hover, lint ve servis çakışması kontrolü için gereklidir. Compiler tarafında ise aynı registry'den FreeBASIC dispatcher üretmek ikinci aşamada yapılabilir.

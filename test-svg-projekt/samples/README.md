# Przykładowe pliki wyjściowe

Po uruchomieniu skryptów generujące w tym katalogu pojawią się:

- `certificate_background.svg` - przykładowe tło certyfikatu
- `advertisement_background.svg` - przykładowe tło reklamy
- `converted_image.svg` - skonwertowany obrazek

## Jak używać

```bash
# Generuj tło certyfikatu
../generate_certificate.sh certificate_background.svg "#8B4513" geometric

# Generuj tło reklamy
../generate_advertisement.sh ad_background.svg "#ff6b6b,#4ecdc4"

# Konwertuj obrazek
../convert_image.sh ../samples/sample.jpg converted.svg
```

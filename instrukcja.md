# Qwen-Tam.sh: Zautomatyzowany Workflow Przetwarzania Książek

## Cel zadania

Stworzyć w pełni zautomatyzowany workflow przy użyciu aplikacji `qwen-tam.sh`, który:
1. Tworzy katalog `/input/` i wczytuje z niego pliki `.txt` oraz `.md`
2. Dzieli zawartość plików na części i zapisuje je w katalogu `/chunk/`
3. Na podstawie chunków tworzy strukturę książki (rozdziały, podrozdziały)
4. Redaguje i finalizuje książkę do katalogu `/finish/`

---

## Struktura katalogów roboczych

```
/workspace
├── input/          # Katalog wejściowy: pliki .txt i .md do przetworzenia
├── chunk/          # Katalog pośredni: podzielone fragmenty tekstu
├── finish/         # Katalog wyjściowy: gotowa książka, rozdziały, podrozdziały
├── qwen-tam.sh     # Główny skrypt automatyzujący
└── instrukcja.md   # Ten plik
```

---

## Krok po kroku: Implementacja workflow

### KROK 1: Utworzenie katalogu `/input/` i przygotowanie plików wejściowych

#### 1.1. Utwórz katalog wejściowy
```bash
mkdir -p /workspace/input
```

#### 1.2. Umieść pliki źródłowe w katalogu `/input/`
- Wgraj wszystkie pliki `.txt` i `.md` zawierające materiał źródłowy książki
- Zalecane nazewnictwo: `01_wstep.md`, `02_rozdzial1.txt`, `03_rozdzial2.md`, itp.
- Pliki powinny zawierać oznaczone nagłówki (dla `.md`):
  ```markdown
  # Rozdział 1: Tytuł
  
  ## Podrozdział 1.1
  
  Treść podrozdziału...
  
  ## Podrozdział 1.2
  
  Treść podrozdziału...
  ```

---

### KROK 2: Konfiguracja i uruchomienie `qwen-tam.sh`

#### 2.1. Nadaj uprawnienia wykonania (jeśli brak)
```bash
chmod +x /workspace/qwen-tam.sh
```

#### 2.2. Uruchom skrypt w trybie interaktywnym
```bash
cd /workspace
./qwen-tam.sh
```

#### 2.3. Alternatywnie: tryb z linii poleceń (gdy dostępny)
```bash
./qwen-tam.sh --automate book-workflow
```

---

### KROK 3: Wczytanie plików `.txt` i `.md` z katalogu `/input/`

Skrypt `qwen-tam.sh` wykonuje następujące operacje:

1. **Skanowanie katalogu `/input/`**:
   - Wyszukuje wszystkie pliki z rozszerzeniem `.txt` i `.md`
   - Sortuje pliki alfabetycznie/numerycznie dla zachowania kolejności

2. **Wczytanie zawartości**:
   - Odczytuje każdy plik z encodingiem UTF-8
   - Waliduje poprawność składni Markdown (dla `.md`)
   - Przygotowuje dane do dalszego przetwarzania

3. **Logowanie procesu**:
   - Wszystkie operacje są rejestrowane w `/workspace/logs/app.log`
   - Błędy walidacji są raportowane użytkownikowi

---

### KROK 4: Podział treści na chunki i zapis do katalogu `/chunk/`

#### 4.1. Utwórz katalog pośredni
```bash
mkdir -p /workspace/chunk
```

#### 4.2. Zasady podziału na chunki

Skrypt dzieli tekst według następujących reguł:

| Poziom podziału | Kryterium | Przykład nazwy chunka |
|-----------------|-----------|----------------------|
| **Plik** | Każdy plik wejściowy | `chunk_01_wstep.txt` |
| **Rozdział** | Nagłówek poziomu 1 (`#`) lub 2 (`##`) | `chunk_01_rozdzial_1.txt` |
| **Podrozdział** | Nagłówek poziomu 3 (`###`) lub akapity | `chunk_01_rozdzial_1_podrozdzial_1.txt` |
| **Segment** | Bloki tekstu ~500-1000 słów | `chunk_01_segment_A.txt` |

#### 4.3. Struktura katalogu `/chunk/`
```
chunk/
├── 01_wstep/
│   ├── chunk_001.txt
│   └── chunk_002.txt
├── 02_rozdzial1/
│   ├── chunk_001.txt
│   ├── chunk_002.txt
│   └── chunk_003.txt
└── 03_rozdzial2/
    ├── chunk_001.txt
    └── chunk_002.txt
```

#### 4.4. Metadane chunków
Każdy chunk zawiera nagłówek z metadanymi:
```
=== CHUNK METADATA ===
Source: 01_wstep.md
Chapter: Wstęp
Subchapter: Cel książki
Chunk ID: 001
Word count: 750
Timestamp: 2024-01-15 10:30:00
====================

[Treść chunka...]
```

---

### KROK 5: Tworzenie struktury książki na podstawie chunków

#### 5.1. Analiza i agregacja chunków

Skrypt wykonuje:

1. **Grupowanie chunków** według plików źródłowych
2. **Identyfikację rozdziałów** na podstawie metadanych i nagłówków
3. **Budowę drzewa struktury** książki:
   ```
   Książka
   ├── Wstęp
   ├── Rozdział 1
   │   ├── Podrozdział 1.1
   │   ├── Podrozdział 1.2
   │   └── Podrozdział 1.3
   ├── Rozdział 2
   │   ├── Podrozdział 2.1
   │   └── Podrozdział 2.2
   └── Zakończenie
   ```

#### 5.2. Generowanie streszczeń

Dla każdego poziomu struktury tworzone są streszczenia:

- **Streszczenie chunka**: 2-3 zdania kluczowych informacji
- **Streszczenie podrozdziału**: akapit podsumowujący
- **Streszczenie rozdziału**: pół strony najważniejszych tez
- **Streszczenie całej książki**: abstrakt (250-500 słów)

#### 5.3. Tworzenie spisu treści

Automatycznie generowany spis treści zawiera:
- Numery stron (szacowane)
- Linki do rozdziałów (w formacie Markdown/HTML)
- Hierarchiczną strukturę z wcięciami

---

### KROK 6: Redagowanie i finalizacja książki do katalogu `/finish/`

#### 6.1. Utwórz katalog wyjściowy
```bash
mkdir -p /workspace/finish
```

#### 6.2. Proces redagowania

Skrypt `qwen-tam.sh` realizuje:

1. **Scalanie chunków** w spójne rozdziały
2. **Ujednolicenie stylu**:
   - Spójna terminologia
   - Ujednolicenie formatowania
   - Poprawa płynności przejść między sekcjami

3. **Korekta i optymalizacja**:
   - Usuwanie powtórzeń
   - Naprawa niespójności
   - Dodawanie transitional phrases

4. **Formatowanie finalne**:
   - Nagłówki w jednolitej konwencji
   - Numeracja stron/rozdziałów
   - Indeksy i odnośniki krzyżowe

#### 6.3. Struktura katalogu `/finish/`
```
finish/
├── book_complete.md           # Pełna książka w jednym pliku
├── book_complete.pdf          # Wersja PDF (jeśli konwerter dostępny)
├── book_complete.epub         # Wersja EPUB (jeśli konwerter dostępny)
├── chapters/
│   ├── 00_preface.md          # Przedmowa
│   ├── 01_chapter_1.md        # Rozdział 1
│   ├── 02_chapter_2.md        # Rozdział 2
│   └── 99_conclusion.md       # Zakończenie
├── subchapters/
│   ├── 01_01_subchapter.md
│   ├── 01_02_subchapter.md
│   └── ...
├── summaries/
│   ├── book_abstract.md       # Streszczenie całej książki
│   ├── chapter_summaries.md   # Streszczenia rozdziałów
│   └── keywords.md            # Słowa kluczowe
├── toc.md                     # Spis treści
└── metadata.json              # Metadane książki (autor, data, statystyki)
```

#### 6.4. Plik metadanych `metadata.json`
```json
{
  "title": "Tytuł książki",
  "author": "Autor/Autorzy",
  "created_date": "2024-01-15",
  "source_files": ["01_wstep.md", "02_rozdzial1.md"],
  "total_chunks": 45,
  "total_chapters": 8,
  "total_subchapters": 23,
  "word_count": 25000,
  "processing_time": "00:15:32"
}
```

---

## Pełny workflow w jednym poleceniu

Po skonfigurowaniu `qwen-tam.sh`, cały proces można uruchomić jako:

```bash
cd /workspace
./qwen-tam.sh --workflow book-from-input --input-dir ./input --output-dir ./finish
```

Lub w trybie interaktywnym wybrać opcję:
```
[Automation Menu]
  → Book Processing Workflow
    → Process files from /input/
    → Generate chunks to /chunk/
    → Compile book to /finish/
```

---

## Monitorowanie postępu

### Logi procesu
- **Główny log**: `/workspace/logs/app.log`
- **Log przetwarzania**: `/workspace/logs/book_workflow.log`
- **Log błędów**: `/workspace/logs/error.log`

### Pasek postępu
W trybie interaktywnym wyświetlany jest pasek postępu:
```
[████████████░░░░] 65% - Processing chapter 3/8
```

---

## Rozwiązywanie problemów

### Problem: Brak plików w `/input/`
**Rozwiązanie**: Sprawdź, czy pliki `.txt` i `.md` istnieją:
```bash
ls -la /workspace/input/*.txt /workspace/input/*.md
```

### Problem: Błędy parsowania Markdown
**Rozwiązanie**: Zweryfikuj składnię plików:
```bash
# Ręczna inspekcja problematicznego pliku
cat /workspace/input/problematic_file.md
```

### Problem: Niekompletne chunki
**Rozwiązanie**: Sprawdź logi i uruchom ponownie z flagą `--debug`:
```bash
./qwen-tam.sh --debug --workflow book-from-input
```

### Problem: Brak miejsca na dysku
**Rozwiązanie**: Wyczyść katalog `/chunk/` z tymczasowych plików:
```bash
rm -rf /workspace/chunk/*
```

---

## Wymagania systemowe

| Komponent | Wymaganie |
|-----------|-----------|
| System | Linux (Raspberry Pi OS, Ubuntu, Debian) |
| Bash | Wersja 4.0+ |
| Python | 3.8+ (opcjonalnie, dla zaawansowanych funkcji AI) |
| Pamięć RAM | Minimum 2GB (zalecane 4GB) |
| Miejsce na dysku | 1GB wolnego miejsca |

---

## Przykładowe użycie - sesja krok po kroku

```bash
# 1. Przygotowanie środowiska
mkdir -p /workspace/input /workspace/chunk /workspace/finish

# 2. Kopiowanie plików źródłowych
cp ~/moje_notatki/*.md /workspace/input/
cp ~/dokumenty/brudnopis.txt /workspace/input/

# 3. Uruchomienie workflow
cd /workspace
./qwen-tam.sh

# 4. W menu wybierz:
#    [4] Automation
#    → Book Processing
#    → Start Full Workflow

# 5. Poczekaj na zakończenie przetwarzania
# 6. Sprawdź wyniki w /workspace/finish/
ls -la /workspace/finish/

# 7. Przegląd gotowej książki
cat /workspace/finish/book_complete.md
```

---

## Podsumowanie

Ten workflow automatyzuje kompletny proces tworzenia książki:

1. ✅ **Input**: Pliki `.txt` i `.md` z katalogu `/input/`
2. ✅ **Chunking**: Podział na fragmenty w katalogu `/chunk/`
3. ✅ **Strukturyzacja**: Tworzenie rozdziałów i podrozdziałów
4. ✅ **Redakcja**: Przeredagowanie i scalenie treści
5. ✅ **Output**: Gotowa książka w katalogu `/finish/`

Wszystko zarządzane przez centralny skrypt `qwen-tam.sh` z możliwością pracy w trybie interaktywnym lub z linii poleceń.

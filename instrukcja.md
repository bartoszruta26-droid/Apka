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
# Instrukcja obsługi - System Przetwarzania Dokumentów i Generowania Aplikacji

## 1. Opis systemu

### Cel systemu
Niniejsza instrukcja opisuje **kompleksowy system przetwarzania dokumentów Markdown** który umożliwia:
- Przetwarzanie plików Markdown z katalogu `/input/`
- Generowanie streszczeń na różnych poziomach szczegółowości
- Automatyczne tworzenie książek w formatach MD/PDF/EPUB
- Tworzenie aplikacji w katalogu `/apka/` z interfejsami TUI/WebUI/GUI/Android

### Narzędzie realizujące: qwen-tam.sh
Do realizacji powyższych funkcji wykorzystujemy **QWEN TIME & AUTOMATION MANAGER** (qwen-tam.sh) - zaawansowane narzędzie TUI które poprzez moduły AI Code Generation oraz Automation pozwala na zautomatyzowane tworzenie wszystkich wymienionych komponentów.

### Główne funkcjonalności realizowane przez qwen-tam.sh
- **Generowanie skryptów przetwarzających Markdown** - moduł Coder tworzy dedykowane skrypty bash/python
- **AI-powered stresszczenia** - wykorzystanie modelu Qwen do analizy tekstu i generowania podsumowań
- **Konwersja formatów** - automatyczne tworzenie pipeline'ów konwertujących MD→PDF→EPUB
- **Generowanie aplikacji** - tworzenie kompletnych projektów TUI/WebUI/GUI/Android w `/apka/`

### Wymagania
- Bash 4.0+
- Dostęp do modelu Qwen (lokalny endpoint np. Ollama na http://localhost:11434)
- Narzędzia: pandoc, wkhtmltopdf, ebook-tool (do konwersji formatów)
- Opcjonalnie: token GitHub API do version controlu

---

## 2. Struktura katalogów roboczych

```
/workspace/
├── qwen-tam.sh          # Główne narzędzie realizujące zadania
├── input/               # Katalog wejściowy z plikami Markdown
│   ├── rozdzial1.md
│   ├── rozdzial2.md
│   └── ...
├── apka/                # Katalog wyjściowy dla generowanych aplikacji
│   ├── tui_app/         # Aplikacja terminalowa
│   ├── webui_app/       # Aplikacja webowa
│   ├── gui_app/         # Aplikacja z interfejsem graficznym
│   └── android_app/     # Aplikacja mobilna
├── output/              # Wygenerowane książki i streszczenia
│   ├── books/           # Książki w różnych formatach
│   ├── summaries/       # Streszczenia na różnych poziomach
│   └── reports/         # Raporty z przetwarzania
├── scripts/             # Moduły funkcjonalne qwen-tam.sh
│   ├── coder.sh         # Generowanie kodu z AI (KLUCZOWY MODUŁ)
│   ├── automation.sh    # Automatyzacja zadań
│   ├── verify.sh        # Weryfikacja wygenerowanego kodu
│   └── ...
└── projects/            # Projekty tymczasowe
```

---

## 3. Jak wykorzystać qwen-tam.sh krok po kroku

### PRZYGOTOWANIE ŚRODOWISKA

#### Krok 1: Przygotowanie katalogów
```bash
mkdir -p /workspace/input
mkdir -p /workspace/apka/{tui_app,webui_app,gui_app,android_app}
mkdir -p /workspace/output/{books,summaries,reports}
chmod +x /workspace/qwen-tam.sh
```

#### Krok 2: Przygotowanie plików wejściowych
Umieść pliki Markdown w `/workspace/input/`:
```bash
/workspace/input/
├── 01_wstep.md
├── 02_rozdzial_glowny.md
├── 03_podsumowanie.md
└── metadata.yaml
```

#### Krok 3: Konfiguracja modelu Qwen
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen-coder:latest
curl http://localhost:11434/api/tags
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
### SCENARIUSZ 1: Przetwarzanie plików Markdown z /input/

#### Realizacja przez qwen-tam.sh:

**Krok 1.1:** Uruchom qwen-tam.sh
```bash
cd /workspace && ./qwen-tam.sh
```

**Krok 1.2:** Wybierz opcję `2` - Qwen Coder - Code Generation

**Krok 1.3:** Wybierz `2.2` - Create/Update Shell Script

**Krok 1.4:** Podaj ścieżkę: `/workspace/scripts/process_markdown.sh`

**Krok 1.5:** Prompt dla AI:
```
Create a bash script that processes all Markdown files from /workspace/input/ directory.
The script should:
1. Read all .md files from /input/ in alphabetical order
2. Concatenate them into /workspace/output/combined.md
3. Extract frontmatter metadata
4. Generate table of contents
5. Create JSON index with file statistics
6. Handle errors and log operations
7. Support verbose mode with -v flag
```

**Krok 1.6:** Zweryfikuj (opcja `3` → `3.1`) i uruchom:
```bash
chmod +x /workspace/scripts/process_markdown.sh
/workspace/scripts/process_markdown.sh -v
```

---

### SCENARIUSZ 2: Generowanie streszczeń na różnych poziomach

#### Realizacja przez qwen-tam.sh:

**Krok 2.1:** Opcja `2` → `2.2`

**Krok 2.2:** Ścieżka: `/workspace/scripts/generate_summaries.sh`

**Krok 2.3:** Prompt dla AI:
```
Create a bash script that generates summaries at 3 levels:
- Level 1: One-sentence summary (max 20 words)
- Level 2: Short paragraph (max 100 words)
- Level 3: Detailed summary with bullets (max 500 words)
Use Qwen AI API. Save to /workspace/output/summaries/
```

**Krok 2.4:** Zweryfikuj i uruchom:
```bash
chmod +x /workspace/scripts/generate_summaries.sh
/workspace/scripts/generate_summaries.sh
```

---

### SCENARIUSZ 3: Automatyczne tworzenie książek (MD/PDF/EPUB)

#### Realizacja przez qwen-tam.sh:

**Krok 3.1:** Opcja `2` → `2.2`

**Krok 3.2:** Ścieżka: `/workspace/scripts/create_books.sh`

**Krok 3.3:** Prompt dla AI:
```
Create bash script converting Markdown to multiple book formats:
1. Check for pandoc, wkhtmltopdf, epub tools
2. Generate MD book with TOC and metadata
3. Convert to PDF with CSS styling, A4, bookmarks
4. Create EPUB3 with navigation and responsive layout
5. Quality control and validation
6. Logging and error handling
Save outputs to /workspace/output/books/
```

**Krok 3.4:** Uruchom:
```bash
chmod +x /workspace/scripts/create_books.sh
/workspace/scripts/create_books.sh --verbose
```

---

### SCENARIUSZ 4: Tworzenie aplikacji w /apka/

#### 4.1 Aplikacja TUI
**Krok:** Opcja `2` → `2.1`
**Ścieżka:** `/workspace/apka/tui_app`
**Prompt:**
```
Create TUI bash application displaying:
1. List of books from /workspace/output/books/
2. Summary reader with level selector
3. Search functionality
4. Navigation with keyboard shortcuts
5. ANSI color output
Structure: main.sh, lib/, config/, data/
```

#### 4.2 Aplikacja WebUI
**Krok:** Opcja `2` → `2.4`
**Ścieżka:** `/workspace/apka/webui_app`
**Prompt:**
```
Create Flask web app with:
1. Book list homepage
2. Markdown reader
3. Summary viewer (levels 1/2/3)
4. Search engine
5. PDF/EPUB download buttons
6. Responsive design
7. REST API
8. Admin upload panel
Structure: app.py, templates/, static/, api/
```

#### 4.3 Aplikacja GUI
**Krok:** Opcja `2` → `2.3` lub `2.1` (Python Tkinter)
**Ścieżka:** `/workspace/apka/gui_app`
**Prompt:**
```
Create Python Tkinter desktop app:
1. Book library view
2. Markdown preview panel
3. Chapter navigation sidebar
4. Summary panel with detail toggle
5. Real-time search
6. Export options (PDF/EPUB/TXT)
7. Settings dialog
8. Dark/Light themes
Structure: main.py, gui/, core/, assets/
```

#### 4.4 Aplikacja Android
**Krok:** Opcja `2` → `2.5`
**Ścieżka:** `/workspace/apka/android_app`
**Prompt:**
```
Create Kotlin Android app:
1. Splash screen
2. Book list (RecyclerView)
3. Chapter navigation
4. Markdown reader
5. Summary fragment with levels
6. Search with suggestions
7. Room database for offline
8. PDF/EPUB download manager
9. Settings, Dark mode
Standard Android structure with Material Design
```

---

## 4. Kompletne workflow

```bash
# ETAP 1: Przygotowanie
mkdir -p /workspace/{input,apka,output/{books,summaries}}
cp *.md /workspace/input/

# ETAP 2: Generowanie przez qwen-tam.sh
./qwen-tam.sh
# [2]→[2.2] → process_markdown.sh
# [2]→[2.2] → generate_summaries.sh
# [2]→[2.2] → create_books.sh
# [2]→[2.1/2.4/2.3/2.5] → aplikacje w /apka/

# ETAP 3: Weryfikacja (opcja 3)

# ETAP 4: Uruchomienie pipeline
/workspace/scripts/process_markdown.sh
/workspace/scripts/generate_summaries.sh
/workspace/scripts/create_books.sh

# ETAP 5: Aplikacje
cd /workspace/apka/tui_app && ./main.sh
cd /workspace/apka/webui_app && python app.py
cd /workspace/apka/gui_app && python main.py
```

---

## 5. Tryby CLI

```bash
./qwen-tam.sh --generate-code "Bash script to process markdown from /input/"
./qwen-tam.sh --generate-project "/workspace/apka/webui_app" --type flask
./qwen-tam.sh --verify "/workspace/scripts/*.sh"
./qwen-tam.sh --automate "markdown_pipeline"
./qwen-tam.sh --ai-chat "How to optimize PDF conversion?"
```

---

## 6. Podsumowanie - mapa funkcji

| Cel | Funkcja qwen-tam.sh | Opcja |
|-----|---------------------|-------|
| Przetwarzanie MD | Code Generation → Shell | 2.2 |
| Streszczenia | Code Gen + AI Discussion | 2.2 + 4.1 |
| Książki MD/PDF/EPUB | Code Gen + Automation | 2.2 + 4.2 |
| TUI App | Project Structure | 2.1 |
| WebUI App | WebUI Script | 2.4 |
| GUI App | GUI Code | 2.3 |
| Android App | Android App | 2.5 |
| Weryfikacja | Code Verification | 3.x |
| Automatyzacja | Automation Agent | 4.x |

---

## 7. Sesja 30-minutowa

```bash
# 0-5 min: mkdir /workspace/input, dodaj pliki .md
# 5-10 min: ./qwen-tam.sh → generuj 3 skrypty
# 10-15 min: Weryfikacja (opcja 3)
# 15-20 min: Uruchom skrypty
# 20-30 min: Generuj 4 aplikacje w /apka/

# GOTOWE: dokumenty w /output/, aplikacje w /apka/
```

---

## 8. Rozwiązywanie problemów

| Problem | Rozwiązanie |
|---------|-------------|
| Qwen nie odpowiada | Sprawdź `systemctl status ollama`, opcja 7.4 |
| Błędy w kodzie | Opcja 3 (Verification), potem 2.6 (Edit with AI) |
| Brak zależności | Opcja 4.1 (AI Discussion) - zapytaj o pakiety |
| Aplikacje nie działają | Sprawdź logi, `chmod +x`, uruchom z `-v` |

---

## 9. Najlepsze praktyki

1. Zawsze weryfikuj kod (opcja 3)
2. Testuj na małych plikach
3. Używaj `--debug` podczas rozwoju
4. Backupuj `/output/` i `/apka/`
5. Monitoruj logi przy pierwszym uruchomieniu
6. Dostosuj prompty do swoich potrzeb
7. Automatyzuj powtarzalne zadania

---

Ten workflow automatyzuje kompletny proces tworzenia książki:

1. ✅ **Input**: Pliki `.txt` i `.md` z katalogu `/input/`
2. ✅ **Chunking**: Podział na fragmenty w katalogu `/chunk/`
3. ✅ **Strukturyzacja**: Tworzenie rozdziałów i podrozdziałów
4. ✅ **Redakcja**: Przeredagowanie i scalenie treści
5. ✅ **Output**: Gotowa książka w katalogu `/finish/`

Wszystko zarządzane przez centralny skrypt `qwen-tam.sh` z możliwością pracy w trybie interaktywnym lub z linii poleceń.
## 10. Licencja

Instrukcja opisuje wykorzystanie qwen-tam.sh do budowy systemu przetwarzania dokumentów.

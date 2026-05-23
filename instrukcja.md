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

---

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

## 10. Licencja

Instrukcja opisuje wykorzystanie qwen-tam.sh do budowy systemu przetwarzania dokumentów.

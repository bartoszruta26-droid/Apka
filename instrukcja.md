# Instrukcja obsługi aplikacji do przetwarzania plików Markdown i tworzenia książek

## 1. Jak wykorzystać aplikację do wczytania plików .md z katalogu /input/

### Cel aplikacji
Aplikacja służy do automatycznego przetwarzania plików Markdown (.md) umieszczonych w katalogu `/input/`, dzielenia ich na części, generowania streszczeń na różnych poziomach (plik, rozdział, podrozdział) oraz zautomatyzowanego tworzenia kompletnej książki na podstawie zebranych materiałów.

### Struktura katalogów
```
/workspace
├── input/          # Katalog wejściowy na pliki .md
├── apka/           # Katalog aplikacji (do utworzenia)
└── instrukcja.md   # Ten plik
```

### Krok po kroku - Przetwarzanie plików

#### Krok 1: Przygotowanie plików wejściowych
1. Umieść wszystkie pliki Markdown (.md) w katalogu `/workspace/input/`
2. Pliki powinny być nazwane w sposób uporządkowany (np. `01_wstep.md`, `02_rozdzial1.md`)
3. Każdy plik może zawierać strukturę nagłówków:
   ```markdown
   # Tytuł rozdziału
   
   ## Podrozdział 1.1
   
   Treść podrozdziału...
   
   ## Podrozdział 1.2
   
   Treść podrozdziału...
   ```

#### Krok 2: Wczytanie i parsowanie plików
Aplikacja wykonuje następujące operacje:
- Skanuje katalog `/input/` w poszukiwaniu plików `.md`
- Wczytuje zawartość każdego pliku
- Parsuje strukturę nagłówków (H1, H2, H3, itd.)
- Identyfikuje rozdziały i podrozdziały

#### Krok 3: Podział na części
System automatycznie dzieli treść na:
- **Części główne** - odpowiadające nagłówkom poziomu 1 (#)
- **Rozdziały** - odpowiadające nagłówkom poziomu 2 (##)
- **Podrozdziały** - odpowiadające nagłówkom poziomu 3 (###) i głębiej

#### Krok 4: Generowanie streszczeń
Dla każdej jednostki tekstu aplikacja tworzy streszczenia:

1. **Streszczenie pliku** - krótkie podsumowanie całego pliku .md
2. **Streszczenie rozdziału** - podsumowanie treści danego rozdziału
3. **Streszczenie podrozdziału** - esencja treści podrozdziału

Proces wykorzystuje algorytmy NLP lub modele AI do ekstrakcji kluczowych informacji.

#### Krok 5: Automatyczne tworzenie książki
Na podstawie zebranych części i streszczeń aplikacja:
1. Generuje spis treści
2. Tworzy wstęp książki (na podstawie streszczeń wszystkich rozdziałów)
3. Łączy wszystkie elementy w spójną całość
4. Dodaje indeksy i odnośniki
5. Eksportuje wynikowy plik książki w formacie:
   - Markdown (.md)
   - PDF (poprzez konwersję)
   - EPUB (dla czytników e-booków)

### Przykładowe użycie (szkic kodu Python)

```python
import os
from pathlib import Path

class BookGenerator:
    def __init__(self, input_dir='/workspace/input'):
        self.input_dir = Path(input_dir)
        self.chapters = []
        self.summaries = {}
    
    def load_markdown_files(self):
        """Wczytaj wszystkie pliki .md z katalogu input"""
        files = sorted(self.input_dir.glob('*.md'))
        for file in files:
            with open(file, 'r', encoding='utf-8') as f:
                content = f.read()
                self.parse_chapters(content, file.name)
    
    def parse_chapters(self, content, filename):
        """Parsuj content na rozdziały i podrozdziały"""
        # Implementacja parsera nagłówków
        pass
    
    def generate_summary(self, text, level='chapter'):
        """Generuj streszczenie dla danego tekstu"""
        # Implementacja algorytmu podsumowującego
        pass
    
    def compile_book(self):
        """Złożenie całej książki z części i streszczeń"""
        # Generowanie finalnej książki
        pass
```

---

## 2. Proces tworzenia nowej aplikacji w katalogu /apka/

### Krok 1: Utworzenie katalogu /apka/
```bash
mkdir -p /workspace/apka
cd /workspace/apka
```

### Krok 2: Przygotowanie ogólnych założeń w pliku readme_app.md

Plik `readme_app.md` powinien zawierać:
- Opis celu aplikacji
- Wymagania funkcjonalne
- Wymagania niefunkcjonalne
- Architekturę systemu
- Technologie do wykorzystania
- Harmonogram prac

### Krok 3: Rozbudowanie pliku o różne funkcje

W `readme_app.md` należy szczegółowo opisać:

#### Funkcje podstawowe:
- Wczytywanie plików Markdown
- Parsowanie struktury dokumentu
- Generowanie streszczeń
- Eksport do różnych formatów

#### Funkcje zaawansowane:
- Integracja z API AI (np. GPT, Claude)
- Wielowątkowe przetwarzanie
- Cache'owanie wyników
- Konfiguracja przez plik YAML/JSON

#### Funkcje dodatkowe:
- Statystyki tekstu
- Wykrywanie języka
- Tłumaczenie automatyczne
- Korekta gramatyczna

### Krok 4: Napisanie szkieletu skryptu

Szkielet główny aplikacji (`main.py`):

```python
#!/usr/bin/env python3
"""
Główny moduł aplikacji do przetwarzania Markdown
"""

def main():
    """Punkt wejścia aplikacji"""
    pass

if __name__ == '__main__':
    main()
```

Struktura katalogów aplikacji:
```
apka/
├── main.py              # Punkt wejścia
├── requirements.txt     # Zależności
├── config.yaml          # Konfiguracja
├── src/
│   ├── __init__.py
│   ├── loader.py        # Wczytywanie plików
│   ├── parser.py        # Parsowanie Markdown
│   ├── summarizer.py    # Generowanie streszczeń
│   ├── compiler.py      # Kompilowanie książki
│   └── utils.py         # Funkcje pomocnicze
├── tests/               # Testy jednostkowe
├── docs/                # Dokumentacja
└── output/              # Wyniki pracy
```

### Krok 5: Liczne uzupełnienie szkieletu o funkcje

Należy zaimplementować:

1. **Moduł loader.py**:
   - `load_file(path)` - wczytanie pojedynczego pliku
   - `load_directory(path)` - wczytanie całego katalogu
   - `validate_markdown(content)` - walidacja składni

2. **Moduł parser.py**:
   - `extract_headers(content)` - ekstrakcja nagłówków
   - `build_tree(headers)` - budowa drzewa struktury
   - `split_by_level(content, level)` - podział po poziomie

3. **Moduł summarizer.py**:
   - `summarize_text(text, ratio)` - podsumowanie tekstu
   - `extract_keywords(text)` - ekstrakcja słów kluczowych
   - `generate_abstract(chapters)` - generowanie abstraktu

4. **Moduł compiler.py**:
   - `compile_toc(chapters)` - tworzenie spisu treści
   - `compile_book(chapters, summaries)` - kompilacja książki
   - `export_pdf(content)` - eksport do PDF
   - `export_epub(content)` - eksport do EPUB

### Krok 6: Weryfikacja błędów

Implementacja obsługi błędów:
- Try-except dla wszystkich operacji I/O
- Walidacja danych wejściowych
- Logowanie błędów do pliku
- Testy jednostkowe pokrycia >80%
- Continuous Integration (CI/CD)

Przykład:
```python
try:
    content = load_file(path)
except FileNotFoundError:
    logger.error(f"Plik nie znaleziony: {path}")
except UnicodeDecodeError:
    logger.error(f"Błąd kodowania w pliku: {path}")
```

### Krok 7: Stworzenie TUI (Terminal User Interface)

Wykorzystaj biblioteki:
- **Rich** - bogate wyjście terminala
- **Textual** - framework TUI
- **Questionary** - interaktywne pytania

Funkcje TUI:
- Interaktywny wybór plików
- Pasek postępu przetwarzania
- Podgląd na żywo generowanych treści
- Menu konfiguracyjne

### Krok 8: Stworzenie WebUI (Web User Interface)

Technologie:
- **Backend**: FastAPI lub Flask
- **Frontend**: React, Vue.js lub Streamlit
- **Baza danych**: SQLite lub PostgreSQL

Funkcje WebUI:
- Przeciągnij-i-upuść plików
- Dashboard z postępem
- Edytor online
- Pobieranie wyników
- Historia przetworzeń

### Krok 9: Stworzenie GUI (Graphical User Interface)

Technologie:
- **Tkinter** - wbudowany w Python
- **PyQt6** - zaawansowane GUI
- **Kivy** - cross-platform

Funkcje GUI:
- Okno główne z menu
- Panel nawigacji plików
- Okno podglądu
- Dialogi konfiguracji
- Powiadomienia systemowe

### Krok 10: Stworzenie Android App

Technologie:
- **Kivy + Buildozer** - Python na Android
- **Flutter** - Dart, cross-platform
- **React Native** - JavaScript
- **Native Kotlin** - natywny Android

Funkcje Android App:
- Menadżer plików lokalnych
- Przetwarzanie offline
- Synchronizacja z chmurą
- Powiadomienia push
- Udostępnianie plików

### Plan realizacji

| Etap | Zadanie | Czas szacowany |
|------|---------|----------------|
| 1 | Utworzenie szkieletu | 1 dzień |
| 2 | Implementacja core | 3 dni |
| 3 | Testy i debugowanie | 2 dni |
| 4 | TUI | 2 dni |
| 5 | WebUI | 4 dni |
| 6 | GUI desktop | 3 dni |
| 7 | Android app | 5 dni |
| 8 | Dokumentacja | 2 dni |

### Wymagania sprzętowe
- Python 3.9+
- Minimum 4GB RAM
- 1GB wolnego miejsca na dysku
- Połączenie internetowe (dla funkcji AI)

### Licencja
Projekt dostępny na licencji MIT lub Apache 2.0

---

## Podsumowanie

Ta instrukcja opisuje kompletny proces:
1. Przygotowania środowiska do przetwarzania plików Markdown
2. Automatyzacji tworzenia książek z wielu źródeł
3. Budowy profesjonalnej aplikacji z wieloma interfejsami (TUI, WebUI, GUI, Mobile)

Każdy etap można realizować iteracyjnie, testując i doskonaląc poszczególne komponenty.

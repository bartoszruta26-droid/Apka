# Instrukcja obsługi QWEN TIME & AUTOMATION MANAGER (qwen-tam.sh)

## 1. Opis aplikacji

### Cel aplikacji
**QWEN TIME & AUTOMATION MANAGER** (w skrócie Qwen-TAM) to zaawansowane narzędzie typu TUI (Terminal User Interface) przeznaczone głównie dla Raspberry Pi 4, które integruje model AI Qwen Coder z codziennymi zadaniami programistycznymi i administracyjnymi.

### Główne funkcjonalności
- **Zarządzanie repozytoriami GitHub** - tworzenie, klonowanie, synchronizacja
- **Generowanie kodu z AI** - wykorzystanie lokalnego modelu Qwen do tworzenia kodu
- **Weryfikacja kodu** - sprawdzanie składni, bezpieczeństwo, testy
- **Automatyzacja zadań** - workflow, harmonogramy, AI Agent
- **Monitorowanie systemu** - logi, zasoby, temperatura
- **Konfiguracja** - zarządzanie ustawieniami i tokenami API

### Wymagania
- Bash 4.0+
- Dostęp do modelu Qwen (lokalny endpoint np. Ollama na http://localhost:11434)
- Opcjonalnie: token GitHub API

---

## 2. Struktura aplikacji

```
/workspace/
├── qwen-tam.sh          # Główny skrypt uruchamiający
├── scripts/             # Moduły funkcjonalne
│   ├── auth.sh          # Autoryzacja i credentials
│   ├── repo.sh          # Operacje na repozytoriach GitHub
│   ├── coder.sh         # Generowanie kodu z AI
│   ├── verify.sh        # Weryfikacja kodu
│   ├── automation.sh    # Automatyzacja zadań
│   ├── config.sh        # Konfiguracja
│   ├── logs.sh          # Zarządzanie logami
│   ├── system.sh        # Informacje o systemie
│   ├── update.sh        # Aktualizacje aplikacji
│   └── lib/             # Biblioteki pomocnicze
├── logs/                # Katalog z logami (tworzony automatycznie)
├── config/              # Pliki konfiguracyjne
└── projects/            # Wygenerowane projekty
```

---

## 3. Jak wykorzystać qwen-tam.sh krok po kroku

### Krok 1: Przygotowanie środowiska

1. **Upewnij się że skrypt ma uprawnienia do wykonania:**
```bash
chmod +x /workspace/qwen-tam.sh
```

2. **Skonfiguruj dostęp do modelu Qwen:**
   - Zainstaluj Ollama: `curl -fsSL https://ollama.com/install.sh | sh`
   - Pobierz model: `ollama pull qwen-coder:latest`
   - Lub skonfiguruj zdalny endpoint API

3. **Opcjonalnie - skonfiguruj token GitHub:**
   - Wygeneruj token w GitHub Settings → Developer settings → Personal access tokens
   - Token będzie potrzebny do operacji na repozytoriach

---

### Krok 2: Uruchomienie aplikacji

#### Tryb interaktywny (domyślny):
```bash
cd /workspace
./qwen-tam.sh
```

#### Tryb z debugowaniem:
```bash
./qwen-tam.sh --debug
```

#### Tryb verbose (szczegółowe logi):
```bash
./qwen-tam.sh --verbose
```

#### Tryb daemon (w tle):
```bash
./qwen-tam.sh --daemon
```

#### Pokaż pomoc:
```bash
./qwen-tam.sh --help
```

---

### Krok 3: Nawigacja w menu głównym

Po uruchomieniu zobaczysz menu główne z opcjami:

```
╔══════════════════════════════════════════════════════════════╗
║           QWEN TIME & AUTOMATION MANAGER v1.0                ║
║                    Raspberry Pi 4 Edition                    ║
╠══════════════════════════════════════════════════════════════╣
║  MAIN MENU                                                   ║
╠══════════════════════════════════════════════════════════════╣
║  [1] 📁 GitHub Repository Management                         ║
║  [2] 🤖 Qwen Coder - Code Generation                         ║
║  [3] ✅ Code Verification                                    ║
║  [4] 🔄 Automation & AI Agent                                ║
║  [5] ⚙️  Configuration & Settings                            ║
║  [6] 📊 Logs & Monitoring                                    ║
║  [7] ℹ️  System Information                                  ║
║  [8] 🔄 Update Application                                   ║
║  [9] 🚪 Exit                                                 ║
╠══════════════════════════════════════════════════════════════╣
║  Status: ● Connected  |  Mode: Interactive  |  Debug: OFF   ║
║  Press 'D' for Debug mode | 'V' for Verbose | 'Q' to quit   ║
╚══════════════════════════════════════════════════════════════╝
```

**Skróty klawiszowe:**
- `D` - włącz/wyłącz tryb debugowania
- `V` - włącz/wyłącz tryb verbose
- `Q` - wyjście z aplikacji

---

## 4. Szczegółowy opis funkcji

### 4.1 GitHub Repository Management (opcja 1)

**Dostępne podfunkcje:**
- `1.1` - Konfiguracja credentials GitHub
- `1.2` - Utwórz nowe repozytorium
- `1.3` - Lista Twoich repozytoriów
- `1.4` - Usuń repozytorium
- `1.5` - Sklonuj repozytorium
- `1.6` - Synchronizuj lokalne ze zdalnym

**Przykład - tworzenie repozytorium:**
1. Wybierz opcję `1` z menu głównego
2. Wybierz `1.2` (Create New Repository)
3. Podaj nazwę repozytorium
4. Wybierz widoczność (public/private)
5. Potwierdź utworzenie

---

### 4.2 Qwen Coder - Code Generation (opcja 2)

**Dostępne podfunkcje:**
- `2.1` - Utwórz/zaktualizuj strukturę projektu
- `2.2` - Utwórz/zaktualizuj skrypt Shell
- `2.3` - Utwórz/zaktualizuj kod C/C#/C++ z GUI
- `2.4` - Utwórz/zaktualizuj WebUI
- `2.5` - Utwórz/zaktualizuj aplikację Android
- `2.6` - Edytuj istniejący plik z AI

**Przykład - generowanie projektu Python:**
1. Wybierz opcję `2` z menu głównego
2. Wybierz `2.1` (Create/Update Project Structure)
3. Podaj nazwę projektu: `moj_projekt`
4. Wybierz typ projektu: `python`
5. AI wygeneruje strukturę katalogów:
   ```
   moj_projekt/
   ├── main.py
   ├── requirements.txt
   ├── README.md
   └── src/
   ```

**Przykład - generowanie skryptu bash:**
1. Wybierz opcję `2` → `2.2`
2. Podaj ścieżkę: `/workspace/scripts/moj_skrypt.sh`
3. Opisz co skrypt ma robić: "Skrypt do backupu katalogu /home"
4. AI wygeneruje kompletny skrypt z obsługą błędów

---

### 4.3 Code Verification (opcja 3)

**Dostępne podfunkcje:**
- `3.1` - Sprawdzenie składni Shell
- `3.2` - Sprawdzenie składni C/C++
- `3.3` - Skanowanie bezpieczeństwa
- `3.4` - Sprawdzenie stylu kodu
- `3.5` - Uruchom testy jednostkowe
- `3.6` - Generuj raport weryfikacji

**Przykład - weryfikacja skryptu:**
1. Wybierz opcję `3` → `3.1`
2. Podaj ścieżkę do pliku: `/workspace/scripts/test.sh`
3. Skrypt zostanie sprawdzony pod kątem:
   - Poprawności składni
   - Niezdefiniowanych zmiennych
   - Potencjalnych błędów

---

### 4.4 Automation & AI Agent (opcja 4)

**Dostępne podfunkcje:**
- `4.1` - Sesja dyskusji z AI
- `4.2` - Utwórz workflow automatyzacji
- `4.3` - Uruchom zadanie automatyzacji
- `4.4` - Pauza/wznowienie zadań w tle
- `4.5` - Zatrzymaj działające zadania
- `4.6` - Zaplanuj zadanie (cron)
- `4.7` - Historia zadań
- `4.8` - Szybkie automatyzacje:
  - `4.8.1` - Auto-commit & Push
  - `4.8.2` - Dzienny backup
  - `4.8.3` - Pętla code review
  - `4.8.4` - Własny skrypt

**Przykład - automatyczny commit:**
1. Wybierz opcję `4` → `4.8` → `4.8.1`
2. Skrypt automatycznie:
   - Dodaje zmienione pliki do git
   - Tworzy commit z opisem zmian
   - Pushuje do zdalnego repozytorium

---

### 4.5 Configuration & Settings (opcja 5)

**Dostępne podfunkcje:**
- `5.1` - Zarządzanie tokenem GitHub
- `5.2` - Konfiguracja endpointu Qwen API
- `5.3` - Ustawienie katalogu roboczego
- `5.4` - Opcje wyświetlania i motyw
- `5.5` - Ustawienia powiadomień
- `5.6` - Backup konfiguracji
- `5.7` - Przywracanie konfiguracji
- `5.8` - Reset do ustawień domyślnych

---

### 4.6 Logs & Monitoring (opcja 6)

**Dostępne podfunkcje:**
- `6.1` - Podgląd app.log
- `6.2` - Podgląd debug.log
- `6.3` - Podgląd events.log
- `6.4` - Wyszukiwanie w logach
- `6.5` - Czyszczenie starych logów
- `6.6` - Eksport logów
- `6.7` - Monitorowanie logów w czasie rzeczywistym

**Przykład - monitorowanie na żywo:**
1. Wybierz opcję `6` → `6.7`
2. Logi będą wyświetlane na bieżąco jak w `tail -f`

---

### 4.7 System Information (opcja 7)

**Dostępne podfunkcje:**
- `7.1` - Zasoby systemu (CPU/RAM/Dysk)
- `7.2` - Temperatura i status zdrowia (Raspberry Pi)
- `7.3` - Zainstalowane zależności
- `7.4` - Status modelu Qwen
- `7.5` - Łączność sieciowa
- `7.6` - Wersja i changelog

---

### 4.8 Update Application (opcja 8)

**Dostępne podfunkcje:**
- `8.1` - Sprawdź aktualizacje
- `8.2` - Pobierz najnowszą wersję
- `8.3` - Auto-instalacja zależności
- `8.4` - Instalacja aktualizacji
- `8.5` - Przegląd changelog
- `8.6` - Cofnij do poprzedniej wersji
- `8.7` - Konfiguracja auto-update
- `8.8` - Aktualizacja węzłów klastra

---

## 5. Przykłady użycia w praktyce

### Scenariusz 1: Nowy projekt z AI

1. Uruchom: `./qwen-tam.sh`
2. Wybierz `2` → `2.1`
3. Podaj nazwę: `api_server`
4. Typ: `python_fastapi`
5. AI stworzy kompletną strukturę z:
   - `main.py`
   - `requirements.txt`
   - `config.yaml`
   - Testami w `/tests/`

### Scenariusz 2: Backup repozytorium

1. Uruchom: `./qwen-tam.sh --debug`
2. Wybierz `4` → `4.8` → `4.8.2`
3. Skrypt wykona backup wszystkich repozytoriów

### Scenariusz 3: Weryfikacja bezpieczeństwa

1. Uruchom: `./qwen-tam.sh`
2. Wybierz `3` → `3.3`
3. Podaj ścieżkę: `/workspace/scripts/`
4. Otrzymasz raport potencjalnych zagrożeń

---

## 6. Tryby pracy z linii poleceń

Aplikacja wspiera również tryb CLI bez menu interaktywnego:

```bash
# Tworzenie repozytorium
./qwen-tam.sh --create-repo "nazwa-repo"

# Generowanie kodu
./qwen-tam.sh --generate-code "stworz skrypt backupu"

# Weryfikacja pliku
./qwen-tam.sh --verify "/workspace/scripts/test.sh"

# Automatyzacja
./qwen-tam.sh --automate "daily_backup"
```

---

## 7. Logi i diagnostyka

Lokalizacje logów:
- **app.log** - główne zdarzenia aplikacji
- **debug.log** - szczegółowe informacje debugowe
- **events.log** - historia zdarzeń użytkownika

```bash
# Podgląd logów na żywo
tail -f /workspace/logs/app.log

# Wyszukaj błędy
grep "ERROR" /workspace/logs/app.log
```

---

## 8. Rozwiązywanie problemów

### Problem: Model Qwen nie odpowiada
**Rozwiązanie:**
1. Sprawdź czy Ollama działa: `systemctl status ollama`
2. Zweryfikuj endpoint: `curl http://localhost:11434/api/tags`
3. W menu `5.2` ustaw poprawny endpoint

### Problem: Błąd autoryzacji GitHub
**Rozwiązanie:**
1. Wygeneruj nowy token w GitHub
2. W menu wybierz `5.1` → wprowadź nowy token
3. Upewnij się że token ma uprawnienia `repo`

### Problem: Skrypty nie mają uprawnień
**Rozwiązanie:**
```bash
chmod +x /workspace/scripts/*.sh
chmod +x /workspace/qwen-tam.sh
```

---

## 9. Podsumowanie

**qwen-tam.sh** to kompleksowe narzędzie które umożliwia:

| Funkcja | Opis | Menu |
|---------|------|------|
| GitHub | Zarządzanie repozytoriami | 1 |
| Code Gen | Generowanie kodu z AI | 2 |
| Verify | Weryfikacja i testy | 3 |
| Automate | Automatyzacja zadań | 4 |
| Config | Konfiguracja | 5 |
| Logs | Monitorowanie logów | 6 |
| System | Info o systemie | 7 |
| Update | Aktualizacje | 8 |

Każda funkcja jest realizowana przez dedykowany moduł w katalogu `scripts/`, co ułatwia rozwój i utrzymanie aplikacji.

---

## 10. Licencja

Projekt dostępny na licencji MIT.
